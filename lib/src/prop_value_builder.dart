import 'package:flutter/material.dart';
import 'package:view_shell/src/prop.dart';
import 'package:view_shell/src/shell_widget.dart';

/// A widget that extracts and rebuilds the UI out of a selected prop from [TControl].
///
/// The builder provides the value [TValue] of the prop in the builder.
class PropValueBuilder<
  TWidget extends ShellWidget,
  TState extends ShellState<TWidget>,
  TValue
>
    extends StatelessWidget {
  /// Creates a [PropValueBuilder] widget.
  const PropValueBuilder({
    super.key,
    required this.selector,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
  });

  /// Selects the [PropBase] from the [TState].
  final PropBase<TValue> Function(TState state) selector;

  /// The builder to use when the prop is in a [PropState.success] state.
  final Widget Function(BuildContext context, TValue value) builder;

  /// An optional builder to use when the prop is in a [PropState.loading] state.
  ///
  /// If this is not provided, the widget will throw a [StateError] during loading,
  /// consistent with the behavior of `prop.require`.
  final Widget Function(BuildContext context)? loadingBuilder;

  /// An optional builder to use when the prop is in a [PropState.error] state.
  ///
  /// If this is not provided, the widget will throw a [StateError] when an error is present.
  final Widget Function(BuildContext context, Object error, StackTrace? st)?
  errorBuilder;

  @override
  Widget build(BuildContext context) {
    final prop = context.prop<TWidget, TState, PropBase<TValue>>(selector);

    return ListenableBuilder(
      listenable: prop,
      builder: (context, _) {
        return switch (prop.state) {
          PropState.success => builder(context, prop.require),
          PropState.loading => loadingBuilder?.call(context) ?? _invalidState(),
          PropState.error =>
            errorBuilder?.call(context, prop.error!, prop.stackTrace) ??
                _invalidState(),
          PropState.initial => loadingBuilder?.call(context) ?? _invalidState(),
        };
      },
    );
  }
}

Widget _invalidState() {
  throw StateError(
    '''PropValueBuilder expected the prop to have a value but instead found an invalid state. 
    Please make sure the prop is managed by a ViewController or has custom loading and error builders defined''',
  );
}
