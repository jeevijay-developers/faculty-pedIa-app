import 'user_model.dart';

class Educator extends User {
  final List<String> subject;
  final List<String> specialization;
  final List<Qualification> qualifications;
  final List<WorkExperience> workExperience;
  final int? yearsOfExperience;
  final Rating? rating;
  final int followerCount;
  final List<String> followerIds;
  final String? status;
  final String? introVideoLink;
  final String? introVideoVimeoUri;
  final double? payPerHourFee;

  Educator({
    required super.id,
    super.name,
    super.firstName,
    super.lastName,
    required super.email,
    super.mobileNumber,
    super.username,
    super.image,
    super.bio,
    super.joinedAt,
    super.createdAt,
    this.subject = const [],
    this.specialization = const [],
    this.qualifications = const [],
    this.workExperience = const [],
    this.yearsOfExperience,
    this.rating,
    this.followerCount = 0,
    this.followerIds = const [],
    this.status,
    this.introVideoLink,
    this.introVideoVimeoUri,
    this.payPerHourFee,
  }) : super(role: 'educator');

  String get displaySubjects {
    if (subject.isEmpty) return 'Not specified';
    return subject.map((s) => _formatSubject(s)).join(', ');
  }

  String _formatSubject(String value) {
    return value
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : word)
        .join(' ');
  }

  String get displayExperience {
    if (yearsOfExperience != null) {
      return '$yearsOfExperience+ years';
    }
    return 'Not specified';
  }

  String? get displayQualification {
    if (qualifications.isNotEmpty) {
      return qualifications.first.title ?? qualifications.first.degree;
    }
    return null;
  }

  factory Educator.fromJson(Map<String, dynamic> json) {
    return Educator(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['fullName'] ?? json['name'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'] ?? '',
      mobileNumber: json['mobileNumber'] ?? json['mobile'],
      username: json['username'],
      image: _parseImage(json),
      bio: json['bio'] ?? json['description'],
      joinedAt:
          json['joinedAt'] != null ? DateTime.tryParse(json['joinedAt']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      subject: _parseStringList(json['subject']),
      specialization: _parseStringList(json['specialization']),
      qualifications: _parseQualifications(json),
      workExperience: (json['workExperience'] as List<dynamic>?)
              ?.map((e) => WorkExperience.fromJson(e))
              .toList() ??
          [],
      yearsOfExperience:
          json['yoe'] ?? json['yearsExperience'] ?? json['experience'],
      rating: json['rating'] != null ? Rating.fromJson(json['rating']) : null,
      followerCount: _parseFollowerCount(json),
      followerIds: _parseFollowerIds(json['followers']),
      status: json['status'],
      introVideoLink: json['introVideo'] ?? json['introVideoLink'],
      introVideoVimeoUri: json['introVideoVimeoUri'],
      payPerHourFee: (json['payPerHourFee'] as num?)?.toDouble(),
    );
  }

  static UserImage? _parseImage(Map<String, dynamic> json) {
    if (json['profileImage'] != null) {
      return UserImage.fromJson(json['profileImage']);
    }
    if (json['profilePicture'] != null) {
      return UserImage.fromJson({'url': json['profilePicture']});
    }
    if (json['imageUrl'] != null) {
      return UserImage.fromJson(json['imageUrl']);
    }
    if (json['profileImageUrl'] != null) {
      return UserImage.fromJson(json['profileImageUrl']);
    }
    if (json['avatar'] != null) {
      return UserImage.fromJson(json['avatar']);
    }
    if (json['image'] != null) {
      return UserImage.fromJson(json['image']);
    }
    return null;
  }

  static List<Qualification> _parseQualifications(Map<String, dynamic> json) {
    final raw = (json['qualification'] as List<dynamic>?) ??
        (json['qualifications'] as List<dynamic>?) ??
        [];
    return raw
        .map(
          (e) => Qualification.fromJson(e is String ? {'title': e} : e),
        )
        .toList();
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is String) return [value];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static int _parseFollowerCount(Map<String, dynamic> json) {
    if (json['followerCount'] is int) return json['followerCount'];
    if (json['followers'] is List) return (json['followers'] as List).length;
    return 0;
  }

  static List<String> _parseFollowerIds(dynamic value) {
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

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'subject': subject,
      'specialization': specialization,
      'qualification': qualifications.map((q) => q.toJson()).toList(),
      'workExperience': workExperience.map((w) => w.toJson()).toList(),
      'yoe': yearsOfExperience,
      'rating': rating?.toJson(),
      'followerCount': followerCount,
      'followers': followerIds,
      'status': status,
      'introVideoLink': introVideoLink,
      'introVideoVimeoUri': introVideoVimeoUri,
      'payPerHourFee': payPerHourFee,
    };
  }
}

class Qualification {
  final String? title;
  final String? degree;
  final String? institution;
  final String? year;

  Qualification({this.title, this.degree, this.institution, this.year});

  factory Qualification.fromJson(Map<String, dynamic> json) {
    return Qualification(
      title: json['title'],
      degree: json['degree'],
      institution: json['institute'] ?? json['institution'],
      year: _formatDateRange(json['startDate'], json['endDate']) ??
          json['year']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'degree': degree,
      'institution': institution,
      'year': year,
    };
  }
}

class WorkExperience {
  final String? title;
  final String? company;
  final String? duration;
  final String? description;

  WorkExperience({this.title, this.company, this.duration, this.description});

  factory WorkExperience.fromJson(Map<String, dynamic> json) {
    return WorkExperience(
      title: json['title'],
      company: json['company'],
      duration: _formatDateRange(json['startDate'], json['endDate']) ??
          json['duration'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'company': company,
      'duration': duration,
      'description': description,
    };
  }
}

String? _formatDateRange(dynamic startDate, dynamic endDate) {
  final start = _parseDate(startDate);
  final end = _parseDate(endDate);
  if (start == null && end == null) return null;
  final startLabel = start != null ? '${start.month}/${start.year}' : 'Present';
  final endLabel = end != null ? '${end.month}/${end.year}' : 'Present';
  return '$startLabel - $endLabel';
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

class Rating {
  final double? average;
  final int? count;

  Rating({this.average, this.count});

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      average: (json['average'] as num?)?.toDouble(),
      count: json['count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average': average,
      'count': count,
    };
  }
}
