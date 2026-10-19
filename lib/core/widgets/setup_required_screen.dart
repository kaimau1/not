import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// `flutterfire configure` henüz çalıştırılmadıysa gösterilen yönerge ekranı.
/// Uygulamanın geri kalanı Firebase olmadan çalışamayacağı için ayrı,
/// bağımsız bir MaterialApp olarak açılır.
class SetupRequiredApp extends StatelessWidget {
  const SetupRequiredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notlar — Kurulum Gerekli',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const _SetupRequiredScreen(),
    );
  }
}

class _SetupRequiredScreen extends StatelessWidget {
  const _SetupRequiredScreen();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.build_circle_outlined,
                  size: 48,
                  color: scheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Firebase yapılandırması gerekli',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Uygulama henüz bir Firebase projesine bağlanmamış. '
                  'Proje kök dizininde aşağıdaki komutları çalıştırın ve '
                  'uygulamayı yeniden derleyin:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const SelectableText(
                    'dart pub global activate flutterfire_cli\n'
                    'flutterfire configure --platforms=android,web',
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Adım adım kurulum için depodaki README.md dosyasına bakın.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
