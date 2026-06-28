import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/team.dart';
import '../bloc/teams_bloc.dart';

class TeamFormDialog extends StatefulWidget {
  final Team? team;
  final BuildContext blocContext;

  const TeamFormDialog({
    super.key,
    this.team,
    required this.blocContext,
  });

  @override
  State<TeamFormDialog> createState() => _TeamFormDialogState();
}

class _TeamFormDialogState extends State<TeamFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late int _selectedColor;
  late String _selectedSection;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.team?.name ?? '');
    _selectedColor = widget.team?.color ?? AppColors.teamColors.first.value;
    _selectedSection = widget.team?.section ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.team != null;
    return AlertDialog(
      title: Text(isEdit ? AppStrings.editTeam : AppStrings.addTeam),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.teamName,
                  hintText: 'e.g. Zion Warriors',
                ),
                autofocus: true,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppStrings.nameRequired
                    : null,
              ),
              const SizedBox(height: 20),
              // Section dropdown
              DropdownButtonFormField<String>(
                value: _selectedSection.isEmpty ? null : _selectedSection,
                decoration: const InputDecoration(
                  labelText: AppStrings.section,
                  hintText: 'All sections',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(AppStrings.allSections,
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  ...AppStrings.sections.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s,
                            textDirection: TextDirection.rtl,
                            style:
                                const TextStyle(color: AppColors.textPrimary)),
                      )),
                ],
                onChanged: (v) =>
                    setState(() => _selectedSection = v ?? ''),
              ),
              const SizedBox(height: 20),
              const Text(
                AppStrings.selectColor,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppColors.teamColors.map((color) {
                  final isSelected = _selectedColor == color.value;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedColor = color.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: isSelected ? 36 : 32,
                      height: isSelected ? 36 : 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : Border.all(
                                color:
                                    Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final team = Team(
      id: widget.team?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      color: _selectedColor,
      score: widget.team?.score ?? 0,
      section: _selectedSection,
    );
    widget.blocContext.read<TeamsBloc>().add(SaveTeam(team));
    Navigator.pop(context);
  }
}
