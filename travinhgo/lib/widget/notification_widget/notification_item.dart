import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:travinhgo/Models/notification/notification.dart';

import '../../utils/string_helper.dart';

class NotificationItem extends StatelessWidget {
  final UserNotification userNotification;
  final bool isNew;

  const NotificationItem(
      {super.key, required this.userNotification, required this.isNew});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 4,
      color: isNew ? colorScheme.secondaryContainer : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              textAlign: TextAlign.left,
              StringHelper.toTitleCase(userNotification.title),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              textAlign: TextAlign.left,
              StringHelper.normalizeName(userNotification.content!) ?? 'N/A',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              textAlign: TextAlign.left,
              StringHelper.formatDateTime(
                  userNotification.createdAt.toString()),
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
