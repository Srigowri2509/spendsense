import 'package:flutter/material.dart';

class IconPicker extends StatelessWidget {
  final IconData? selectedIcon;
  final ValueChanged<IconData> onIconSelected;

  const IconPicker({
    super.key,
    this.selectedIcon,
    required this.onIconSelected,
  });

  static const List<IconData> financeIcons = [
    Icons.account_balance_wallet,
    Icons.credit_card,
    Icons.savings,
    Icons.attach_money,
    Icons.currency_rupee,
    Icons.payment,
    Icons.account_balance,
    Icons.monetization_on,
  ];

  static const List<IconData> lifestyleIcons = [
    Icons.fitness_center,
    Icons.local_hospital,
    Icons.sports_esports,
    Icons.movie,
    Icons.music_note,
    Icons.book,
    Icons.sports_soccer,
    Icons.spa,
  ];

  static const List<IconData> servicesIcons = [
    Icons.wifi,
    Icons.phone,
    Icons.electrical_services,
    Icons.water_drop,
    Icons.local_gas_station,
    Icons.build,
    Icons.cleaning_services,
    Icons.plumbing,
  ];

  static const List<IconData> otherIcons = [
    Icons.category,
    Icons.star,
    Icons.favorite,
    Icons.pets,
    Icons.school,
    Icons.work,
    Icons.flight,
    Icons.hotel,
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(context, 'Finance', financeIcons),
          const SizedBox(height: 16),
          _buildSection(context, 'Lifestyle', lifestyleIcons),
          const SizedBox(height: 16),
          _buildSection(context, 'Services', servicesIcons),
          const SizedBox(height: 16),
          _buildSection(context, 'Other', otherIcons),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<IconData> icons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: icons.map((icon) {
            final isSelected = selectedIcon == icon;
            return InkWell(
              onTap: () => onIconSelected(icon),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
