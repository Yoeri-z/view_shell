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
  ///
  /// Premade builders are [DefaultShellBuilder], [NoAnimationShellBuilder].
  /// Making your own builder can be done by extending [SimpleShellBuilder] or [ShellBuilder].
  final ShellBuilder? shellBuilder;

  /// The builder for the valid state, which is passed as the `child` to the [shellBuilder].
  final Widget Function(BuildContext context, T control) builder;

  @override
  State<ViewShell<T>> createState() => _ViewShellState<T>();
}

class _ViewShellState<T extends ViewShellControl> extends State<ViewShell<T>> {
  late final T control;

  void _stateListener() {
    //the control already checks if the status change warrants a rebuild or not.
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    control = widget.create(context);
    control.registerContextProvider(() => context);
    control.addListener(_stateListener);
  }

  @override
  void dispose() {
    control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shellBuilder =
        widget.shellBuilder ??
        ViewShellConfig.of(context)?.shellBuilder ??
        const DefaultShellBuilder();

    return ChangeNotifierProvider.value(
      value: control,
      builder: (context, _) {
        return shellBuilder.build(
          context,
          control.state,
          () => widget.builder(context, control),
        );
      },
    );
  }
}
