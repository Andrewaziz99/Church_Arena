import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late final TextEditingController _memberCtrl;
  late int _selectedColor;
  late String _selectedSection;
  late List<String> _members;

  @override
  void initState() {
    super.initState();
    _nameCtrl   = TextEditingController(text: widget.team?.name ?? '');
    _memberCtrl = TextEditingController();
    _selectedColor   = widget.team?.color ?? AppColors.teamColors.first.value;
    _selectedSection = widget.team?.section ?? '';
    _members = List<String>.from(widget.team?.members ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _memberCtrl.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _memberCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _members.add(name);
      _memberCtrl.clear();
    });
  }

  void _removeMember(int index) {
    setState(() => _members.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.team != null;
    return AlertDialog(
      title: Text(
        isEdit ? AppStrings.editTeam : AppStrings.addTeam,
        style: GoogleFonts.alexandria(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Team name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: AppStrings.teamName,
                    hintText: 'e.g. Zion Warriors',
                    prefixIcon: Icon(Icons.groups_rounded),
                  ),
                  autofocus: true,
                  style: GoogleFonts.alexandria(),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppStrings.nameRequired
                      : null,
                ),

                const SizedBox(height: 16),

                // Section
                DropdownButtonFormField<String>(
                  value: _selectedSection.isEmpty ? null : _selectedSection,
                  decoration: const InputDecoration(
                    labelText: AppStrings.section,
                    hintText: 'All sections',
                    prefixIcon: Icon(Icons.school_rounded),
                  ),
                  style: GoogleFonts.alexandria(color: AppColors.textPrimary, fontSize: 14),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(AppStrings.allSections,
                          style: GoogleFonts.alexandria(color: AppColors.textSecondary)),
                    ),
                    ...AppStrings.sections.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s,
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.alexandria(color: AppColors.textPrimary)),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedSection = v ?? ''),
                ),

                const SizedBox(height: 20),

                // Color picker
                Text(AppStrings.selectColor,
                    style: GoogleFonts.alexandria(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: AppColors.teamColors.map((color) {
                    final isSelected = _selectedColor == color.value;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: isSelected ? 36 : 30,
                        height: isSelected ? 36 : 30,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)]
                              : [],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Members section
                Row(
                  children: [
                    Text(
                      'أعضاء الفريق',
                      style: GoogleFonts.alexandria(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.blueContent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_members.length}',
                        style: GoogleFonts.alexandria(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.blueContent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Add member input
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _memberCtrl,
                        decoration: InputDecoration(
                          hintText: 'اسم العضو',
                          hintStyle: GoogleFonts.alexandria(fontSize: 13),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: GoogleFonts.alexandria(fontSize: 14),
                        textDirection: TextDirection.rtl,
                        onFieldSubmitted: (_) => _addMember(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _addMember,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.blueContent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),

                if (_members.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 160),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _members.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundColor: Color(_selectedColor).withOpacity(0.2),
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.alexandria(fontSize: 10, fontWeight: FontWeight.w700, color: Color(_selectedColor)),
                            ),
                          ),
                          title: Text(
                            _members[index],
                            style: GoogleFonts.alexandria(fontSize: 13, fontWeight: FontWeight.w600),
                            textDirection: TextDirection.rtl,
                          ),
                          trailing: GestureDetector(
                            onTap: () => _removeMember(index),
                            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.redError),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.cancel, style: GoogleFonts.alexandria()),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(AppStrings.save, style: GoogleFonts.alexandria(fontWeight: FontWeight.w700)),
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
      members: _members,
    );
    widget.blocContext.read<TeamsBloc>().add(SaveTeam(team));
    Navigator.pop(context);
  }
}
