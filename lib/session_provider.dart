// import 'package:flutter/foundation.dart';
// import 'package:my_desktop_app/main.dart';


// class SessionProvider extends ChangeNotifier {
//   UserRole? _role;
//   String? _sessionId;

//   bool _isConnected = false;

//   // ---------------- GETTERS ----------------
//   UserRole? get role => _role;
//   String? get sessionId => _sessionId;
//   bool get isConnected => _isConnected;

//   // ---------------- ROLE SET / CONNECT ----------------
//   void connect(UserRole selectedRole, {String? sessionId}) {
//     _role = selectedRole;
//     _sessionId = sessionId ?? "session_123";

//     _isConnected = true;

//     debugPrint("✅ Session Connected as: $_role");

//     notifyListeners();
//   }

//   // ---------------- UPDATE ROLE (optional) ----------------
//   void updateRole(UserRole role) {
//     _role = role;
//     notifyListeners();
//   }

//   // ---------------- RESET SESSION ----------------
//   void disconnect() {
//     _role = null;
//     _sessionId = null;
//     _isConnected = false;

//     debugPrint("❌ Session Disconnected");

//     notifyListeners();
//   }
// }