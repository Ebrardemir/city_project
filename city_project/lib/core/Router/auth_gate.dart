import 'package:city_project/Features/Login/view/login_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Init/boot_manager.dart';
import '../Router/pending_route.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _bootStarted = false;
  bool _hasServer = true; // TODO: yerel storage'dan oku

  @override
  void initState() {
    super.initState();
    // Yerel async okuma ile server/token bilgilerini oku
    Future.microtask(() async {
      // serverAddress ve token var mı? → state’e yaz
      setState(() {
        _hasServer = true; // örnek: oku ve set et
      });

      if (!_bootStarted) {
        _bootStarted = true;
        if (mounted) {
          context.read<BootManager>().startBoot();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final boot = context.watch<BootManager>();
    final pending = context.watch<PendingRoute>();

    // Force update gate
    if (boot.forceUpdateRequired) {
      return const UpdateGate();
    }

    // Server yoksa
    if (!_hasServer) {
      return const ServerSelectionPage();
    }

    // Auth durumuna göre ekran
    if (boot.authState == AuthState.unknown) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (boot.authState == AuthState.unauthenticated) {
      return const LoginView();
    }

    // Eğer pending hedef varsa ve authenticated’sa yönlendir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final t = pending.consumeIfValid(const Duration(minutes: 10));
      if (t != null && mounted) {
        Navigator.of(context).pushNamed(t.route, arguments: t.params);
      }
    });

    return const HomeSkeleton();
  }
}

/// Dummy ekranlar
class UpdateGate extends StatelessWidget {
  const UpdateGate({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Force Update')));
}

class ServerSelectionPage extends StatelessWidget {
  const ServerSelectionPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Server Selection')));
}

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Home (Skeleton)')));
}
