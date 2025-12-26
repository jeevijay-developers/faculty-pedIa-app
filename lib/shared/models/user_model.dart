class User {
  final String id;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String email;
  final String? mobileNumber;
  final String? username;
  final UserImage? image;
  final String? bio;
  final String role; // 'student' or 'educator'
  final DateTime? joinedAt;
  final DateTime? createdAt;
  
  User({
    required this.id,
    this.name,
    this.firstName,
    this.lastName,
    required this.email,
    this.mobileNumber,
    this.username,
    this.image,
    this.bio,
    required this.role,
    this.joinedAt,
    this.createdAt,
  });
  
  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    if (firstName != null || lastName != null) {
      return [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
    }
    return email.split('@').first;
  }
  
  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.substring(0, 2).toUpperCase();
  }
  
  String? get imageUrl => image?.url;
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'] ?? '',
      mobileNumber: json['mobileNumber'] ?? json['mobile'],
      username: json['username'],
      image: json['image'] != null ? UserImage.fromJson(json['image']) : null,
      bio: json['bio'],
      role: json['role'] ?? 'student',
      joinedAt: json['joinedAt'] != null ? DateTime.tryParse(json['joinedAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobileNumber': mobileNumber,
      'username': username,
      'image': image?.toJson(),
      'bio': bio,
      'role': role,
      'joinedAt': joinedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
  
  User copyWith({
    String? id,
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? mobileNumber,
    String? username,
    UserImage? image,
    String? bio,
    String? role,
    DateTime? joinedAt,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      username: username ?? this.username,
      image: image ?? this.image,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class UserImage {
  final String? url;
  final String? publicId;
  
  UserImage({this.url, this.publicId});
  
  factory UserImage.fromJson(dynamic json) {
    if (json is String) {
      return UserImage(url: json);
    }
    if (json is Map<String, dynamic>) {
      return UserImage(
        url: json['url'],
        publicId: json['publicId'] ?? json['public_id'],
      );
    }
    return UserImage();
  }
  
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'publicId': publicId,
    };
  }
}
