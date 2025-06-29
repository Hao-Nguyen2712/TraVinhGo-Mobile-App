import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/notification_provider.dart';

class NotificationLoginButton extends StatelessWidget {
  const NotificationLoginButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationProvider = NotificationProvider.of(context);
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          'Notification',
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                "assets/images/navigations/bell.png",
                color: Colors.white,
                scale: 10,
              ),
            ),
          ),
          if(notificationProvider.userNotification.length>0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFDD2334),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Text(
                  notificationProvider.userNotification.length.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
