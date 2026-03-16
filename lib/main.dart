import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'logic/blocs/navigation/navigation_bloc.dart';
import 'logic/blocs/onboarding/onboarding_bloc.dart';
import 'logic/blocs/splash/splash_bloc.dart';
import 'logic/blocs/splash/splash_event.dart';
import 'logic/blocs/auth/auth_bloc.dart';
import 'logic/blocs/auth/auth_event.dart';
import 'pages/splash_page.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp();

  // Remove this method to stop OneSignal Debugging
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

  OneSignal.initialize("d643324c-c642-44c1-a4e1-6c4fc5bb4a00");
  debugPrint("✅ OneSignal Initialized!");

  // The promptForPushNotificationsWithUserResponse function will show the iOS or Android push prompt.
  // We recommend removing the following code and instead using an In-App Message to prompt for notification permission
  OneSignal.Notifications.requestPermission(true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => NavigationBloc()),
        BlocProvider(create: (context) => SplashBloc()..add(StartSplash())),
        BlocProvider(create: (context) => AuthBloc()..add(AppStarted())),
        BlocProvider(create: (context) => OnboardingBloc()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GymDude BLoC',
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFFC0FF00),
          useMaterial3: true,
        ),
        home: const SplashPage(),
      ),
    );
  }
}
