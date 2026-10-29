# TECHNOLOGIA Shop App

A Flutter storefront for computer hardware and tools. The app uses Firebase for authentication and data storage, Supabase Edge Functions for trusted server-side operations, and Xendit for hosted checkout.

## Features

- Product browsing, search, category filters, cart, and checkout
- Customer, seller, and admin roles
- Sellers can add, edit, and delete catalog products
- Admins can manage products and user roles
- Delivery address and phone are loaded from the signed-in user's profile at checkout
- Xendit-hosted invoice payments and order status updates

## Requirements

- Flutter SDK compatible with the Dart constraint in `pubspec.yaml`
- A configured Firebase project with Authentication, Cloud Firestore, and Storage
- A Supabase project with the Edge Functions used by this app
- An Xendit account and API key for the desired test or live mode

## Run the App

```powershell
flutter pub get
flutter run -d chrome
```

To run on a connected device, use `flutter run` and select the target device. Firebase platform configuration is in `lib/firebase_options.dart`; Android also uses `android/app/google-services.json`.

## Data and Services

- Firebase Authentication handles sign-in, registration, Google sign-in, and password reset.
- Cloud Firestore stores `users`, `products`, and `orders` documents.
- Firebase Storage stores profile photos.
- Supabase Edge Functions provide trusted user-management actions, create Xendit invoices, and process Xendit payment callbacks.
- Xendit hosts the payment page. The app sends only an order ID to the invoice function; the function reads the amount from Firestore.

The Supabase function URLs used by Flutter are configured in `lib/config.dart`.

## Roles

- `customer`: browse the shop, manage a cart, and place orders.
- `seller`: add, edit, and delete products.
- `admin`: manage products and assign user roles.

The user-management function checks the caller's role before changing accounts. New registrations are customers by default.

## Supabase Functions

The canonical function entry points in this repository are:

- `supabase/functions/manage-users/index.ts`
- `supabase/functions/create-invoice/index.ts`
- `supabase/functions/xendit-webhook/index.ts`
- Shared Firebase helpers: `supabase/functions/_shared/firebase.ts`

Deploy the matching function source to the same Supabase project referenced in `lib/config.dart`. Local edits do not update a deployed function until it is deployed. When working with dashboard downloads, use the function's root `index.ts`; nested `src/index.ts` files may be downloaded copies and are not the entry points listed above.

The `create-invoice` function must have **Verify JWT** disabled in Supabase because the app authenticates with a Firebase ID token, which the function verifies itself. The `xendit-webhook` function must accept Xendit's callback request and validate its callback token.

## Supabase Secrets

Configure secrets in the Supabase project; never commit secret values or put them in Flutter code.

- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`
- `FIREBASE_API_KEY` (optional for the shared helper)
- `XENDIT_SECRET_KEY` (Test key in Xendit Test Mode, Live key in Live Mode)
- `XENDIT_CALLBACK_TOKEN` (must match the Xendit callback verification token)

Do not use the Xendit API key as the callback token. Keep the Supabase secrets and Xendit webhook configured for the same Xendit account and mode.

## Validation

```powershell
flutter analyze lib
```

Supabase Edge Functions require Deno tooling for local type-checking and the Supabase CLI for CLI-based deployment.
