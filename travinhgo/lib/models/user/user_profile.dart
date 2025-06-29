class UserProfileResponse {
  final String fullname;
  final String address;
  final String avatar;
  final String email;
  final String gender;
  final String phone;
  final String hassedPassword;
  final String? dateOfBirth;

  UserProfileResponse({
    required this.fullname,
    required this.address,
    required this.avatar,
    required this.email,
    required this.gender,
    required this.phone,
    required this.hassedPassword,
    this.dateOfBirth,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    // Check both uppercase and lowercase field names
    return UserProfileResponse(
      fullname: json['Fullname'] ?? json['fullname'] ?? '',
      address: json['Address'] ?? json['address'] ?? '',
      avatar: json['Avatar'] ?? json['avatar'] ?? '',
      email: json['Email'] ?? json['email'] ?? '',
      gender: json['Gender'] ?? json['gender'] ?? '',
      phone: json['Phone'] ?? json['phone'] ?? '',
      hassedPassword: json['HassedPassword'] ?? json['hassedPassword'] ?? '',
      dateOfBirth:
          json['DateOfBirth']?.toString() ?? json['dateOfBirth']?.toString(),
    );
  }

  // Debug method to print all fields
  void debugPrint() {
    print('UserProfileResponse: {');
    print('  fullname: "$fullname"');
    print('  address: "$address"');
    print('  avatar: "$avatar"');
    print('  email: "$email"');
    print('  gender: "$gender"');
    print('  phone: "$phone"');
    print('  hassedPassword: "$hassedPassword"');
    print('  dateOfBirth: "$dateOfBirth"');
    print('}');
  }
}
