class OcopType {
  final String id;
  final String ocopTypeName;

  OcopType({required this.id, required this.ocopTypeName});
  
  factory OcopType.fromJson(Map<String, dynamic> json) {
    return OcopType(id: json['id'], ocopTypeName: json['ocopTypeName']);
  }
}