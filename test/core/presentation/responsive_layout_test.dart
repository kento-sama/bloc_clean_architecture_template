import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:clean_bloc/core/presentation/responsive_layout.dart';

void main() {
  testWidgets('switches layouts at the available-width breakpoint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(767, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Widget testApp() => const MaterialApp(
      home: ResponsiveLayout(
        mobileBuilder: _mobileLayout,
        wideBuilder: _wideLayout,
      ),
    );

    await tester.pumpWidget(testApp());
    expect(find.text('Narrow layout'), findsOneWidget);
    expect(find.text('Wide layout'), findsNothing);

    tester.view.physicalSize = const Size(768, 800);
    await tester.pumpWidget(testApp());
    expect(find.text('Narrow layout'), findsNothing);
    expect(find.text('Wide layout'), findsOneWidget);
  });

  testWidgets('supports choosing another Bootstrap breakpoint', (tester) async {
    tester.view.physicalSize = const Size(575, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveLayout(
          breakpoint: BootstrapBreakpoints.sm,
          mobileBuilder: _mobileLayout,
          wideBuilder: _wideLayout,
        ),
      ),
    );
    expect(find.text('Narrow layout'), findsOneWidget);
    tester.view.physicalSize = const Size(576, 800);
    await tester.pumpAndSettle();
    expect(find.text('Wide layout'), findsOneWidget);
    expect(find.text('Narrow layout'), findsNothing);
  });
}

Widget _mobileLayout(BuildContext context) => const Text('Narrow layout');
Widget _wideLayout(BuildContext context) => const Text('Wide layout');
