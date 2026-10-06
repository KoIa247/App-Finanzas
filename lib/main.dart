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
      title: 'Leep',
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
        // Lo que pide el telefono por su cuenta, multiplicado por lo que el
        // usuario haya elegido en Accesibilidad. El tope sigue existiendo
        // para que los tableros de cifras no se rompan.
        final mq = MediaQuery.of(context);
        final delTelefono = mq.textScaler.clamp(maxScaleFactor: 1.35).scale(1);
        return MediaQuery(
          data: mq.copyWith(
            textScaler:
                TextScaler.linear(delTelefono * ref.watch(escalaProvider)),
          ),
          child: child!,
        );
      },
      home: const Caparazon(),
    );
  }
}
