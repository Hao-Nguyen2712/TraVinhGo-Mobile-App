import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../Models/notification/notification.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';
import '../../widget/notification_widget/notification_item.dart';

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

      // Sau khi thêm rồi thì xóa khỏi provider (nếu bạn không muốn lưu lặp)
      // NotificationProvider.of(context, listen: false).resetNotification();
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: Colors.white,
              title: Text('Notification(${notificationProvider.userNotification.length.toString()})'),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  // context.pop();
                  final router = GoRouter.of(context);
                  if (router.canPop()) {
                    router.pop();
                  } else {
                    router.go('/home'); // hoặc router.goNamed('Home') nếu bạn dùng tên route
                  }
                },
              ),
            ),
            _isLoading
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: CircularProgressIndicator(),
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
                          final isNew = index < notificationProvider.userNotification.length;
                          final listNew = notificationProvider.userNotification;
                          
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
