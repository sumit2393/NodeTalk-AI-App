import 'package:node_talk_app/core/models/user_model.dart';

class AuthModel {
  final String accessToken;
  final String refreshToken;
  final UserModel user;
  final OrgModel org;

  AuthModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.org,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      user: UserModel.fromJson(json['user']),
      org: OrgModel.fromJson(json['org']),
    );
  }
}

class OrgModel {
  final String id;
  final String name;
  final String slug;

  OrgModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory OrgModel.fromJson(Map<String, dynamic> json) {
    return OrgModel(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
    );
  }
}