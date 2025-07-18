import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import '../../Models/notification/notification.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/string_helper.dart';
import '../../widget/notification_widget/notification_item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  List<UserNotification> _userNotification = [];
  bool _isLoading = true;
  late NotificationProvider _notificationProvider;
  bool _isListenerAdded = false;

  @override
  void initState() {
    super.initState();
    fetchNotificationMessage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isListenerAdded) {
      _notificationProvider = NotificationProvider.of(context, listen: false);
      _notificationProvider.addListener(_onNotificationChanged);
      _isListenerAdded = true;
    }
  }

  void _onNotificationChanged() {
    final newNotifications = _notificationProvider.userNotification;

    if (newNotifications.isNotEmpty) {
      setState(() {
        _userNotification.insertAll(0, newNotifications);
      });
    }
  }

  @override
  void dispose() {
    _notificationProvider.removeListener(_onNotificationChanged);
    super.dispose();
  }

  Future<void> fetchNotificationMessage() async {
    final data = await NotificationService().getNotifications();

    setState(() {
      _userNotification = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = NotificationProvider.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: colorScheme.surface,
              title: Text(
                AppLocalizations.of(context)!.notificationTitle(
                    notificationProvider.userNotification.length),
                style: TextStyle(
                  color: colorScheme.onSurface,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: colorScheme.onSurface,
                ),
                onPressed: () {
                  final router = GoRouter.of(context);
                  if (router.canPop()) {
                    router.pop();
                  } else {
                    router.go('/home');
                  }
                },
              ),
            ),
            _isLoading
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.all(2),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1, childAspectRatio: 2.8),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final isNew = index <
                              notificationProvider.userNotification.length;

                          // return NotificationItem(
                          //   userNotification: _userNotification[index],
                          //   isNew: isNew,
                          // );
                          return GestureDetector(
                            onTap: () {
                              final notification = _userNotification[index]; // Lấy thông báo hiện tại
                              _showNotificationDetailsDialog(notification);
                            },
                            child: NotificationItem(
                              userNotification: _userNotification[index], // Truyền notification đã lấy
                              isNew: isNew,
                            ),
                          );
                        },
                        childCount: _userNotification.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
  
  // Thêm hàm này vào trong class _MessageScreenState
  void _showNotificationDetailsDialog(UserNotification notification) {
    // Lấy theme hiện tại để style cho dialog
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            StringHelper.toTitleCase(notification.title),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          // Bọc nội dung trong SingleChildScrollView để có thể cuộn khi nội dung quá dài
          content: SingleChildScrollView(
            child: Html(
              data: StringHelper.capitalizeFirstHtmlTextContent(
                  notification.content ?? 'N/A'),
              // Bạn có thể tái sử dụng style từ NotificationItem hoặc tạo style mới ở đây
              // Style này không giới hạn dòng (maxLines)
              style: {
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
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Đóng',
                style: TextStyle(color: colorScheme.primary),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

}
