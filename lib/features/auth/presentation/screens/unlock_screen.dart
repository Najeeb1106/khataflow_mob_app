import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    try {
      // Validate that PIN hash is accessible; if Keystore is corrupted/decryption fails, this throws
      final hasPin = await SecurityService.hasPinHash();
      if (!hasPin) {
        if (mounted) {
          context.go('/setup-profile?mode=reset-security');
        }
        return;
      }

      final name = await SecurityService.getProfileName();
      final biometricsEnabled = await SecurityService.isBiometricsEnabled();

      setState(() {
        _profileName = name ?? 'User';
        _biometricsAvailable = biometricsEnabled;
      });

      if (biometricsEnabled) {
        await _triggerBiometrics();
      }
    } catch (e) {
      debugPrint('[UNLOCK] Secure storage failed to initialize or read: $e');
      if (mounted) {
        context.go('/setup-profile?mode=reset-security');
      }
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

    try {
      final isValid = await SecurityService.verifyPin(_enteredPin);
      if (isValid) {
        _unlock();
      } else if (_enteredPin.length >= 4) {
        // If reached max length and invalid, show error and reset
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid Security PIN.'),
            duration: Duration(seconds: 1),
          ),
        );
        _onClear();
      }
    } catch (e) {
      debugPrint('[UNLOCK] Secure storage failed during PIN verification: $e');
      if (mounted) {
        context.go('/setup-profile?mode=reset-security');
      }
    }
  }

  Future<void> _unlock() async {
    await SecurityService.updateLastActive();
    if (mounted) {
      context.go('/dashboard');
    }
  }

  Future<void> _onForgotPin() async {
    try {
      final question = await SecurityService.getRecoveryQuestion();
      if (question == null || question.isEmpty) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('PIN Recovery', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('PIN recovery is not configured for this device.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: Colors.teal)),
              ),
            ],
          ),
        );
        return;
      }

      if (await SecurityService.isRecoveryLockedOut()) {
        final secondsLeft = await SecurityService.getRemainingLockoutTimeInSeconds();
        final minutesLeft = (secondsLeft / 60).ceil();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Too many incorrect attempts. Please try again in $minutesLeft minutes.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show recovery answer dialog
      final answerController = TextEditingController();
      if (!mounted) return;
      final answeredCorrectly = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => SafeArea(
          child: Dialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.06,
              vertical: 24.0,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Verify Recovery Answer',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Confirm your recovery answer to reset your PIN.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.teal.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RECOVERY QUESTION',
                            style: TextStyle(
                              color: Colors.teal.shade300,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            question,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: answerController,
                      decoration: const InputDecoration(
                        labelText: 'Your Answer',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade800,
                            disabledForegroundColor: Colors.grey.shade500,
                          ),
                          onPressed: () async {
                            try {
                              final isCorrect = await SecurityService.verifyRecoveryAnswer(answerController.text);
                              if (isCorrect) {
                                Navigator.pop(context, true);
                              } else {
                                final locked = await SecurityService.isRecoveryLockedOut();
                                if (locked) {
                                  Navigator.pop(context, false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Too many incorrect attempts. Please try again later.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } else {
                                  final remaining = 5 - await SecurityService.getFailedRecoveryAttempts();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Incorrect answer. $remaining attempts remaining.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              debugPrint('[UNLOCK] Secure storage failed during recovery verification: $e');
                              Navigator.pop(context, false);
                              if (mounted) {
                                context.go('/setup-profile?mode=reset-security');
                              }
                            }
                          },
                          child: const Text('Verify'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      if (answeredCorrectly == true) {
        _showResetPinDialog();
      }
    } catch (e) {
      debugPrint('[UNLOCK] Secure storage failed during forgot pin check: $e');
      if (mounted) {
        context.go('/setup-profile?mode=reset-security');
      }
    }
  }

  void _showResetPinDialog() {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Reset Security PIN',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(labelText: 'New PIN', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(labelText: 'Confirm New PIN', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade800,
                        disabledForegroundColor: Colors.grey.shade500,
                      ),
                      onPressed: () async {
                        final newPin = pinController.text;
                        final confirm = confirmController.text;
                        if (newPin.length != 4) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PIN must be exactly 4 digits.')),
                          );
                          return;
                        }
                        if (newPin != confirm) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PINs do not match.')),
                          );
                          return;
                        }
                        try {
                          await SecurityService.resetPin(newPin);
                          if (!mounted) return;
                          Navigator.pop(context); // Close dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PIN reset successfully!')),
                          );
                          _unlock();
                        } catch (e) {
                          debugPrint('[UNLOCK] Secure storage failed to reset PIN: $e');
                          Navigator.pop(context); // Close dialog
                          if (mounted) {
                            context.go('/setup-profile?mode=reset-security');
                          }
                        }
                      },
                      child: const Text('Save PIN'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          side: BorderSide(
            color: Colors.teal.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        onPressed: () => _onKeyPress(label),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
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
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
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
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Welcome back, $_profileName',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 32),

                        // PIN dots
                        if (!isKeyboardVisible) ...[
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
                                  border: Border.all(
                                    color: filled ? Colors.teal : Colors.grey[400]!,
                                  ),
                                ),
                              );
                            }),
                          ),
                          const Spacer(),
                        ],

                        // PIN Keypad - Centered & Compact
                        if (!isKeyboardVisible) ...[
                          Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 270),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildKey('1'),
                                      _buildKey('2'),
                                      _buildKey('3'),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildKey('4'),
                                      _buildKey('5'),
                                      _buildKey('6'),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildKey('7'),
                                      _buildKey('8'),
                                      _buildKey('9'),
                                    ],
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
                                                child: const Text(
                                                  'Clear',
                                                  style: TextStyle(
                                                    color: Colors.teal,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                      ),
                                      _buildKey('0'),
                                      _buildActionKey(
                                        IconButton(
                                          icon: const Icon(
                                            Icons.backspace_outlined,
                                            size: 26,
                                            color: Colors.teal,
                                          ),
                                          onPressed: _onDelete,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _onForgotPin,
                            child: const Text(
                              'Forgot PIN?',
                              style: TextStyle(
                                color: Colors.teal,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
