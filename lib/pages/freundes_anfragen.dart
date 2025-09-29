import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:loginpage/components/my_backbutton.dart';

class MyFriendrequests extends StatefulWidget {
  const MyFriendrequests({super.key});

  @override
  State<MyFriendrequests> createState() => _MyFriendrequestsState();
}

class _MyFriendrequestsState extends State<MyFriendrequests> {
  List<Map<String, dynamic>> friendRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFriendRequests();
  }

  Future<void> loadFriendRequests() async {
    setState(() {
      isLoading = true;
    });

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final response = await Supabase.instance.client
        .from('friend_requests')
        .select('id, requester_id, profiles!requester_id(username, avatar_url)')
        .eq('receiver_id', currentUserId)
        .eq('status', 'pending');

    setState(() {
      friendRequests = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  Future<void> acceptFriendRequest(String requestId, String requesterId) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    final insertResponse = await Supabase.instance.client.from('friends').insert({
      'user_id': currentUserId,
      'friend_id': requesterId,
    });

    if (insertResponse.error != null) {
      print('Fehler beim Anlegen der Freundschaft: ${insertResponse.error!.message}');
      return;
    }

    final deleteResponse = await Supabase.instance.client
        .from('friend_requests')
        .delete()
        .eq('id', requestId);

    if (deleteResponse.error != null) {
      print('Fehler beim Löschen der Anfrage: ${deleteResponse.error!.message}');
      return;
    }

    // Lade die Liste komplett neu
    await loadFriendRequests();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Freundschaftsanfrage angenommen')),
    );
  }

  Future<void> declineFriendRequest(String requestId) async {
    final deleteResponse = await Supabase.instance.client
        .from('friend_requests')
        .delete()
        .eq('id', requestId);

    if (deleteResponse.error != null) {
      print('Fehler beim Löschen der Anfrage: ${deleteResponse.error!.message}');
      return;
    }

    // Lade die Liste komplett neu
    await loadFriendRequests();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Freundschaftsanfrage abgelehnt')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 50.0, left: 20.0),
              child: Row(
                children: const [
                  CustomBackButton(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 30.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Freundschaftsanfragen',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : friendRequests.isEmpty
                      ? const Center(child: Text('Keine neuen Freundschaftsanfragen'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 30.0),
                          itemCount: friendRequests.length,
                          itemBuilder: (context, index) {
                            final request = friendRequests[index];
                            final requester = request['profiles'] as Map<String, dynamic>?;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: requester != null && requester['avatar_url'] != null
                                    ? CircleAvatar(
                                        backgroundImage: NetworkImage(requester['avatar_url']),
                                      )
                                    : const CircleAvatar(child: Icon(Icons.person)),
                                title: Text(
                                  requester != null ? '@${requester['username']}' : 'Unbekannter Nutzer',
                                ),
                                subtitle: const Text('möchte dein Freund werden'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check, color: Colors.green),
                                      onPressed: () => acceptFriendRequest(
                                        request['id'],
                                        request['requester_id'],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      onPressed: () => declineFriendRequest(
                                        request['id'],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
