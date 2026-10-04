import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'i18n.dart';
import 'screens/home_shell.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final store = Store();
  await store.load();
  runApp(ChangeNotifierProvider.value(value: store, child: const GanzJahrApp()));
}

class GanzJahrApp extends StatelessWidget {
  const GanzJahrApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = langFromCode(context.select<Store, String>((s) => s.language));
    appLang = lang;
    return MaterialApp(
      title: 'GanzJahr Invoices'.tr,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: lang.locale,
      supportedLocales: AppLang.values.map((l) => l.locale),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: HomeShell(key: ValueKey(lang)),
    );
  }
}
