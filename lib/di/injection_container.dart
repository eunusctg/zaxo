/// Dependency Injection container for the Zaxo app.
///
/// Uses [GetIt] as a service locator. All Firebase services, storage, and
/// AI chat services are registered here for injection into BLoCs.
library;

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:zaxo/data/datasources/local/hive_datasource.dart';
import 'package:zaxo/data/datasources/remote/api_datasource.dart';
import 'package:zaxo/data/services/firebase_auth_service.dart';
import 'package:zaxo/data/services/firebase_database_service.dart';
import 'package:zaxo/data/services/ai_chat_service.dart';
import 'package:zaxo/data/services/r2_storage_service.dart';
import 'package:zaxo/data/services/fcm_service.dart';

/// Global service locator instance.
final sl = GetIt.instance;

/// Initialize all dependencies.
Future<void> setup() async {
  // ── Dio HTTP client ────────────────────────────────────────────────────
  sl.registerLazySingleton<Dio>(
    () => Dio(
      BaseOptions(
        baseUrl: ApiDataSource.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    ),
  );

  // ── API data source ────────────────────────────────────────────────────
  sl.registerLazySingleton<ApiDataSource>(
    () => ApiDataSource(dio: sl<Dio>()),
  );

  // ── Hive local data source ─────────────────────────────────────────────
  final hiveDataSource = HiveDataSource();
  await hiveDataSource.init();
  sl.registerLazySingleton<HiveDataSource>(() => hiveDataSource);

  // ── Firebase Auth Service ──────────────────────────────────────────────
  sl.registerLazySingleton<FirebaseAuthService>(
    () => FirebaseAuthService(),
  );

  // ── Firebase Database Service ──────────────────────────────────────────
  sl.registerLazySingleton<FirebaseDatabaseService>(
    () => FirebaseDatabaseService(),
  );

  // ── AI Chat Service ────────────────────────────────────────────────────
  // Default baseUrl is http://10.0.2.2:3000 (Android emulator localhost).
  // Override for physical devices or production as needed.
  sl.registerLazySingleton<AiChatService>(
    () => AiChatService(baseUrl: 'http://10.0.2.2:3000'),
  );

  // ── R2 Storage Service ─────────────────────────────────────────────────
  sl.registerLazySingleton<R2StorageService>(
    () => R2StorageService(),
  );

  // ── FCM Service ────────────────────────────────────────────────────────
  sl.registerLazySingleton<FcmService>(
    () => FcmService(),
  );
}

/// Dispose all registered singletons.
Future<void> dispose() async {
  await sl<HiveDataSource>().dispose();
  await sl.reset();
}
