// Gerçek paketin YALNIZ `antalia_engine.dart`ın kullandığı yüzü; imzalar aynı.
// Yeni bir ONNX çağrısı eklenirse buraya da eklenmeli (aksi halde Play
// derlemesi derlenmez — sessiz değil, derleme hatası).
library;

UnsupportedError _off() => UnsupportedError('ONNX Play derlemesinde yok');

class OnnxRuntime {
  Future<OrtSession> createSession(
    String modelPath, {
    OrtSessionOptions? options,
  }) => throw _off();
}

class OrtSessionOptions {
  OrtSessionOptions({int? intraOpNumThreads});
}

class OrtSession {
  Future<Map<String, OrtValue>> run(Map<String, OrtValue> inputs) =>
      throw _off();

  Future<void> close() => throw _off();
}

class OrtValue {
  List<int> get shape => throw _off();

  static Future<OrtValue> fromList(dynamic data, List<int> shape) =>
      throw _off();

  Future<List<dynamic>> asFlattenedList() => throw _off();

  Future<void> dispose() => throw _off();
}
