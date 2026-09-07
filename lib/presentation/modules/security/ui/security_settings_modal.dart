import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/di/injection.dart';
import '../../../../core/services/security_service/security_service.dart';

/// Modal bottom sheet for configuring App Lock, Biometrics, PIN, and Privacy Mode
class SecuritySettingsModal extends StatefulWidget {
  const SecuritySettingsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const SecuritySettingsModal(),
    );
  }

  @override
  State<SecuritySettingsModal> createState() => _SecuritySettingsModalState();
}

class _SecuritySettingsModalState extends State<SecuritySettingsModal> {
  final SecurityService _securityService = sl<SecurityService>();

  bool _canUseBiometrics = false;
  bool _hasPin = false;
  late bool _isBiometricEnabled;
  late AutoLockTimeout _selectedTimeout;
  late bool _isPrivacyMode;

  @override
  void initState() {
    super.initState();
    _isBiometricEnabled = _securityService.isBiometricEnabled;
    _selectedTimeout = _securityService.autoLockTimeout;
    _isPrivacyMode = _securityService.isPrivacyMode;

    _checkCapabilities();
  }

  Future<void> _checkCapabilities() async {
    final canBio = await _securityService.canCheckBiometrics();
    final hasPin = await _securityService.hasStoredPin();
    if (mounted) {
      setState(() {
        _canUseBiometrics = canBio;
        _hasPin = hasPin;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      // Prompt biometric to confirm enrollment before enabling
      final success = await _securityService.authenticateWithBiometrics(
        reason: 'Confirm biometric authentication to enable app lock',
      );
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric verification failed or cancelled')),
          );
        }
        return;
      }
    }

    setState(() {
      _isBiometricEnabled = value;
      _securityService.isBiometricEnabled = value;
    });
  }

  void _onSetupOrChangePin() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _SetPinModal(
        onSuccess: () {
          _checkCapabilities();
          setState(() {
            _hasPin = true;
          });
        },
      ),
    );
  }

  Future<void> _removePin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove PIN?'),
        content: const Text('Your 4-digit PIN will be deleted. You can set a new one anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.debitRed),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _securityService.removePin();
      _checkCapabilities();
      setState(() {
        _hasPin = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN removed successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Security & Privacy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Protect your expenses, account balances, and Khata ledger.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
          ),

          const SizedBox(height: 20),

          // 1. Biometric Lock
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant.withValues(alpha: 0.5) : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder.withValues(alpha: 0.6) : AppColors.lightBorder,
              ),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.creditGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.fingerprint_rounded, color: AppColors.creditGreen, size: 22),
              ),
              title: const Text('Biometric Lock', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(
                _canUseBiometrics
                    ? 'Unlock with Fingerprint or Face ID'
                    : 'Biometrics not enrolled on device',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
              ),
              value: _isBiometricEnabled && _canUseBiometrics,
              onChanged: _canUseBiometrics ? _toggleBiometrics : null,
            ),
          ),

          const SizedBox(height: 12),

          // 2. 4-Digit Fallback PIN
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant.withValues(alpha: 0.5) : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder.withValues(alpha: 0.6) : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pin_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '4-Digit PIN',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hasPin ? 'PIN is configured' : 'Set a fallback passcode',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                      ),
                    ],
                  ),
                ),
                if (_hasPin) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.debitRed, size: 20),
                    onPressed: _removePin,
                    tooltip: 'Remove PIN',
                  ),
                ],
                TextButton(
                  onPressed: _onSetupOrChangePin,
                  child: Text(_hasPin ? 'Change' : 'Set PIN'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 3. Auto-Lock Duration Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant.withValues(alpha: 0.5) : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder.withValues(alpha: 0.6) : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warningAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.timer_outlined, color: AppColors.warningAmber, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Auto-Lock Timeout',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                DropdownButton<AutoLockTimeout>(
                  value: _selectedTimeout,
                  underline: const SizedBox.shrink(),
                  borderRadius: BorderRadius.circular(12),
                  dropdownColor: theme.cardTheme.color,
                  items: AutoLockTimeout.values.map((timeout) {
                    return DropdownMenuItem(
                      value: timeout,
                      child: Text(timeout.label, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedTimeout = val;
                        _securityService.autoLockTimeout = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 4. Privacy Mode
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant.withValues(alpha: 0.5) : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder.withValues(alpha: 0.6) : AppColors.lightBorder,
              ),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.khataBook.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.visibility_off_outlined, color: AppColors.khataBook, size: 22),
              ),
              title: const Text('Privacy Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text(
                'Mask balances on Dashboard (₹ ••••••)',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
              ),
              value: _isPrivacyMode,
              onChanged: (val) {
                setState(() {
                  _isPrivacyMode = val;
                  _securityService.togglePrivacyMode();
                });
              },
            ),
          ),
        ],
      ),
    ),
  );
}
}

/// Sub-modal for entering & confirming a 4-digit PIN
class _SetPinModal extends StatefulWidget {
  final VoidCallback onSuccess;

  const _SetPinModal({required this.onSuccess});

  @override
  State<_SetPinModal> createState() => _SetPinModalState();
}

class _SetPinModalState extends State<_SetPinModal> {
  final SecurityService _securityService = sl<SecurityService>();

  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _error;

  void _onDigit(String d) {
    if (_isConfirming) {
      if (_confirmPin.length >= 4) return;
      setState(() {
        _confirmPin += d;
        _error = null;
      });
      if (_confirmPin.length == 4) {
        _submit();
      }
    } else {
      if (_pin.length >= 4) return;
      setState(() {
        _pin += d;
        _error = null;
      });
      if (_pin.length == 4) {
        setState(() {
          _isConfirming = true;
        });
      }
    }
  }

  void _onDelete() {
    setState(() {
      _error = null;
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _isConfirming = false;
        }
      } else if (_pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _submit() async {
    if (_pin != _confirmPin) {
      setState(() {
        _error = 'PINs do not match. Try again.';
        _confirmPin = '';
        _isConfirming = false;
        _pin = '';
      });
      return;
    }

    await _securityService.setPin(_pin);
    widget.onSuccess();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN configured successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePin = _isConfirming ? _confirmPin : _pin;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isConfirming ? 'Confirm your 4-Digit PIN' : 'Enter a new 4-Digit PIN',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < activePin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? AppColors.primary : Colors.transparent,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
              );
            }),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.debitRed, fontSize: 12)),
          ],
          const SizedBox(height: 20),
          // Mini Numeric Pad
          Column(
            children: [
              _buildRow(['1', '2', '3']),
              const SizedBox(height: 12),
              _buildRow(['4', '5', '6']),
              const SizedBox(height: 12),
              _buildRow(['7', '8', '9']),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 54, height: 54),
                  _buildButton('0'),
                  InkWell(
                    onTap: _onDelete,
                    borderRadius: BorderRadius.circular(28),
                    child: const SizedBox(
                      width: 54,
                      height: 54,
                      child: Icon(Icons.backspace_outlined, size: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildRow(List<String> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items.map((i) => _buildButton(i)).toList(),
    );
  }

  Widget _buildButton(String digit) {
    return InkWell(
      onTap: () => _onDigit(digit),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.darkSurfaceVariant.withValues(alpha: 0.5),
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
