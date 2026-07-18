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
  bool _appLockEnabled = true;
  int _sessionTimeout = 60; // default 60s (1 min)
  bool _isFingerprint = false;
  bool _biometricsSupported = false;

  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _recoveryQuestionController = TextEditingController();
  final _recoveryAnswerController = TextEditingController();
  String _selectedQuestion = "What was my first school's name?";
  bool _isCustomQuestion = false;

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
    _recoveryQuestionController.dispose();
    _recoveryAnswerController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final finger = await SecurityService.isFingerprintEnabled();
    final lockEnabled = await SecurityService.isAppLockEnabled();
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
      _appLockEnabled = lockEnabled;
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

  Future<void> _toggleAppLock(bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!value) {
      // Disabling app lock requires PIN verification
      final pinVerified = await _verifyPinDialog('Verify PIN to Disable App Lock');
      if (pinVerified == true) {
        await SecurityService.setAppLockEnabled(false);
        setState(() {
          _appLockEnabled = false;
        });
        messenger.showSnackBar(
          const SnackBar(content: Text('App Lock disabled successfully.')),
        );
      }
    } else {
      // Enabling App Lock does not require old PIN verification
      await SecurityService.setAppLockEnabled(true);
      setState(() {
        _appLockEnabled = true;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('App Lock enabled successfully.')),
      );
    }
  }

  Future<bool?> _verifyPinDialog(String title) async {
    final controller = TextEditingController();
    return await showDialog<bool>(
      context: context,
      builder: (context) => AnimatedPadding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        duration: const Duration(milliseconds: 100),
        curve: Curves.decelerate,
        child: AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(borderRadius: AppDesign.borderMedium),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          content: TextField(
            controller: controller,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(labelText: 'Enter PIN', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesign.primaryEmerald,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade800,
                disabledForegroundColor: Colors.grey.shade500,
              ),
              onPressed: () async {
                final isValid = await SecurityService.verifyPin(controller.text);
                if (isValid) {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect PIN.')),
                  );
                }
              },
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangeRecoveryQuestionDialog() async {
    // First, verify PIN
    final pinVerified = await _verifyPinDialog('Verify PIN to Change Recovery Question');
    if (pinVerified != true) return;

    // Show the custom dialog to input question and answer
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(borderRadius: AppDesign.borderMedium),
          title: const Text('Change Recovery Question', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedQuestion,
                decoration: const InputDecoration(
                  labelText: 'Question Presets',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: "What was my first school's name?",
                    child: Text("What was my first school's name?", style: TextStyle(fontSize: 12)),
                  ),
                  DropdownMenuItem(
                    value: "What nickname did my grandfather call me?",
                    child: Text("What nickname did my grandfather call me?", style: TextStyle(fontSize: 12)),
                  ),
                  DropdownMenuItem(
                    value: "What is my favorite cricket team?",
                    child: Text("What is my favorite cricket team?", style: TextStyle(fontSize: 12)),
                  ),
                  DropdownMenuItem(
                    value: "Write custom question...",
                    child: Text("Write custom question...", style: TextStyle(fontSize: 12)),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      _selectedQuestion = val;
                      _isCustomQuestion = val == "Write custom question...";
                    });
                  }
                },
              ),
              if (_isCustomQuestion) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _recoveryQuestionController,
                  decoration: const InputDecoration(
                    labelText: 'Custom Recovery Question',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _recoveryAnswerController,
                decoration: const InputDecoration(
                  labelText: 'Recovery Answer',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _recoveryQuestionController.clear();
                _recoveryAnswerController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppDesign.primaryEmerald),
              onPressed: () async {
                final question = _isCustomQuestion ? _recoveryQuestionController.text.trim() : _selectedQuestion;
                final answer = _recoveryAnswerController.text.trim();

                if (question.isEmpty || answer.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill out all fields.')),
                  );
                  return;
                }

                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);

                await SecurityService.saveRecoveryQuestionAndAnswer(question, answer);
                
                nav.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Recovery question updated successfully.')),
                );
                _recoveryQuestionController.clear();
                _recoveryAnswerController.clear();
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesign.space24,
          vertical: AppDesign.space16,
        ),
        children: [
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesign.space12,
              vertical: 2,
            ),
            child: Text(
              'AUTHORIZATION CONTROLS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.password_rounded,
                    color: AppDesign.primaryEmerald,
                    size: 20,
                  ),
                  title: const Text('Change Security PIN', style: TextStyle(fontSize: 13)),
                  subtitle: const Text(
                    'Update your local security authorization PIN',
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                  onTap: _showChangePinDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.help_center_rounded,
                    color: AppDesign.primaryEmerald,
                    size: 20,
                  ),
                  title: const Text('Change Recovery Question', style: TextStyle(fontSize: 13)),
                  subtitle: const Text(
                    'Update your backup PIN recovery question',
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                  onTap: _showChangeRecoveryQuestionDialog,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  dense: true,
                  secondary: Icon(
                    Icons.lock_rounded,
                    color: AppDesign.primaryEmerald,
                    size: 20,
                  ),
                  activeColor: AppDesign.primaryEmerald,
                  title: const Text('App Lock Active', style: TextStyle(fontSize: 13)),
                  subtitle: const Text(
                    'Require PIN authentication on startup/resume',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: _appLockEnabled,
                  onChanged: (val) {
                    _toggleAppLock(val);
                  },
                ),
                if (_biometricsSupported || _isFingerprint) ...[
                  const Divider(height: 1),
                  SwitchListTile(
                    dense: true,
                    secondary: Icon(
                      Icons.fingerprint_rounded,
                      color: AppDesign.primaryEmerald,
                      size: 20,
                    ),
                    activeColor: AppDesign.primaryEmerald,
                    title: const Text('Fingerprint Unlock', style: TextStyle(fontSize: 13)),
                    subtitle: const Text(
                      'Unlock using registered device biometrics',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: _fingerprintEnabled,
                    onChanged: _toggleFingerprint,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesign.space12,
              vertical: 2,
            ),
            child: Text(
              'AUTO-LOCK PREFERENCES',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Auto-Lock Timeout',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'How long the app should remain unlocked in the background',
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                        child: Text('Lock Immediately', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 60,
                        child: Text('Lock after 1 Minute', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 300,
                        child: Text('Lock after 5 Minutes', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: -1,
                        child: Text('Never Lock', style: TextStyle(fontSize: 13)),
                      ),
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
