import 'package:flutter/material.dart';
import 'package:toktok/config/theme/app_colors.dart';
import 'package:toktok/presentation/screens/discover/discover_screen.dart';
import 'package:toktok/presentation/widgets/auth/auth_text_field.dart';
import 'package:toktok/presentation/widgets/auth/gradient_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;

    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DiscoverScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _SoftBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _Logo(),
                        const SizedBox(height: 20),
                        Text(
                          'Tok Tok',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Comparte con los demás',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        AuthTextField(
                          controller: _emailCtrl,
                          hint: 'Correo electrónico',
                          icon: Icons.alternate_email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) return 'Ingresa tu correo';
                            if (!value.contains('@')) return 'Correo no válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          controller: _passCtrl,
                          hint: 'Contraseña',
                          icon: Icons.lock_outline,
                          obscure: true,
                          textInputAction: TextInputAction.done,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Ingresa tu contraseña'
                              : null,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GradientButton(
                          label: 'Iniciar sesión',
                          onPressed: _onLogin,
                        ),
                        const SizedBox(height: 20),
                        const _OrDivider(),
                        const SizedBox(height: 20),
                        _GoogleButton(onPressed: () {}),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '¿No tienes cuenta? ',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            GestureDetector(
                              onTap: () {}, // Registro: commit 3
                              child: const Text(
                                'Regístrate',
                                style: TextStyle(
                                  color: AppColors.magenta,
                                  fontWeight: FontWeight.w800,
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
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white),
        boxShadow: AppColors.brandGlow,
      ),
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1020),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.magenta,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'O',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'G',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Continuar con Google',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftBackground extends StatelessWidget {
  const _SoftBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -120,
          child: _glow(AppColors.magenta.withValues(alpha: 0.18), 360),
        ),
        Positioned(
          bottom: -140,
          right: -140,
          child: _glow(AppColors.orange.withValues(alpha: 0.16), 380),
        ),
      ],
    );
  }

  Widget _glow(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      );
}
