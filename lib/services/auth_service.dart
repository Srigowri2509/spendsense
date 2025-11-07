import 'api_client.dart';
import 'endpoints.dart';

class AuthService {
  AuthService(this._api);
  final ApiClient _api;

  Future<(String token, Map<String, dynamic> user)> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.postJson(
      Endpoints.login,
      body: {'email': email, 'password': password},
    ) as Map<String, dynamic>;
    final data = (res['Data'] as Map<String, dynamic>);
    final token = (data['accessToken'] as String?) ?? (data['token'] as String?) ?? '';
    final user = (data['user'] as Map<String, dynamic>?) ?? data;
    return (token, user);
  }

  Future<(String token, Map<String, dynamic> user)> register({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    String? gender,
    String? nickName,
  }) async {
    final res = await _api.postJson(
      Endpoints.register,
      body: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        if (gender != null) 'gender': gender,
        if (nickName != null) 'nickName': nickName,
      },
    ) as Map<String, dynamic>;
    final data = (res['Data'] as Map<String, dynamic>);
    final token = (data['accessToken'] as String?) ?? (data['token'] as String?) ?? '';
    final user = (data['user'] as Map<String, dynamic>?) ?? data;
    return (token, user);
  }

  Future<Map<String, dynamic>> currentUser() async {
    final res = await _api.getJson(Endpoints.getCurrentUser) as Map<String, dynamic>;
    final data = (res['Data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    // Handle both nested user structure and direct data structure
    return (data['user'] as Map<String, dynamic>?) ?? data;
  }
}
