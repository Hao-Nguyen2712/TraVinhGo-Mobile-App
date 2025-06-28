import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/constants.dart';
import '../widget/auth_required_screen.dart';
import 'home/home_screen.dart';
import 'map/map_screen.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int currentIndex = 2;

  static final List<Widget> screens = [
    const MapScreen(),
    // Events screen - Auth required
    const AuthRequiredScreen(
      child: Scaffold(body: Center(child: Text("Events Coming Soon"))),
      message: 'Please login to use this feature',
    ),
    // Home screen - Available to all users
    const HomeScreen(),
    // Favorites screen - Auth required
    const AuthRequiredScreen(
      child: Scaffold(body: Center(child: Text("Favorites Coming Soon"))),
      message: 'Please login to use this feature',
    ),
    // Profile screen - Auth required
    const AuthRequiredScreen(
      child: Scaffold(body: Center(child: Text("Profile Coming Soon"))),
      message: 'Please login to use this feature',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Calculate if keyboard is visible
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return GestureDetector(
        // Dismiss keyboard when tapping outside input fields
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          // Prevent resizing when keyboard appears
          resizeToAvoidBottomInset: false,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(top: 70),
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  currentIndex = 2;
                });
                context.go('/home');
              },
              shape: const CircleBorder(),
              backgroundColor:
                  currentIndex == 2 ? kprimaryColor : Colors.grey.shade400,
              child: Image.asset(
                'assets/images/navigations/home.png',
                color: currentIndex == 2 ? Colors.white : Colors.black,
                scale: 20,
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: Container(
            // Use a container with a fixed position to ensure the navbar stays at the bottom
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: SafeArea(
              // Only apply bottom padding
              top: false,
              left: false,
              right: false,
              bottom: false,
              child: BottomAppBar(
                height: 70,
                elevation: 1,
                color: Colors.white,
                notchMargin: 10,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          currentIndex = 0;
                        });
                        context.go('/map');
                      },
                      icon: Image.asset(
                        'assets/images/navigations/map.png',
                        color: currentIndex == 0
                            ? kprimaryColor
                            : Colors.grey.shade400,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          currentIndex = 1;
                        });
                        context.go('/events');
                      },
                      icon: Image.asset(
                        'assets/images/navigations/event.png',
                        color: currentIndex == 1
                            ? kprimaryColor
                            : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 60),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          currentIndex = 3;
                        });
                        context.go('/favorites');
                      },
                      icon: Image.asset(
                        'assets/images/navigations/love.png',
                        color: currentIndex == 3
                            ? kprimaryColor
                            : Colors.grey.shade400,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          currentIndex = 4;
                        });
                        context.go('/profile');
                      },
                      icon: Image.asset(
                        'assets/images/navigations/user.png',
                        color: currentIndex == 4
                            ? kprimaryColor
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: screens[currentIndex],
        ));
  }
}

// Shell route navigator component that will be used by Go Router
class ShellNavigator extends StatefulWidget {
  final Widget child;
  final String location;

  const ShellNavigator({
    Key? key,
    required this.child,
    required this.location,
  }) : super(key: key);

  @override
  State<ShellNavigator> createState() => _ShellNavigatorState();
}

class _ShellNavigatorState extends State<ShellNavigator> {
  int _getCurrentIndex(String location) {
    if (location.startsWith('/map')) {
      return 0;
    } else if (location.startsWith('/events')) {
      return 1;
    } else if (location.startsWith('/home')) {
      return 2;
    } else if (location.startsWith('/favorites')) {
      return 3;
    } else if (location.startsWith('/profile')) {
      return 4;
    }
    return 2; // Default to home
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(widget.location);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(top: 70),
          child: FloatingActionButton(
            onPressed: () => context.go('/home'),
            shape: const CircleBorder(),
            backgroundColor:
                currentIndex == 2 ? kprimaryColor : Colors.grey.shade400,
            child: Image.asset(
              'assets/images/navigations/home.png',
              color: currentIndex == 2 ? Colors.white : Colors.black,
              scale: 20,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            bottom: false,
            child: BottomAppBar(
              height: 70,
              elevation: 1,
              color: Colors.white,
              notchMargin: 10,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.go('/map'),
                    icon: Image.asset(
                      'assets/images/navigations/map.png',
                      color: currentIndex == 0
                          ? kprimaryColor
                          : Colors.grey.shade400,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.go('/events'),
                    icon: Image.asset(
                      'assets/images/navigations/event.png',
                      color: currentIndex == 1
                          ? kprimaryColor
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 60),
                  IconButton(
                    onPressed: () => context.go('/favorites'),
                    icon: Image.asset(
                      'assets/images/navigations/love.png',
                      color: currentIndex == 3
                          ? kprimaryColor
                          : Colors.grey.shade400,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.go('/profile'),
                    icon: Image.asset(
                      'assets/images/navigations/user.png',
                      color: currentIndex == 4
                          ? kprimaryColor
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: widget.child,
      ),
    );
  }
}
