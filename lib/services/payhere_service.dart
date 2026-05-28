import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class PayHereService {
  final String merchantId = "1224827"; // Mock Sandbox Merchant ID
  final String md5Secret = "LANKAGO_PAYHERE_SECRET_KEY"; // Sandbox MD5 Secret
  final String currency = "LKR";

  /// Generates the checkout MD5 signature: MD5(merchant_id + order_id + amount_formatted + currency + md5_secret_hashed)
  String generateCheckoutSignature({
    required String orderId,
    required double amount,
  }) {
    // Format amount to 2 decimal places (PayHere requirement)
    final String amountFormatted = amount.toStringAsFixed(2);
    
    // Hash the secret first (PayHere standard validation hashing)
    final secretHash = md5.convert(utf8.encode(md5Secret)).toString().toUpperCase();
    
    // Combine parameters: merchant_id + order_id + amount + currency + status_code(which is 2 for gateway callbacks, but for client checksum we combine md5(secret))
    final rawString = "$merchantId$orderId$amountFormatted$currency$secretHash";
    
    final finalHash = md5.convert(utf8.encode(rawString)).toString().toUpperCase();
    return finalHash;
  }

  /// Simulates a callback transaction to the Flask backend to notify it of a successful reload order.
  Future<bool> triggerWebhookSuccess({
    required String orderId,
    required double amount,
    required String userId,
    required String backendUrl,
  }) async {
    final String amountFormatted = amount.toStringAsFixed(2);
    const int statusCode = 2; // Success code in PayHere
    
    // md5sig generated on backend is: MD5(merchant_id + order_id + payhere_amount + payhere_currency + status_code + md5(payhere_secret))
    final secretHash = md5.convert(utf8.encode(md5Secret)).toString().toUpperCase();
    final rawString = "$merchantId$orderId$amountFormatted$currency$statusCode$secretHash";
    final md5sig = md5.convert(utf8.encode(rawString)).toString().toUpperCase();

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/transactions/reload'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'merchant_id': merchantId,
          'order_id': orderId,
          'payhere_amount': amountFormatted,
          'payhere_currency': currency,
          'status_code': statusCode,
          'md5sig': md5sig,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('PayHere Webhook error: $e');
      return false;
    }
  }
}
