class InteractionRequest {
  final String itemId;
  final String itemType;
  int totalCount;

  InteractionRequest(
      {required this.itemId, required this.itemType, this.totalCount =1});
  
  Map<String, dynamic> toJson() {
    return {
      "itemId": itemId,
      "itemType": itemType,
      "totalCount": totalCount
    };
  }

  factory InteractionRequest.fromJson(Map<String, dynamic> json) {
    return InteractionRequest(
      itemId: json['itemId'] as String,
      itemType: json['itemType'] as String,
      totalCount: json['totalCount'] != null
          ? (json['totalCount'] as int)
          : 1,
    );
  }
}
