import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:view_shell/src/prop.dart';
import 'package:view_shell/src/shell_control.dart';

/// A widget that extracts and rebuilds the UI out of a selected prop from [TControl].
///
/// The builder provides the selected [TProp].
class PropBuilder<TControl extends ViewShellControl, TProp extends PropBase>
    extends StatelessWidget {
  /// Creates a [PropBuilder] widget.
  const PropBuilder({super.key, required this.selector, required this.builder});

  /// Selects the [PropBase] from the [TControl].
  final TProp Function(TControl) selector;

  /// The builder to use when the prop is in a valid state.
  final Widget Function(BuildContext context, TProp value) builder;

  @override
  Widget build(BuildContext context) {
    final prop = selector(context.read<TControl>());

    return ListenableBuilder(
      listenable: prop,
      builder: (context, _) => builder(context, prop),
    );
  }
}
