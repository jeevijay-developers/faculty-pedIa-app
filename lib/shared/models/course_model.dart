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
  
  Course({
    required this.id,
    required this.title,
    this.description,
    this.slug,
    this.image,
    this.subject = const [],
    this.specialization = const [],
    this.educator,
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
      fees: (json['fees'] as num?)?.toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      maxStudents: json['maxStudents'] ?? json['seatLimit'],
      enrolledCount: json['enrolledCount'] ?? json['enrolledStudents'],
      status: json['status'],
      isActive: json['isActive'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      classes: (json['classes'] as List<dynamic>?)
          ?.map((e) => CourseClass.fromJson(e))
          .toList(),
    );
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
      'fees': fees,
      'discount': discount,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'maxStudents': maxStudents,
      'enrolledCount': enrolledCount,
      'status': status,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
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
      name: json['fullName'] ?? json['name'] ?? 
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
