import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:health_checkin/app/dependencies.dart';
import 'package:health_checkin/app/localization/app_localizations.dart';
import 'package:health_checkin/app/router.dart';
import 'package:health_checkin/app/theme.dart';
import 'package:health_checkin/features/session/presentation/session_cubit.dart';
import 'package:health_checkin/features/settings/presentation/locale_cubit.dart';

class ProgramCheckInApp extends StatefulWidget {
  const ProgramCheckInApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<ProgramCheckInApp> createState() => _ProgramCheckInAppState();
}

class _ProgramCheckInAppState extends State<ProgramCheckInApp> {
  
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();

    // Important:
    // Router must be created once. Do not recreate it on locale changes.
    _appRouter = AppRouter(dependencies: widget.dependencies);
  }

  @override
  Widget build(BuildContext context) {

final dependencies = widget.dependencies;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: dependencies),
        RepositoryProvider.value(value: dependencies.programRepository),
        RepositoryProvider.value(value: dependencies.sessionRepository),
        RepositoryProvider.value(value: dependencies.checkInDraftStore),
        RepositoryProvider.value(value: dependencies.observability),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                LocaleCubit(widget.dependencies.plainPreferences)..restore(),
          ),
          BlocProvider(
            create: (_) =>
                SessionCubit(widget.dependencies.sessionRepository)..restore(),
          ),
        ],
        child: BlocBuilder<LocaleCubit, LocaleState>(
          builder: (context, localeState) {
            final router = _appRouter.router;
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Program Check-in',
              theme: AppTheme.light,
              locale: localeState.locale,
              supportedLocales: AppStrings.supportedLocales,
              localizationsDelegates: const [
                AppStrings.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }
}
