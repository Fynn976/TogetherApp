import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loginpage/auth/auth_service.dart';
import 'package:loginpage/components/menu_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  final authService = AuthService();
  List<dynamic> userPosts = [];

  Future<List<dynamic>> getCommentsForPost(int postId) async {
  final response = await Supabase.instance.client
      .from('comments')
      .select()
      .eq('post_id', postId)
      .order('created_at', ascending: true);

  return response;
}


  @override
  void initState() {
    super.initState();
    fetchOwnPosts();
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
                    // Profile picture
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.all(25),
                      child: const Icon(
                        Icons.person,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      'Mein Profil',
                      style: TextStyle(
                        fontFamily: GoogleFonts.montserrat().fontFamily,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
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
                    const SizedBox(height: 10),
                    Text(
                      currentEmail.toString(),
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
                    // Grid mit Bildern
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: userPosts.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(imageUrl),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.favorite, size: 20,),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${post['likes'] ?? 0} Likes',
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // 🧠 Kommentare dynamisch laden
                                      FutureBuilder<List<dynamic>>(
                                        future: getCommentsForPost(postId),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const CircularProgressIndicator();
                                          } else if (snapshot.hasError) {
                                            return Text('Fehler beim Laden der Kommentare');
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
                                                alignment: Alignment.centerLeft,
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                                  child: Text(
                                                    '• ${comment['text']}',
                                                    style: const TextStyle(fontSize: 14),
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
              // "tgthr." text oben links
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
              // Drawer-Icon oben rechts
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
