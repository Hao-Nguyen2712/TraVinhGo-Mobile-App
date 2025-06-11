class Tag {
  final String id;
  final String name;
  final String image;

  Tag({required this.id, required this.name, required this.image});
  
  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(id: json['id'], name: json['name'], image: json['image']);
  }
}
