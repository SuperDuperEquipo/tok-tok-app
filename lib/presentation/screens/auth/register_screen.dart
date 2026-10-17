import 'package:flutter/material.dart';
import 'package:toktok/config/theme/app_colors.dart';
import 'package:toktok/presentation/screens/discover/discover_screen.dart';
import 'package:toktok/presentation/widgets/auth/auth_background.dart';
import 'package:toktok/presentation/widgets/auth/auth_text_field.dart';
import 'package:toktok/presentation/widgets/auth/gradient_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _userCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DiscoverScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Stack(
        children: [
          const AuthBackground(),
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
                        Text(
                          'Crea tu cuenta',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Únete a Tok Tok y comparte con los demás',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 28),
                        AuthTextField(
                          controller: _userCtrl,
                          hint: 'Nombre de usuario',
                          icon: Icons.person_outline,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.length < 3) {
                              return 'Mínimo 3 caracteres';
                            }
                            if (value.contains(' ')) {
                              return 'No uses espacios';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
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
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Mínimo 6 caracteres'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          controller: _confirmCtrl,
                          hint: 'Confirmar contraseña',
                          icon: Icons.lock_outline,
                          obscure: true,
                          textInputAction: TextInputAction.done,
                          validator: (v) => v != _passCtrl.text
                              ? 'Las contraseñas no coinciden'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        GradientButton(
                          label: 'Crear cuenta',
                          onPressed: _onRegister,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '¿Ya tienes cuenta? ',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Inicia sesión',
                                style: TextStyle(
                                  color: AppColors.magenta,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
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