import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/calc.dart';

bool get _isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

/// Not yazarken hızlı hesap için dahili hesap makinesi alt sayfası.
/// "Nota ekle" ile kapatılırsa eklenecek metni ("12,5×3 = 37,5" ya da
/// tek sayıysa yalnızca sonucu) döner; iptalde null.
Future<String?> showCalculatorSheet(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _CalculatorSheet(),
    );

class _CalculatorSheet extends StatefulWidget {
  const _CalculatorSheet();

  @override
  State<_CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<_CalculatorSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _expression => _controller.text;

  double? get _value {
    final expr = _expression.trim();
    if (expr.isEmpty) return null;
    return evaluateExpression(expr);
  }

  void _append(String text) {
    setState(() => _controller.text = _expression + text);
  }

  void _tapKey(String key) {
    switch (key) {
      case 'C':
        setState(_controller.clear);
      case '⌫':
        if (_expression.isNotEmpty) {
          setState(() => _controller.text =
              _expression.substring(0, _expression.length - 1));
        }
      case '( )':
        _appendParen();
      case '=':
        final value = _value;
        if (value != null) {
          setState(() => _controller.text = formatCalcResult(value));
        }
      default:
        _append(key);
    }
  }

  /// Açık parantez sayısına ve son karaktere göre ( ya da ) ekler.
  void _appendParen() {
    final expr = _expression;
    final open = '('.allMatches(expr).length;
    final close = ')'.allMatches(expr).length;
    final last = expr.isEmpty ? '' : expr[expr.length - 1];
    final canClose = open > close &&
        last != '(' &&
        !'+−×÷'.contains(last);
    _append(canClose ? ')' : '(');
  }

  /// Nota eklenecek metin: ifade tek bir sayı değilse "ifade = sonuç".
  String? get _insertText {
    final value = _value;
    if (value == null) return null;
    final result = formatCalcResult(value);
    final expr = _expression.trim();
    return expr == result ? result : '$expr = $result';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final value = _value;
    final hasExpression = _expression.trim().isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              // Mobilde sistem klavyesi tuş takımını örtmesin; masaüstünde
              // fiziksel klavyeyle yazmak serbest.
              readOnly: !_isDesktop,
              showCursor: true,
              autofocus: _isDesktop,
              onChanged: (_) => setState(() {}),
              style: Theme.of(context).textTheme.titleLarge,
              decoration: InputDecoration(
                hintText: l10n.calcExpressionHint,
                suffixIcon: hasExpression
                    ? Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          value == null ? l10n.calcInvalid : '= ${formatCalcResult(value)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color:
                                    value == null ? scheme.error : scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      )
                    : null,
                suffixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
              ),
            ),
            const SizedBox(height: 10),
            for (final row in const [
              ['C', '( )', '%', '÷'],
              ['7', '8', '9', '×'],
              ['4', '5', '6', '−'],
              ['1', '2', '3', '+'],
              ['⌫', '0', ',', '='],
            ]) ...[
              Row(
                children: [
                  for (final key in row) ...[
                    Expanded(child: _buildKey(key)),
                    if (key != row.last) const SizedBox(width: 6),
                  ],
                ],
              ),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: Text(l10n.copy),
                  onPressed: value == null
                      ? null
                      : () async {
                          await Clipboard.setData(
                            ClipboardData(text: formatCalcResult(value)),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(content: Text(l10n.copied)),
                              );
                          }
                        },
                ),
                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.playlist_add, size: 18),
                  label: Text(l10n.addToNote),
                  onPressed: value == null
                      ? null
                      : () => Navigator.pop(context, _insertText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String key) {
    final scheme = Theme.of(context).colorScheme;
    final isOperator = '÷×−+%'.contains(key) || key == '( )';
    final isAction = key == 'C' || key == '⌫';

    final Widget child = Text(
      key,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w600),
    );
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    if (key == '=') {
      return FilledButton(
        style: style,
        onPressed: () => _tapKey(key),
        child: child,
      );
    }
    if (isOperator || isAction) {
      return FilledButton.tonal(
        style: style.copyWith(
          backgroundColor: isAction
              ? WidgetStatePropertyAll(scheme.surfaceContainerHigh)
              : null,
        ),
        onPressed: () => _tapKey(key),
        child: child,
      );
    }
    return OutlinedButton(
      style: style,
      onPressed: () => _tapKey(key),
      child: child,
    );
  }
}
