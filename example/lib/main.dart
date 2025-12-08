import 'package:flutter/material.dart';
import 'package:view_shell/view_shell.dart';

Future<bool?> showConfimationDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        child: SizedBox(
          width: 200,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Are you sure you want to reset this stream?",
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('No'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Yes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class CounterShell extends Shell {
  final counter = SyncProp(0);

  final asyncCounter = FutureProp(
    Future.delayed(const Duration(seconds: 1), () => 0),
  );

  final automaticCounter = StreamProp(
    Stream<int>.periodic(const Duration(seconds: 1), (nr) => nr),
  );

  @override
  //these are the properties that will be displayed on screen
  List<PropBase> get viewProps => [counter, asyncCounter, automaticCounter];

  void incrementSync() {
    counter.transform((old) => old + 1);
  }

  void incrementAsync() {
    asyncCounter.transform(
      (old) => Future.delayed(const Duration(seconds: 1), () => old + 1),
    );
  }

  void resetCounter() async {
    final allowed = await shellRun(showConfimationDialog);

    if (allowed == null || !allowed) return;

    automaticCounter.hook(
      Stream<int>.periodic(const Duration(seconds: 1), (nr) => nr),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: ShellWidget<CounterShell>(
        create: (context) => CounterShell(),
        child: Builder(
          builder: (context) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('Synchronous Counter'),
                  PropValueBuilder<CounterShell, int>(
                    selector: (shell) => shell.counter,
                    builder: (context, value) {
                      return Text(
                        '$value',
                        style: Theme.of(context).textTheme.headlineMedium,
                      );
                    },
                  ),
                  TextButton(
                    onPressed: context.shell<CounterShell>().incrementSync,
                    child: const Text('Increment'),
                  ),
                  const SizedBox(height: 50),
                  const Text('Asynchronous Counter'),
                  PropValueBuilder<CounterShell, int>(
                    selector: (shell) => shell.asyncCounter,
                    builder: (context, value) {
                      return Text(
                        '$value',
                        style: Theme.of(context).textTheme.headlineMedium,
                      );
                    },
                  ),
                  TextButton(
                    onPressed: context.shell<CounterShell>().incrementAsync,
                    child: const Text('Increment'),
                  ),
                  const SizedBox(height: 50),
                  const Text('Automatic Counter'),
                  PropValueBuilder<CounterShell, int>(
                    selector: (shell) => shell.automaticCounter,
                    builder: (context, value) {
                      return Text(
                        '$value',
                        style: Theme.of(context).textTheme.headlineMedium,
                      );
                    },
                  ),
                  TextButton(
                    onPressed: context.shell<CounterShell>().resetCounter,
                    child: const Text('Reset'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
