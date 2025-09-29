import 'package:flutter/material.dart';
import 'package:loginpage/pages/ProfileForOthers.dart';
import 'package:loginpage/pages/event_chat_page.dart';
import 'package:loginpage/pages/friend_chat.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MyFriends extends StatefulWidget {
  const MyFriends({super.key});

  @override
  State<MyFriends> createState() => _MyFriendsState();
}

class _MyFriendsState extends State<MyFriends> {
  List<Map<String, dynamic>> friends = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMutualFriends();
  }

  Future<void> loadMutualFriends() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      // 1️⃣ RPC aufrufen und friend_ids bekommen
      final List<Map<String, dynamic>> friendIds = await Supabase.instance.client
          .rpc('get_mutual_friends', params: {'p_user_id': currentUserId});

      if (friendIds.isEmpty) {
        setState(() {
          friends = [];
          isLoading = false;
        });
        return;
      }

      // 2️⃣ Profile der Freunde laden
      final profilesData = await Supabase.instance.client
          .from('profiles')
          .select('id, username, avatar_url, is_online, last_online')
          .filter('id', 'in', '(${friendIds.map((f) => f['friend_id']).join(',')})');

      if (profilesData == null || profilesData.isEmpty) {
        setState(() {
          friends = [];
          isLoading = false;
        });
        return;
      }

      // 3️⃣ Profile in State speichern
      setState(() {
        friends = List<Map<String, dynamic>>.from(profilesData);
        isLoading = false;
      });
    } catch (error) {
      print('Fehler beim Laden der Freunde oder Profile: $error');
      setState(() {
        friends = [];
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchEvents() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    // 1. Events, die ich erstellt habe
    final createdEvents = await Supabase.instance.client
        .from('events')
        .select('id, title, time_and_date, location_name, created_by')
        .eq('created_by', userId);

    // 2. Events, denen ich beigetreten bin
    final joinedEvents = await Supabase.instance.client
        .from('event_participants')
        .select('events(id, title, time_and_date, location_name, created_by)')
        .eq('user_id', userId);

    // 3. Mergen
    final allEvents = [
      ...List<Map<String, dynamic>>.from(createdEvents),
      ...List<Map<String, dynamic>>.from(joinedEvents.map((e) => e['events'])),
    ];

    return allEvents;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Text(
                  'tgthr.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 6),
                child: Text(
                  'Freunde',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 30,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: TabBar(
                  tabs: const [
                    Tab(text: 'Personen'),
                    Tab(text: 'Ereignisse'),
                  ],
                  labelColor: Theme.of(context).colorScheme.inversePrimary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).colorScheme.inversePrimary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    buildUserFriendsTab(context),
                    buildEventsTab(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildUserFriendsTab(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (friends.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(30),
        child: Text(
          'Du hast noch keine Freunde, die beidseitig bestätigt sind.',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.inversePrimary,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return ListTile(
          leading: friend['avatar_url'] != null && (friend['avatar_url'] as String).isNotEmpty
              ? CircleAvatar(backgroundImage: NetworkImage(friend['avatar_url']))
              : CircleAvatar(child: Text(friend['username'][0].toUpperCase())),
          title: Text(
            '@${friend['username']}',
            style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
          ),
          subtitle: Text(
            friend['is_online'] == true
                ? '🟢 Online'
                : friend['last_online'] != null
                    ? 'Zuletzt online: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(friend['last_online']).toLocal())}'
                    : 'Zuletzt online: Unbekannt',
            style: const TextStyle(color: Colors.grey),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FriendChatPage(
                  friendId: friend['id'],
                  friendUsername: friend['username'],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildEventsTab(BuildContext context) {
    return FutureBuilder(
      future: fetchEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return Center(
            child: Text(
              'Du nimmst an keinen Ereignissen teil.',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          );
        }

        final events = snapshot.data as List<Map<String, dynamic>>;

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(event['title']),
                subtitle: Text(
                  event['time_and_date'] != null
                      ? DateFormat('dd.MM.yyyy HH:mm')
                          .format(DateTime.parse(event['time_and_date']))
                      : 'Kein Datum gesetzt',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventChatPage(eventId: event['id']),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
