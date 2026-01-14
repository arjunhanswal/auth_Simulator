enum AuthType { authCode, easyAuth }

enum AuthStatus { pending, approved, rejected, expired }

class AuthRequest {
  final String id;
  final String username;
  final AuthType type;
  final DateTime timestamp;
  final int expirySeconds;
  AuthStatus status;
  String? code;
  List<int>? easyAuthDigits;

  AuthRequest({
    required this.id,
    required this.username,
    required this.type,
    required this.timestamp,
    this.expirySeconds = 60,
    this.status = AuthStatus.pending,
    this.code,
    this.easyAuthDigits,
  });

  bool get isExpired {
    final elapsed = DateTime.now().difference(timestamp).inSeconds;
    return elapsed >= expirySeconds;
  }

  int get remainingSeconds {
    final elapsed = DateTime.now().difference(timestamp).inSeconds;
    final remaining = expirySeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }
}
