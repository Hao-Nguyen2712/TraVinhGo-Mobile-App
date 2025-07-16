class SellingLink {
  final String id;
  final String productId;
  final String title;
  final String link;

  SellingLink({
    required this.id,
    required this.productId,
    required this.title,
    required this.link,
  });

  factory SellingLink.fromJson(Map<String, dynamic> json) {
    return SellingLink(
      id: json['id'],
      productId: json['productId'],
      title: json['title'],
      link: json['link'],
    );
  }
}