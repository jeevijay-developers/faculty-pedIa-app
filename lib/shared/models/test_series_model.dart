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
  final double? rating;
  final int? ratingCount;
  final DateTime? createdAt;
  final List<Test>? tests;
  final List<String> enrolledStudentIds;
  final List<TestSeriesReview> reviews;

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
    this.rating,
    this.ratingCount,
    this.createdAt,
    this.tests,
    this.enrolledStudentIds = const [],
    this.reviews = const [],
  });

  String get imageUrl => image?.url ?? '';

  factory TestSeries.fromJson(Map<String, dynamic> json) {
    return TestSeries(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      slug: json['slug'],
      image: json['image'] != null
          ? TestSeriesImage.fromJson(json['image'])
          : null,
      subject: _parseStringList(json['subject']),
      specialization: _parseStringList(json['specialization']),
      educatorId: _parseEducatorId(json),
      educatorName: _parseEducatorName(json),
      fees: (json['fees'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
      totalTests: _parseInt(json['totalTests']) ??
          _parseInt(json['testCount']) ??
          _parseInt(json['numberOfTests']),
      enrolledCount: _parseInt(json['enrolledCount']) ??
          (json['enrolledStudents'] is List
              ? (json['enrolledStudents'] as List).length
              : null),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      status: json['status'],
      isActive: json['isActive'],
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: (json['ratingCount'] as num?)?.toInt(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      tests: (json['tests'] is List)
          ? (json['tests'] as List).map((e) {
              if (e is Map<String, dynamic>) {
                return Test.fromJson(e);
              } else {
                return Test(id: e.toString());
              }
            }).toList()
          : null,
      enrolledStudentIds: _parseIdList(json['enrolledStudents']),
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => TestSeriesReview.fromJson(e))
              .toList() ??
          [],
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

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _parseEducatorId(Map<String, dynamic> json) {
    final educator =
        json['educatorId'] ?? json['educatorID'] ?? json['educator'];
    if (educator is String) return educator;
    if (educator is Map) return educator['_id']?.toString();
    return null;
  }

  static String? _parseEducatorName(Map<String, dynamic> json) {
    final educator =
        json['educatorId'] ?? json['educatorID'] ?? json['educator'];
    if (educator is Map) {
      return educator['name'] ?? educator['fullName'];
    }
    return json['educatorName'];
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
      'rating': rating,
      'ratingCount': ratingCount,
      'createdAt': createdAt?.toIso8601String(),
      'enrolledStudents': enrolledStudentIds,
      'reviews': reviews.map((review) => review.toJson()).toList(),
    };
  }
}

class TestSeriesReview {
  final String? studentId;
  final String? name;
  final String? avatar;
  final double? rating;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TestSeriesReview({
    this.studentId,
    this.name,
    this.avatar,
    this.rating,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  factory TestSeriesReview.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return TestSeriesReview();
    }
    return TestSeriesReview(
      studentId: json['student']?.toString(),
      name: json['name']?.toString(),
      avatar: json['avatar']?.toString(),
      rating: (json['rating'] as num?)?.toDouble(),
      comment: json['comment']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
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
  final DateTime? createdAt;
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
    this.createdAt,
    this.status,
    this.isActive,
    this.questions,
  });

  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'],
      description: json['description'],
      duration: TestSeries._parseInt(json['duration']),
      totalQuestions: TestSeries._parseInt(json['totalQuestions']) ??
          TestSeries._parseInt(json['questionCount']),
      totalMarks: TestSeries._parseInt(json['totalMarks']),
      passingMarks: TestSeries._parseInt(json['passingMarks']),
      negativeMarking: TestSeries._parseInt(json['negativeMarking']),
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'])
          : null,
      endTime:
          json['endTime'] != null ? DateTime.tryParse(json['endTime']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      status: json['status'],
      isActive: json['isActive'],
      questions: (json['questions'] is List)
          ? (json['questions'] as List).map((e) {
              if (e is Map<String, dynamic>) {
                return Question.fromJson(e);
              } else {
                return Question(id: e.toString());
              }
            }).toList()
          : null,
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
      'createdAt': createdAt?.toIso8601String(),
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
  final dynamic correctOption;
  final dynamic correctOptions;
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
    this.correctOptions,
    this.explanation,
    this.marks,
    this.negativeMarks,
    this.subject,
    this.topic,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final optionsValue = json['options'];
    final marksValue = json['marks'];
    final parsedOptions = <Option>[];

    if (optionsValue is Map<String, dynamic>) {
      const labels = ['A', 'B', 'C', 'D'];
      for (var i = 0; i < labels.length; i++) {
        final label = labels[i];
        final text = optionsValue[label];
        if (text != null && text.toString().isNotEmpty) {
          parsedOptions.add(Option(index: i, text: text.toString()));
        }
      }
    } else if (optionsValue is List) {
      parsedOptions.addAll(optionsValue
          .asMap()
          .entries
          .map((e) => Option.fromJson(e.value, e.key))
          .toList());
    }

    int? positiveMarks;
    int? negativeMarks;
    if (marksValue is Map<String, dynamic>) {
      final positive = marksValue['positive'];
      final negative = marksValue['negative'];
      if (positive is num) positiveMarks = positive.toInt();
      if (negative is num) negativeMarks = negative.toInt();
    } else if (marksValue is num) {
      positiveMarks = marksValue.toInt();
    }

    return Question(
      id: json['_id'] ?? json['id'] ?? '',
      text: json['text'] ?? json['question'] ?? json['title'],
      imageUrl: json['imageUrl'] ?? json['image'] ?? json['questionImage'],
      options: parsedOptions,
      correctOption: json['correctOption'] ?? json['correctAnswer'],
      correctOptions: json['correctOptions'],
      explanation: json['explanation'],
      marks: positiveMarks ?? TestSeries._parseInt(json['marks']),
      negativeMarks:
          negativeMarks ?? TestSeries._parseInt(json['negativeMarks']),
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
      'correctOptions': correctOptions,
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
