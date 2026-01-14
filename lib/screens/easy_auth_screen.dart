// lib/screens/easy_auth_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/auth_request.dart';

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
