import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/note_find_controller.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

/// F9.3: not içi aramanın durumu editörden ayrı denetleyicide.
void main() {
  late WrapTextController title;
  late WrapTextController body;
  late FocusNode f1;
  late FocusNode f2;
  late NoteFindController find;

  setUp(() {
    title = WrapTextController(text: 'Süt al');
    body = WrapTextController(text: 'sut, ekmek ve **süt**');
    f1 = FocusNode();
    f2 = FocusNode();
    find = NoteFindController();
  });

  tearDown(() {
    find.dispose();
    title.dispose();
    body.dispose();
    f1.dispose();
    f2.dispose();
  });

  List<NoteFindField> fields() => [
    (controller: title, focus: f1, where: 'Başlık', icon: Icons.title),
    (controller: body, focus: f2, where: 'Gövde', icon: Icons.notes),
  ];

  test('alanlar sırayla taranır, biçim işaretleri atlanır', () {
    var notified = 0;
    find.addListener(() => notified++);
    find.query.text = 'süt';
    find.search(fields());
    expect(find.hits.length, 3);
    expect(find.hits.first.where, 'Başlık');
    expect(find.index, 0);
    expect(notified, 1);
  });

  test('ileri/geri döngüsel; liste seçimi', () {
    find.query.text = 'süt';
    find.search(fields());
    find.step(-1);
    expect(find.index, 2);
    find.step(1);
    expect(find.index, 0);
    find.select(1);
    expect(find.current!.controller, body);
  });

  test('düzenleme sonrası tazelemede odak aynı alanda kalır', () {
    find.query.text = 'süt';
    find.search(fields());
    find.select(2);
    body.text = 'yeni: sut, ekmek ve **süt**';
    find.search(fields(), keepIndex: true);
    expect(find.current!.controller, body);
  });

  test('sıfırlama sorguyu ve eşleşmeleri temizler', () {
    find.query.text = 'süt';
    find.search(fields());
    find.paint(dark: false);
    find.reset();
    expect(find.hits, isEmpty);
    expect(find.index, -1);
    expect(find.query.text, isEmpty);
  });
}
