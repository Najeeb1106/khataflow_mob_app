import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/services/security_service.dart';
import '../../../../core/presentation/design_system.dart';
import '../../../../core/presentation/widgets/shared_widgets.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _fingerprintEnabled = false;
  int _sessionTimeout = 60; // default 60s (1 min)
  bool _isFingerprint = false;
  bool _biometricsSupported = false;
  String _lastAuthTime = 'Just now';

  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final finger = await SecurityService.isFingerprintEnabled();
    final timeout = await SecurityService.getSessionTimeout();

    bool isFingerprint = false;
    bool biometricsSupported = false;
    try {
      final localAuth = LocalAuthentication();
      final canCheck = await localAuth.canCheckBiometrics;
      final isSupported = await localAuth.isDeviceSupported();
      biometricsSupported = canCheck || isSupported;

      final available = await localAuth.getAvailableBiometrics();
      isFingerprint =
          available.contains(BiometricType.fingerprint) ||
          available.contains(BiometricType.strong) ||
          available.contains(BiometricType.face);
    } catch (_) {}

    setState(() {
      _fingerprintEnabled = finger;
      _sessionTimeout = timeout;
      _isFingerprint = isFingerprint;
      _biometricsSupported = biometricsSupported;
      _lastAuthTime =
          '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _toggleFingerprint(bool value) async {
    await SecurityService.setFingerprintEnabled(value);
    setState(() {
      _fingerprintEnabled = value;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Biometric Authentication ${value ? 'Enabled' : 'Disabled'}',
          ),
        ),
      );
    }
  }

  Future<void> _changeSessionTimeout(int seconds) async {
    await SecurityService.setSessionTimeout(seconds);
    setState(() {
      _sessionTimeout = seconds;
    });
  }

  void _showChangePinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppDesign.borderMedium),
        title: const Text(
          'Change Security PIN',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _oldPinController,
                labelText: 'Old PIN',
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                prefixIcon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: AppDesign.space12),
              AppTextField(
                controller: _newPinController,
                labelText: 'New PIN',
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                prefixIcon: Icons.lock_rounded,
              ),
              const SizedBox(height: AppDesign.space12),
              AppTextField(
                controller: _confirmPinController,
                labelText: 'Confirm New PIN',
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                prefixIcon: Icons.lock_rounded,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _oldPinController.clear();
              _newPinController.clear();
              _confirmPinController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          AppButton(onPressed: _performPinChange, label: 'Update PIN'),
        ],
      ),
    );
  }

  Future<void> _performPinChange() async {
    final oldPin = _oldPinController.text;
    final newPin = _newPinController.text;
    final confirm = _confirmPinController.text;

    if (newPin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New PIN must be exactly 4 digits.')),
      );
      return;
    }

    if (newPin != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('New PINs do not match.')));
      return;
    }

    try {
      await SecurityService.changePin(oldPin, newPin);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update PIN: $e')));
    } finally {
      _oldPinController.clear();
      _newPinController.clear();
      _confirmPinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Security Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDesign.space16),
        children: [
          // Encryption Banner
          Container(
            padding: const EdgeInsets.all(AppDesign.space16),
            decoration: BoxDecoration(
              color: AppDesign.primaryEmerald.withValues(alpha: 0.05),
              borderRadius: AppDesign.borderMedium,
              border: Border.all(
                color: AppDesign.primaryEmerald.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.enhanced_encryption_rounded,
                  color: AppDesign.primaryEmerald,
                  size: 28,
                ),
                const SizedBox(width: AppDesign.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AES-256 Encryption Active',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your database and authentication parameters are securely hashed and stored locally.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDesign.space24),
          const SectionHeader(title: 'Authentication Status'),
          const SizedBox(height: AppDesign.space12),

          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.pin_rounded,
                    color: AppDesign.primaryEmerald,
                  ),
                  title: const Text('PIN Protection'),
                  subtitle: const Text(
                    'Authorized configuration PIN is enabled',
                  ),
                  trailing: const StatusBadge(
                    label: 'Enabled',
                    color: AppDesign.greenReceivable,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.fingerprint_rounded,
                    color: AppDesign.primaryEmerald,
                  ),
                  title: const Text('Biometric Hardware'),
                  subtitle: Text(
                    _biometricsSupported
                        ? 'Supported on this device'
                        : 'Unsupported on this device',
                  ),
                  trailing: StatusBadge(
                    label: _biometricsSupported ? 'Ready' : 'Not Found',
                    color: _biometricsSupported
                        ? AppDesign.greenReceivable
                        : AppDesign.grayNeutral,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.history_toggle_off_rounded,
                    color: AppDesign.primaryTeal,
                  ),
                  title: const Text('Last Session Auth'),
                  subtitle: Text('Last active: $_lastAuthTime'),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDesign.space24),
          const SectionHeader(title: 'Authorization Controls'),
          const SizedBox(height: AppDesign.space12),

          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.password_rounded,
                    color: AppDesign.primaryEmerald,
                  ),
                  title: const Text('Change Security PIN'),
                  subtitle: const Text(
                    'Update your local security authorization PIN',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: _showChangePinDialog,
                ),
                if (_biometricsSupported || _isFingerprint) ...[
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: Icon(
                      Icons.fingerprint_rounded,
                      color: AppDesign.primaryEmerald,
                    ),
                    activeColor: AppDesign.primaryEmerald,
                    title: const Text('Fingerprint & Face Unlock'),
                    subtitle: const Text(
                      'Unlock using registered device biometrics',
                    ),
                    value: _fingerprintEnabled,
                    onChanged: _toggleFingerprint,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppDesign.space24),
          const SectionHeader(title: 'Auto-Lock Preferences'),
          const SizedBox(height: AppDesign.space12),

          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppDesign.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Auto-Lock Timeout',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'How long the app should remain unlocked in the background',
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _sessionTimeout,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: AppDesign.borderMedium,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppDesign.darkBg
                          : Colors.grey.shade50,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 0,
                        child: Text('Lock Immediately'),
                      ),
                      DropdownMenuItem(
                        value: 60,
                        child: Text('Lock after 1 Minute'),
                      ),
                      DropdownMenuItem(
                        value: 300,
                        child: Text('Lock after 5 Minutes'),
                      ),
                      DropdownMenuItem(value: -1, child: Text('Never Lock')),
                    ],
                    onChanged: (val) {
                      if (val != null) _changeSessionTimeout(val);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
