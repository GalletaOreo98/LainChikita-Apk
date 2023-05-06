import 'package:flutter/material.dart';

import '../app_colors.dart' as MY_APP_COLORS;
import '../global_vars.dart';

class InventoryScreen extends StatefulWidget {
  final Function callback;
  const InventoryScreen({super.key, required this.callback});

  @override
  MyWidgetState createState() => MyWidgetState();
}

class MyWidgetState extends State<InventoryScreen> {
  void changeAccessory(String newAccessoryName) {
    setState(() {
      accessoryName = newAccessoryName;
    });
    // Llamada a la función de callback
    widget.callback(accessoryName);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MY_APP_COLORS.darkBackground,
      child: ListView.builder(
        itemCount: inventory.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
              onTap: () {
                changeAccessory(inventory[index]['name']);
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  textColor: Colors.white,
                  title: Text(inventory[index]['name']),
                  subtitle: Text('unlocker: ${inventory[index]['unlockedby']}',
                      style: const TextStyle(
                          color: MY_APP_COLORS.secondaryLightText,
                          fontStyle: FontStyle.italic)),
                ),
              ));
        },
      ),
    );
  }
}
