import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/config/app_config.dart';
import '../../../shared/models/student_model.dart';
import '../../../shared/models/educator_model.dart';
import '../../../shared/models/user_model.dart';

// Auth State
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final String? userRole; // 'student' or 'educator'
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.userRole,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    User? user,
    String? userRole,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      userRole: userRole ?? this.userRole,
      error: error,
    );
  }

  bool get isStudent => userRole == 'student';
  bool get isEducator => userRole == 'educator';

  Student? get student => user is Student ? user as Student : null;
  Educator? get educator => user is Educator ? user as Educator : null;
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthNotifier(this._apiService) : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    try {
      final token = await StorageService.getSecure(AppConfig.authTokenKey);
      final userDataJson = StorageService.getString(AppConfig.userDataKey);
      final userRole = StorageService.getString(AppConfig.userRoleKey);

      if (token != null && token.isNotEmpty && userDataJson != null) {
        final userData = json.decode(userDataJson);
        User user;

        if (userRole == 'educator') {
          user = Educator.fromJson(userData);
        } else {
          user = Student.fromJson(userData);
        }

        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          user: user,
          userRole: userRole,
        );
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.post(
        '/api/auth/login-student',
        data: {'email': email, 'password': password},
      );

      return _handleLoginResponse(response.data, 'student');
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<bool> _handleLoginResponse(
      Map<String, dynamic> data, String userType) async {
    // Extract token
    final token = data['TOKEN'] ??
        data['token'] ??
        data['accessToken'] ??
        data['data']?['token'];

    if (token == null) {
      throw Exception('No token received');
    }

    // Extract user data
    Map<String, dynamic>? userData;
    if (userType == 'student') {
      userData = data['student'] ?? data['user'] ?? data['data']?['student'];
    } else {
      userData = data['educator'] ?? data['user'] ?? data['data']?['educator'];
    }

    if (userData == null) {
      throw Exception('No user data received');
    }

    // Save to storage
    await StorageService.setSecure(AppConfig.authTokenKey, token);
    await StorageService.setString(
        AppConfig.userDataKey, json.encode(userData));
    await StorageService.setString(AppConfig.userRoleKey, userType);

    // Create user object
    User user;
    if (userType == 'educator') {
      user = Educator.fromJson(userData);
    } else {
      user = Student.fromJson(userData);
    }

    state = state.copyWith(
      isAuthenticated: true,
      isLoading: false,
      user: user,
      userRole: userType,
    );

    return true;
  }

  Future<bool> signupStudent({
    required String name,
    required String username,
    required String email,
    required String password,
    required String mobileNumber,
    String? specialization,
    String? academicClass,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final payload = {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'mobileNumber': mobileNumber,
        if (specialization != null) 'specialization': specialization,
        if (academicClass != null) 'class': academicClass,
      };

      final response = await _apiService.signupStudent(payload);

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['TOKEN'] != null || data['token'] != null) {
          await _handleLoginResponse(data, 'student');
          return true;
        }
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<bool> requestPresignupOtp({
    required String email,
    required String userType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.requestPresignupVerification(
        email: email,
        userType: userType,
      );

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<bool> verifyEmailOtp({
    required String email,
    required String otp,
    required String userType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.verifyEmailOtp(
        email: email,
        otp: otp,
        userType: userType,
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['TOKEN'] != null || data['token'] != null) {
          await _handleLoginResponse(data, 'student');
          return true;
        }
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<bool> resendVerificationOtp({
    required String email,
    required String userType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.resendEmailOtp(
        email: email,
        userType: userType,
      );

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<bool> signupEducator({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String mobileNumber,
    required List<String> subject,
    String? bio,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.post(
        '/api/auth/ed-signup',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'mobileNumber': mobileNumber,
          'subject': subject,
          if (bio != null) 'bio': bio,
        },
      );

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<bool> forgotPassword({
    required String email,
    required String userType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.post(
        '/api/auth/forgot-password',
        data: {
          'email': email,
          'userType': userType,
        },
      );

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String userType,
    required String otp,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.post(
        '/api/auth/reset-password',
        data: {
          'email': email,
          'userType': userType,
          'otp': otp,
          'newPassword': newPassword,
        },
      );

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<void> logout() async {
    await StorageService.deleteSecure(AppConfig.authTokenKey);
    await StorageService.remove(AppConfig.userDataKey);
    await StorageService.remove(AppConfig.userRoleKey);

    state = const AuthState(
      isAuthenticated: false,
      isLoading: false,
    );
  }

  Future<void> updateUser(User user) async {
    await StorageService.setString(
        AppConfig.userDataKey, json.encode(user.toJson()));
    state = state.copyWith(user: user);
  }

  bool _isAuthError(dynamic error) {
    if (error is Exception) {
      final errorString = error.toString();
      return errorString.contains('400') || errorString.contains('401');
    }
    return false;
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
      if (data is String && data.trim().isNotEmpty) {
        return data.trim();
      }
      final statusCode = error.response?.statusCode;
      if (statusCode == 400) {
        return 'Invalid request. Please check your details.';
      }
      if (statusCode == 401) {
        return 'Invalid credentials. Please try again.';
      }
      if (statusCode == 403) {
        return 'Access denied. Please contact support.';
      }
      if (statusCode == 404) {
        return 'Service not available. Please try again later.';
      }
      if (statusCode != null && statusCode >= 500) {
        return 'Server error. Please try again later.';
      }
    }
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection refused')) {
      return 'Network error. Please check your internet connection.';
    }

    return 'Request failed. Please try again.';
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiServiceProvider));
});

// Selectors
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});

final userRoleProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).userRole;
});
