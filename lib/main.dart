import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'scenes/menu_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const HoldTheHoochApp());
}

class HoldTheHoochApp extends StatelessWidget {
  const HoldTheHoochApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hold the Hooch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const MenuScreen(),
    );
  }
}
