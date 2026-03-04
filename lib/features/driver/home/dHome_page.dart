import 'package:flutter/material.dart';
import '../../widgets/AppBar.dart';
import '../../widgets/dNavBar.dart';
import 'widgets/dHome_widgets.dart';

class DHomePage extends StatelessWidget {
  const DHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: const UAppBar(title: "Welcome Driver"),
      bottomNavigationBar: const DNavBar(currentIndex: 0),
      body: const DriverHomeContent(),
    );
  }
}
