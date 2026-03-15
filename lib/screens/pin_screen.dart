import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';

class PinScreen extends StatefulWidget {
  final bool isSetup;
  final VoidCallback? onSuccess;

  const PinScreen({super.key, this.isSetup = false, this.onSuccess});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final AuthService _authService = AuthService();
  String _currentPin = '';
  String _confirmPin = ''; // For setup mode
  bool _isConfirming = false; // For setup mode step 2
  String _message = 'Enter PIN';

  @override
  void initState() {
    super.initState();
    if (widget.isSetup) {
      _message = 'Set a 4-digit PIN';
    }
  }

  void _onDigitPress(String digit) {
    if (_currentPin.length < 4) {
      setState(() {
        _currentPin += digit;
      });

      if (_currentPin.length == 4) {
        _handlePinComplete();
      }
    }
  }

  void _onBackspace() {
    if (_currentPin.isNotEmpty) {
      setState(() {
        _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      });
    }
  }

  Future<void> _handlePinComplete() async {
    if (widget.isSetup) {
      if (!_isConfirming) {
        // First step of setup complete, move to confirm
        setState(() {
          _confirmPin = _currentPin;
          _currentPin = '';
          _isConfirming = true;
          _message = 'Confirm PIN';
        });
      } else {
        // Confirmation complete
        if (_currentPin == _confirmPin) {
          await _authService.setPin(_currentPin);
          await _authService.setAuthEnabled(true);
          if (mounted) {
            if (widget.onSuccess != null) {
              widget.onSuccess!();
            } else {
              Navigator.pop(context, true);
            }
          }
        } else {
          // Mismatch
          setState(() {
            _currentPin = '';
            _confirmPin = '';
            _isConfirming = false;
            _message = 'PINs did not match. Try again.';
          });
        }
      }
    } else {
      // Normal auth
      final isValid = await _authService.checkPin(_currentPin);
      if (isValid) {
        if (mounted) {
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          }
        }
      } else {
        setState(() {
          _currentPin = '';
          _message = 'Incorrect PIN';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Icon(Icons.lock_outline, size: 60, color: Colors.white),
            const SizedBox(height: 24),
            Text(
              _message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _currentPin.length
                        ? Colors.white
                        : Colors.white.withAlpha(51),
                  ),
                );
              }),
            ),
            const Spacer(),
            _buildKeypad(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildKey('1'), _buildKey('2'), _buildKey('3')],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildKey('4'), _buildKey('5'), _buildKey('6')],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildKey('7'), _buildKey('8'), _buildKey('9')],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 70), // Spacer for align
              _buildKey('0'),
              IconButton(
                onPressed: _onBackspace,
                icon: const Icon(Icons.backspace_outlined, color: Colors.white),
                iconSize: 28,
                style: IconButton.styleFrom(minimumSize: const Size(70, 70)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String digit) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: InkWell(
        onTap: () => _onDigitPress(digit),
        customBorder: const CircleBorder(),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
