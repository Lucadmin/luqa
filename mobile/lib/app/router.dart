import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/app/app_shell.dart';
import 'package:luqa/app/destination_placeholder.dart';
import 'package:luqa/app/profile_screen.dart';
import 'package:luqa/app/settings_screen.dart';
import 'package:luqa/design_system/component_gallery_screen.dart';
import 'package:luqa/features/today/presentation/today_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final luqaRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: TodayScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/gym',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DestinationPlaceholder(
                  title: 'Gym',
                  icon: Icons.fitness_center_rounded,
                  description:
                      'Fast, one-handed session logging is the next domain slice.',
                ),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/money',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DestinationPlaceholder(
                  title: 'Money',
                  icon: Icons.account_balance_wallet_outlined,
                  description:
                      'Balances, expenses, and settlements will share this shell.',
                ),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/people',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DestinationPlaceholder(
                  title: 'People',
                  icon: Icons.group_outlined,
                  description:
                      'Relationships, groups, and person-led context belong here.',
                ),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/insights',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DestinationPlaceholder(
                  title: 'Insights',
                  icon: Icons.bar_chart_rounded,
                  description:
                      'Reports and the life-in-weeks view will converge here.',
                ),
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/gallery',
      builder: (context, state) => const ComponentGalleryScreen(),
    ),
  ],
);
