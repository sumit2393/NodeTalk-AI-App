class ApiConstants {
  // Local development endpoint. On a physical device, use the host machine's
  // network address instead of localhost.
  static const String baseUrl =  String.fromEnvironment('API_BASE_URL');

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Users
  static const String me = '/users/me';

  // Datasources
  static const String datasources = '/datasources';
  static const String upload = '/datasources/upload';

  // AI
  static const String conversations = '/ai/conversations';
  static const String chat = '/ai/chat';
  static const String embed = '/ai/embed';
}
