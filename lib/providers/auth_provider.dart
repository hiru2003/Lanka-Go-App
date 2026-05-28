import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isAuthenticating = false;
  String? _authError;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAuthenticating => _isAuthenticating;
  String? get authError => _authError;

  /// Validates the QR code scanned. If it contains "LANKAGO:USER", it decodes and logs in.
  Future<bool> loginWithQR(String qrPayload) async {
    _isAuthenticating = true;
    _authError = null;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      if (qrPayload.startsWith('LANKAGO:USER:')) {
        final user = UserModel.fromQRString(qrPayload);
        _currentUser = user;
        _isAuthenticating = false;
        notifyListeners();
        return true;
      } else {
        _authError = 'Invalid Lanka Go payload. QR code format is unrecognized.';
        _isAuthenticating = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _authError = 'Error decoding QR card: ${e.toString()}';
      _isAuthenticating = false;
      notifyListeners();
      return false;
    }
  }

  /// Simulate a balance reload
  void reloadBalance(double amount) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        balance: _currentUser!.balance + amount,
      );
      notifyListeners();
    }
  }

  /// Simulate a trip cost deduction and daily cap update
  bool deductTrip(double cost) {
    if (_currentUser == null) return false;
    if (_currentUser!.balance < cost) return false;

    // Sri Lankan daily cap logic: if daily spent reaches daily cap, fares are free or capped.
    double newDailySpent = _currentUser!.dailySpent;
    double actualCost = cost;

    if (newDailySpent >= _currentUser!.dailyCap) {
      actualCost = 0.0; // Travel is capped/free for the rest of the day
    } else if (newDailySpent + cost > _currentUser!.dailyCap) {
      actualCost = _currentUser!.dailyCap - newDailySpent; // Pay up to the cap
      newDailySpent = _currentUser!.dailyCap;
    } else {
      newDailySpent += cost;
    }

    _currentUser = _currentUser!.copyWith(
      balance: _currentUser!.balance - actualCost,
      dailySpent: newDailySpent,
    );
    notifyListeners();
    return true;
  }

  /// Clear any error message
  void clearError() {
    _authError = null;
    notifyListeners();
  }

  /// Perform logout
  void logout() {
    _currentUser = null;
    _authError = null;
    notifyListeners();
  }
}
