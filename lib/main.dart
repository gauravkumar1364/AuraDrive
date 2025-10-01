import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/navigation_screen.dart';
import 'services/gnss_service.dart';
import 'services/mesh_network_service.dart';
import 'services/collision_detection_service.dart';

void main() {
  runApp(const NaviSafeApp());
}

class NaviSafeApp extends StatelessWidget {
  const NaviSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GnssService()),
        ChangeNotifierProvider(create: (_) => MeshNetworkService()),
        ChangeNotifierProvider(create: (_) => CollisionDetectionService()),
      ],
      child: MaterialApp(
        title: 'NaviSafe - Autonomous Vehicle Navigation',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Navigation safety theme with high contrast colors
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF1565C0), // Deep blue for navigation
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.light,
            primary: const Color(0xFF1565C0),
            secondary: const Color(0xFFFF6F00), // Orange for warnings
            error: const Color(0xFFD32F2F), // Red for alerts
            surface: Colors.white,
          ),
          
          // Typography optimized for in-vehicle readability
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
            headlineMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1565C0),
            ),
            bodyLarge: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF212121),
            ),
            bodyMedium: TextStyle(
              fontSize: 16,
              color: Color(0xFF424242),
            ),
          ),
          
          // Enhanced visibility for safety-critical UI elements
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Card design for information panels
          cardTheme: const CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            margin: EdgeInsets.all(8),
          ),
          
          // AppBar styling for navigation header
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1565C0),
            foregroundColor: Colors.white,
            elevation: 2,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          useMaterial3: true,
        ),
        
        // Dark theme for night driving
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF90CAF9), // Light blue for dark mode
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF90CAF9),
            brightness: Brightness.dark,
            primary: const Color(0xFF90CAF9),
            secondary: const Color(0xFFFFB74D), // Lighter orange for dark mode
            error: const Color(0xFFEF5350),
            surface: const Color(0xFF1E1E1E),
          ),
          useMaterial3: true,
        ),
        
        themeMode: ThemeMode.system, // Adapts to system settings
        home: const NavigationScreen(),
      ),
    );
  }
}
