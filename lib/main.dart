// lib/main.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:math';

void main() {
  runApp(const AuthApp());
}

class AuthApp extends StatelessWidget {
  const AuthApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
      ),
      home: const HomeScreen(),
      routes: {
        '/auth-code': (context) => AuthCodeScreen(),
        '/easy-auth': (context) => EasyAuthScreen(),
      },
    );
  }
}

// lib/models/auth_request.dart
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

// lib/services/auth_service.dart

class AuthService {
  // Singleton pattern
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
    // Example:
    // final response = await http.post(
    //   Uri.parse('https://your-api.com/api/auth/approve'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({
    //     'request_id': request.id,
    //     'status': request.status.toString().split('.').last,
    //   }),
    // );

    print('Sending to backend: ${request.id} - ${request.status}');
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void clearCurrentRequest() {
    _currentRequest = null;
  }
}

// lib/screens/home_screen.dart

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _usernameController = TextEditingController();
  final _authService = AuthService();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _simulateAuthCodeRequest() {
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a username')));
      return;
    }

    _authService.createAuthRequest(
      username: _usernameController.text,
      type: AuthType.authCode,
    );

    Navigator.pushNamed(context, '/auth-code');
  }

  void _simulateEasyAuthRequest() {
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a username')));
      return;
    }

    _authService.createAuthRequest(
      username: _usernameController.text,
      type: AuthType.easyAuth,
    );

    Navigator.pushNamed(context, '/easy-auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication App'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.security, size: 80, color: Colors.blue),
              const SizedBox(height: 32),
              const Text(
                'Secure Login',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Authenticate your website login',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Simulate Login Request:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _simulateAuthCodeRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Auth Code (6-Digit)',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _simulateEasyAuthRequest,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Easy Auth (2-Digit)',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(height: 8),
                    Text(
                      'In production, requests come from the website. This demo simulates incoming requests.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthCodeScreen extends StatefulWidget {
  const AuthCodeScreen({Key? key}) : super(key: key);

  @override
  State<AuthCodeScreen> createState() => _AuthCodeScreenState();
}

class _AuthCodeScreenState extends State<AuthCodeScreen> {
  final _authService = AuthService();
  Timer? _timer;
  int _remainingSeconds = 60;
  AuthRequest? _request;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _request = _authService.getCurrentRequest();
    if (_request != null) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds = _request!.remainingSeconds;
        if (_remainingSeconds == 0) {
          _isExpired = true;
          _timer?.cancel();
          _authService.expireRequest();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _copyCode() {
    if (_request?.code != null && !_isExpired) {
      Clipboard.setData(ClipboardData(text: _request!.code!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _markAsUsed() async {
    final success = await _authService.markAuthCodeUsed();
    if (success) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 64,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Login Successful',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You have successfully authenticated as ${_request?.username}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Auth Code')),
        body: const Center(child: Text('No active request')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Auth Code Login'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _request!.username,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your Authentication Code',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _copyCode,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: _isExpired
                              ? Colors.grey.shade200
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isExpired
                                ? Colors.grey.shade300
                                : Colors.blue.shade200,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          _request!.code!,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                            color: _isExpired
                                ? Colors.grey.shade400
                                : Colors.blue.shade700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                    if (!_isExpired) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.copy,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to copy',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isExpired
                            ? Colors.red.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isExpired ? Icons.error : Icons.timer,
                            color: _isExpired
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isExpired
                                ? 'Code Expired'
                                : 'Expires in $_remainingSeconds seconds',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _isExpired
                                  ? Colors.red.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Enter this code on the website to complete login',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isExpired ? null : _markAsUsed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: const Text(
                  'Mark as Used',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EasyAuthScreen extends StatefulWidget {
  const EasyAuthScreen({Key? key}) : super(key: key);

  @override
  State<EasyAuthScreen> createState() => _EasyAuthScreenState();
}

class _EasyAuthScreenState extends State<EasyAuthScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  Timer? _timer;
  int _remainingSeconds = 60;
  AuthRequest? _request;
  bool _isExpired = false;
  int? _selectedDigit;
  bool _isProcessing = false;
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _request = _authService.getCurrentRequest();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );

    if (_request != null) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds = _request!.remainingSeconds;
        if (_remainingSeconds == 0) {
          _isExpired = true;
          _timer?.cancel();
          _authService.expireRequest();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _selectDigit(int digit) async {
    if (_isExpired || _isProcessing) return;

    setState(() {
      _selectedDigit = digit;
      _isProcessing = true;
    });

    await _animationController?.forward();
    await _animationController?.reverse();

    final success = await _authService.approveEasyAuth(digit);

    if (success) {
      _showSuccessDialog();
    } else {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Authentication failed')));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 64,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Login Approved!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You have successfully authenticated as ${_request?.username}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _reject() async {
    await _authService.rejectRequest();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_request == null || _request!.easyAuthDigits == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Easy Auth')),
        body: const Center(child: Text('No active request')),
      );
    }

    final digits = _request!.easyAuthDigits!;

    return Scaffold(
      appBar: AppBar(title: const Text('Easy Auth Login'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _request!.username,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Website is showing these digits:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDisplayDigit(digits[0]),
                        const SizedBox(width: 16),
                        _buildDisplayDigit(digits[1]),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isExpired
                            ? Colors.red.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isExpired ? Icons.error : Icons.timer,
                            color: _isExpired
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isExpired
                                ? 'Request Expired'
                                : 'Expires in $_remainingSeconds seconds',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _isExpired
                                  ? Colors.red.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Tap the digit shown on the website:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTapDigit(digits[0]),
                  const SizedBox(width: 20),
                  _buildTapDigit(digits[1]),
                ],
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: _isExpired || _isProcessing ? null : _reject,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: Colors.red,
                ),
                child: const Text(
                  'Reject Login',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayDigit(int digit) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Center(
        child: Text(
          digit.toString(),
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildTapDigit(int digit) {
    final isSelected = _selectedDigit == digit;
    final isDisabled = _isExpired || _isProcessing;

    return ScaleTransition(
      scale: isSelected && !isDisabled
          ? _scaleAnimation!
          : const AlwaysStoppedAnimation(1.0),
      child: GestureDetector(
        onTap: isDisabled ? null : () => _selectDigit(digit),
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: isDisabled
                ? Colors.grey.shade200
                : isSelected
                ? Colors.green.shade500
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDisabled
                  ? Colors.grey.shade300
                  : isSelected
                  ? Colors.green.shade700
                  : Colors.blue.shade300,
              width: 3,
            ),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              digit.toString(),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: isDisabled
                    ? Colors.grey.shade400
                    : isSelected
                    ? Colors.white
                    : Colors.blue.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
