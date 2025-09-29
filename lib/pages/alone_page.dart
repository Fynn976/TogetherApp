import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loginpage/auth/auth_service.dart';
import 'package:loginpage/components/menu_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:loginpage/components/My_favorite_sport.dart';
import 'package:loginpage/components/profile_image.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  final authService = AuthService();
  List<dynamic> userPosts = [];

  String uniqueUsername = '...'; // wird dynamisch geladen
  String displayName = '...'; // wird dynamisch geladen

  @override
  void initState() {
    super.initState();
    fetchOwnPosts();
    fetchUniqueUsername();
    fetchDisplayName();
  }

  Future<void> fetchUniqueUsername() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .single();

      setState(() {
        uniqueUsername = response['username'] ?? 'Unbekannt';
      });
    } catch (e) {
      setState(() {
        uniqueUsername = 'Unbekannt';
      });
    }
  }

  Future<void> fetchDisplayName() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('display_name')
          .eq('id', userId)
          .single();

      setState(() {
        displayName = response['display_name'] ?? 'Unbekannt';
      });
    } catch (e) {
      setState(() {
        displayName = 'Unbekannt';
      });
    }
  }

  Future<void> fetchOwnPosts() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    final response = await Supabase.instance.client
        .from('posts')
        .select()
        .eq('user_id', userId!)
        .order('created_at', ascending: false);

    setState(() {
      userPosts = response;
    });
  }

  Future<List<dynamic>> getCommentsForPost(int postId) async {
    final response = await Supabase.instance.client
        .from('comments')
        .select()
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return response;
  }

  Future<void> deletePost(int postId) async {
    await Supabase.instance.client.from('posts').delete().eq('id', postId);
    fetchOwnPosts(); // Refresh after deletion
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = authService.getCurrentUserEmail();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      endDrawer: MyDrawer(),
      body: SafeArea(
        child: Builder(
          builder: (ctx) => Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    const ProfileImage(),
                    const SizedBox(height: 25),
                    Text(
                      '$displayName\'s Profil',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 27,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Hier können Sie Ihr Profil bearbeiten.',
                      style: TextStyle(
                        fontFamily: GoogleFonts.montserrat().fontFamily,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const FavoriteSportDropdown(),
                    const SizedBox(height: 10),
                    Text(
                      currentEmail.toString(),
                      style: TextStyle(
                        fontFamily: GoogleFonts.montserrat().fontFamily,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Benutzername: $uniqueUsername',
                      style: TextStyle(
                        fontFamily: GoogleFonts.montserrat().fontFamily,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Divider(thickness: 1),
                    const SizedBox(height: 10),
                    Text(
                      'Meine Beiträge',
                      style: TextStyle(
                        fontFamily: GoogleFonts.montserrat().fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: userPosts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                      ),
                      itemBuilder: (context, index) {
                        final post = userPosts[index];
                        final imageUrl = post['image_url'];
                        final postId = post['id'];

                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(0.5),
                              builder: (BuildContext context) {
                                return Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(imageUrl),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.favorite,
                                                size: 20),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${post['likes'] ?? 0} Likes',
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),

                                        FutureBuilder<List<dynamic>>(
                                          future: getCommentsForPost(postId),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const CircularProgressIndicator();
                                            } else if (snapshot.hasError) {
                                              return const Text(
                                                  'Fehler beim Laden der Kommentare');
                                            }

                                            final comments = snapshot.data ?? [];

                                            if (comments.isEmpty) {
                                              return const Text(
                                                'Keine Kommentare vorhanden',
                                                style: TextStyle(fontSize: 16),
                                              );
                                            }

                                            return Column(
                                              children: comments.map((comment) {
                                                return Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 4),
                                                    child: Text(
                                                      '• ${comment['text']}',
                                                      style: const TextStyle(
                                                          fontSize: 14),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            );
                                          },
                                        ),

                                        const SizedBox(height: 10),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                            await deletePost(postId);
                                          },
                                          icon: const Icon(Icons.delete),
                                          label: const Text('Beitrag löschen'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
              Positioned(
                top: 20,
                left: 30,
                child: Text(
                  'tgthr.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
