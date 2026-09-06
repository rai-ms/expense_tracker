import 'package:flutter/material.dart';

/// Base class for Widget Views in Clean Architecture
/// [T] is the type of the WidgetView
/// [S] is the State type of the Controller
abstract class WidgetView<T extends WidgetView<T, S>, S extends State>
    extends StatelessWidget {
  final S ctr;

  const WidgetView(this.ctr, {super.key});

  @override
  Widget build(BuildContext context);
}

/// Stateful WidgetView base for more complex scenarios
abstract class StatefulWidgetView<T extends StatefulWidget>
    extends StatelessWidget {
  final State<T> state;

  const StatefulWidgetView(this.state, {super.key});

  @override
  Widget build(BuildContext context);
}
