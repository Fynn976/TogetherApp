import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteSportDropdown extends StatefulWidget {
  const FavoriteSportDropdown({super.key});

  @override
  State<FavoriteSportDropdown> createState() => _FavoriteSportDropdownState();
}

class _FavoriteSportDropdownState extends State<FavoriteSportDropdown> {
  String? selectedSport;
  List<String> sportsList = [
    'Fußball',
    'Basketball',
    'Volleyball',
    'Schwimmen',
    'Laufen',
    'Tennis',
    'Klettern',
    'Boxen',
    'Tanzen',
    'Skifahren',
    'Golf',
    'Rugby',
    'Badminton',
    'Handball',
    'Eishockey',
    'American Football',
    'Baseball',
    'Cricket',
    'Radsport',
    'Kraftsport',
    'Andere',
  ];

  @override
  void initState() {
    super.initState();
    print("FavoriteSportDropdown initState aufgerufen");
    loadFavoriteSport();
  }

  Future<void> loadFavoriteSport() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final response = await Supabase.instance.client
        .from('profiles')
        .select('favorite_sport')
        .eq('id', userId)
        .single();

        print("Geladene Sportart: ${response['favorite_sport']}");

    setState(() {
      selectedSport = response['favorite_sport'];
    });
  }

  Future<void> _updateFavoriteSport(String? newSport) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || newSport == null) return;

    await Supabase.instance.client.from('profiles').upsert({
      'id': userId,
      'favorite_sport': newSport,
    });

    setState(() {
      selectedSport = newSport;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Lieblingssportart',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedSport,
            isExpanded: true,
            hint: const Text('Lieblingssportart wählen'),
            borderRadius: BorderRadius.circular(10),
            onChanged: _updateFavoriteSport,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
            items: sportsList.map((sport) {
              return DropdownMenuItem<String>(
                value: sport,
                child: Text(sport),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
