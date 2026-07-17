import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n_ext.dart';

/// Gizlilik Politikası — depo kökündeki PRIVACY_POLICY.md dosyasını gösterir
/// (tek kaynak: aynı metin hem uygulamada hem depoda durur). Play'in Veri
/// Güvenliği formu ve KVKK bilgilendirmesi bu metne dayanır.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicyTitle)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('PRIVACY_POLICY.md'),
        builder: (context, snapshot) {
          final text = snapshot.data;
          if (text == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  SelectableText(
                    // Markdown işaretlerini sadeleştir: düz okunabilir metin.
                    text.replaceAll(RegExp(r'^#+\s*', multiLine: true), ''),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
