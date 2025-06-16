import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/providers/auth_provider.dart';
import 'package:travinhgo/providers/setting_provider.dart';
import 'package:travinhgo/widget/language_switch.dart';
import 'package:travinhgo/widget/notification_login_button.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settingProvider = Provider.of<SettingProvider>(context);
    final isLoggedIn = authProvider.isAuthenticated;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: 80, // Fixed height for the header
      padding: const EdgeInsets.fromLTRB(0, 5, 10, 5),
      decoration: const BoxDecoration(
        color: Color(0xFF158247), // Green background color
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: App logo - adjusted to match image
          Image.asset(
            "assets/images/auth/logo-horizontal.png",
            height: 60,
            width: screenWidth * 0.4, // 40% of screen width
            fit: BoxFit.contain,
          ),

          // Right side: Language switch and notification button (only if logged in)
          Row(
            children: [
              // Language switch
              const LanguageSwitch(),

              // Only show notification button if logged in
              if (isLoggedIn) ...[
                const SizedBox(width: 12),
                const NotificationLoginButton(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
