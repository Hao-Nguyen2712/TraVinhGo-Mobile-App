class Marker {
  final String id;
  final String name;
  final String image;

  Marker({required this.id, required this.name, required this.image});

  factory Marker.fromJson(Map<String, dynamic> json) {
    return Marker(id: json['id'], name: json['name'], image: json['image']);
  }
}
