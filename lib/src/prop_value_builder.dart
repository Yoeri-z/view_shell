import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:view_shell/src/prop.dart';
import 'package:view_shell/src/shell_control.dart';

/// A widget that extracts and rebuilds the UI out of a selected prop from [TControl].
///
/// The builder provides the value [TValue] of the prop in the builder.
class PropValueBuilder<TControl extends ViewShellControl, TValue>
    extends StatelessWidget {
  /// Creates a [PropValueBuilder] widget.
  const PropValueBuilder({
    super.key,
    required this.selector,
    required this.builder,
  });

  /// Selects the [PropBase] from the [TControl].
  final PropBase<TValue> Function(TControl) selector;

  /// The builder to use when the prop is in a valid state.
  final Widget Function(BuildContext context, TValue value) builder;
  @override
  Widget build(BuildContext context) {
    final control = context.watch<TControl>();
    final prop = selector(control);

    return builder(context, prop.require);
  }
}
