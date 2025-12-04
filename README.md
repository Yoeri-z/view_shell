# view_shell

A minimal, intuitive, and boilerplate-free state management library for Flutter. `view_shell` gracefully handles loading, error, and valid states for your widgets, ensuring a clean architecture and a robust user experience.

The core idea is to wrap your page or complex widget in a `ViewShell`, which observes a set of properties (`Prop`s). The `ViewShell` automatically displays a loading indicator, an error message, or your UI, based on the collective state of these properties.

---

## Core Concepts

1.  **`Prop<T>`**: The heart of the library. A `Prop` is a reactive container for a value that can be in a loading, error, or valid state. It simplifies handling data from asynchronous operations like API calls or database queries. There are several types of `Prop`s to fit different use cases.

2.  **`ViewShellControl`**: A `ChangeNotifier` that groups one or more `Prop`s. It listens to its props and computes a single, overall `ViewState` (e.g., `PendingView`, `ErrorView`, `ValidView`).

3.  **`ViewShell`**: A widget that uses a `ViewShellControl` to decide what to render. It takes care of showing a loading UI while data is fetching, an error UI on failure, and your main widget only when all required data is valid and available.

4.  **`PropValueBuilder`**: A convenient widget for accessing the **value** of a `Prop` from within a `ViewShell`'s `builder`. It ensures you are safely accessing a valid value.
    
5.  **`PropBuilder`**: A widget that listens to a specific `Prop` and provides the **`Prop` object itself** to its builder. This is useful for building UI that needs to react to a prop's specific state (e.g., `isLoading`).

## Features

- ✅ **Declarative & Simple**: No boilerplate. Just define your props and let `ViewShell` handle the UI states.
- 🚀 **Asynchronous Operations Made Easy**: Built-in support for `Future` and `Stream` based properties.
- 🛠️ **Rich Prop Ecosystem**: Specialized props for common patterns like debouncing, pagination, and synchronous state.
- 🎨 **Customizable UI**: Easily replace the default loading and error widgets with your own, either globally or locally.
- ⛑️ **Type-Safe & Null-Safe**: Ensures that you only access data when it's valid, preventing runtime errors.

## Getting Started

Let's build a simple view that fetches data from a future and displays it.

### 1. Define a Controller

Create a class that extends `ViewShellControl` and define the properties your view needs. Here, we'll use a `FutureProp` to wrap an asynchronous call.

```dart
// my_page_control.dart
import 'package:view_shell/view_shell.dart';

class MyPageControl extends ViewShellControl {
  late final Prop<String> titleProp;

  MyPageControl() {
    titleProp = FutureProp(
      // Simulate a network request
      Future.delayed(const Duration(seconds: 2), () => 'Hello from the Future!'),
    );
  }

  // The ViewShell will monitor the props listed here.
  @override
  List<PropBase> get viewProps => [titleProp];
}
```

### 2. Build the UI with `ViewShell`

Wrap your page's UI with the `ViewShell` widget. It will automatically create your controller and handle the different states.

```dart
// my_page.dart
import 'package:flutter/material.dart';
import 'package:view_shell/view_shell.dart';
import 'my_page_control.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ViewShell Example')),
      body: ViewShell(
        // The `create` function provides the controller to the widget tree.
        create: (context) => MyPageControl(),
        // The `builder` is called only when all `viewProps` are valid.
        builder: (context, control) {
          // Use a PropValueBuilder to safely access the prop's value.
          return PropValueBuilder<MyPageControl, String>(
            selector: (ctrl) => ctrl.titleProp,
            builder: (context, title) {
              // `title` is the guaranteed valid String value from your Future.
              return Center(
                child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
              );
            },
          );
        },
      ),
    );
  }
}
```

When `MyPage` is built, `ViewShell` will:
1.  Create `MyPageControl`.
2.  The `FutureProp` starts executing its future.
3.  `ViewShell` sees that `titleProp` is not yet valid and shows a loading indicator (by default, a `CircularProgressIndicator`).
4.  After 2 seconds, the future completes, `titleProp` becomes valid.
5.  `ViewShell` rebuilds and calls its `builder`, displaying the `Center` widget with the fetched title.

## Global Configuration (`ViewShellConfig`)

To avoid specifying a `shellBuilder` on every `ViewShell`, you can provide a default one for your entire app or a specific widget subtree using `ViewShellConfig`. This is the recommended approach for defining a consistent look and feel.

Wrap your `MaterialApp` or another top-level widget with `ViewShellConfig`:

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:view_shell/view_shell.dart';

// 1. Define your custom shell builder
class MyCustomShellBuilder extends ShellBuilder {
  const MyCustomShellBuilder();

  @override
  Widget build(BuildContext context, ViewState state, ValidViewBuilder builder) {
    return switch (state) {
      ValidView() => builder(),
      ErrorView(error: final err) => Center(child: Text('Oops: $err')),
      PendingView() => const Center(child: Text('Fetching data, please wait...')),
    };
  }
}

void main() {
  runApp(
    // 2. Provide it to the widget tree
    const ViewShellConfig(
      shellBuilder: MyCustomShellBuilder(),
      child: MyApp(),
    ),
  );
}
```
Now, all descendant `ViewShell` widgets will automatically use `MyCustomShellBuilder` without needing the `shellBuilder` property set locally.

## Usage

### `Prop` Types

`view_shell` provides several `Prop` variants for different scenarios.

| Prop                  | Description                                                                                             |
| --------------------- | ------------------------------------------------------------------------------------------------------- |
| **`Prop<T>`**         | The general-purpose prop. Manually manage loading, success, and error states using `run()` or `set()`.    |
| **`FutureProp<T>`**   | A declarative prop that is driven by a `Future`. Automatically handles loading/error states.              |
| **`StreamProp<T>`**   | Subscribes to a `Stream` and updates its value with each new event.                                     |
| **`SyncProp<T>`**     | A lightweight synchronous prop. Holds a value and a validity flag, but no loading or error states.        |
| **`DebouncedProp<T>`**| A prop that debounces an operation, useful for live search fields.                                        |
| **`PaginatedProp<T>`**| Manages paginated data where one page is loaded at a time. Provides helpers like `fetchNextPage()`.      |

### `PropBuilder` vs. `PropValueBuilder`

You have two builder widgets to choose from when working with props.

#### `PropValueBuilder`
Use this widget when you are **inside a `ViewShell`'s `builder`** and you just need the unwrapped, valid value of a prop. It assumes the `ViewShell` has already guaranteed the prop is valid.

```dart
// Use when you know the prop is valid and just want the value.
ViewShell(
  create: (_) => MyControl(),
  builder: (context, control) {
    return PropValueBuilder<MyControl, String>(
      selector: (c) => c.myProp,
      builder: (context, value) {
        // `value` is the String, not the Prop<String>
        return Text(value);
      },
    );
  },
)
```

#### `PropBuilder`
Use this widget when you need to react to the **different states of a single prop** (e.g., `isLoading`, `hasError`). It provides the entire `Prop` object to the builder and rebuilds whenever the prop's state changes. This is useful for creating interactive components like buttons that show a loading spinner.

```dart
// In your control
class MyControl extends ViewShellControl {
  final resultsProp = Prop<String>.empty();
  void fetchData() {
    resultsProp.run(() => Future.delayed(Duration(seconds: 1), () => "Data loaded!"));
  }
  @override
  List<PropBase> get viewProps => []; // Not used for this example
}

// In your UI, maybe outside a ViewShell
PropBuilder<MyControl, Prop<String>>(
  selector: (c) => c.resultsProp,
  builder: (context, prop) {
    // `prop` is the `resultsProp` object itself.
    return Column(
      children: [
        ElevatedButton(
          // Disable button while loading
          onPressed: prop.isLoading ? null : context.read<MyControl>().fetchData,
          child: prop.isLoading
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
              : Text('Fetch Data'),
        ),
        if (prop.hasError) Text('Error: ${prop.error}'),
        if (prop.valid) Text('Result: ${prop.require}'),
      ],
    );
  },
)
```

### Customizing UI States
The `ShellBuilder` used by a `ViewShell` is chosen with the following priority:
1.  The `shellBuilder` parameter passed directly to the `ViewShell` widget.
2.  The `shellBuilder` from an ancestor `ViewShellConfig` widget.
3.  The default `DefaultShellBuilder`.

This means you can override a global `shellBuilder` for a specific `ViewShell` when needed.

```dart
// Assuming you have a global ViewShellConfig set...

// This ViewShell will use the special "fancy" builder
ViewShell(
  create: (context) => MyPageControl(),
  shellBuilder: const FancyLoadingBuilder(), // Local override
  builder: (context, control) {
    // ... your valid UI
  },
)

// This ViewShell will fall back to the builder from ViewShellConfig
ViewShell(
  create: (context) => AnotherControl(),
  builder: (context, control) {
    // ... your valid UI
  },
)
```

### Example: Multiple Props

A `ViewShell` is valid only when **all** of its `viewProps` are valid. This is perfect for pages that need data from multiple sources.

```dart
class DashboardControl extends ViewShellControl {
  late final Prop<User> userProp;
  late final Prop<List<Notification>> notificationsProp;

  DashboardControl() {
    userProp = FutureProp(_api.fetchUserProfile());
    notificationsProp = FutureProp(_api.fetchNotifications());
  }

  @override
  List<PropBase> get viewProps => [userProp, notificationsProp];
}

// The ViewShell's `builder` will only be called after BOTH futures complete successfully.
ViewShell(
  create: (context) => DashboardControl(),
  builder: (context, control) {
    return Column(
      children: [
        PropValueBuilder<DashboardControl, User>(
          selector: (c) => c.userProp,
          builder: (context, user) => Text('Welcome, ${user.name}'),
        ),
        PropValueBuilder<DashboardControl, List<Notification>>(
          selector: (c) => c.notificationsProp,
          builder: (context, notifications) => Text('You have ${notifications.length} notifications.'),
        ),
      ],
    );
  },
)
```

### Example: Debounced Search

Use `DebouncedProp` to implement a search field that only triggers a network request after the user stops typing.

```dart
// In your control:
class SearchControl extends ViewShellControl {
  final DebouncedProp<List<String>> resultsProp;

  SearchControl() : resultsProp = DebouncedProp(initialValue: []);

  void search(String query) {
    // The `debounce` method schedules the future to run after the duration.
    // If called again before it runs, the timer is reset.
    resultsProp.debounce(() => _api.search(query));
  }

  @override
  List<PropBase> get viewProps => [resultsProp];
}

// In your UI:
TextField(
  onChanged: (text) => context.read<SearchControl>().search(text),
)
```

## API Reference

### Main Widgets & Classes
- **`ViewShell`**: The primary widget that manages UI states.
- **`ViewShellConfig`**: An `InheritedWidget` to provide a default `ShellBuilder` to descendant `ViewShell`s.
- **`ViewShellControl`**: The controller that holds and manages `Prop`s.
- **`PropValueBuilder`**: A widget to safely access the **value** of a valid `Prop`.
- **`PropBuilder`**: A widget that provides the entire **`Prop` object** to its builder, allowing UI to react to prop state changes.
- **`ShellBuilder`**: An abstract class for building custom UI for different `ViewState`s.
- **`DefaultShellBuilder`**: The default implementation of `ShellBuilder`.

### State & Property Classes
- **`ViewState`**: A sealed class representing the shell's state (`ValidView`, `ErrorView`, `PendingView`).
- **`PropBase<T>`**: The abstract base class for all props.
- **`Prop<T>`** and its variants: `FutureProp`, `StreamProp`, `SyncProp`, `DebouncedProp`, `PaginatedProp`.

This package is designed to be small, understandable, and extensible. Dive into the source code to see how you can create your own custom `Prop`s or `ShellBuilder`s.
