import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/kaylo_button.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/kaylo_text_field.dart';
import '../../domain/auth_repository.dart';
import '../../../../core/widgets/kaylo_snackbar.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  final String phone;
  
  const OtpVerifyScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  int _countdown = 25;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }
  
  void _startTimer() {
    setState(() => _countdown = 25);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      KayloSnackbar.showError(context, 'Please enter a valid 4-digit code');
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).verifyOtp(widget.phone, otp);
      await Future.delayed(const Duration(milliseconds: 100)); // Wait for stream propagation
      if (mounted) {
        // After verifying OTP, check if location is set. For now, go to location setup.
        context.go(Routes.location);
      }
    } catch (e) {
      if (mounted) {
        KayloSnackbar.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _resendOtp() async {
    if (_countdown > 0) return;
    
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithPhone(widget.phone);
      _startTimer();
      if (mounted) KayloSnackbar.showInfo(context, 'OTP resent successfully');
    } catch (e) {
      if (mounted) KayloSnackbar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Verify your number',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'We sent a 4-digit code to ${widget.phone}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              KayloCard(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  children: [
                    KayloTextField(
                      label: 'Verification Code',
                      hintText: '0000',
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.password_outlined),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    KayloButton(
                      text: 'Verify',
                      onPressed: _verifyOtp,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn\'t receive the code? ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: _countdown > 0 ? null : _resendOtp,
                    child: Text(
                      _countdown > 0 ? 'Resend in 00:${_countdown.toString().padLeft(2, '0')}' : 'Resend',
                      style: TextStyle(
                        color: _countdown > 0 
                            ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)
                            : AppColors.brandPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
