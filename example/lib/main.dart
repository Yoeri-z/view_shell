import 'package:flutter/material.dart';
import 'package:view_shell/view_shell.dart';

class MyShell extends ShellWidget {
  const MyShell({super.key, required super.child});

  @override
  ShellState<MyShell> createState() => _MyShellState();
}

class _MyShellState extends ShellState<MyShell> {
  final counter = SyncProp(0);

  final asyncCounter = FutureProp(
    Future.delayed(Duration(seconds: 1), () => 0),
  );

  final automaticCounter = StreamProp(
    Stream<int>.periodic(Duration(seconds: 1), (nr) => nr),
  );

  @override
  //these are the properties that will be displayed on screen
  List<PropBase> get viewProps => [counter, asyncCounter, automaticCounter];

  void incrementSync() {
    counter.transform((old) => old + 1);
  }

  void incrementAsync() {
    asyncCounter.transform(
      (old) => Future.delayed(Duration(seconds: 1), () => old + 1),
    );
  }

  void resetCounter() {
    automaticCounter.hook(
      Stream<int>.periodic(Duration(seconds: 1), (nr) => nr),
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
      body: MyShell(
        child: Builder(
          builder: (context) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('Synchronous Counter'),
                  PropValueBuilder<MyShell, _MyShellState, int>(
                    selector: (control) => control.counter,
                    builder: (context, value) {
                      return Text(
                        '$value',
                        style: Theme.of(context).textTheme.headlineMedium,
                      );
                    },
                  ),
                  TextButton(
                    onPressed: context
                        .shell<MyShell, _MyShellState>()
                        .incrementSync,
                    child: Text('Increment'),
                  ),
                  SizedBox(height: 50),
                  const Text('Asynchronous Counter'),
                  PropValueBuilder<MyShell, _MyShellState, int>(
                    selector: (control) => control.asyncCounter,
                    builder: (context, value) {
                      return Text(
                        '$value',
                        style: Theme.of(context).textTheme.headlineMedium,
                      );
                    },
                  ),
                  TextButton(
                    onPressed: context
                        .shell<MyShell, _MyShellState>()
                        .incrementAsync,
                    child: Text('Increment'),
                  ),

                  SizedBox(height: 50),
                  const Text('Automatic Counter'),
                  PropValueBuilder<MyShell, _MyShellState, int>(
                    selector: (control) => control.automaticCounter,
                    builder: (context, value) {
                      return Text(
                        '$value',
                        style: Theme.of(context).textTheme.headlineMedium,
                      );
                    },
                  ),
                  TextButton(
                    onPressed: context
                        .shell<MyShell, _MyShellState>()
                        .resetCounter,
                    child: Text('Reset'),
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
