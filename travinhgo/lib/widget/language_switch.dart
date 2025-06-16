import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/providers/setting_provider.dart';

class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingProvider = Provider.of<SettingProvider>(context);
    final isVietnamese = settingProvider.currentLanguage == 'vi';

    return GestureDetector(
      onTap: () {
        settingProvider.toggleLanguage();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 90,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/navigations/vietnam.png',
                        width: 12,
                        height: 12,
                      ),
                      const SizedBox(width: 2),
                      const Text(
                        "Vie",
                        style: TextStyle(
                          color: Color(0xFF158247),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Row(
                    children: [
                      const Text(
                        "Eng",
                        style: TextStyle(
                          color: Color(0xFF158247),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Image.asset(
                        'assets/images/navigations/circle.png',
                        width: 12,
                        height: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              alignment:
                  isVietnamese ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: 46,
                height: 26,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Color(0xFF158247),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF158247), width: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
