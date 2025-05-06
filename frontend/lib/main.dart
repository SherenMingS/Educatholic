import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/screen/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (context, child) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (_, ThemeMode currentMode, __) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              themeMode: currentMode,
              theme: ThemeData(
                primaryColor: Colors.blue,
                scaffoldBackgroundColor: Colors.white,
                appBarTheme: AppBarTheme(backgroundColor: Colors.blue),
                colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
                    .copyWith(secondary: Colors.blueAccent),
              ),
              darkTheme: ThemeData.dark().copyWith(
                primaryColor: Colors.blue,
                scaffoldBackgroundColor: const Color(0xFF121212),
                appBarTheme: AppBarTheme(backgroundColor: Colors.blue),
                cardColor: const Color(0xFF1E1E1E),
                iconTheme: const IconThemeData(color: Colors.white),
                textTheme: const TextTheme(
                  bodyLarge: TextStyle(color: Colors.white),
                  bodyMedium: TextStyle(color: Colors.white),
                ),
              ),
              home: SplashScreen(),
            );
          },
        );
      },
    );
  }
}
