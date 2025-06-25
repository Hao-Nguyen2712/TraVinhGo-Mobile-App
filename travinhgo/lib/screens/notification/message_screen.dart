import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    fetchNotificationMessage();

    // Lắng nghe thay đổi từ NotificationProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationProvider.of(context, listen: false).addListener(_onNotificationChanged);
    });
  }

  void _onNotificationChanged() {
    final newNotifications = NotificationProvider.of(context, listen: false).userNotification;

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
    NotificationProvider.of(context, listen: false).removeListener(_onNotificationChanged);
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
                  Navigator.of(context).pop();
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
