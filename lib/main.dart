import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'state/app_state.dart';
import 'ui/app_shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  runApp(ImagoHubApp(state: state));
  await state.initialize();
}

class ImagoHubApp extends StatelessWidget {
  final AppState state;
  const ImagoHubApp({super.key, required this.state});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) => MaterialApp(
      title: 'ImagoHub',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: imagoTheme(false),
      darkTheme: imagoTheme(true),
      themeMode: state.dark ? ThemeMode.dark : ThemeMode.light,
      home: state.initialized
          ? AppShell(state: state)
          : const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: ImagoColors.brand),
              ),
            ),
    ),
  );
}
