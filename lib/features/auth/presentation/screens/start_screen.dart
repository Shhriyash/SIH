import 'package:dakmadad/core/theme/app_colors.dart';
import 'package:dakmadad/l10n/generated/S.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dakmadad/features/auth/presentation/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_divider.dart';
import '../widgets/get_started_button.dart';

class StartScreen extends StatelessWidget {
  final void Function(Locale locale) onLanguageChange;
  final void Function(ThemeMode mode) onThemeChange;

  const StartScreen({
    super.key,
    required this.onLanguageChange,
    required this.onThemeChange,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(60.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context)!.welcomeTo,
                        style: GoogleFonts.montserrat(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryRed,
                        ),
                      ),
                      Text(
                        S.of(context)!.dakMadad,
                        style: GoogleFonts.montserrat(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  PopupMenuButton<Locale>(
                    onSelected: (Locale locale) {
                      onLanguageChange(locale);
                    },
                    icon: const Icon(Icons.language),
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: Locale('en'),
                        child: Text('English'),
                      ),
                      const PopupMenuItem(
                        value: Locale('hi'),
                        child: Text('हिंदी'),
                      ),
                      const PopupMenuItem(
                        value: Locale('ta'),
                        child: Text('தமிழ்'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: SvgPicture.asset(
                  'assets/svg/delivery-person-holding-package.svg',
                  height: 300,
                  width: 200,
                  fit: BoxFit.contain,
                ),
              ),
              Center(
                child: Column(
                  children: [
                    Text(
                      S.of(context)!.poweredByIndiaPost,
                      style: textTheme.bodyLarge,
                    ),
                    Text(
                      S.of(context)!.dakSewaJanSewa,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GetStartedButton(onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      onLanguageChange: onLanguageChange,
                      onThemeChange: onThemeChange,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 60),
              const CustomDivider(),
            ],
          ),
        ),
      ),
    );
  }
}
