import 'dart:convert';
import 'package:dio/dio.dart';
import '../Models/Maps/top_favorite_destination.dart';
import '../utils/env_config.dart';

class MapService {
  // Base URL for API calls from environment config
  final Dio _dio = Dio();

  // Method to fetch top favorite destinations
  Future<List<TopFavoriteDestination>> getTopFavoriteDestinations() async {
    try {
      final response = await _dio.get(
        '${EnvConfig.apiBaseUrl}/TouristDestination/top-favorite-destination',
      );

      // Check if the response is successful and has data
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => _parseDestination(json)).toList();
      } else {
        // If the API call was successful but returned an error status
        print('API Error: ${response.data['message']}');
        throw Exception(
            'Failed to load destinations: ${response.data['message']}');
      }
    } catch (e) {
      // In case of error, return mock data for development
      print('Error fetching destinations: $e');
      return _getMockDestinations();
    }
  }

  // Parse destination from JSON
  TopFavoriteDestination _parseDestination(Map<String, dynamic> json) {
    // Parse HTML content if needed
    String description = json['description'] ?? '';
    // Basic HTML tag removal (for <p> tags in the example)
    description = description.replaceAll(RegExp(r'<\/?p>'), '');
    // Handle HTML entities like &nbsp;
    description = description.replaceAll('&nbsp;', ' ');

    // Extract coordinates, assuming API provides [longitude, latitude]
    final coordinates = json['location']?['coordinates'] as List?;
    final latitude = (coordinates != null && coordinates.length > 1)
        ? (coordinates[1] as num?)?.toDouble()
        : null;
    final longitude = (coordinates != null && coordinates.isNotEmpty)
        ? (coordinates[0] as num?)?.toDouble()
        : null;

    return TopFavoriteDestination(
      json['id'],
      json['name'],
      json['image'],
      json['averageRating']?.toDouble(),
      description,
      latitude,
      longitude,
    );
  }

  // Temporary method to generate mock data for development
  List<TopFavoriteDestination> _getMockDestinations() {
    final coordinates = getDestinationCoordinates();
    return [
      TopFavoriteDestination(
          '684822310d26e9eb99410533',
          'Ngoc Hien Conservation Area',
          'https://res.cloudinary.com/ddaj2hsk5/image/upload/v1749557809672/w3sq3xjj1kh0kqrc6x61lua.jpg',
          3.9,
          'A place to preserve the unique Khmer cultural traditions of Tra Vinh land, attracting domestic and foreign tourists water',
          coordinates['684822310d26e9eb99410533']![0],
          coordinates['684822310d26e9eb99410533']![1]),
      TopFavoriteDestination(
          '2',
          'Ba Om Pond',
          'assets/images/sample/destination1.jpg',
          4.5,
          'A scenic pond surrounded by ancient trees and Khmer architecture.',
          coordinates['2']![0],
          coordinates['2']![1]),
      TopFavoriteDestination(
          '3',
          'Duyen Hai Beach',
          'assets/images/sample/destination1.jpg',
          4.3,
          'A peaceful beach area with fishing villages and seafood restaurants.',
          coordinates['3']![0],
          coordinates['3']![1]),
      TopFavoriteDestination(
          '4',
          'Con Chim Eco-Tourism Area',
          'assets/images/sample/destination1.jpg',
          4.4,
          'Mangrove forests and waterways offering a glimpse of local ecosystems.',
          coordinates['4']![0],
          coordinates['4']![1]),
      TopFavoriteDestination(
          '5',
          'Tra Vinh Museum',
          'assets/images/sample/destination1.jpg',
          4.2,
          'Showcasing the rich history and culture of Tra Vinh province.',
          coordinates['5']![0],
          coordinates['5']![1]),
      TopFavoriteDestination(
          '6',
          'Ao Ba Om',
          'assets/images/sample/destination1.jpg',
          4.6,
          'A legendary pond with ancient trees and cultural significance.',
          coordinates['6']![0],
          coordinates['6']![1]),
      TopFavoriteDestination(
          '7',
          'Khmer Cultural Museum',
          'assets/images/sample/destination1.jpg',
          4.5,
          'Preserving and displaying the unique Khmer culture of the region.',
          coordinates['7']![0],
          coordinates['7']![1]),
      TopFavoriteDestination(
          '8',
          'Long Binh Islet',
          'assets/images/sample/destination1.jpg',
          4.3,
          'An island in the Mekong Delta known for fruit orchards and homestays.',
          coordinates['8']![0],
          coordinates['8']![1]),
      TopFavoriteDestination(
          '9',
          'Chùa Hang Pagoda',
          'assets/images/sample/destination1.jpg',
          4.4,
          'A historic Buddhist temple with unique cave structures.',
          coordinates['9']![0],
          coordinates['9']![1]),
      TopFavoriteDestination(
          '10',
          'Tra Vinh Central Market',
          'assets/images/sample/destination1.jpg',
          4.1,
          'A bustling market offering local goods, food, and cultural experiences.',
          coordinates['10']![0],
          coordinates['10']![1]),
    ];
  }

  // Get destination coordinates (in a real app, these would come from the API)
  Map<String, List<double>> getDestinationCoordinates() {
    return {
      '684822310d26e9eb99410533': [
        9.9465,
        106.3345
      ], // Ngoc Hien Conservation Area
      '2': [9.9347, 106.3331], // Ba Om Pond
      '3': [9.6809, 106.5012], // Duyen Hai Beach
      '4': [9.7506, 106.4220], // Con Chim
      '5': [9.9340, 106.3456], // Tra Vinh Museum
      '6': [9.9350, 106.3330], // Ao Ba Om
      '7': [9.9360, 106.3440], // Khmer Cultural Museum
      '8': [9.8912, 106.2733], // Long Binh Islet
      '9': [9.9281, 106.3425], // Chùa Hang
      '10': [9.9349, 106.3452], // Central Market
    };
  }
}
