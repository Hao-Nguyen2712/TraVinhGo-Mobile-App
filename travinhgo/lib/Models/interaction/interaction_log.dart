class InteractionLogRequest {
  final String itemId;
  final String itemType;
  final int duration;

  InteractionLogRequest(
      {required this.itemId, required this.itemType, required this.duration});

  Map<String, dynamic> toJson() {
    return {
      "itemId": itemId,
      "itemType": itemType,
      "duration": duration
    };
  }

  factory InteractionLogRequest.fromJson(Map<String, dynamic> json) {
    return InteractionLogRequest(
      itemId: json['itemId'] as String,
      itemType: json['itemType'] as String,
      duration: json['duration'] as int,
    );
  }
}
