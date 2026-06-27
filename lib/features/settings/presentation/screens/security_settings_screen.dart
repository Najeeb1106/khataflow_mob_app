import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/services/security_service.dart';

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
      isFingerprint = available.contains(BiometricType.fingerprint) || available.contains(BiometricType.strong);
    } catch (_) {}

    setState(() {
      _fingerprintEnabled = finger;
      _sessionTimeout = timeout;
      _isFingerprint = isFingerprint;
      _biometricsSupported = biometricsSupported;
    });
  }

  Future<void> _toggleFingerprint(bool value) async {
    await SecurityService.setFingerprintEnabled(value);
    setState(() {
      _fingerprintEnabled = value;
    });
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
        title: const Text('Change Security PIN'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _oldPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'Old PIN'),
              ),
              TextField(
                controller: _newPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'New PIN'),
              ),
              TextField(
                controller: _confirmPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'Confirm New PIN'),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _performPinChange,
            child: const Text('Update PIN'),
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New PINs do not match.')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update PIN: $e')),
      );
    } finally {
      _oldPinController.clear();
      _newPinController.clear();
      _confirmPinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          ListTile(
            enabled: true,
            leading: const Icon(Icons.pin, color: Colors.teal),
            title: const Text('Change PIN'),
            subtitle: const Text('Update your local security authorization PIN'),
            onTap: _showChangePinDialog,
          ),
          const Divider(),
          if (_isFingerprint) ...[
            SwitchListTile(
              activeColor: Colors.teal,
              title: const Text('Fingerprint Unlock', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Unlock using registered fingerprint credentials'),
              value: _fingerprintEnabled,
              onChanged: _toggleFingerprint,
            ),
            const Divider(),
          ],
          if (!_isFingerprint && _biometricsSupported) ...[
            SwitchListTile(
              activeColor: Colors.teal,
              title: const Text('Fingerprint Unlock', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Unlock using local device fingerprint credentials'),
              value: _fingerprintEnabled,
              onChanged: _toggleFingerprint,
            ),
            const Divider(),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auto-Lock Timeout',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'How long the app should remain unlocked in the background',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _sessionTimeout,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Lock Immediately')),
                    DropdownMenuItem(value: 60, child: Text('Lock after 1 Minute')),
                    DropdownMenuItem(value: 300, child: Text('Lock after 5 Minutes')),
                    DropdownMenuItem(value: -1, child: Text('Never Lock')),
                  ],
                  onChanged: (val) => _changeSessionTimeout(val!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
