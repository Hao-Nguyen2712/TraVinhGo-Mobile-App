import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Models/selling_link/selling_link.dart';
import '../../utils/constants.dart';

class SellingLinkList extends StatelessWidget {
  final List<SellingLink> sellingLinks;
  final int maxVisibleLinks;

  const SellingLinkList({
    super.key,
    required this.sellingLinks,
    this.maxVisibleLinks = 2,
  });

  void _launchLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $url");
    }
  }

  void _showAllLinks(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kbackgroundColor,
        title: const Text("Selling Links"),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sellingLinks.map((link) {
              return InkWell(
                onTap: () => _launchLink(link.link),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    link.title,
                    style: const TextStyle(
                      color: kprimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleLinks = sellingLinks.length > maxVisibleLinks
        ? sellingLinks.sublist(0, maxVisibleLinks)
        : sellingLinks;

    return Wrap(
      spacing: 1,
      runSpacing: 4,
      children: [
        ...visibleLinks.map((link) => InkWell(
          onTap: () => _launchLink(link.link),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              link.title,
              style: const TextStyle(
                color: kprimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )),
        if (sellingLinks.length > maxVisibleLinks)
          InkWell(
            onTap: () => _showAllLinks(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 1, vertical: 4),
              child: Text(
                '...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

