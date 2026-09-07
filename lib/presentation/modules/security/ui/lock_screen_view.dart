import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/di/injection.dart';
import '../../../../core/services/security_service/security_service.dart';

/// Premium Dark Fintech App Lock Screen with Biometrics and 4-Digit Numeric PIN Pad
class LockScreenView extends StatefulWidget {
  const LockScreenView({super.key});

  @override
  State<LockScreenView> createState() => _LockScreenViewState();
}

class _LockScreenViewState extends State<LockScreenView> with SingleTickerProviderStateMixin {
  final SecurityService _securityService = sl<SecurityService>();

  String _enteredPin = '';
  bool _isChecking = false;
  String? _errorMessage;
  Timer? _cooldownTimer;
  int _remainingCooldown = 0;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 16)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _shakeController.reverse();
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLockout();
      if (_securityService.isBiometricEnabled && !_securityService.isLockoutActive) {
        _promptBiometric();
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _checkLockout() {
    if (_securityService.isLockoutActive) {
      setState(() {
        _remainingCooldown = _securityService.remainingLockoutSeconds;
        _errorMessage = 'Too many failed attempts. Wait $_remainingCooldown s';
      });
      _startCooldownTimer();
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = _securityService.remainingLockoutSeconds;
      if (remaining <= 0) {
        timer.cancel();
        setState(() {
          _remainingCooldown = 0;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _remainingCooldown = remaining;
          _errorMessage = 'Too many failed attempts. Wait $remaining s';
        });
      }
    });
  }

  Future<void> _promptBiometric() async {
    if (_isChecking || _securityService.isLockoutActive) return;
    HapticFeedback.lightImpact();
    final success = await _securityService.authenticateWithBiometrics(
      reason: 'Scan fingerprint or face to unlock SpendWise',
    );
    if (!success && mounted) {
      setState(() {
        _errorMessage = 'Biometric verification cancelled';
      });
    }
  }

  void _onDigitPress(String digit) {
    if (_isChecking || _securityService.isLockoutActive || _enteredPin.length >= 4) return;
    HapticFeedback.selectionClick();

    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onDeletePress() {
    if (_isChecking || _enteredPin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _verifyPin() async {
    setState(() => _isChecking = true);
    final isValid = await _securityService.verifyPin(_enteredPin);

    if (!mounted) return;

    if (isValid) {
      HapticFeedback.mediumImpact();
      // App is unlocked via SecurityService
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward();
      setState(() {
        _isChecking = false;
        _enteredPin = '';
        if (_securityService.isLockoutActive) {
          _remainingCooldown = _securityService.remainingLockoutSeconds;
          _errorMessage = 'Too many failed attempts. Wait $_remainingCooldown s';
          _startCooldownTimer();
        } else {
          final attemptsLeft = 5 - _securityService.failedAttempts;
          _errorMessage = 'Incorrect PIN. $attemptsLeft attempts left';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Shield Icon & Brand
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.creditGreen.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  size: 44,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'SpendWise',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'App is locked for your security',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryDark,
                ),
              ),

              const Spacer(flex: 2),

              // PIN Dots with Shake Animation
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _enteredPin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                          color: isFilled
                              ? AppColors.primary
                              : AppColors.textSecondaryDark.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 16),

              // Error / Status Message
              AnimatedOpacity(
                opacity: _errorMessage != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _errorMessage ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.debitRed,
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Keypad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    _buildKeypadRow(['1', '2', '3']),
                    const SizedBox(height: 18),
                    _buildKeypadRow(['4', '5', '6']),
                    const SizedBox(height: 18),
                    _buildKeypadRow(['7', '8', '9']),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Biometric button (if available)
                        _securityService.isBiometricEnabled
                            ? _buildActionButton(
                                icon: Icons.fingerprint_rounded,
                                onTap: _promptBiometric,
                                label: 'Scan',
                              )
                            : const SizedBox(width: 68, height: 68),
                        // Center: 0
                        _buildDigitButton('0'),
                        // Right: Backspace
                        _buildActionButton(
                          icon: Icons.backspace_outlined,
                          onTap: _onDeletePress,
                          label: 'Delete',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: digits.map((d) => _buildDigitButton(d)).toList(),
    );
  }

  Widget _buildDigitButton(String digit) {
    final isDisabled = _securityService.isLockoutActive;

    return InkWell(
      onTap: isDisabled ? null : () => _onDigitPress(digit),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.darkSurfaceVariant.withValues(alpha: 0.6),
          border: Border.all(
            color: AppColors.darkBorder.withValues(alpha: 0.6),
          ),
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: isDisabled ? AppColors.textTertiaryDark : AppColors.textPrimaryDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String label,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 68,
        height: 68,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Center(
          child: Icon(
            icon,
            size: 26,
            color: AppColors.textSecondaryDark,
          ),
        ),
      ),
    );
  }
}
