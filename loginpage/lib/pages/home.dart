import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> posts = [];
  TextEditingController _commentController = TextEditingController();

  Future<void> fetchPosts() async {
    final response = await Supabase.instance.client
        .from('posts')
        .select()
        .order('created_at', ascending: false);

    if (response != null) {
      setState(() {
        posts = response as List<dynamic>;
      });
    } else {
      print('Fehler beim Laden der Posts: Keine Daten gefunden.');
    }
  }

  Future<void> toggleLike(int postId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    final existingLike = await Supabase.instance.client
        .from('likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', userId!)
        .maybeSingle();

    if (existingLike != null) {
      await Supabase.instance.client
          .from('likes')
          .delete()
          .eq('id', existingLike['id']);
    } else {
      await Supabase.instance.client
          .from('likes')
          .insert({'post_id': postId, 'user_id': userId});
    }

    fetchPosts();
  }

  Future<void> addComment(int postId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final commentText = _commentController.text.trim();

    if (commentText.isEmpty) return;

    final response = await Supabase.instance.client
        .from('comments')
        .insert({
          'post_id': postId,
          'user_id': userId,
          'text': commentText,
        });

    if (response == null) {
      print('Fehler beim Hinzufügen des Kommentars');
    }

    _commentController.clear();
    fetchPosts();
  }

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text('Bitte logge dich ein'),
        ),
      );
    }

    final username = user.userMetadata?['username'] ?? 'Unbekannt';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: LiquidPullToRefresh(
          onRefresh: fetchPosts,
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).colorScheme.surface,
          height: 150.0,
          animSpeedFactor: 2.0,
          showChildOpacityTransition: false,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            children: [
              // Logo oben rechts (scrollbar)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'tgthr.',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
          
              Text(
                'Willkommen, $username',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontSize: 30,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Bereit für dein nächstes Training?',
                style: TextStyle(
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 50),
              Text(
                'Hier beginnt dein Feed!',
                style: TextStyle(
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
          
              if (posts.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Text(
                    'Es scheint hier gerade etwas ruhig zu sein...',
                    style: TextStyle(
                      fontFamily: GoogleFonts.montserrat().fontFamily,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 18,
                    ),
                  ),
                )
              else
                ...posts.map((post) {
                  final postId = post['id'];
                  final imageUrl = post['image_url'];
          
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.favorite),
                                onPressed: () => toggleLike(postId),
                              ),
                              Text('Likes: ${post['like_count'] ?? 0}'),
                            ],
                          ),
                        ),
                        FutureBuilder(
                          future: Supabase.instance.client
                              .from('comments')
                              .select()
                              .eq('post_id', postId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return Text(
                                  'Fehler: ${snapshot.error.toString()}');
                            }
          
                            final comments =
                                snapshot.data as List<dynamic>? ?? [];
          
                            if (comments.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Noch keine Kommentare.'),
                              );
                            }
          
                            return Column(
                              children: comments.map((comment) {
                                return ListTile(
                                  title: Text(comment['text']),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Füge einen Kommentar hinzu...',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: () => addComment(postId),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
