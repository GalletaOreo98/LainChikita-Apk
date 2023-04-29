import 'package:flutter/material.dart';

import '../global_vars.dart';

class InventoryScreen extends StatefulWidget {
  final Function callback;
  const InventoryScreen({super.key, required this.callback});

  @override
  MyWidgetState createState() => MyWidgetState();
}

class MyWidgetState extends State<InventoryScreen> {
  void _incrementCounter(String newAccessoryName) {
    setState(() {
      accessoryName = newAccessoryName;
    });
    // Llamada a la función de callback
    widget.callback(accessoryName);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView.builder(
        itemCount: inventory.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
              onTap: () {
                _incrementCounter(inventory[index]['name']);
              },
              child: ListTile(
                title: Text(inventory[index]['name']),
                subtitle: Text('By: ${inventory[index]['unlockedby']}'),
              ));
        },
      ),
    );
  }
}
