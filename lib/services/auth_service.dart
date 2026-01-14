// lib/services/auth_service.dart
import 'dart:math';
import '../models/auth_request.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  AuthRequest? _currentRequest;
  final Random _random = Random.secure();

  // Simulate receiving a login request from website
  AuthRequest createAuthRequest({
    required String username,
    required AuthType type,
  }) {
    // Invalidate any existing request
    if (_currentRequest != null) {
      _currentRequest!.status = AuthStatus.expired;
    }

    final request = AuthRequest(
      id: _generateRequestId(),
      username: username,
      type: type,
      timestamp: DateTime.now(),
    );

    if (type == AuthType.authCode) {
      request.code = _generate6DigitCode();
    } else {
      request.easyAuthDigits = _generate2Digits();
    }

    _currentRequest = request;
    return request;
  }

  AuthRequest? getCurrentRequest() => _currentRequest;

  // Generate unique request ID
  String _generateRequestId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Generate 6-digit auth code
  String _generate6DigitCode() {
    final code = _random.nextInt(900000) + 100000; // 100000 to 999999
    return code.toString();
  }

  // Generate 2 random digits for Easy Auth
  List<int> _generate2Digits() {
    final digit1 = _random.nextInt(10); // 0-9
    int digit2;
    do {
      digit2 = _random.nextInt(10);
    } while (digit2 == digit1); // Ensure digits are different
    return [digit1, digit2];
  }

  // Approve Easy Auth
  Future<bool> approveEasyAuth(int selectedDigit) async {
    if (_currentRequest == null ||
        _currentRequest!.type != AuthType.easyAuth ||
        _currentRequest!.isExpired) {
      return false;
    }

    // Simulate backend call
    await Future.delayed(const Duration(milliseconds: 500));

    _currentRequest!.status = AuthStatus.approved;
    await _sendToBackend(_currentRequest!);
    return true;
  }

  // Mark Auth Code as used
  Future<bool> markAuthCodeUsed() async {
    if (_currentRequest == null ||
        _currentRequest!.type != AuthType.authCode ||
        _currentRequest!.isExpired) {
      return false;
    }

    _currentRequest!.status = AuthStatus.approved;
    await _sendToBackend(_currentRequest!);
    return true;
  }

  // Reject request
  Future<void> rejectRequest() async {
    if (_currentRequest != null) {
      _currentRequest!.status = AuthStatus.rejected;
      await _sendToBackend(_currentRequest!);
    }
  }

  // Expire request
  Future<void> expireRequest() async {
    if (_currentRequest != null) {
      _currentRequest!.status = AuthStatus.expired;
      await _sendToBackend(_currentRequest!);
    }
  }

  // Simulate backend API call
  Future<void> _sendToBackend(AuthRequest request) async {
    // TODO: Replace with actual API call
    print('Sending to backend: ${request.id} - ${request.status}');
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void clearCurrentRequest() {
    _currentRequest = null;
  }
}
