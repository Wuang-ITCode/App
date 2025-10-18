import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'services/auth_service.dart';
import 'services/task_service.dart';
import 'services/theme_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Mỗi khi mở lại app → tự động đăng xuất user trước đó
  try {
    await FirebaseAuth.instance.signOut();
    debugPrint("Đã tự động đăng xuất user cũ khi khởi động app");
  } catch (e) {
    debugPrint("Lỗi khi đăng xuất tự động: $e");
  }

  runApp(const TaskManagerPro());
}

class TaskManagerPro extends StatelessWidget {
  const TaskManagerPro({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// ✅ Dịch vụ xác thực người dùng (Firebase Auth)
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),

        /// ✅ Theo dõi trạng thái đăng nhập (Stream)
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),

        /// ✅ Dịch vụ Task (chỉ khởi tạo khi có user đăng nhập)
        ProxyProvider<User?, TaskService?>(
          update: (_, user, __) => user == null ? null : TaskService(),
        ),

        /// ✅ Dịch vụ Theme (Dark / Light Mode)
        ChangeNotifierProvider(
          create: (_) => ThemeService(),
        ),
      ],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final themeSrv = context.watch<ThemeService>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager Pro',

      /// ✅ Dùng theme hiện tại (Dark/Light)
      themeMode: themeSrv.themeMode,

      home: const SplashScreen(),

      // 🌞 Giao diện sáng (Light Mode)
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),

      // 🌙 Giao diện tối (Dark Mode)
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.indigoAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade900,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/// ✅ Widget trung gian kiểm tra đăng nhập
class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    final taskSrv = context.watch<TaskService?>();

    // 🔸 Nếu chưa đăng nhập → chuyển về màn hình đăng nhập
    if (user == null) return const LoginScreen();

    // 🔸 Nếu TaskService chưa sẵn sàng → hiển thị loading
    if (taskSrv == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ Khi đã đăng nhập → về HomeScreen
    return const HomeScreen();
  }
}
