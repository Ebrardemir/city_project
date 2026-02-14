class CommentModel {
  final String id;
  final String reportId;
  final String userId;
  final String userFullName;
  final String message;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.reportId,
    required this.userId,
    required this.userFullName,
    required this.message,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      reportId: json['reportId'] ?? '',
      userId: json['userId'] ?? '',
      userFullName: json['userFullName'] ?? 'Anonim',
      message: json['message'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is String
              ? DateTime.parse(json['createdAt'])
              : (json['createdAt'] as dynamic).toDate())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportId': reportId,
      'userId': userId,
      'userFullName': userFullName,
      'message': message,
      'createdAt': createdAt,
    };
  }
}
