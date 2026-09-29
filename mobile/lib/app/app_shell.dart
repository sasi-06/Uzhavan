import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/app_state.dart';
import '../features/farmer/farmer_shell.dart';
import '../features/owner/owner_shell.dart';

/// Routes to the correct shell based on the active role context (Farmer / Owner).
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final activeRole = context.watch<AppState>().activeRole;
    if (activeRole == 'owner') return const OwnerShell();
    return const FarmerShell();
  }
}
