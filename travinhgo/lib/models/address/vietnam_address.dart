class Province {
  final String name;
  final List<District> districts;

  Province({
    required this.name,
    required this.districts,
  });

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      name: json['name'] as String,
      districts: (json['districts'] as List<dynamic>)
          .map((district) => District.fromJson(district))
          .toList(),
    );
  }
}

class District {
  final String name;
  final List<Ward> wards;

  District({
    required this.name,
    required this.wards,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      name: json['name'] as String,
      wards: (json['wards'] as List<dynamic>)
          .map((ward) => Ward.fromJson(ward))
          .toList(),
    );
  }
}

class Ward {
  final String name;

  Ward({
    required this.name,
  });

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      name: json['name'] as String,
    );
  }
}
