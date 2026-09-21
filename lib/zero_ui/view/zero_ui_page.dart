// lib/zero_ui/view/zero_ui_page.dart
import 'package:beacon_os/zero_ui/cubit/zero_ui_cubit.dart';
import 'package:beacon_os/zero_ui/view/zero_ui_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class ZeroUiPage extends StatelessWidget {
  const ZeroUiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ZeroUiCubit(
        repository: context.read<LauncherRepository>(),
      ),
      child: const ZeroUiView(),
    );
  }
}
