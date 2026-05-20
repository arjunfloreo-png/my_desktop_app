// lib/providers/role_selection_provider.dart

import 'dart:convert';

import 'package:floreo/features/session/models/user_role.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../services/socket_service.dart';
import '../models/role_based_reponse_model.dart';

class RoleSelectionProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  RoleBasedResponseModel? _response;

  bool get isLoading => _isLoading;
  String? get error => _error;
  RoleBasedResponseModel? get response => _response;

  static const String _baseUrl =
      'https://floreo-server.onrender.com/agora/token';

  Future<RoleBasedResponseModel?> generateAgoraToken({
    required String channelName,
    required int uid,
    required String role,
    required String roleName,
  }) async {
    print('Generating token for channel: $channelName, uid: $uid, role: $role');
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "channelName": channelName,
          "uid": uid,
          "role": role,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        _response = RoleBasedResponseModel.fromJson(data);

        // connect socket + join session
        final socket = SocketService();
        socket.connect();

        // Use channelName as sessionId (matches your backend logic)
        socket.joinSession(
          channelName,
          // ignore: unrelated_type_equality_checks
          roleName,
        );

        return _response;
      } else {
        _error = 'Failed to generate token';
        debugPrint('Error Response: ${response.body}');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Provider Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return null;
  }
}
