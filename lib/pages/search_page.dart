import 'package:flutter/material.dart';
import 'package:loginpage/pages/ProfileForOthers.dart';
import 'package:loginpage/pages/events_tab.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MySearch extends StatefulWidget {
  const MySearch({super.key});

  @override
  State<MySearch> createState() => _MySearchState();
}

class _MySearchState extends State<MySearch> with TickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  List<dynamic> searchResults = [];
  bool isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> searchUsers() async {
    final query = searchController.text.trim();

    if (query.isEmpty) {
      _showSnackBar('Bitte einen Suchbegriff eingeben');
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, username, avatar_url, display_name, favorite_sport')
          .ilike('username', '%$query%');

      setState(() {
        searchResults = response;
      });

      if (response.isEmpty) {
        _showSnackBar('Keine Benutzer gefunden');
      }
    } catch (e) {
      _showSnackBar('Fehler bei der Suche: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Row(
            children: [
              Text(
                'tgthr.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:  Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.inversePrimary,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Entdecken',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Finde Trainingspartner und Events',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inversePrimary,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Trainingspartner suchen...',
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon:  Icon(Icons.search, color: Theme.of(context).colorScheme.inversePrimary),
              onPressed: searchUsers,
            ),
          ),
        ),
        onSubmitted: (_) => searchUsers(),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inversePrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            backgroundImage: (user['avatar_url'] != null && user['avatar_url'] != '')
                ? NetworkImage(user['avatar_url'])
                : null,
            child: (user['avatar_url'] == null || user['avatar_url'] == '')
                ? const Icon(Icons.person, size: 30)
                : null,
          ),
        ),
        title: Text(
          user['display_name'] ?? user['username'],
          style:  TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '@${user['username']}',
              style: TextStyle(color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
            ),
            if (user['favorite_sport'] != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user['favorite_sport'],
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.arrow_forward_ios,
            color: Theme.of(context).colorScheme.primary,
            size: 16,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PublicProfilePage(userId: user['id']),
            ),
          );
        },
      ),
    );
  }

  Widget buildUserSearchTab() {
    return Column(
      children: [
        _buildSearchBar(),
        if (isLoading)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (searchResults.isEmpty && searchController.text.isNotEmpty)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Keine Trainingspartner gefunden',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Versuche einen anderen Suchbegriff',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          )
        else if (searchResults.isEmpty)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Finde deine Trainingspartner',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Suche nach Benutzernamen, um andere Sportbegeisterte zu finden und dich zu vernetzen',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.6),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) => _buildUserCard(searchResults[index]),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          _buildSearchHeader(),
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs:  [
                Tab(
                  icon: Icon(Icons.people, color: Theme.of(context).colorScheme.inversePrimary,),
                  text: 'Personen',
                ),
                Tab(
                  icon: Icon(Icons.event, color: Theme.of(context).colorScheme.inversePrimary,),
                  text: 'Events',
                ),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.6),
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildUserSearchTab(),
                const ModernEventsTab()
              ],
            ),
          ),
        ],
      ),
    );
  }
}