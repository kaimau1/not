import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n_ext.dart';
import '../features/settings/settings_providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class NotlarApp extends ConsumerWidget {
  const NotlarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(effectiveThemeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final paper = ref.watch(themeChoiceProvider) == AppThemeChoice.paper;

    return MaterialApp.router(
      title: 'Notlar',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: paper ? AppTheme.paper() : AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(fontScale),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
