import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';
import 'features/history/data/repositories/history_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale date formatting (required for 'id_ID' locale)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize locale date formatting (required for 'id_ID' locale)
  await initializeDateFormatting('id_ID', null);

  // Initialize local database
  await HistoryRepository.initialize();

  runApp(const ProviderScope(child: CapsicumApp()));
}
