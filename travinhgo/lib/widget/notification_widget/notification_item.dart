import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    textAlign: TextAlign.left,
                    StringHelper.toTitleCase(userNotification.title),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 7.0),
              child: Text(
                textAlign: TextAlign.left,
                StringHelper.formatDateTime(
                    userNotification.createdAt.toString()),
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Html(
              data: StringHelper.capitalizeFirstHtmlTextContent(
                  userNotification.content ?? 'N/A'),
              style: _htmlStyle(context),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Style> _htmlStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return {
      "body": Style(
        maxLines: 2,
        textOverflow: TextOverflow.ellipsis,
        fontSize: FontSize(16.0),
        lineHeight: LineHeight(1.5),
        color: colorScheme.onSurface,
      ),
      "p": Style(margin: Margins.only(bottom: 10)),
      "strong": Style(fontWeight: FontWeight.bold),
      "em": Style(fontStyle: FontStyle.italic),
      "u": Style(textDecoration: TextDecoration.underline),
      "h1": Style(
        fontSize: FontSize.xxLarge,
        fontWeight: FontWeight.bold,
        margin: Margins.symmetric(vertical: 10),
      ),
      "h2": Style(
        fontSize: FontSize.xLarge,
        fontWeight: FontWeight.w600,
        margin: Margins.symmetric(vertical: 8),
      ),
      "h3": Style(
        fontSize: FontSize.large,
        fontWeight: FontWeight.w500,
        margin: Margins.symmetric(vertical: 6),
      ),
      "blockquote": Style(
        fontStyle: FontStyle.italic,
        padding: HtmlPaddings.symmetric(horizontal: 15, vertical: 8),
        margin: Margins.symmetric(vertical: 10),
        backgroundColor: colorScheme.surfaceVariant,
        border: Border(left: BorderSide(color: colorScheme.outline, width: 4)),
      ),
      "ul": Style(margin: Margins.only(left: 20, bottom: 10)),
      "ol": Style(margin: Margins.only(left: 20, bottom: 10)),
      "li": Style(padding: HtmlPaddings.symmetric(vertical: 2)),
      "a": Style(
        color: colorScheme.primary,
        textDecoration: TextDecoration.underline,
      ),
      "table": Style(
          border: Border.all(color: colorScheme.outline.withOpacity(0.5))),
      "th": Style(
        padding: HtmlPaddings.all(6),
        backgroundColor: colorScheme.surfaceVariant,
        fontWeight: FontWeight.bold,
      ),
      "td": Style(
        padding: HtmlPaddings.all(6),
        border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
      ),
    };
  }
}
