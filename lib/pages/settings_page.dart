import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loginpage/components/my_backbutton.dart';
import 'package:loginpage/auth/auth_service.dart';
import 'package:loginpage/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final authService = AuthService();
  bool notificationsEnabled = true;
  bool privateProfile = false;
  bool darkModeEnabled = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('notifications_enabled, private_profile')
          .eq('id', userId)
          .maybeSingle();
      
      if (response != null) {
        setState(() {
          notificationsEnabled = response['notifications_enabled'] ?? true;
          privateProfile = response['private_profile'] ?? false;
        });
      }
    } catch (e) {
      print('Fehler beim Laden der Einstellungen: $e');
    }
  }

  Future<void> _updateSetting(String field, bool value) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('profiles')
          .upsert({
            'id': userId,
            field: value,
          });
    } catch (e) {
      print('Fehler beim Speichern: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern: $e')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account löschen'),
        content: const Text('Möchtest du deinen Account wirklich permanent löschen? Diese Aktion kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Hier würdest du normalerweise den Account löschen
        // Bei Supabase ist das etwas komplexer und sollte serverseitig gemacht werden
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account-Löschung angefordert')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.inversePrimary),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header mit Back Button
            const Padding(
              padding: EdgeInsets.only(top: 20.0, left: 20.0),
              child: Row(
                children: [CustomBackButton()],
              ),
            ),
            
            // Titel
            Padding(
              padding: const EdgeInsets.only(left: 30.0, top: 20, bottom: 30),
              child: Row(
                children: [
                  Text(
                    'Einstellungen',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 30,
                    ),
                  ),
                ],
              ),
            ),

            // Settings Liste
            Expanded(
              child: ListView(
                children: [
                  // Account Sektion
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    child: Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                  ),

                  _buildSettingsTile(
                    icon: Icons.notifications,
                    title: 'Benachrichtigungen',
                    subtitle: 'Push-Benachrichtigungen aktivieren',
                    trailing: Switch(
                      value: notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          notificationsEnabled = value;
                        });
                        _updateSetting('notifications_enabled', value);
                      },
                    ),
                  ),

                  _buildSettingsTile(
                    icon: Icons.privacy_tip,
                    title: 'Privates Profil',
                    subtitle: 'Nur Freunde können deine Beiträge sehen',
                    trailing: Switch(
                      value: privateProfile,
                      onChanged: (value) {
                        setState(() {
                          privateProfile = value;
                        });
                        _updateSetting('private_profile', value);
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Darstellung Sektion
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    child: Text(
                      'Darstellung',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                  ),

                  _buildSettingsTile(
                    icon: Icons.dark_mode,
                    title: 'Dark Mode',
                    subtitle: 'Dunkles Design verwenden',
                    trailing: Switch(
                      value: context.watch<ThemeProvider>().isDarkMode,
                      onChanged: (value) {
                        context.read<ThemeProvider>().toggleTheme();
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Support Sektion
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    child: Text(
                      'Support',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                  ),

                  _buildSettingsTile(
                    icon: Icons.help,
                    title: 'Hilfe & Support',
                    subtitle: 'FAQ und Kontakt',
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hilfe-Seite wird geöffnet')),
                      );
                    },
                  ),

                  _buildSettingsTile(
                    icon: Icons.info,
                    title: 'Über die App',
                    subtitle: 'Version 1.0.0',
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'tgthr.',
                        applicationVersion: '1.0.0',
                        children: [
                          const Text('Eine App für Sportbegeisterte um zusammen zu trainieren.'),
                        ],
                      );
                    },
                  ),

                  _buildSettingsTile(
                    icon: Icons.privacy_tip,
                    title: 'Datenschutz',
                    subtitle: 'Datenschutzerklärung lesen',
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Datenschutzerklärung wird geöffnet')),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Danger Zone
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    child: Text(
                      'Danger Zone',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),

                  _buildSettingsTile(
                    icon: Icons.delete_forever,
                    title: 'Account löschen',
                    subtitle: 'Account permanent löschen',
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                    onTap: _deleteAccount,
                  ),

                  _buildSettingsTile(
                    icon: Icons.logout,
                    title: 'Ausloggen',
                    subtitle: 'Von der App abmelden',
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      await authService.signOut();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Erfolgreich ausgeloggt')),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}