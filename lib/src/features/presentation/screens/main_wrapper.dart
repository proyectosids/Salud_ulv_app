import 'dart:async';

// import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sensors/geolocator_sensor.dart';
import 'package:salud_ulv_app/src/core/models/roles.dart';
import 'package:salud_ulv_app/src/core/repositories/services/exercise_permission.dart';
import 'package:salud_ulv_app/src/core/services/current_location_cache.dart';
import 'package:salud_ulv_app/src/core/usecase/auth/check_auth_usecase.dart';
import 'package:salud_ulv_app/src/core/data/source/token/current_user_service.dart';
import 'package:salud_ulv_app/src/core/data/source/token/token.dart';
import 'package:salud_ulv_app/src/core/data/source/token/token_storage.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/user_repo.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_state.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/bottom_bar_bloc/bottom_bar_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/exercise%20tracking/exercise_catalog_page.dart';
// import 'package:salud_ulv_app/src/features/presentation/screens/groups/join_group_page.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/home/home_admin.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/home/home_member.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/profile/profile_page.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/records/main_records_page.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/shadows.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';

class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => BottomBarBloc(initialIndex: 1)),

        BlocProvider(
          create: (context) => CheckRoleBLoc(
            checkAuthUseCase: CheckAuthUsecase(
              TokenStorage(),
              TokenHandler(),
              CurrentUserSession(),
              UserLocalRepo(),
            ),
          ),
        ),
      ],

      child: _MainWrapper(),
    );
  }
}

class _MainWrapper extends StatefulWidget {
  const _MainWrapper();

  @override
  State<_MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<_MainWrapper> {
  late PageController pageController;
  // late List<Widget> topLevelPages;

  static const int _initialIndex = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareExercisePermissionsAndLocation());
    context.read<CheckRoleBLoc>().add(CheckRoleEvent());
    pageController = PageController(initialPage: _initialIndex);
    context.read<BottomBarBloc>().add(ChangeSelectedIndex(_initialIndex));
  }

  Future<void> _prepareExercisePermissionsAndLocation() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    final permission = await context
        .read<IExercisePermissionService>()
        .requestWhenNeeded(requiresLocation: true);
    if (!mounted || !permission.isGranted) return;
    await CurrentLocationCache.instance.warmUp(GeolocatorSensor());
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  // List<Widget> pagesForRole(UserRole role) {

  //   switch (role) {
  //     case UserRole.member:
  //       return const [
  //         ProfileMainPage(),
  //         MemberHomePage(),
  //         MainProgressPage(),
  //       ];
  //     case UserRole.admin:
  //       return const [
  //         ProfileMainPage(),
  //         AdminHomePage(),
  //         // MainProgressPage(),
  //         // AdminPanelPage(), // example — give admin something extra if relevant
  //       ];
  //   }
  // }

  void onPageChange(int page) {
    BlocProvider.of<BottomBarBloc>(context).add(ChangeSelectedIndex(page));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckRoleBLoc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        debugPrint(
          'In screen ${state.toString()} [--------------------------DEBUG--------------------------]',
        );

        if (state is CheckAuthenticated) {
          final tabs = tabsForRole(
            state.role,
            onActivitySelected: () {
              context.read<BottomBarBloc>().add(ChangeSelectedIndex(1));
              pageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              );
            },
          );
          final showFab = state.role == UserRole.member;

          return BlocBuilder<BottomBarBloc, int>(
            builder: (context, _) => Scaffold(
              backgroundColor: context.colors.background,
              bottomNavigationBar: _mainWrapperBottomNavBar(
                context,
                tabs,
                showFab,
              ),
              body: _mainWrapperBody(tabs),
            ),
          );
        }
        if (state is Unauthenticated) {
          return const Scaffold(
            body: Center(child: Text('Could not load your account.')),
          );
        }

        // debugPrint('Navigador bar user: ${state.role} /////////////////////////////////');
        return Center(child: Text('An error happened, sorry.'));
      },
    );
  }

  PageView _mainWrapperBody(List<RoleTab> tabs) {
    return PageView(
      onPageChanged: (int page) => onPageChange(page),
      controller: pageController,
      children: tabs.map((t) => t.page).toList(),
    );
  }

  Widget _bottomAppBarItem(
    BuildContext context, {
    required IconData defaultIcon,
    required int page,
    required String label,
    required IconData filledIcon,
  }) {
    final isSelected = context.watch<BottomBarBloc>().state == page;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBackground = isDark
        ? context.colors.onTertiary
        : context.colors.primaryContainer;
    final selectedForeground = isDark
        ? context.colors.textPrimary
        : context.colors.onPrimaryContainer;
    final unselectedForeground = context.colors.onTertiary;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          context.read<BottomBarBloc>().add(ChangeSelectedIndex(page));

          pageController.animateToPage(
            page,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? selectedBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected ? context.shadows.smBoxShadow : null,
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? filledIcon : defaultIcon,
                color: isSelected ? selectedForeground : unselectedForeground,
                size: 24,
              ),
              const SizedBox(height: 2),

              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: GoogleFonts.aBeeZee(
                      color: isSelected
                          ? selectedForeground
                          : unselectedForeground,
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mainWrapperBottomNavBar(
    BuildContext context,
    List<RoleTab> tabs,
    bool showFab,
  ) {
    return SafeArea(
      top: false,
      bottom: true,
      minimum: const EdgeInsets.only(bottom: 15),
      child: SizedBox(
        height: 88,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Bottom navigation bar
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: context.colors.tertiary,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: context.shadows.bigBoxShadow,
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 6,
                    // right: showFab ? 70 : 6,
                    top: 0,
                    bottom: 0,
                  ),
                  child: Row(
                    children: [
                      for (int i = 0; i < tabs.length; i++)
                        _bottomAppBarItem(
                          context,
                          defaultIcon: tabs[i].defaultIcon,
                          page: i,
                          label: tabs[i].label,
                          filledIcon: tabs[i].filledIcon,
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Exercise button
            // if (showFab)
            //   Positioned(
            //     // left: 0,
            //     right: 125,
            //     bottom: 80,
            //     child: _exerciseButton(context),
            //   ),
          ],
        ),
      ),
    );
  }

  // Widget _exerciseButton(BuildContext context) {
  //   return Material(
  //     color: Colors.transparent,
  //     child: Ink(
  //       decoration: BoxDecoration(
  //         color: context.colors.primary,
  //         borderRadius: BorderRadius.circular(20),
  //         // boxShadow: [
  //         //   BoxShadow(
  //         //     color: Colors.black.withOpacity(0.18),
  //         //     blurRadius: 10,
  //         //     offset: const Offset(0, 4),
  //         //   ),
  //         // ],
  //       ),
  //       child: InkWell(
  //         onTap: () {
  //           Navigator.push(
  //             context,
  //             MaterialPageRoute(
  //               builder: (context) => WalkExerciseMainPage(),
  //             ),
  //           );
  //         },
  //         borderRadius: BorderRadius.circular(20),
  //         child: const SizedBox(
  //           width: 52,
  //           height: 48,
  //           child: Center(
  //             child: Icon(
  //               Icons.play_arrow_rounded,
  //               size: 30,
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}

class RoleTab {
  const RoleTab({
    required this.page,
    required this.defaultIcon,
    required this.filledIcon,
    required this.label,
  });

  final Widget page;
  final IconData defaultIcon;
  final IconData filledIcon;
  final String label;
}

List<RoleTab> tabsForRole(UserRole role, {VoidCallback? onActivitySelected}) {
  switch (role) {
    case UserRole.member:
      return [
        RoleTab(
          page: MemberHomePage(onActivitySelected: onActivitySelected),
          defaultIcon: Icons.home_outlined,
          filledIcon: Icons.home,
          label: 'Inicio',
        ),
        RoleTab(
          page: const ExerciseCatalogPage(),
          defaultIcon: Icons.play_arrow_outlined,
          filledIcon: Icons.play_arrow,
          label: 'Actividades',
        ),
        RoleTab(
          page: const MainProgressPage(),
          defaultIcon: Icons.bar_chart_outlined,
          filledIcon: Icons.bar_chart,
          label: 'Progreso',
        ),
        // RoleTab(
        //   page: const MemberGroupPage(),
        //   defaultIcon: Icons.people_alt_outlined,
        //   filledIcon: Icons.people_alt,
        //   label: 'Grupos',
        // ),
      ];

    case UserRole.admin:
      return [
        RoleTab(
          page: const ProfileMainPage(),
          defaultIcon: Icons.person,
          filledIcon: Icons.person_rounded,
          label: 'Profile',
        ),
        RoleTab(
          page: const AdminHomePage(),
          defaultIcon: Icons.home,
          filledIcon: Icons.home_filled,
          label: 'Home',
        ),
        // RoleTab(
        //   page: const MainProgressPage(),
        //   defaultIcon: Icons.bar_chart,
        //   filledIcon: Icons.bar_chart_rounded,
        //   label: 'Progress',
        // ),
        // RoleTab(
        //   page: const AdminPanelPage(),
        //   defaultIcon: Icons.admin_panel_settings,
        //   filledIcon: Icons.admin_panel_settings,
        //   label: 'Admin',
        // ),
      ];
  }
}
