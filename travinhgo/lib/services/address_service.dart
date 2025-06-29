import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/address/vietnam_address.dart';

class AddressService {
  static final AddressService _instance = AddressService._internal();
  List<Province> _provinces = [];
  bool _isLoaded = false;

  factory AddressService() {
    return _instance;
  }

  AddressService._internal();

  Future<void> loadAddressData() async {
    if (_isLoaded) return;

    try {
      final String jsonString =
          await rootBundle.loadString('assets/geo/vietnam-provinces.json');
      final List<dynamic> jsonData = json.decode(jsonString);

      _provinces = jsonData.map((data) => Province.fromJson(data)).toList();
      _isLoaded = true;
    } catch (e) {
      print('Error loading address data: $e');
      _provinces = [];
    }
  }

  List<Province> get provinces => _provinces;

  List<String> getProvinceNames() {
    return _provinces.map((province) => province.name).toList();
  }

  List<String> getDistrictNames(String provinceName) {
    final province = _provinces.firstWhere(
      (p) => p.name == provinceName,
      orElse: () => Province(name: '', districts: []),
    );
    return province.districts.map((district) => district.name).toList();
  }

  List<String> getWardNames(String provinceName, String districtName) {
    final province = _provinces.firstWhere(
      (p) => p.name == provinceName,
      orElse: () => Province(name: '', districts: []),
    );

    final district = province.districts.firstWhere(
      (d) => d.name == districtName,
      orElse: () => District(name: '', wards: []),
    );

    return district.wards.map((ward) => ward.name).toList();
  }

  // Parse a full address string into its components
  Map<String, String> parseAddress(String fullAddress) {
    final parts = fullAddress.split(',').map((part) => part.trim()).toList();

    // Default values
    String streetAddress = '';
    String ward = '';
    String district = '';
    String province = '';

    // Try to match from the end (most specific to least specific)
    if (parts.length >= 4) {
      province = parts[parts.length - 1];
      district = parts[parts.length - 2];
      ward = parts[parts.length - 3];
      streetAddress = parts.sublist(0, parts.length - 3).join(', ');
    } else if (parts.length == 3) {
      province = parts[2];
      district = parts[1];
      ward = '';
      streetAddress = parts[0];
    } else if (parts.length == 2) {
      province = parts[1];
      district = '';
      ward = '';
      streetAddress = parts[0];
    } else if (parts.length == 1) {
      streetAddress = parts[0];
    }

    return {
      'streetAddress': streetAddress,
      'ward': ward,
      'district': district,
      'province': province,
    };
  }
}
