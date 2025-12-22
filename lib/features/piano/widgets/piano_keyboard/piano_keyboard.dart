import 'package:flutter/material.dart';

class PianoKeyboard extends StatelessWidget {
  const PianoKeyboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Keyboard placeholder',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
