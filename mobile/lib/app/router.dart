import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/app/app_shell.dart';
import 'package:luqa/app/settings_screen.dart';
import 'package:luqa/design_system/component_gallery_screen.dart';
import 'package:luqa/features/gym/presentation/exercise_history_screen.dart';
import 'package:luqa/features/gym/presentation/exercise_library_screen.dart';
import 'package:luqa/features/gym/presentation/gym_history_screen.dart';
import 'package:luqa/features/gym/presentation/gym_locations_screen.dart';
import 'package:luqa/features/gym/presentation/gym_screen.dart';
import 'package:luqa/features/gym/presentation/workout_screen.dart';
import 'package:luqa/features/habits/presentation/habits_screen.dart';
import 'package:luqa/features/insights/presentation/insights_screen.dart';
import 'package:luqa/features/money/presentation/groups_screen.dart';
import 'package:luqa/features/money/presentation/money_screen.dart';
import 'package:luqa/features/money/presentation/money_people_screen.dart';
import 'package:luqa/features/money/presentation/person_ledger_screen.dart';
import 'package:luqa/features/people/presentation/birthdays_screen.dart';
import 'package:luqa/features/people/presentation/people_screen.dart';
import 'package:luqa/features/people/presentation/person_screen.dart';
import 'package:luqa/features/people/presentation/places_screen.dart';
import 'package:luqa/features/today/presentation/timeline_screen.dart';

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
                  const NoTransitionPage(child: TimelineScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/gym',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: GymScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/money',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: MoneyScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/people',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: PeopleScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/insights',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: InsightsScreen()),
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
      redirect: (context, state) => '/settings',
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/habits',
      builder: (context, state) => const HabitsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/gallery',
      builder: (context, state) => const ComponentGalleryScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/gym/workouts/:sessionId',
      builder: (context, state) =>
          WorkoutScreen(sessionId: state.pathParameters['sessionId']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/gym/history',
      builder: (context, state) => const GymHistoryScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/gym/exercises',
      builder: (context, state) => const ExerciseLibraryScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/gym/exercises/:exerciseId/history',
      builder: (context, state) => ExerciseHistoryScreen(
        exerciseId: state.pathParameters['exerciseId']!,
        initialLocationId: state.uri.queryParameters['locationId'],
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/gym/locations',
      builder: (context, state) => const GymLocationsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/money/people',
      builder: (context, state) => const MoneyPeopleScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/money/people/:personId',
      builder: (context, state) =>
          PersonLedgerScreen(personId: state.pathParameters['personId']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/people/birthdays',
      builder: (context, state) => const BirthdaysScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/people/places',
      builder: (context, state) => const PlacesScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/people/:personId',
      builder: (context, state) =>
          PersonScreen(personId: state.pathParameters['personId']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/money/groups',
      builder: (context, state) => const GroupsScreen(),
    ),
  ],
);
