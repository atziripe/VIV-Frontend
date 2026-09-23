import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/viv_theme.dart';
import 'router/app_router.dart';

class VivApp extends ConsumerWidget {
  const VivApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'VIV',
      debugShowCheckedModeBanner: false,
      theme: VivTheme.light(),
      darkTheme: VivTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
