class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? createdAt;
  final NotificationSender? sender;
  final NotificationMetadata? metadata;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.createdAt,
    this.sender,
    this.metadata,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final senderData = json['sender'];
    final metadataData = json['metadata'];

    return AppNotification(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      isRead: json['isRead'] == true,
      createdAt: _parseDate(json['createdAt']),
      sender: senderData is Map<String, dynamic>
          ? NotificationSender.fromJson(senderData)
          : null,
      metadata: metadataData is Map<String, dynamic>
          ? NotificationMetadata.fromJson(metadataData)
          : null,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class NotificationSender {
  final String? name;
  final String? avatar;

  const NotificationSender({this.name, this.avatar});

  factory NotificationSender.fromJson(Map<String, dynamic> json) {
    return NotificationSender(
      name: json['fullName']?.toString() ??
          json['name']?.toString() ??
          json['username']?.toString(),
      avatar: json['profilePicture']?.toString() ??
          json['image']?.toString() ??
          json['avatar']?.toString(),
    );
  }
}

class NotificationMetadata {
  final String? resourceRoute;
  final String? link;
  final String? thumbnail;
  final String? summary;
  final String? contentTitle;
  final String? resourceId;
  final String? resourceType;

  const NotificationMetadata({
    this.resourceRoute,
    this.link,
    this.thumbnail,
    this.summary,
    this.contentTitle,
    this.resourceId,
    this.resourceType,
  });

  factory NotificationMetadata.fromJson(Map<String, dynamic> json) {
    return NotificationMetadata(
      resourceRoute: json['resourceRoute']?.toString(),
      link: json['link']?.toString(),
      thumbnail: json['thumbnail']?.toString(),
      summary: json['summary']?.toString(),
      contentTitle: json['contentTitle']?.toString(),
      resourceId: json['resourceId']?.toString(),
      resourceType: json['resourceType']?.toString(),
    );
  }
}
