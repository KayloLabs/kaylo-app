import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import 'package:kaylo_ui/widgets/kaylo_text_field.dart';
import '../../application/current_user_provider.dart';
import '../../domain/auth_repository.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';

/// Where a sign-in code went: an email address (the usual way) or a
/// phone number (Firebase SMS, once the project is on the Blaze plan).
enum OtpChannel { email, phone }

class OtpTarget {
  final OtpChannel channel;
  final String destination;

  const OtpTarget.email(this.destination) : channel = OtpChannel.email;
  const OtpTarget.phone(this.destination) : channel = OtpChannel.phone;
}

class OtpVerifyScreen extends ConsumerStatefulWidget {
  final OtpTarget target;

  const OtpVerifyScreen({super.key, required this.target});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

/// Firebase sends six digits; the mock sign-in accepts 1234.
const int otpLength = useMockData ? 4 : 6;

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _left = false;
  int _countdown = 25;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // A full code submits itself, as on any OTP screen people know.
    _otpController.addListener(() {
      if (_otpController.text.length == otpLength && !_isLoading) {
        _verifyOtp();
      }
    });
  }

  void _leaveTo(String route) {
    if (_left || !mounted) return;
    _left = true;
    context.go(route);
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
    if (otp.length < otpLength) {
      KayloSnackbar.showError(
        context,
        'Please enter the $otpLength-digit code',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      final target = widget.target;
      if (target.channel == OtpChannel.email) {
        await auth.verifyEmailCode(target.destination, otp);
      } else {
        await auth.verifyOtp(target.destination, otp);
      }
      // The router only lets a signed-in user past login, so wait for the
      // profile to load before moving on.
      await awaitSignedInUser(ref);
      _leaveTo(Routes.location);
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
      final auth = ref.read(authRepositoryProvider);
      final target = widget.target;
      if (target.channel == OtpChannel.email) {
        await auth.requestEmailCode(target.destination);
      } else {
        await auth.signInWithPhone(target.destination);
      }
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
    // On Android, Firebase can read the SMS and sign in by itself; the
    // session then appears without a tap here.
    ref.listen(currentUserProvider, (_, user) {
      if (user != null && !_isLoading) _leaveTo(Routes.location);
    });
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
                widget.target.channel == OtpChannel.email
                    ? 'Check your email'
                    : 'Verify your number',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'We sent a $otpLength-digit code to ${widget.target.destination}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              KayloCard(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  children: [
                    KayloTextField(
                      label: 'Verification Code',
                      hintText: '0' * otpLength,
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: otpLength,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      autofillHints: const [AutofillHints.oneTimeCode],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _verifyOtp(),
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
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: _countdown > 0 ? null : _resendOtp,
                    child: Text(
                      _countdown > 0
                          ? 'Resend in 00:${_countdown.toString().padLeft(2, '0')}'
                          : 'Resend',
                      style: TextStyle(
                        color: _countdown > 0
                            ? (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary)
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
