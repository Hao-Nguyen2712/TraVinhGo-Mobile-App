import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../Models/notification/notification.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';
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
                              crossAxisCount: 1, childAspectRatio: 2.6),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final isNew = index <
                              notificationProvider.userNotification.length;

                          return NotificationItem(
                            userNotification: _userNotification[index],
                            isNew: isNew,
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
}
