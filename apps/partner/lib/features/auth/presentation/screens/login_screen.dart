import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import 'package:kaylo_ui/widgets/kaylo_logo.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import 'package:kaylo_ui/widgets/kaylo_text_field.dart';

import 'package:kaylo_core/config/app_env.dart';

import '../../../../core/router/routes.dart';
import '../../domain/partner_auth_repository.dart';
import '../../application/partner_session.dart';

class PartnerLoginScreen extends ConsumerStatefulWidget {
  const PartnerLoginScreen({super.key});

  @override
  ConsumerState<PartnerLoginScreen> createState() => _PartnerLoginScreenState();
}

class _PartnerLoginScreenState extends ConsumerState<PartnerLoginScreen> {
  // The sample build pre-fills the demo number and code.
  final _phoneController = TextEditingController(
    text: useMockData ? '98470 12345' : '',
  );
  final _otpController = TextEditingController(text: useMockData ? '1234' : '');
  int get _codeLength => useMockData ? 4 : 6;

  bool _isOtpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (phone.length < 10) {
      KayloSnackbar.showError(
        context,
        'Please enter a valid 10-digit phone number',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await ref
          .read(partnerAuthRepositoryProvider)
          .sendOtp(phone);
      if (!mounted) return;
      if (success) {
        KayloFeedback.press();
        setState(() => _isOtpSent = true);
      }
    } on PartnerAuthMessage catch (e) {
      if (mounted) KayloSnackbar.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.length != _codeLength) {
      KayloSnackbar.showError(
        context,
        useMockData
            ? 'Please enter the 4-digit OTP (e.g. 1234)'
            : 'Please enter the $_codeLength-digit code from the SMS',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await ref
          .read(partnerAuthRepositoryProvider)
          .verifyOtp(phone, otp);
      if (!mounted) return;
      if (success) {
        KayloFeedback.press();
        KayloSnackbar.showSuccess(context, 'Welcome back!');
        context.go(Routes.jobs);
      } else {
        KayloSnackbar.showError(context, 'Invalid OTP. Enter 1234 for demo.');
      }
    } on PartnerAuthMessage catch (e) {
      if (mounted) KayloSnackbar.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(partnerAuthRepositoryProvider).signInWithGoogle();
      if (!mounted) return;
      KayloFeedback.press();
      context.go(Routes.jobs);
    } on PartnerAuthMessage catch (e) {
      if (mounted) KayloSnackbar.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.l,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const KayloLogo(width: 80),
                const SizedBox(height: AppSpacing.m),
                Text(
                  'Kaylo Partner',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Service professionals delivery partner portal',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                KayloCard(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isOtpSent
                        ? _buildOtpForm(isDark)
                        : _buildPhoneForm(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneForm(bool isDark) {
    return Column(
      key: const ValueKey('phone_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Partner Sign In',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Enter your registered phone number to receive a verification code.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        KayloTextField(
          controller: _phoneController,
          label: 'Mobile number',
          hintText: '98470 12345',
          prefixIcon: const Icon(Icons.phone_android_rounded),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppSpacing.xl),
        KayloButton(
          text: 'Continue',
          isLoading: _isLoading,
          onPressed: _handleSendOtp,
        ),
        const SizedBox(height: AppSpacing.m),
        KayloButton(
          text: 'Continue with Google',
          icon: Icons.g_mobiledata_rounded,
          variant: KayloButtonVariant.secondary,
          onPressed: _isLoading ? null : _handleGoogle,
        ),
      ],
    );
  }

  Widget _buildOtpForm(bool isDark) {
    return Column(
      key: const ValueKey('otp_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verify OTP',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          useMockData
              ? 'Enter 4-digit code sent to +91 ${_phoneController.text.trim()} (Demo code: 1234)'
              : 'Enter the $_codeLength-digit code sent to ${_phoneController.text.trim()}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        KayloTextField(
          controller: _otpController,
          label: useMockData ? '4-digit OTP' : 'Verification code',
          hintText: useMockData ? '1234' : '',
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          keyboardType: TextInputType.number,
          maxLength: _codeLength,
        ),
        const SizedBox(height: AppSpacing.m),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _isOtpSent = false),
              child: const Text('Change number'),
            ),
            if (useMockData)
              TextButton(
                onPressed: () {
                  _otpController.text = '1234';
                  _handleVerifyOtp();
                },
                child: const Text('Fill 1234'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        KayloButton(
          text: 'Verify & Sign In',
          isLoading: _isLoading,
          onPressed: _handleVerifyOtp,
        ),
      ],
    );
  }
}
