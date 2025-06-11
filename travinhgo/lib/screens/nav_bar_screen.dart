import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'home/home_screen.dart';
import 'map/map_screen.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int cuttentIndex = 2;
  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  void _initializeScreens() {
    screens = [
      MapScreen(
          key: UniqueKey()), // Using UniqueKey to force rebuild on navigation
      const Scaffold(body: Center(child: Text("Events Coming Soon"))),
      const HomeScreen(),
      const Scaffold(body: Center(child: Text("Favorites Coming Soon"))),
      const Scaffold(body: Center(child: Text("Profile Coming Soon"))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 70),
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              cuttentIndex = 2;
            });
          },
          shape: const CircleBorder(),
          backgroundColor:
              cuttentIndex == 2 ? kprimaryColor : Colors.grey.shade400,
          child: Image.asset(
            'assets/images/navigations/home.png',
            color: cuttentIndex == 2 ? Colors.white : Colors.black,
            scale: 20,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 70,
        elevation: 1,
        color: Colors.white,
        shape: CircularNotchedRectangle(),
        notchMargin: 10,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  // If already on map screen, reinitialize all screens
                  if (cuttentIndex == 0) {
                    _initializeScreens();
                  }
                  cuttentIndex = 0;
                });
              },
              icon: Image.asset(
                'assets/images/navigations/map.png',
                color: cuttentIndex == 0 ? kprimaryColor : Colors.grey.shade400,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  cuttentIndex = 1;
                });
              },
              icon: Image.asset(
                'assets/images/navigations/event.png',
                color: cuttentIndex == 1 ? kprimaryColor : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 60),
            IconButton(
              onPressed: () {
                setState(() {
                  cuttentIndex = 3;
                });
              },
              icon: Image.asset(
                'assets/images/navigations/love.png',
                color: cuttentIndex == 3 ? kprimaryColor : Colors.grey.shade400,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  cuttentIndex = 4;
                });
              },
              icon: Image.asset(
                'assets/images/navigations/user.png',
                color: cuttentIndex == 4 ? kprimaryColor : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
      body: screens[cuttentIndex],
    );
  }
}
