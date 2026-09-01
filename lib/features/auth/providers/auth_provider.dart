import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/auth_model.dart';

// Auth State
class AuthState {
  final bool isLoading;
  final String? error;
  final AuthModel? authModel;

  AuthState({this.isLoading = false, this.error, this.authModel});

  AuthState copyWith({bool? isLoading, String? error, AuthModel? authModel}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      authModel: authModel ?? this.authModel,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService = ApiService();

  AuthNotifier() : super(AuthState());

  // Login
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      final authModel = AuthModel.fromJson(response.data['data']);

      // Save the access token.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', authModel.accessToken);
      await prefs.setString('refresh_token', authModel.refreshToken);
      await prefs.setString('user_id', authModel.user.id);
      await prefs.setString('org_id', authModel.org.id);

      state = state.copyWith(isLoading: false, authModel: authModel);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed. Check credentials.',
      );
      return false;
    }
  }

  // Register
  Future<bool> register(
    String fullName,
    String email,
    String password,
    String orgName,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.post(
        ApiConstants.register,
        data: {
          'full_name': fullName,
          'email': email,
          'password': password,
          'org_name': orgName,
        },
      );

      final authModel = AuthModel.fromJson(response.data['data']);

      // Save the access token.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', authModel.accessToken);
      await prefs.setString('refresh_token', authModel.refreshToken);
      await prefs.setString('user_id', authModel.user.id);
      await prefs.setString('org_id', authModel.org.id);

      state = state.copyWith(isLoading: false, authModel: authModel);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Registration failed.');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = AuthState();
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
