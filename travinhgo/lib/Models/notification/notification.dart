class UserNotification {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  UserNotification({required this.id, required this.title, required this.content, required this.createdAt});
  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}