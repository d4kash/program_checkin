import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:health_checkin/app/dependencies.dart';
import 'package:health_checkin/app/localization/app_localizations.dart';
import 'package:health_checkin/features/checkin/presentation/checkin_cubit.dart';
import 'package:health_checkin/features/checkin/presentation/checkin_screen.dart';
import 'package:health_checkin/features/history/presentation/history_cubit.dart';
import 'package:health_checkin/features/history/presentation/history_screen.dart';
import 'package:health_checkin/features/program/presentation/dashboard_cubit.dart';
import 'package:health_checkin/features/program/presentation/dashboard_screen.dart';

class AppRoute {
  static const dashboard = 'dashboard';
  static const checkIn = 'check-in';
  static const history = 'history';
}

class AppRouter {
  AppRouter({required this.dependencies});

  final AppDependencies dependencies;

  late final GoRouter router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/dashboard',
        name: AppRoute.dashboard,
        builder: (context, state) => BlocProvider(
          create: (_) => DashboardCubit(
            repository: dependencies.programRepository,
            observability: dependencies.observability,
          )..load(),
          child: const DashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/check-in',
        name: AppRoute.checkIn,
        builder: (context, state) {
          final source = state.uri.queryParameters['source'];
          if (source != null && source != 'dashboard' && source != 'history') {
            return RecoverableRouteErrorScreen(
              message: AppStrings.of(context).invalidRouteData,
            );
          }
          return BlocProvider(
            create: (_) => CheckInCubit(
              repository: dependencies.programRepository,
              sessionRepository: dependencies.sessionRepository,
              draftStore: dependencies.checkInDraftStore,
              clock: dependencies.clock,
              observability: dependencies.observability,
            ),
            child: const CheckInScreen(),
          );
        },
      ),
      GoRoute(
        path: '/history',
        name: AppRoute.history,
        builder: (context, state) => BlocProvider(
          create: (_) => HistoryCubit(
            repository: dependencies.programRepository,
            observability: dependencies.observability,
          )..load(),
          child: const HistoryScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) => RecoverableRouteErrorScreen(
      message: AppStrings.of(context).routeNotFound,
    ),
  );
}

class RecoverableRouteErrorScreen extends StatelessWidget {
  const RecoverableRouteErrorScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.routeError)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.route_outlined, size: 48),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.goNamed(AppRoute.dashboard),
                child: Text(strings.backToDashboard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
