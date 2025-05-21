import 'package:flutter/material.dart';

class EmptyBottomBar extends StatelessWidget {
  const EmptyBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      elevation: 10,
      color: Colors.blue,
      child: SizedBox(height: 30),
    );
  }
}
