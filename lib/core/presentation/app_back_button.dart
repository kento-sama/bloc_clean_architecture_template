import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Pops when a previous route exists, otherwise navigates to a safe fallback.
class AppBackButton extends StatelessWidget {
  const AppBackButton({required this.fallback, super.key});

  final String fallback;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    return BackButton(
      onPressed: () {
        if (router != null && router.canPop()) {
          context.pop();
          return;
        }
        if (router != null) {
          context.go(fallback);
          return;
        }
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        }
      },
    );
  }
}
