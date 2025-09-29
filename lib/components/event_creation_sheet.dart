import 'dart:convert'; // für jsonEncode
import 'package:flutter/material.dart';
import 'package:loginpage/components/image_events.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geocoding/geocoding.dart';

class EventCreationSheet extends StatefulWidget {
  const EventCreationSheet({super.key});

  @override
  State<EventCreationSheet> createState() => _EventCreationSheetState();
}

class _EventCreationSheetState extends State<EventCreationSheet> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final sportController = TextEditingController();
  final streetController = TextEditingController();
  final zipController = TextEditingController();
  final cityController = TextEditingController();
  final maxParticipantsController = TextEditingController();
  final timeController = TextEditingController();
  DateTime? selectedDateTime;

  List<String> imageUrls = []; // Liste der URLs
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showError('Du musst eingeloggt sein, um ein Event zu erstellen.');
      setState(() => _isSubmitting = false);
      return;
    }

    final street = streetController.text.trim();
    final zip = zipController.text.trim();
    final city = cityController.text.trim();
    final address = '$street, $zip $city, Deutschland';

    double? latitude;
    double? longitude;

    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        latitude = locations.first.latitude;
        longitude = locations.first.longitude;
      } else {
        _showError('Koordinaten für die Adresse konnten nicht gefunden werden.');
        setState(() => _isSubmitting = false);
        return;
      }
    } catch (e) {
      _showError('Fehler bei der Umwandlung der Adresse:\n$e');
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      await Supabase.instance.client.from('events').insert({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'location_name': address,
        'latitude': latitude,
        'longitude': longitude,
        'sport': sportController.text.trim(),
        'max_participants': int.tryParse(maxParticipantsController.text) ?? 0,
        'current_participants': 0,
        'created_by': user.id,
        'image_urls': jsonEncode(imageUrls), // als JSON-String speichern,
        'created_at': DateTime.now().toIso8601String(),
        'time_and_date': selectedDateTime?.toIso8601String(),

        

      });

      print('Event erstellt mit folgenden Daten: time_and_date: ${selectedDateTime?.toIso8601String()}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event wurde erfolgreich erstellt!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      _showError('Fehler beim Erstellen des Events: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1,
      TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte $label eingeben';
              }
              return null;
            },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
  final DateTime? date = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime(2100),
  );

  if (date == null) return;

  final TimeOfDay? time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );

  if (time == null) return;

  setState(() {
    selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  });
}


  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Divider(
              color: Theme.of(context).colorScheme.primary,
              thickness: 4,
              indent: 150,
              endIndent: 150,
            ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Neues Event erstellen',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 16),
                ModernImageEvents(
                  onImagesChanged: (urls) {
                    setState(() {
                      imageUrls = urls;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(titleController, 'Titel'),
                _buildTextField(descriptionController, 'Beschreibung', maxLines: 4),
                _buildTextField(sportController, 'Sportart'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: _pickDateTime,
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Datum und Uhrzeit',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (_) {
                          if (selectedDateTime == null) return 'Bitte Datum und Uhrzeit wählen';
                          return null;
                        },
                        controller: TextEditingController(
                          text: selectedDateTime == null
                              ? ''
                              : '${selectedDateTime!.day.toString().padLeft(2, '0')}.${selectedDateTime!.month.toString().padLeft(2, '0')}.${selectedDateTime!.year} – ${selectedDateTime!.hour.toString().padLeft(2, '0')}:${selectedDateTime!.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                ),

                _buildTextField(streetController, 'Straße und Hausnummer'),
                _buildTextField(zipController, 'Postleitzahl', keyboardType: TextInputType.number),
                _buildTextField(cityController, 'Stadt'),
                _buildTextField(
                  maxParticipantsController,
                  'Max. Teilnehmerzahl',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Bitte Teilnehmerzahl eingeben';
                    if (int.tryParse(value) == null) return 'Bitte eine gültige Zahl eingeben';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Event erstellen',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
