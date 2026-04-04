import 'user_model.dart';

class Course {
  final String id;
  final String title;
  final String? description;
  final String? slug;
  final CourseImage? image;
  final List<String> subject;
  final List<String> specialization;
  final EducatorInfo? educator;
  final String? courseType;
  final double? fees;
  final double? discount;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? maxStudents;
  final int? enrolledCount;
  final String? status;
  final bool? isActive;
  final DateTime? createdAt;
  final List<CourseClass>? classes;
  final String? introVideo;
  final String? introVideoVimeoUri;
  final double? rating;
  final int? ratingCount;
  final List<CourseReview> reviews;
  final List<String> enrolledStudentIds;

  Course({
    required this.id,
    required this.title,
    this.description,
    this.slug,
    this.image,
    this.subject = const [],
    this.specialization = const [],
    this.educator,
    this.courseType,
    this.fees,
    this.discount,
    this.startDate,
    this.endDate,
    this.maxStudents,
    this.enrolledCount,
    this.status,
    this.isActive,
    this.createdAt,
    this.classes,
    this.introVideo,
    this.introVideoVimeoUri,
    this.rating,
    this.ratingCount,
    this.reviews = const [],
    this.enrolledStudentIds = const [],
  });

  String get imageUrl => image?.url ?? '';

  double get finalPrice {
    if (fees == null) return 0;
    if (discount == null || discount == 0) return fees!;
    return fees! * (1 - discount! / 100);
  }

  bool get hasDiscount => discount != null && discount! > 0;

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      slug: json['slug'],
      image: _parseImage(json),
      subject: _parseStringList(json['subject']),
      specialization: _parseStringList(json['specialization']),
      educator: _parseEducator(json),
      courseType: json['courseType'],
      fees: (json['fees'] as num?)?.toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'])
          : null,
      endDate:
          json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      maxStudents: json['maxStudents'] ?? json['seatLimit'],
      enrolledCount: _parseEnrolledCount(
        json['enrolledCount'] ?? json['enrolledStudents'],
      ),
      status: json['status'],
      isActive: json['isActive'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      introVideo: json['introVideo'] ?? json['introVideoLink'],
      introVideoVimeoUri: json['introVideoVimeoUri'],
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['ratingCount'] as int?,
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => CourseReview.fromJson(e))
              .toList() ??
          [],
      enrolledStudentIds: _parseIdList(json['enrolledStudents']),
      classes: (json['classes'] as List<dynamic>?)
          ?.map((e) => CourseClass.fromJson(e))
          .toList(),
    );
  }

  static int? _parseEnrolledCount(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is List) return value.length;
    return null;
  }

  static CourseImage? _parseImage(Map<String, dynamic> json) {
    if (json['image'] != null) {
      return CourseImage.fromJson(json['image']);
    }
    if (json['courseThumbnail'] != null) {
      return CourseImage.fromJson(json['courseThumbnail']);
    }
    return null;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is String) return [value];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static List<String> _parseIdList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((entry) {
            if (entry is String) return entry;
            if (entry is Map && entry['_id'] != null) {
              return entry['_id'].toString();
            }
            return '';
          })
          .where((entry) => entry.isNotEmpty)
          .toList();
    }
    return [];
  }

  static EducatorInfo? _parseEducator(Map<String, dynamic> json) {
    final educatorData = json['educatorID'] ??
        json['educatorId'] ??
        json['educator'] ??
        json['educatorDetails'];

    if (educatorData == null) return null;
    if (educatorData is String) {
      return EducatorInfo(id: educatorData);
    }
    if (educatorData is Map<String, dynamic>) {
      return EducatorInfo.fromJson(educatorData);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'slug': slug,
      'image': image?.toJson(),
      'subject': subject,
      'specialization': specialization,
      'educator': educator?.toJson(),
      'courseType': courseType,
      'fees': fees,
      'discount': discount,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'maxStudents': maxStudents,
      'enrolledCount': enrolledCount,
      'status': status,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'introVideo': introVideo,
      'introVideoVimeoUri': introVideoVimeoUri,
      'rating': rating,
      'ratingCount': ratingCount,
      'reviews': reviews.map((review) => review.toJson()).toList(),
      'enrolledStudents': enrolledStudentIds,
    };
  }
}

class CourseReview {
  final String? studentId;
  final String? name;
  final String? avatar;
  final double? rating;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CourseReview({
    this.studentId,
    this.name,
    this.avatar,
    this.rating,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  factory CourseReview.fromJson(Map<String, dynamic> json) {
    return CourseReview(
      studentId: json['student']?.toString(),
      name: json['name'],
      avatar: json['avatar'],
      rating: (json['rating'] as num?)?.toDouble(),
      comment: json['comment'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student': studentId,
      'name': name,
      'avatar': avatar,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class CourseImage {
  final String? url;
  final String? publicId;

  CourseImage({this.url, this.publicId});

  factory CourseImage.fromJson(dynamic json) {
    if (json is String) {
      return CourseImage(url: json);
    }
    if (json is Map<String, dynamic>) {
      return CourseImage(
        url: json['url'],
        publicId: json['publicId'] ?? json['public_id'],
      );
    }
    return CourseImage();
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'publicId': publicId,
    };
  }
}

class EducatorInfo {
  final String? id;
  final String? name;
  final String? profilePicture;

  EducatorInfo({this.id, this.name, this.profilePicture});

  factory EducatorInfo.fromJson(Map<String, dynamic> json) {
    return EducatorInfo(
      id: json['_id'] ?? json['id'],
      name: json['fullName'] ??
          json['name'] ??
          [json['firstName'], json['lastName']]
              .where((s) => s != null)
              .join(' '),
      profilePicture: json['profilePicture'] is String
          ? json['profilePicture']
          : json['profilePicture']?['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'profilePicture': profilePicture,
    };
  }
}

class CourseClass {
  final String? id;
  final String? title;
  final String? description;
  final DateTime? scheduledAt;
  final int? duration;
  final String? status;

  CourseClass({
    this.id,
    this.title,
    this.description,
    this.scheduledAt,
    this.duration,
    this.status,
  });

  factory CourseClass.fromJson(Map<String, dynamic> json) {
    return CourseClass(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      description: json['description'],
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'])
          : null,
      duration: json['duration'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'duration': duration,
      'status': status,
    };
  }
}
