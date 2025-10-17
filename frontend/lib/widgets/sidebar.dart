import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final List<String> menuTitles;
  final ValueChanged<int> onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.menuTitles,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: const Color.fromARGB(64, 246, 247, 248),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            'Menú',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 20),
          for (int i = 0; i < menuTitles.length; i++)
            ListTile(
              title: Text(
                menuTitles[i],
                style: TextStyle(
                  color: i == selectedIndex ? Colors.amber : Colors.white70,
                ),
              ),
              onTap: () => onItemSelected(i),
            ),
        ],
      ),
    );
  }
}
