import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/kaylo_button.dart';
import '../../../../core/widgets/kaylo_liquid_glass.dart';
import '../../../../core/widgets/kaylo_logo.dart';
import '../../../../core/widgets/kaylo_text_field.dart';
import '../../domain/auth_repository.dart';
import '../../../../core/widgets/kaylo_snackbar.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSignUp = false; // Toggle between Sign In and Sign Up

  late final AnimationController _animController;
  late final Animation<double> _formHeightAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _formHeightAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
    });
    if (_isSignUp) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  Future<void> _handlePhoneSubmit() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      KayloSnackbar.showError(context, 'Please enter a valid phone number');
      return;
    }
    
    if (_isSignUp) {
      final firstName = _firstNameController.text.trim();
      if (firstName.isEmpty) {
        KayloSnackbar.showError(context, 'Please enter your first name');
        return;
      }
    }
    
    final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithPhone(formattedPhone);
      if (mounted) {
        context.push(Routes.loginOtp, extra: formattedPhone);
      }
    } catch (e) {
      if (mounted) KayloSnackbar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _handleSocial(Future<void> Function() authMethod) async {
    setState(() => _isLoading = true);
    try {
      await authMethod();
      await Future.delayed(const Duration(milliseconds: 100)); // Wait for stream propagation
      if (mounted) context.go(Routes.location);
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
      body: Stack(
        children: [
          // Background Gradient / Decor
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                      ? [const Color(0xFF0F1713), const Color(0xFF16211B)]
                      : [const Color(0xFFF0FDF4), const Color(0xFFF8FAFC)],
                ),
              ),
            ),
          ),
          // Glow blobs
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.15 : 0.2),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.m),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: SizedBox(width: 72, height: 72, child: KayloLogo()),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Welcome to Kaylo',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Your home, farm, and care companion',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    
                    // Glassmorphic Auth Card
                    KayloLiquidGlass(
                      borderRadius: 32,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        children: [
                          // Custom Tab Toggle
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.white60,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Stack(
                              children: [
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  left: _isSignUp ? MediaQuery.of(context).size.width / 2 - AppSpacing.xl * 2 - 4 : 4,
                                  right: _isSignUp ? 4 : MediaQuery.of(context).size.width / 2 - AppSpacing.xl * 2 - 4,
                                  top: 4,
                                  bottom: 4,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.surfaceDark : AppColors.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: _isSignUp ? _toggleAuthMode : null,
                                        child: Center(
                                          child: Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontWeight: !_isSignUp ? FontWeight.w700 : FontWeight.w500,
                                              color: !_isSignUp 
                                                  ? (isDark ? Colors.white : Colors.black)
                                                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: !_isSignUp ? _toggleAuthMode : null,
                                        child: Center(
                                          child: Text(
                                            'Sign Up',
                                            style: TextStyle(
                                              fontWeight: _isSignUp ? FontWeight.w700 : FontWeight.w500,
                                              color: _isSignUp 
                                                  ? (isDark ? Colors.white : Colors.black)
                                                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          
                          // Expandable fields for Sign Up
                          SizeTransition(
                            sizeFactor: _formHeightAnim,
                            // The replacement `alignment` parameter does not
                            // exist yet on the Flutter versions the team runs
                            // locally; switch over once everyone is past 3.41.
                            // ignore: deprecated_member_use
                            axisAlignment: -1.0,
                            child: FadeTransition(
                              opacity: _fadeAnim,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: KayloTextField(
                                          label: 'First Name',
                                          hintText: 'John',
                                          controller: _firstNameController,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.m),
                                      Expanded(
                                        child: KayloTextField(
                                          label: 'Last Name',
                                          hintText: 'Doe',
                                          controller: _lastNameController,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.l),
                                ],
                              ),
                            ),
                          ),
                          
                          KayloTextField(
                            label: 'Phone Number',
                            hintText: 'e.g. 98470 12345',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          KayloButton(
                            text: 'Continue',
                            onPressed: _handlePhoneSubmit,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          
                          Row(
                            children: [
                              Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.border)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                                child: Text(
                                  'OR',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.border)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          
                          Row(
                            children: [
                              Expanded(
                                child: KayloButton(
                                  text: 'Google',
                                  variant: KayloButtonVariant.secondary,
                                  onPressed: () => _handleSocial(() => ref.read(authRepositoryProvider).signInWithGoogle()),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.m),
                              Expanded(
                                child: KayloButton(
                                  text: 'Apple',
                                  variant: KayloButtonVariant.secondary,
                                  onPressed: () => _handleSocial(() => ref.read(authRepositoryProvider).signInWithApple()),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
