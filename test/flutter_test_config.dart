import 'dart:async';

import 'package:notlar/features/notes/presentation/editor/items_editor.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  debugEagerItemFields = true;
  await testMain();
}
