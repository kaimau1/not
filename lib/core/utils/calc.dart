/// Dahili hesap makinesinin ifade değerlendiricisi.
///
/// Desteklenenler: + − × ÷, parantez, ondalık virgül/nokta ve yüzde
/// (% hem önek `%10` hem sonek `10%` olarak değerin yüzde biri demektir;
/// mod işlemi yoktur). Geçersiz ifadede null döner.
double? evaluateExpression(String input) {
  final normalized = input
      .replaceAll('×', '*')
      .replaceAll('÷', '/')
      .replaceAll('−', '-')
      .replaceAll(',', '.');
  final parser = _ExprParser(normalized);
  try {
    final value = parser.parse();
    if (value.isNaN || value.isInfinite) return null;
    return value;
  } on FormatException {
    return null;
  }
}

/// Sonucu Türkçe biçimde yazar: tam sayılar kesirsiz, ondalıklar virgülle
/// ve sondaki sıfırlar atılmış olarak.
String formatCalcResult(double value) {
  if (value == value.roundToDouble() && value.abs() < 1e15) {
    return value.toInt().toString();
  }
  var text = value.toStringAsFixed(8);
  text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return text.replaceAll('.', ',');
}

/// Özyinelemeli inişli ayrıştırıcı:
///   ifade  := terim (('+'|'-') terim)*
///   terim  := tekil (('*'|'/') tekil)*
///   tekil  := '-' tekil | '%' tekil | sonek
///   sonek  := birincil ('%')*
///   birincil := sayı | '(' ifade ')'
class _ExprParser {
  _ExprParser(this._source);

  final String _source;
  int _pos = 0;

  double parse() {
    final value = _expression();
    _skipSpaces();
    if (_pos != _source.length) throw const FormatException();
    return value;
  }

  double _expression() {
    var value = _term();
    while (true) {
      _skipSpaces();
      if (_consume('+')) {
        value += _term();
      } else if (_consume('-')) {
        value -= _term();
      } else {
        return value;
      }
    }
  }

  double _term() {
    var value = _unary();
    while (true) {
      _skipSpaces();
      if (_consume('*')) {
        value *= _unary();
      } else if (_consume('/')) {
        final divisor = _unary();
        if (divisor == 0) throw const FormatException();
        value /= divisor;
      } else {
        return value;
      }
    }
  }

  double _unary() {
    _skipSpaces();
    if (_consume('-')) return -_unary();
    if (_consume('%')) return _unary() / 100;
    return _postfix();
  }

  double _postfix() {
    var value = _primary();
    while (true) {
      _skipSpaces();
      if (_consume('%')) {
        value /= 100;
      } else {
        return value;
      }
    }
  }

  double _primary() {
    _skipSpaces();
    if (_consume('(')) {
      final value = _expression();
      _skipSpaces();
      if (!_consume(')')) throw const FormatException();
      return value;
    }
    final start = _pos;
    while (_pos < _source.length &&
        (_isDigit(_source.codeUnitAt(_pos)) || _source[_pos] == '.')) {
      _pos++;
    }
    if (start == _pos) throw const FormatException();
    final number = double.tryParse(_source.substring(start, _pos));
    if (number == null) throw const FormatException();
    return number;
  }

  bool _consume(String char) {
    if (_pos < _source.length && _source[_pos] == char) {
      _pos++;
      return true;
    }
    return false;
  }

  void _skipSpaces() {
    while (_pos < _source.length && _source[_pos] == ' ') {
      _pos++;
    }
  }

  static bool _isDigit(int codeUnit) => codeUnit >= 0x30 && codeUnit <= 0x39;
}
