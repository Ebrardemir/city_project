import 'dart:ui';
import 'package:city_project/Features/Login/view_model/register_viewmodel.dart';
import 'package:city_project/core/Router/app_router_constants.dart';
import 'package:city_project/core/constants/tr_locations.dart'; // ✅ BURASI
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/auth_text_field.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RegisterViewModel>();
    final size = MediaQuery.of(context).size;

    // ✅ İl seçimine göre ilçeleri çek
    final districts = TrLocations.districtsOf(viewModel.selectedCity);
    // Eğer sende districtsOf yoksa, şunu kullan:
    // final districts = TrLocations.districtsByCity[viewModel.selectedCity] ?? const [];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            height: size.height,
            width: size.width,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 70,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Yeni Hesap Oluştur",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "CityPulse topluluğuna katılın",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  const SizedBox(height: 40),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 25,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            if (viewModel.errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        viewModel.errorMessage!,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            AuthTextField(
                              controller: viewModel.nameController,
                              label: "Ad Soyad",
                              icon: Icons.person_outline,
                              hint: "Adınız ve soyadınız",
                            ),
                            const SizedBox(height: 18),

                            AuthTextField(
                              controller: viewModel.emailController,
                              label: "E-posta",
                              icon: Icons.email_outlined,
                              hint: "email@belediye.bel.tr",
                            ),
                            const SizedBox(height: 18),

                            AuthTextField(
                              controller: viewModel.passwordController,
                              label: "Şifre",
                              icon: Icons.lock_outline,
                              hint: "Güçlü bir şifre giriniz",
                              isPassword: true,
                            ),
                            const SizedBox(height: 18),

                            // ✅ İl (Şehir)
                            DropdownButtonFormField<String>(
                              value: viewModel.selectedCity,
                              decoration: InputDecoration(
                                labelText: "Yaşadığınız Şehir",
                                prefixIcon: const Icon(Icons.map_outlined),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1565C0),
                                    width: 2,
                                  ),
                                ),
                              ),
                              items: TrLocations.cities
                                  .map(
                                    (city) => DropdownMenuItem(
                                      value: city,
                                      child: Text(city),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                viewModel.setSelectedCity(value);
                              },
                            ),

                            const SizedBox(height: 18),

                            // ✅ İlçe
                            DropdownButtonFormField<String>(
                              value: viewModel.selectedDistrict,
                              decoration: InputDecoration(
                                labelText: "Yaşadığınız İlçe",
                                prefixIcon: const Icon(
                                  Icons.location_on_outlined,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1565C0),
                                    width: 2,
                                  ),
                                ),
                              ),
                              items: districts
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d),
                                    ),
                                  )
                                  .toList(),
                              onChanged: viewModel.selectedCity == null
                                  ? null
                                  : (value) {
                                      viewModel.setSelectedDistrict(value);
                                    },
                            ),

                            const SizedBox(height: 30),

                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 6,
                                  backgroundColor: const Color(0xFF1565C0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: viewModel.isLoading
                                    ? null
                                    : () async {
                                        final success = await viewModel
                                            .register();

                                        if (success && context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Kayıt başarılı! Giriş sayfasına yönlendiriliyorsunuz...',
                                              ),
                                              backgroundColor: Colors.green,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );

                                          await Future.delayed(
                                            const Duration(seconds: 1),
                                          );
                                          if (context.mounted) {
                                            context.goNamed(
                                              AppRouterConstants.loginRouteName,
                                            );
                                          }
                                        }
                                      },
                                child: viewModel.isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      )
                                    : const Text(
                                        "Kayıt Ol",
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Zaten hesabınız var mı? ",
                                  style: TextStyle(color: Colors.black54),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.goNamed(
                                      AppRouterConstants.loginRouteName,
                                    );
                                  },
                                  child: const Text(
                                    "Giriş Yap",
                                    style: TextStyle(
                                      color: Color(0xFF1565C0),
                                      fontWeight: FontWeight.bold,
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

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
