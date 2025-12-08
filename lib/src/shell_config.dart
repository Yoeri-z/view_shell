import 'package:flutter/material.dart';
import 'package:view_shell/view_shell.dart';

/// An inherited widget that provides default configuration for [ViewShell] widgets.
///
/// Descendant `ViewShell` widgets will use the [shellBuilder] provided here
/// unless a specific builder is passed directly to them. This allows for
/// a consistent look and feel for loading/error states across the app.
class ViewShellConfig extends InheritedWidget {
  /// The default [ShellBuilder] to be used by descendant `ViewShell` widgets.
  ///
  /// Premade builders are [DefaultShellBuilder], [NoAnimationShellBuilder].
  /// Making your own builder can be done by extending [SimpleShellBuilder] or [ShellBuilder].
  final ShellBuilder shellBuilder;

  /// Creates a [ViewShellConfig] widget.
  ///
  /// Wrap a part of your widget tree with this to provide a default [shellBuilder].
  ///
  /// Premade builders are [DefaultShellBuilder], [NoAnimationShellBuilder].
  /// Making your own builder can be done by extending [SimpleShellBuilder] or [ShellBuilder].
  const ViewShellConfig({
    super.key,
    required this.shellBuilder,
    required super.child,
  });

  /// Retrieves the nearest [ViewShellConfig] from the widget tree.
  ///
  /// Returns `null` if no ancestor [ViewShellConfig] is found.
  static ViewShellConfig? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ViewShellConfig>();
  }

  @override
  bool updateShouldNotify(ViewShellConfig oldWidget) {
    return oldWidget.shellBuilder != shellBuilder;
  }
}
