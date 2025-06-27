class UserProfileResponse {
  final String fullname;
  final String address;
  final String avatar;
  final String email;
  final String gender;
  final String phone;
  final String hassedPassword;

  UserProfileResponse({
    required this.fullname,
    required this.address,
    required this.avatar,
    required this.email,
    required this.gender,
    required this.phone,
    required this.hassedPassword,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      fullname: json['Fullname'] ?? '',
      address: json['Address'] ?? '',
      avatar: json['Avatar'] ?? '',
      email: json['Email'] ?? '',
      gender: json['Gender'] ?? '',
      phone: json['Phone'] ?? '',
      hassedPassword: json['HassedPassword'] ?? '',
    );
  }
}
