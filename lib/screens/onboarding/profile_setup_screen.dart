import 'package:flutter/material.dart';

import '../../models/medical_profile.dart';
import '../../state/console_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'conditions_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  Gender _gender = Gender.other;
  String? _blood;

  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    final m = ConsoleScope.read(context).medical;
    _name = TextEditingController(text: m.name);
    _age = TextEditingController(text: '${m.age}');
    _height = TextEditingController(text: '${m.heightCm.round()}');
    _weight = TextEditingController(text: '${m.weightKg.round()}');
    _gender = m.gender;
    _blood = m.bloodType;
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  double get _bmi {
    final h = (double.tryParse(_height.text) ?? 170) / 100;
    final w = double.tryParse(_weight.text) ?? 68;
    return h > 0 ? w / (h * h) : 0;
  }

  void _next() {
    final s = ConsoleScope.of(context);
    s.setMedical(s.medical.copyWith(
      name: _name.text.trim(),
      age: int.tryParse(_age.text) ?? s.medical.age,
      gender: _gender,
      heightCm: double.tryParse(_height.text) ?? s.medical.heightCm,
      weightKg: double.tryParse(_weight.text) ?? s.medical.weightKg,
      bloodType: _blood,
    ));
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ConditionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your profile'),
        backgroundColor: c.paper,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: c.heroGradient),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder(
                    valueListenable: _weight,
                    builder: (_, __, ___) => ValueListenableBuilder(
                      valueListenable: _height,
                      builder: (_, __, ___) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: c.accentSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'BMI ${_bmi.toStringAsFixed(1)} · ${bmiCategory(_bmi)}',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: c.accent),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _LabeledField(label: 'Full name', controller: _name, icon: Icons.badge_outlined),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _LabeledField(
                    label: 'Age',
                    controller: _age,
                    icon: Icons.cake_outlined,
                    number: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _GenderDropdown(
                  value: _gender,
                  onChanged: (g) => setState(() => _gender = g),
                )),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _LabeledField(
                    label: 'Height (cm)',
                    controller: _height,
                    icon: Icons.height,
                    number: true,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LabeledField(
                    label: 'Weight (kg)',
                    controller: _weight,
                    icon: Icons.monitor_weight_outlined,
                    number: true,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _BloodDropdown(
              value: _blood,
              items: _bloodTypes,
              onChanged: (b) => setState(() => _blood = b),
            ),
            const SizedBox(height: 26),
            GradientButton(label: 'Next', icon: Icons.arrow_forward, onTap: _next),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.icon,
    this.number = false,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool number;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label, style: TextStyle(fontSize: 12, color: c.muted)),
        ),
        TextField(
          controller: controller,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          onChanged: onChanged,
          style: TextStyle(color: c.ink, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: c.faint, size: 20),
            filled: true,
            fillColor: c.panel,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.accent, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _GenderDropdown extends StatelessWidget {
  const _GenderDropdown({required this.value, required this.onChanged});
  final Gender value;
  final ValueChanged<Gender> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text('Sex', style: TextStyle(fontSize: 12, color: c.muted)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: c.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.line),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Gender>(
              value: value,
              isExpanded: true,
              dropdownColor: c.panel,
              style: TextStyle(color: c.ink, fontSize: 15),
              icon: Icon(Icons.arrow_drop_down, color: c.faint),
              items: [
                for (final g in Gender.values)
                  DropdownMenuItem(value: g, child: Text(g.label)),
              ],
              onChanged: (g) => onChanged(g ?? value),
            ),
          ),
        ),
      ],
    );
  }
}

class _BloodDropdown extends StatelessWidget {
  const _BloodDropdown(
      {required this.value, required this.items, required this.onChanged});
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text('Blood type (optional)',
              style: TextStyle(fontSize: 12, color: c.muted)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: c.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.line),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Row(children: [
                Icon(Icons.bloodtype_outlined, color: c.faint, size: 20),
                const SizedBox(width: 8),
                Text('Select', style: TextStyle(color: c.faint)),
              ]),
              dropdownColor: c.panel,
              style: TextStyle(color: c.ink, fontSize: 15),
              icon: Icon(Icons.arrow_drop_down, color: c.faint),
              items: [
                for (final b in items)
                  DropdownMenuItem(value: b, child: Text(b)),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
