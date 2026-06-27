import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/services/security_service.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  static bool isUnlockVisible = false;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  String _enteredPin = '';
  String _profileName = '';
  bool _biometricsAvailable = false;
  bool _isFingerprint = false;

  @override
  void initState() {
    super.initState();
    UnlockScreen.isUnlockVisible = true;
    _loadProfileAndTriggerBiometrics();
  }

  @override
  void dispose() {
    UnlockScreen.isUnlockVisible = false;
    super.dispose();
  }

  Future<void> _loadProfileAndTriggerBiometrics() async {
    final name = await SecurityService.getProfileName();
    final biometricsEnabled = await SecurityService.isBiometricsEnabled();
    final fingerprintEnabled = await SecurityService.isFingerprintEnabled();
    
    bool isFingerprint = false;
    
    if (biometricsEnabled) {
      try {
        final localAuth = LocalAuthentication();
        final available = await localAuth.getAvailableBiometrics();
        isFingerprint = (available.contains(BiometricType.fingerprint) || available.contains(BiometricType.strong)) && fingerprintEnabled;
      } catch (_) {}
    }

    setState(() {
      _profileName = name ?? 'User';
      _biometricsAvailable = biometricsEnabled;
      _isFingerprint = isFingerprint;
    });

    if (biometricsEnabled) {
      await _triggerBiometrics();
    }
  }

  Future<void> _triggerBiometrics() async {
    final success = await SecurityService.authenticateBiometrics();
    if (success) {
      _unlock();
    }
  }

  void _onKeyPress(String value) {
    if (_enteredPin.length >= 4) return;
    setState(() {
      _enteredPin += value;
    });
    _checkPin();
  }

  void _onDelete() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  void _onClear() {
    setState(() {
      _enteredPin = '';
    });
  }

  Future<void> _checkPin() async {
    if (_enteredPin.length < 4) return;
    
    // Check if the current pin length matches either a 4 or 6 digit PIN setup.
    // Wait, let's verify only when they hit 4, 5, or 6 characters depending on the PIN.
    // To make it seamless, if the PIN is verified successfully, we unlock!
    final isValid = await SecurityService.verifyPin(_enteredPin);
    if (isValid) {
      _unlock();
    } else if (_enteredPin.length >= 4) {
      // If reached max length and invalid, show error and reset
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Security PIN.'),
          duration: Duration(seconds: 1),
        ),
      );
      _onClear();
    }
  }

  Future<void> _unlock() async {
    await SecurityService.updateLastActive();
    if (mounted) {
      context.go('/dashboard');
    }
  }

  Widget _buildKey(String label) {
    return Container(
      width: 68,
      height: 68,
      margin: const EdgeInsets.all(6),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          side: BorderSide(color: Colors.teal.withOpacity(0.3), width: 1.5),
        ),
        onPressed: () => _onKeyPress(label),
        child: Text(
          label,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
      ),
    );
  }

  Widget _buildActionKey(Widget child) {
    return Container(
      width: 68,
      height: 68,
      margin: const EdgeInsets.all(6),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Text('🛡️', style: TextStyle(fontSize: 54)),
              const SizedBox(height: 12),
              const Text(
                'Unlock KhataFlow',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome back, $_profileName',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: filled ? Colors.teal : Colors.grey[300],
                      shape: BoxShape.circle,
                      border: Border.all(color: filled ? Colors.teal : Colors.grey[400]!),
                    ),
                  );
                }),
              ),
              const Spacer(),

              // PIN Keypad - Centered & Compact
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 270),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [_buildKey('1'), _buildKey('2'), _buildKey('3')],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [_buildKey('4'), _buildKey('5'), _buildKey('6')],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [_buildKey('7'), _buildKey('8'), _buildKey('9')],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionKey(
                            _biometricsAvailable
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.fingerprint,
                                      size: 32,
                                      color: Colors.teal,
                                    ),
                                    onPressed: _triggerBiometrics,
                                  )
                                : TextButton(
                                    onPressed: _onClear,
                                    child: const Text('Clear', style: TextStyle(color: Colors.teal, fontSize: 13, fontWeight: FontWeight.bold)),
                                  ),
                          ),
                          _buildKey('0'),
                          _buildActionKey(
                            IconButton(
                              icon: const Icon(Icons.backspace_outlined, size: 26, color: Colors.teal),
                              onPressed: _onDelete,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
