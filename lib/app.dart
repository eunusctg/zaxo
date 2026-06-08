import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaxo/core/theme/app_theme.dart';
import 'package:zaxo/data/services/firebase_database_service.dart';
import 'package:zaxo/data/services/fcm_service.dart';
import 'package:zaxo/di/injection_container.dart';
import 'package:zaxo/presentation/blocs/auth/auth_bloc.dart';
import 'package:zaxo/presentation/blocs/auth/auth_event.dart';
import 'package:zaxo/presentation/blocs/chat/chat_bloc.dart';
import 'package:zaxo/presentation/blocs/chat/chat_event.dart';
import 'package:zaxo/presentation/blocs/message/message_bloc.dart';
import 'package:zaxo/presentation/blocs/call/call_bloc.dart';
import 'package:zaxo/presentation/blocs/call/call_event.dart';
import 'package:zaxo/presentation/blocs/status/status_bloc.dart';
import 'package:zaxo/presentation/blocs/status/status_event.dart';
import 'package:zaxo/routes/app_router.dart';

class ZaxoApp extends StatefulWidget {
  const ZaxoApp({super.key});

  @override
  State<ZaxoApp> createState() => _ZaxoAppState();
}

class _ZaxoAppState extends State<ZaxoApp> with WidgetsBindingObserver {
  final FirebaseDatabaseService _dbService = sl<FirebaseDatabaseService>();
  final FcmService _fcmService = sl<FcmService>();
  StreamSubscription<User?>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize FCM service.
    _fcmService.initialize();

    // Listen for auth state changes to manage online status.
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        if (user != null) {
          // User signed in — set online status.
          _dbService.setOnlineStatus(user.uid, isOnline: true);
        }
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authStateSubscription?.cancel();

    // Set user offline on dispose.
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      _dbService.setOnlineStatus(currentUserId, isOnline: false);
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _dbService.setOnlineStatus(currentUserId, isOnline: true);
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _dbService.setOnlineStatus(currentUserId, isOnline: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()..add(const AuthStarted())),
        BlocProvider(
          create: (_) => ChatBloc(dbService: _dbService)..add(const ChatStarted()),
        ),
        BlocProvider(
          create: (_) => MessageBloc(
            dbService: _dbService,
            aiChatService: sl(),
          ),
        ),
        BlocProvider(
          create: (_) => CallBloc(dbService: _dbService)..add(const CallHistoryLoaded()),
        ),
        BlocProvider(
          create: (_) => StatusBloc(dbService: _dbService)..add(const StatusLoadRequested()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Zaxo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.dark,
        routerConfig: AppRouter.appRouter,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
