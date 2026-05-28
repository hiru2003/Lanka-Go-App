import 'package:flutter/material.dart';

enum AppLanguage { english, sinhala, tamil }

class LanguageProvider with ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.english;

  AppLanguage get currentLanguage => _currentLanguage;

  String get currentLanguageCode {
    switch (_currentLanguage) {
      case AppLanguage.english:
        return 'EN';
      case AppLanguage.sinhala:
        return 'SI';
      case AppLanguage.tamil:
        return 'TA';
    }
  }

  void changeLanguage(AppLanguage language) {
    _currentLanguage = language;
    notifyListeners();
  }

  /// Translates a given key based on the selected language
  String translate(String key) {
    if (_translations[key] == null) return key;
    return _translations[key]![_currentLanguage] ?? key;
  }

  static const Map<String, Map<AppLanguage, String>> _translations = {
    'appName': {
      AppLanguage.english: 'Lanka Go',
      AppLanguage.sinhala: 'ලංකා ගෝ',
      AppLanguage.tamil: 'லங்கா கோ',
    },
    'tagline': {
      AppLanguage.english: 'Smart Transport Companion',
      AppLanguage.sinhala: 'ස්මාර්ට් ප්‍රවාහන සහකරු',
      AppLanguage.tamil: 'ஸ்மார்ட் போக்குவரத்து துணை',
    },
    'loginTitle': {
      AppLanguage.english: 'Scan to Board',
      AppLanguage.sinhala: 'ඇතුල් වීමට ස්කෑන් කරන්න',
      AppLanguage.tamil: 'நுழைய ஸ்கேன் செய்யவும்',
    },
    'loginSubtitle': {
      AppLanguage.english: 'Scan your Lanka Go QR card at the camera viewport to login and view your balance.',
      AppLanguage.sinhala: 'ඔබගේ ලංකා ගෝ QR කාඩ්පත කැමරාවට යොමු කර ලොග් වන්න.',
      AppLanguage.tamil: 'உள்நுழைந்து உங்கள் இருப்பைப் பார்க்க, லங்கா கோ QR கார்டை ஸ்கேன் செய்யவும்.',
    },
    'scanButton': {
      AppLanguage.english: 'Scan QR Code',
      AppLanguage.sinhala: 'QR කේතය ස්කෑන් කරන්න',
      AppLanguage.tamil: 'QR குறியீட்டை ஸ்கேன் செய்',
    },
    'cameraPermissionDenied': {
      AppLanguage.english: 'Camera permission denied. Please grant access to scan your QR card.',
      AppLanguage.sinhala: 'කැමරා අවසරය ප්‍රතික්ෂේප කර ඇත. කරුණාකර අවසර ලබා දෙන්න.',
      AppLanguage.tamil: 'கேமரா அனுமதி மறுக்கப்பட்டது. ஸ்கேன் செய்ய அனுமதி வழங்கவும்.',
    },
    'retryPermission': {
      AppLanguage.english: 'Retry Permission',
      AppLanguage.sinhala: 'නැවත උත්සාහ කරන්න',
      AppLanguage.tamil: 'மீண்டும் முயற்சிக்கவும்',
    },
    'bypassScan': {
      AppLanguage.english: 'Bypass Scan (Mock Dev)',
      AppLanguage.sinhala: 'ස්කෑන් මඟ හැරීම (Mock)',
      AppLanguage.tamil: 'ஸ்கேன் தவிர் (Mock)',
    },
    'invalidQR': {
      AppLanguage.english: 'Invalid Lanka Go QR format. Please scan a valid passenger card.',
      AppLanguage.sinhala: 'වලංගු නොවන QR කේතයකි. කරුණාකර නිවැරදි කාඩ්පතක් ස්කෑන් කරන්න.',
      AppLanguage.tamil: 'செல்லுபடியாகாத QR குறியீடு. சரியான கார்டை ஸ்கேன் செய்யவும்.',
    },
    'dashboard': {
      AppLanguage.english: 'Dashboard',
      AppLanguage.sinhala: 'පාලක පුවරුව',
      AppLanguage.tamil: 'டாஷ்போர்டு',
    },
    'cardStatus': {
      AppLanguage.english: 'Card Status',
      AppLanguage.sinhala: 'කාඩ්පත් තත්ත්වය',
      AppLanguage.tamil: 'அட்டை நிலை',
    },
    'active': {
      AppLanguage.english: 'Active',
      AppLanguage.sinhala: 'සක්‍රිය',
      AppLanguage.tamil: 'செயலில்',
    },
    'suspended': {
      AppLanguage.english: 'Suspended',
      AppLanguage.sinhala: 'අත්හිටුවා ඇත',
      AppLanguage.tamil: 'நிறுத்தி வைக்கப்பட்டுள்ளது',
    },
    'balance': {
      AppLanguage.english: 'Balance',
      AppLanguage.sinhala: 'ඉතිරි මුදල',
      AppLanguage.tamil: 'இருப்பு',
    },
    'dailyCap': {
      AppLanguage.english: 'Daily Cap',
      AppLanguage.sinhala: 'දෛනික සීමාව',
      AppLanguage.tamil: 'தினசரி வரம்பு',
    },
    'spentOf': {
      AppLanguage.english: 'spent of',
      AppLanguage.sinhala: 'වියදම් කර ඇත (සීමාව: ',
      AppLanguage.tamil: 'செலவிடப்பட்டது',
    },
    'reloadBalance': {
      AppLanguage.english: 'Reload Balance',
      AppLanguage.sinhala: 'මුදල් රීලෝඩ් කරන්න',
      AppLanguage.tamil: 'பணம் சேர்க்கவும்',
    },
    'travelHistory': {
      AppLanguage.english: 'Travel History',
      AppLanguage.sinhala: 'ගමන් විස්තර',
      AppLanguage.tamil: 'பயண வரலாறு',
    },
    'profile': {
      AppLanguage.english: 'Profile',
      AppLanguage.sinhala: 'පැතිකඩ',
      AppLanguage.tamil: 'சுயவிவரம்',
    },
    'cardNumber': {
      AppLanguage.english: 'Card Number',
      AppLanguage.sinhala: 'කාඩ්පත් අංකය',
      AppLanguage.tamil: 'அட்டை எண்',
    },
    'logout': {
      AppLanguage.english: 'Log Out',
      AppLanguage.sinhala: 'ලොග් අවුට් වන්න',
      AppLanguage.tamil: 'வெளியேறு',
    },
    'settings': {
      AppLanguage.english: 'Settings',
      AppLanguage.sinhala: 'සැකසුම්',
      AppLanguage.tamil: 'அமைப்புகள்',
    },
    'languageLabel': {
      AppLanguage.english: 'Language / භාෂාව / மொழி',
      AppLanguage.sinhala: 'භාෂාව / Language / மொழி',
      AppLanguage.tamil: 'மொழி / Language / භාෂාව',
    },
    'notification': {
      AppLanguage.english: 'Notification',
      AppLanguage.sinhala: 'නිවේදනය',
      AppLanguage.tamil: 'அறிவிப்பு',
    },
    'lkr': {
      AppLanguage.english: 'LKR',
      AppLanguage.sinhala: 'රු.',
      AppLanguage.tamil: 'ரூ.',
    },
    'scanningText': {
      AppLanguage.english: 'Align Lanka Go QR code inside the frame to scan',
      AppLanguage.sinhala: 'ලංකා ගෝ QR කේතය කොටුව තුලට යොමු කරන්න',
      AppLanguage.tamil: 'லங்கா கோ QR குறியீட்டை சட்டத்திற்குள் சீரமைக்கவும்',
    },
  };
}
