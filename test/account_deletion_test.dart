import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/constants.dart';
import 'package:notlar/features/auth/data/account_service.dart';

/// Hesap silme (F1.2): kod tabanında yazılan HER Firestore koleksiyonu ya
/// hesapla birlikte silinmeli ya da bilerek tutulduğu yazılmış olmalı. Yeni
/// bir koleksiyon eklenip silme listesine unutulursa bu test kırılır.
void main() {
  test('her koleksiyon adı silme ya da tutma listesinde', () {
    final constants = <String, String>{};
    final constantsSrc = File('lib/core/constants.dart').readAsStringSync();
    for (final m in RegExp(
      r"static const String (\w+Collection) = '([^']+)'",
    ).allMatches(constantsSrc)) {
      constants[m.group(1)!] = m.group(2)!;
    }
    expect(constants, isNotEmpty);

    final used = <String>{};
    final literal = RegExp(r"\.collection\(\s*'([^']+)'\s*\)");
    final viaConst = RegExp(r'\.collection\(\s*AppConstants\.(\w+)\s*\)');
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      for (final m in literal.allMatches(src)) {
        used.add(m.group(1)!);
      }
      for (final m in viaConst.allMatches(src)) {
        final v = constants[m.group(1)!];
        if (v != null) used.add(v);
      }
    }
    final covered = {
      ...AccountService.deletedUserSubcollections,
      ...AccountService.deletedRootCollections,
      ...AccountService.keptCollections,
    };
    expect(used.difference(covered), isEmpty);
  });

  test('kişisel veri taşıyan kök kayıtlar silinir', () {
    expect(
      AccountService.deletedRootCollections,
      containsAll([
        'userSearch',
        AppConstants.noteSharesCollection,
        AppConstants.folderSharesCollection,
        AppConstants.folderMessagesCollection,
        AppConstants.userDirectoryCollection,
      ]),
    );
  });

  test('kural dosyasındaki kök koleksiyonlar listede', () {
    final rules = File('firestore.rules').readAsStringSync();
    final roots = {
      for (final m in RegExp(
        r'^    match /(\w+)/\{',
        multiLine: true,
      ).allMatches(rules))
        m.group(1)!,
    };
    final covered = {
      ...AccountService.deletedRootCollections,
      ...AccountService.keptCollections,
    };
    expect(roots.difference(covered), isEmpty);
  });
}
