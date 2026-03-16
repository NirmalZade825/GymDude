import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/blocs/navigation/navigation_bloc.dart';
import '../logic/blocs/navigation/navigation_event.dart';
import '../logic/blocs/navigation/navigation_state.dart';
import './home.dart';
import './progress.dart';
import './workout.dart';
import './profile.dart';
import './add_food_page.dart';


class Bottom extends StatelessWidget {
  const Bottom({super.key});

  static const List<Widget> _pages = [
    Home(),
    Progress(),
    WorkoutPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          extendBody: true, // Allows content to be visible behind the nav bar
          body: Stack(
            children: [
              _pages[state.selectedIndex],
              Align(
                alignment: Alignment.bottomCenter,
                child: _FloatingNavBar(selectedIndex: state.selectedIndex),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;

  const _FloatingNavBar({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      height: 66,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Glass Background Layer
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withOpacity(0.8),
                borderRadius: BorderRadius.circular(33),
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(33),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
          // Nav Items Layer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavBarItem(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                isSelected: selectedIndex == 0,
              ),
              _NavBarItem(
                index: 1,
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart,
                isSelected: selectedIndex == 1,
              ),
              const SizedBox(width: 64),
              _NavBarItem(
                index: 2,
                icon: Icons.fitness_center_outlined,
                activeIcon: Icons.fitness_center,
                isSelected: selectedIndex == 2,
              ),
              _NavBarItem(
                index: 3,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                isSelected: selectedIndex == 3,
              ),
            ],
          ),
          // Floating Center Button Layer (Outside the clipping)
          Positioned(
            top: -32,
            left: 0,
            right: 0,
            child: Center(
              child: _CenterAddButton(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;

  const _NavBarItem({
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<NavigationBloc>().add(ChangeTab(index)),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? const Color(0xFFC0FF00) : Colors.white.withOpacity(0.4),
            size: 24,
          ),
          const SizedBox(height: 6),
          _Indicator(isSelected: isSelected),
        ],
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  final bool isSelected;

  const _Indicator({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFC0FF00) : Colors.transparent,
        shape: BoxShape.circle,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFFC0FF00).withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
    );
  }
}

class _CenterAddButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AddFoodPage()),
        );
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFC0FF00),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC0FF00).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.black,
          size: 36,
        ),
      ),
    );
  }
}
