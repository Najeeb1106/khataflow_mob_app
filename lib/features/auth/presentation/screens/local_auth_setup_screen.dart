import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/services/security_service.dart';

class LocalAuthSetupScreen extends StatefulWidget {
  const LocalAuthSetupScreen({super.key});

  @override
  State<LocalAuthSetupScreen> createState() => _LocalAuthSetupScreenState();
}

class _LocalAuthSetupScreenState extends State<LocalAuthSetupScreen> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _enableFingerprint = false;
  int _currentStep = 0;
  bool _isFingerprintAvailable = false;
  bool _biometricsSupported = false;
  bool _checkingBiometrics = true;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final localAuth = LocalAuthentication();
      final canCheck = await localAuth.canCheckBiometrics;
      final isSupported = await localAuth.isDeviceSupported();
      final supported = canCheck || isSupported;

      if (supported) {
        final available = await localAuth.getAvailableBiometrics();
        setState(() {
          _isFingerprintAvailable =
              available.contains(BiometricType.fingerprint) ||
              available.contains(BiometricType.strong);
          _biometricsSupported = supported;
          _checkingBiometrics = false;
        });
      } else {
        setState(() {
          _biometricsSupported = false;
          _checkingBiometrics = false;
        });
      }
    } catch (e) {
      debugPrint("Error checking biometrics: $e");
      setState(() {
        _biometricsSupported = false;
        _checkingBiometrics = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name.')),
      );
      return;
    }
    if (_currentStep == 1) {
      final pin = _pinController.text;
      final confirmPin = _confirmPinController.text;
      if (pin.length != 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN must be exactly 4 digits.')),
        );
        return;
      }
      if (pin != confirmPin) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PINs do not match.')));
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _saveAndComplete();
    }
  }

  Future<void> _saveAndComplete() async {
    try {
      await SecurityService.setupProfile(
        name: _nameController.text.trim(),
        pin: _pinController.text,
        enableFingerprint: _enableFingerprint,
      );

      // Update session activity timestamp
      await SecurityService.updateLastActive();

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to set up profile: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 40.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('🛡️', style: TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KhataFlow',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        Text(
                          'Secure Offline Ledger',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Indicator
                Row(
                  children: List.generate(3, (index) {
                    final isActive = index <= _currentStep;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.teal : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 36),

                // Step Content
                if (_currentStep == 0) ...[
                  const Text(
                    'Create Profile',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'All profile information and transactions are stored safely on this device and encrypted locally.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 36),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Colors.teal,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.teal,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ] else if (_currentStep == 1) ...[
                  const Text(
                    'Create Security PIN',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Create a 4-digit security PIN to protect your financial data.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 36),
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: 'Security PIN',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Colors.teal,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.teal,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: 'Confirm PIN',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Colors.teal,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.teal,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ] else if (_currentStep == 2) ...[
                  const Text(
                    'Biometric Security',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Enable fingerprint unlock for faster and secure login access.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Detected Biometrics Indicators
                  if (_checkingBiometrics)
                    const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.teal,
                        ),
                      ),
                    )
                  else ...[
                    Center(
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        alignment: WrapAlignment.center,
                        children: [
                          if (_isFingerprintAvailable)
                            Chip(
                              avatar: const Icon(
                                Icons.fingerprint,
                                size: 16,
                                color: Colors.teal,
                              ),
                              label: const Text(
                                'Fingerprint Supported',
                                style: TextStyle(
                                  color: Colors.teal,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: Colors.teal[50],
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          if (!_isFingerprintAvailable && _biometricsSupported)
                            Chip(
                              avatar: const Icon(
                                Icons.security,
                                size: 16,
                                color: Colors.teal,
                              ),
                              label: const Text(
                                'Biometrics Supported',
                                style: TextStyle(
                                  color: Colors.teal,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: Colors.teal[50],
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          if (!_biometricsSupported)
                            Chip(
                              avatar: const Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: Colors.orange,
                              ),
                              label: const Text(
                                'No Biometrics Found',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: Colors.orange[50],
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.fingerprint,
                        size: 72,
                        color: Colors.teal[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_isFingerprintAvailable) ...[
                    SwitchListTile(
                      activeColor: Colors.teal,
                      title: const Text(
                        'Enable Fingerprint Unlock',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Use registered fingerprints to unlock the app',
                      ),
                      value: _enableFingerprint,
                      onChanged: (value) =>
                          setState(() => _enableFingerprint = value),
                    ),
                    const Divider(),
                  ],
                  if (!_isFingerprintAvailable && _biometricsSupported) ...[
                    SwitchListTile(
                      activeColor: Colors.teal,
                      title: const Text(
                        'Enable Fingerprint Unlock',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Use local device fingerprint authentication to unlock',
                      ),
                      value: _enableFingerprint,
                      onChanged: (value) => setState(() {
                        _enableFingerprint = value;
                      }),
                    ),
                    const Divider(),
                  ],
                ],

                const SizedBox(height: 48),

                // Button Layout
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: () => setState(() => _currentStep--),
                        child: const Text(
                          'Back',
                          style: TextStyle(color: Colors.teal, fontSize: 16),
                        ),
                      )
                    else
                      const SizedBox(),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        elevation: 2,
                      ),
                      onPressed: _nextStep,
                      child: Text(
                        _currentStep == 2 ? 'Complete Setup' : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
}
