// DescriptionFm vẫn là StatelessWidget
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class DescriptionFm extends StatelessWidget {
  final String? description;
  final bool isExpanded;
  final VoidCallback onToggle;

  const DescriptionFm({
    super.key,
    required this.description,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final String content =
        description ?? 'There is no description in this item.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: SizedBox(
            height: 80,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Html(data: content, style: _htmlStyle(context)),
            ),
          ),
          secondChild: Html(data: content, style: _htmlStyle(context)),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: onToggle,
            style: TextButton.styleFrom(
              side: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            ),
            child: Text(
              isExpanded ? 'Less' : 'More',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        )
      ],
    );
  }

  Map<String, Style> _htmlStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return {
      "body": Style(
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
