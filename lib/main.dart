import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/tema.dart';
import 'features/shell/caparazon.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Vertical nada mas: es una app de consulta rapida, y el apaisado no aporta
  // nada a cambio de duplicar el trabajo de disenio.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: AppFinanzas()));
}

class AppFinanzas extends ConsumerWidget {
  const AppFinanzas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Finanzas',
      debugShowCheckedModeBanner: false,
      themeMode: ref.watch(temaProvider),
      theme: construirTema(Brightness.light),
      darkTheme: construirTema(Brightness.dark),
      // La app esta pensada para Peru: el castellano es el idioma, no una
      // traduccion opcional.
      locale: const Locale('es', 'PE'),
      supportedLocales: const [Locale('es', 'PE'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Un usuario con la letra muy grande no deberia romper los tableros.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(maxScaleFactor: 1.35),
          ),
          child: child!,
        );
      },
      home: const Caparazon(),
    );
  }
}
