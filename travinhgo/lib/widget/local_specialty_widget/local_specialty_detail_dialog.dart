import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/models/local_specialties/local_specialties.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LocalSpecialtyDetailDialog extends StatelessWidget {
  final LocalSpecialtyLocation location;
  final String tagImage;

  const LocalSpecialtyDetailDialog({
    super.key,
    required this.location,
    required this.tagImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.network(
                      tagImage,
                      width: 36,
                      height: 36,
                    ),
                    SizedBox(width: 2.w),
                    Text(AppLocalizations.of(context)!.local),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  location.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on,
                    color: colorScheme.secondary, size: 16.sp),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    location.address,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
