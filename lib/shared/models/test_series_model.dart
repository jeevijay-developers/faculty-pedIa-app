class TestSeries {
  final String id;
  final String title;
  final String? description;
  final String? slug;
  final TestSeriesImage? image;
  final List<String> subject;
  final List<String> specialization;
  final String? educatorId;
  final String? educatorName;
  final double? fees;
  final double? discount;
  final int? totalTests;
  final int? enrolledCount;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;
  final bool? isActive;
  final DateTime? createdAt;
  final List<Test>? tests;
  
  TestSeries({
    required this.id,
    required this.title,
    this.description,
    this.slug,
    this.image,
    this.subject = const [],
    this.specialization = const [],
    this.educatorId,
    this.educatorName,
    this.fees,
    this.discount,
    this.totalTests,
    this.enrolledCount,
    this.startDate,
    this.endDate,
    this.status,
    this.isActive,
    this.createdAt,
    this.tests,
  });
  
  String get imageUrl => image?.url ?? '';
  
  factory TestSeries.fromJson(Map<String, dynamic> json) {
    return TestSeries(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      slug: json['slug'],
      image: json['image'] != null ? TestSeriesImage.fromJson(json['image']) : null,
      subject: _parseStringList(json['subject']),
      specialization: _parseStringList(json['specialization']),
      educatorId: _parseEducatorId(json),
      educatorName: _parseEducatorName(json),
      fees: (json['fees'] as num?)?.toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
      totalTests: json['totalTests'] ?? json['testCount'],
      enrolledCount: json['enrolledCount'] ?? json['enrolledStudents'],
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      status: json['status'],
      isActive: json['isActive'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      tests: (json['tests'] as List<dynamic>?)
          ?.map((e) => Test.fromJson(e))
          .toList(),
    );
  }
  
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is String) return [value];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
  
  static String? _parseEducatorId(Map<String, dynamic> json) {
    final educator = json['educatorId'] ?? json['educatorID'] ?? json['educator'];
    if (educator is String) return educator;
    if (educator is Map) return educator['_id']?.toString();
    return null;
  }
  
  static String? _parseEducatorName(Map<String, dynamic> json) {
    final educator = json['educatorId'] ?? json['educatorID'] ?? json['educator'];
    if (educator is Map) {
      return educator['name'] ?? educator['fullName'];
    }
    return json['educatorName'];
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
      'educatorId': educatorId,
      'educatorName': educatorName,
      'fees': fees,
      'discount': discount,
      'totalTests': totalTests,
      'enrolledCount': enrolledCount,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class TestSeriesImage {
  final String? url;
  final String? publicId;
  
  TestSeriesImage({this.url, this.publicId});
  
  factory TestSeriesImage.fromJson(dynamic json) {
    if (json is String) {
      return TestSeriesImage(url: json);
    }
    if (json is Map<String, dynamic>) {
      return TestSeriesImage(
        url: json['url'],
        publicId: json['publicId'] ?? json['public_id'],
      );
    }
    return TestSeriesImage();
  }
  
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'publicId': publicId,
    };
  }
}

class Test {
  final String id;
  final String? title;
  final String? description;
  final int? duration; // in minutes
  final int? totalQuestions;
  final int? totalMarks;
  final int? passingMarks;
  final int? negativeMarking;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? status;
  final bool? isActive;
  final List<Question>? questions;
  
  Test({
    required this.id,
    this.title,
    this.description,
    this.duration,
    this.totalQuestions,
    this.totalMarks,
    this.passingMarks,
    this.negativeMarking,
    this.startTime,
    this.endTime,
    this.status,
    this.isActive,
    this.questions,
  });
  
  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'],
      description: json['description'],
      duration: json['duration'],
      totalQuestions: json['totalQuestions'] ?? json['questionCount'],
      totalMarks: json['totalMarks'],
      passingMarks: json['passingMarks'],
      negativeMarking: json['negativeMarking'],
      startTime: json['startTime'] != null ? DateTime.tryParse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime']) : null,
      status: json['status'],
      isActive: json['isActive'],
      questions: (json['questions'] as List<dynamic>?)
          ?.map((e) => Question.fromJson(e))
          .toList(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'duration': duration,
      'totalQuestions': totalQuestions,
      'totalMarks': totalMarks,
      'passingMarks': passingMarks,
      'negativeMarking': negativeMarking,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status,
      'isActive': isActive,
    };
  }
}

class Question {
  final String id;
  final String? text;
  final String? imageUrl;
  final List<Option> options;
  final int? correctOption;
  final String? explanation;
  final int? marks;
  final int? negativeMarks;
  final String? subject;
  final String? topic;
  
  Question({
    required this.id,
    this.text,
    this.imageUrl,
    this.options = const [],
    this.correctOption,
    this.explanation,
    this.marks,
    this.negativeMarks,
    this.subject,
    this.topic,
  });
  
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id'] ?? json['id'] ?? '',
      text: json['text'] ?? json['question'],
      imageUrl: json['imageUrl'] ?? json['image'],
      options: (json['options'] as List<dynamic>?)
          ?.asMap()
          .entries
          .map((e) => Option.fromJson(e.value, e.key))
          .toList() ?? [],
      correctOption: json['correctOption'] ?? json['correctAnswer'],
      explanation: json['explanation'],
      marks: json['marks'],
      negativeMarks: json['negativeMarks'],
      subject: json['subject'],
      topic: json['topic'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'text': text,
      'imageUrl': imageUrl,
      'options': options.map((o) => o.toJson()).toList(),
      'correctOption': correctOption,
      'explanation': explanation,
      'marks': marks,
      'negativeMarks': negativeMarks,
      'subject': subject,
      'topic': topic,
    };
  }
}

class Option {
  final int index;
  final String? text;
  final String? imageUrl;
  
  Option({required this.index, this.text, this.imageUrl});
  
  factory Option.fromJson(dynamic json, int index) {
    if (json is String) {
      return Option(index: index, text: json);
    }
    if (json is Map<String, dynamic>) {
      return Option(
        index: json['index'] ?? index,
        text: json['text'],
        imageUrl: json['imageUrl'] ?? json['image'],
      );
    }
    return Option(index: index);
  }
  
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'text': text,
      'imageUrl': imageUrl,
    };
  }
}
