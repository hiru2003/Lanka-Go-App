import 'package:flutter/material.dart';

class NotificationService {
  /// Simulates sending a real-time push message via Firebase Cloud Messaging (FCM)
  static void triggerFirebasePushNotification({
    required String title,
    required String body,
    required BuildContext? context,
  }) {
    print('FCM Push Notification Sent: Title: "$title", Body: "$body"');
    
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(body, style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF4FACFE),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Simulates a fallback SMS alert via local Sri Lankan telco gateway APIs
  static void triggerFallbackSMSAlert({
    required String phoneNumber,
    required double currentBalance,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    print('\n------------------- TELCO SMS GATEWAY OUTBOX -------------------');
    print('TIMESTAMP: $timestamp');
    print('RECIPIENT: $phoneNumber');
    print('MESSAGE  : Lanka Go Alert! Your card balance has dropped below the ');
    print('           safety threshold of LKR 50.00. Current Balance: LKR ${currentBalance.toStringAsFixed(2)}.');
    print('           Please reload immediately to avoid transit checkout declines.');
    print('----------------------------------------------------------------\n');
  }
}
