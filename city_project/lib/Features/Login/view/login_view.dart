import 'dart:ui';
import 'package:city_project/Features/Login/view_model/login_viewmodel.dart';
import 'package:city_project/core/Router/app_router_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/auth_text_field.dart';
//deneme
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🏙️ LOGO + BAŞLIK
                Icon(
                  Icons.location_city_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  "CityPulse",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Belediye Sosyal Ağı",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),

                const SizedBox(height: 48),

                // Card yerine temiz form alanı
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.dividerColor,
                    ),
                  ),
                  child: Column(
                    children: [
                      // E-Posta
                      AuthTextField(
                        controller: viewModel.emailController,
                        label: "E-posta",
                        hint: "email@belediye.bel.tr",
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 20),

                      // Şifre
                      AuthTextField(
                        controller: viewModel.passwordController,
                        label: "Şifre",
                        hint: "••••••••",
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text("Şifremi Unuttum"),
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Giriş Butonu
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: viewModel.isLoading
                              ? null
                              : () async {
                                  try {
                                    await viewModel.login();
                                  } on Exception catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Hata: $e')),
                                    );
                                  }
                                },
                          child: viewModel.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Giriş Yap"),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                       // Google ile Giriş
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.login),
                          label: const Text("Google ile Devam Et"),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.dividerColor),
                            foregroundColor: theme.colorScheme.onSurface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: viewModel.isLoading
                              ? null
                              : () async {
                                  try {
                                    await viewModel.loginWithGoogle();
                                  } on Exception catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Google giriş başarısız: $e')),
                                    );
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Kayıt Ol Linki
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Hesabın yok mu?",
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    ),
                    TextButton(
                      onPressed: () {
                        context.push(AppRouterConstants.registerRouteName);
                      },
                      child: const Text("Kayıt Ol"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



