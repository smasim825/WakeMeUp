import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/journey_provider.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for seamless dark aesthetic
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B1220),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize offline storage service
  final storageService = await StorageService.init();

  runApp(WakeMeApp(storageService: storageService));
}

class WakeMeApp extends StatelessWidget {
  final StorageService storageService;

  const WakeMeApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        ChangeNotifierProvider<JourneyProvider>(
          create: (_) => JourneyProvider(storageService),
        ),
      ],
      child: MaterialApp(
        title: 'WakeMe',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
