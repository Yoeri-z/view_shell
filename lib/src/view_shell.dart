import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:view_shell/src/shell_builder.dart';
import 'package:view_shell/src/shell_config.dart';
import 'package:view_shell/src/shell_control.dart';

/// A widget that builds a different UI based on the status of a [ViewShellControl].
class ViewShell<T extends ViewShellControl> extends StatefulWidget {
  const ViewShell({
    super.key,
    required this.create,
    this.shellBuilder,
    required this.builder,
  });

  /// A function that creates the [ViewShellControl].
  final T Function(BuildContext context) create;

  /// The builder responsible for constructing the UI based on the shell's current state.
  ///
  /// If not provided, it will fall back to the `shellBuilder` from the nearest
  /// [ViewShellConfig] ancestor, or finally to [DefaultShellBuilder].
  final ShellBuilder? shellBuilder;

  /// The builder for the valid state, which is passed as the `child` to the [shellBuilder].
  final Widget Function(BuildContext context, T control) builder;

  @override
  State<ViewShell<T>> createState() => _ViewShellState<T>();
}

class _ViewShellState<T extends ViewShellControl> extends State<ViewShell<T>> {
  late final T control;

  final builderKey = UniqueKey();

  void _stateListener() {
    // Rebuild whenever the controller notifies. The controller is responsible
    // for deciding when a status change is significant enough to warrant a rebuild.
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    control = widget.create(context);
    control.addListener(_stateListener);
  }

  @override
  void dispose() {
    control.removeListener(_stateListener);
    control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The effective ShellBuilder is chosen with a clear priority:
    // 1. Direct widget parameter
    // 2. Value from ViewShellConfig ancestor
    // 3. Static default
    final shellBuilder =
        widget.shellBuilder ??
        ViewShellConfig.of(context)?.shellBuilder ??
        DefaultShellBuilder();

    shellBuilder.key = builderKey;

    return ChangeNotifierProvider.value(
      value: control,
      child: Builder(
        builder: (context) {
          return shellBuilder.build(
            context,
            control.state,
            () => widget.builder(context, control),
          );
        },
      ),
    );
  }
}
