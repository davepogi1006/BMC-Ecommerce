import {
  FirebaseApiError,
  firebaseServiceIdentity,
  getUserRole,
  listUserProfiles,
  setUserDisabled,
  updateUserProfile,
  updateUserRole,
  verifyFirebaseToken,
} from "../_shared/firebase.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") return json({ error: "Use POST" }, 405);

  let callerId: string;
  try {
    const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
    callerId = await verifyFirebaseToken(token);
  } catch {
    return json({ error: "Please log in again." }, 401);
  }

  try {
    if (await getUserRole(callerId) !== "admin") {
      return json({ error: "Only an active admin can manage users." }, 403);
    }

    const body = await req.json();
    if (body.action === "listUsers") {
      try {
        return json(await listUserProfiles());
      } catch (error) {
        console.error("Could not list Firebase user accounts:", error);
        const detail = error instanceof FirebaseApiError
          ? `${error.service} failed (${error.status}${
            error.apiStatus ? ` ${error.apiStatus}` : ""
          }${
            error.permission ? `; permission ${error.permission}` : ""
          }${
            error.apiMessage ? `; API message: ${error.apiMessage}` : ""
          }).`
          : "Firebase user listing failed before an API response was received.";
        const authFallback = error instanceof FirebaseApiError &&
            error.fallbackError
          ? ` Authentication account listing also failed (${error.fallbackError.status}${
            error.fallbackError.apiStatus
              ? ` ${error.fallbackError.apiStatus}`
              : ""
          }${
            error.fallbackError.permission
              ? `; permission ${error.fallbackError.permission}`
              : ""
          }${
            error.fallbackError.apiMessage
              ? `; API message: ${error.fallbackError.apiMessage}`
              : ""
          }).`
          : "";
        return json({
          error: `${detail}${authFallback} Configured Firebase project: ${firebaseServiceIdentity.projectId}; service account: ${firebaseServiceIdentity.clientEmail}.`,
        }, 502);
      }
    }

    const userId = String(body.userId ?? "");
    if (!/^[A-Za-z0-9_-]+$/.test(userId)) {
      return json({ error: "Invalid user ID." }, 400);
    }
    if (userId === callerId) {
      return json({ error: "You cannot change your own account access." }, 400);
    }

    if (body.action === "setRole") {
      if (body.role !== "admin" && body.role !== "customer") {
        return json({ error: "Invalid role." }, 400);
      }
      await updateUserRole(userId, body.role);
    } else if (body.action === "setProfile") {
      const { name, phone, address } = body.profile ?? {};
      if (typeof name !== "string" ||
          typeof phone !== "string" ||
          typeof address !== "string" ||
          name.trim().length === 0 ||
          name.length > 120 ||
          phone.length > 40 ||
          address.length > 1000) {
        return json({ error: "Invalid profile fields." }, 400);
      }
      await updateUserProfile(userId, {
        name: name.trim(),
        phone: phone.trim(),
        address: address.trim(),
      });
    } else if (body.action === "setDisabled") {
      if (typeof body.disabled !== "boolean") {
        return json({ error: "Invalid disabled value." }, 400);
      }
      await setUserDisabled(userId, body.disabled);
    } else {
      return json({ error: "Unsupported user action." }, 400);
    }

    return json({ success: true });
  } catch (error) {
    console.error("Could not manage user:", error);
    const message = error instanceof FirebaseApiError
      ? `${error.service} failed (HTTP ${error.status}${
        error.apiStatus ? ` ${error.apiStatus}` : ""
      }${
        error.permission ? `; permission ${error.permission}` : ""
      }${
        error.apiMessage ? `; API message: ${error.apiMessage}` : ""
      }).`
      : error instanceof Error &&
          error.message.startsWith("Missing Firebase configuration:")
      ? error.message
      : "The account update failed before Firebase returned an API response. Check the Supabase function logs.";
    return json({ error: message }, 500);
  }
});
