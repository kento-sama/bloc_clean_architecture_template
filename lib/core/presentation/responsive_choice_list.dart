import 'package:material_ui/material_ui.dart';
import 'package:clean_bloc/core/presentation/responsive_layout.dart';

/// Shows selectable choices as a list on narrow screens and a grid when wide.
class ResponsiveChoiceList extends StatelessWidget {
  const ResponsiveChoiceList({
    required this.choices,
    required this.isSelected,
    required this.onChanged,
    required this.isSaving,
    super.key,
  });

  final List<String> choices;
  final bool Function(String choice) isSelected;
  final void Function(String choice, bool selected) onChanged;
  final bool isSaving;

  @override
  Widget build(BuildContext context) => ResponsiveLayout(
    mobileBuilder: (_) => ListView(
      padding: const EdgeInsets.all(16),
      children: [for (final choice in choices) _tile(choice)],
    ),
    wideBuilder: (_) => GridView.extent(
      maxCrossAxisExtent: 360,
      childAspectRatio: 4,
      padding: const EdgeInsets.all(24),
      children: [for (final choice in choices) Card(child: _tile(choice))],
    ),
  );

  Widget _tile(String choice) => CheckboxListTile(
    value: isSelected(choice),
    title: Text(choice),
    controlAffinity: ListTileControlAffinity.leading,
    onChanged: isSaving
        ? null
        : (selected) => onChanged(choice, selected == true),
  );
}
