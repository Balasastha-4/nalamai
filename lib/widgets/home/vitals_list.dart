import 'package:flutter/material.dart';
import '../../models/vital.dart';
import 'vital_card.dart';

class VitalsList extends StatelessWidget {
  final List<Vital> vitals;

  const VitalsList({super.key, required this.vitals});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'Vitals',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150, // Fixed height for scrolling cards
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: vitals.length,
            itemBuilder: (context, index) {
              return VitalCard(vital: vitals[index]);
            },
          ),
        ),
      ],
    );
  }
}
