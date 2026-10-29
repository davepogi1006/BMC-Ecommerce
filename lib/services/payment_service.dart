import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

/// Asks our Supabase function for a Xendit invoice link, then opens it.
/// The app only sends the ORDER ID. The server reads the real amount
/// from Firestore, so nobody can change the price from the phone.
class PaymentService {
  Future<Uri> createPaymentUrl(String orderId) async {
    // Proves to the server who the user is (verified there).
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Please sign in again before paying.');
    }

    final res = await http.post(
      Uri.parse(AppConfig.functionsUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'orderId': orderId}),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(
          body['error'] ?? 'Payment server error (${res.statusCode})');
    }

    final invoiceUrl = Uri.tryParse(body['invoiceUrl'] as String? ?? '');
    if (invoiceUrl == null ||
        invoiceUrl.scheme != 'https' ||
        invoiceUrl.host.isEmpty) {
      throw Exception('Payment server returned an invalid invoice URL.');
    }
    return invoiceUrl;
  }
}
