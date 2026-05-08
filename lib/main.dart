import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
//import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'dart:io';

import 'features/session/screens/role_selection_screen.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('args: $args');
  if (runWebViewTitleBarWidget(args)) {
    return;
  }

  MediaKit.ensureInitialized();

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RoleSelectionScreen(),
    ),
  );
}
