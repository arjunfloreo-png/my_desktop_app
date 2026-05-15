import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

import 'dart:io';

import 'features/session/provider/role_selection_provider.dart';
import 'features/session/screens/role_selection_screen.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('args: $args');

  if (runWebViewTitleBarWidget(args)) {
    return;
  }

  MediaKit.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => RoleSelectionProvider(),
        ),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RoleSelectionScreen(),
      ),
    );
  }
}