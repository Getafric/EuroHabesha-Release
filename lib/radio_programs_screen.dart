import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'access_control.dart';
import 'app_localization_helper.dart';

class RadioProgram {
  final String title;
  final String host;
  final String description;

  RadioProgram({
    required this.title,
    required this.host,
    required this.description,
  });
}

class RadioProgramsScreen extends StatefulWidget {
  const RadioProgramsScreen({super.key});

  @override
  State<RadioProgramsScreen> createState() => _RadioProgramsScreenState();
}

class _RadioProgramsScreenState extends State<RadioProgramsScreen> {
  final List<RadioProgram> _programs = [
    RadioProgram(
      title: 'Habesha Morning Show',
      host: 'EH Studio',
      description: 'Daily updates, diaspora stories, and community opportunities.',
    ),
  ];

  void _openManageDialog() {
    if (!AccessControl.ensureApprovedContributor(context, actionLabel: tr('manage_radio_programs'))) {
      return;
    }

    final titleController = TextEditingController();
    final hostController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF061E12),
          title: Text(tr('add_radio_program'), style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: tr('program_title'),
                    labelStyle: const TextStyle(color: Colors.white70),
                  ),
                ),
                TextField(
                  controller: hostController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: tr('program_host'),
                    labelStyle: const TextStyle(color: Colors.white70),
                  ),
                ),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: tr('description'),
                    labelStyle: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(tr('cancel'), style: const TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: const Color(0xFF061E12),
              ),
              onPressed: () {
                if (titleController.text.trim().isEmpty || hostController.text.trim().isEmpty) {
                  return;
                }
                setState(() {
                  _programs.insert(
                    0,
                    RadioProgram(
                      title: titleController.text.trim(),
                      host: hostController.text.trim(),
                      description: descriptionController.text.trim(),
                    ),
                  );
                });
                Navigator.of(dialogContext).pop();
              },
              child: Text(tr('save')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04160D),
      appBar: AppBar(
        title: Text(tr('radio_programs_audio')),
        actions: [
          AppLocalizationHelper.languageMenu(context),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _openManageDialog,
            tooltip: tr('manage_radio_programs'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _programs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final p = _programs[index];
          return Card(
            color: const Color(0xFF0A2418),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Colors.white12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: const Icon(Icons.graphic_eq, color: Color(0xFFF59E0B)),
              title: Text(p.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${p.host}\n${p.description}',
                style: const TextStyle(color: Colors.white70),
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
