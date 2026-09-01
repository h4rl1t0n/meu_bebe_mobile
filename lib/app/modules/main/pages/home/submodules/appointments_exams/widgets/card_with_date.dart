import 'package:flutter/material.dart';

import '../../../../../widgets/base_card.dart';

class CardWithDate extends StatelessWidget {
  const CardWithDate({
    super.key,
    required this.title,
    required this.date,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String date;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                insetPadding: EdgeInsets.all(15),
                title: const Text('Deseja excluir?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Não')),
                  TextButton(
                    onPressed: () {
                      onTap();
                      Navigator.pop(context);
                    },
                    child: const Text('Sim'),
                  ),
                ],
              ),
            );
          },
          child: BaseCard(
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
              title: Text(title),
              subtitle: Text(description),
              trailing: Text(date),
            ),
          ),
        ),
      ],
    );
  }
}
