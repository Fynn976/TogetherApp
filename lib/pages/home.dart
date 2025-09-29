import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loginpage/pages/ProfileForOthers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<dynamic> posts = [];
  TextEditingController _commentController = TextEditingController();
  String displayName = '...';
  bool isLoading = true;
  Map<int, bool> _showAllComments = {};
  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOut),
    );
    
    fetchPosts();
    fetchDisplayName();
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> fetchPosts() async {
    setState(() => isLoading = true);
    
    try {
      final response = await Supabase.instance.client
          .from('posts')
          .select('''
            id,
            image_url,
            caption,
            created_at,
            user_id,
            profiles (
              display_name,
              avatar_url,
              username,
              id
            )
          ''')
          .order('created_at', ascending: false);

      if (response != null) {
        final postsWithLikes = <dynamic>[];

        for (var post in response) {
          final postId = post['id'];
          final likesResponse = await Supabase.instance.client
              .from('likes')
              .select()
              .eq('post_id', postId);

          post['likes'] = likesResponse ?? [];
          postsWithLikes.add(post);
        }

        setState(() => posts = postsWithLikes);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden der Posts: $e')),
      );
    } finally {
      setState(() => isLoading = false);
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
        displayName = response['display_name'] ?? 'Athlet';
      });
    } catch (e) {
      setState(() => displayName = 'Athlet');
    }
  }

  Future<void> toggleLike(int postId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final existingLike = await Supabase.instance.client
          .from('likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
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

      await fetchPosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Like: $e')),
      );
    }
  }

  Future<void> addComment(int postId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final commentText = _commentController.text.trim();

    if (commentText.isEmpty || userId == null) return;

    try {
      await Supabase.instance.client.from('comments').insert({
        'post_id': postId,
        'user_id': userId,
        'text': commentText,
      });

      _commentController.clear();
      await fetchPosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Kommentieren: $e')),
      );
    }
  }

  Widget _buildMotivationalHeader() {
    final timeOfDay = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    
    if (timeOfDay < 12) {
      greeting = 'Guten Morgen';
      greetingIcon = Icons.wb_sunny;
    } else if (timeOfDay < 17) {
      greeting = 'Guten Tag';
      greetingIcon = Icons.wb_sunny;
    } else {
      greeting = 'Guten Abend';
      greetingIcon = Icons.nights_stay;
    }

    return FadeTransition(
      opacity: _headerAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                greetingIcon,
                color: Theme.of(context).colorScheme.inversePrimary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting, $displayName!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bereit für dein nächstes Training?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                
              ),
              child:  Icon(
                Icons.local_fire_department,
                color: Theme.of(context).colorScheme.inversePrimary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final currentUser = Supabase.instance.client.auth.currentUser!;
    final postId = post['id'];
    final imageUrl = post['image_url'];
    final caption = post['caption'] ?? '';
    final profile = post['profiles'];
    final postDisplayName = profile?['display_name'] ?? 'Unbekannt';
    final avatarUrl = profile?['avatar_url'];
    final profileId = profile?['id'];
    final likeList = post['likes'] as List<dynamic>? ?? [];
    final likeCount = likeList.length;
    final isLiked = likeList.any((like) => like['user_id'] == currentUser.id);
    final createdAt = DateTime.parse(post['created_at']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        
        
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Profil
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () {
                if (profileId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PublicProfilePage(userId: profileId.toString()),
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null ?  Icon(Icons.person, color: Theme.of(context).colorScheme.inversePrimary) : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          postDisplayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                        Text(
                          DateFormat('dd.MM.yyyy • HH:mm').format(createdAt),
                          style: TextStyle(
                            color:Theme.of(context).colorScheme.inversePrimary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 14,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Workout',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bild
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  insetPadding: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: InteractiveViewer(
                      child: Image.network(imageUrl, fit: BoxFit.contain),
                    ),
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 400),
              child: ClipRRect(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: Theme.of(context).colorScheme.surface,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            ),
          ),

          // Actions & Caption
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Like & Share Row
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => toggleLike(postId),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isLiked ? Colors.red.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isLiked ? Colors.red : Theme.of(context).colorScheme.inversePrimary!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Theme.of(context).colorScheme.inversePrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$likeCount',
                              style: TextStyle(
                                color: isLiked ? Colors.red : Theme.of(context).colorScheme.inversePrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).colorScheme.inversePrimary!, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.comment_outlined, size: 20, color: Theme.of(context).colorScheme.inversePrimary),
                          const SizedBox(width: 6),
                          Text(
                            'Kommentar',
                            style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (caption.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    caption,
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.inversePrimary,
                      height: 1.4,
                    ),
                  ),
                ],

                // Kommentare
                FutureBuilder(
                  future: Supabase.instance.client
                      .from('comments')
                      .select('text, profiles(id, display_name, username)')
                      .eq('post_id', postId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }

                    final comments = snapshot.data as List<dynamic>? ?? [];
                    if (comments.isEmpty) return const SizedBox.shrink();

                    final showAll = _showAllComments[postId] ?? false;
                    final commentsToShow = showAll ? comments : comments.take(2).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        ...commentsToShow.map((comment) {
                          final profile = comment['profiles'];
                          final authorName = profile?['display_name'] ?? 'Unbekannt';
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.inversePrimary,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: '$authorName ',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  TextSpan(text: comment['text']),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        
                        if (comments.length > 2)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showAllComments[postId] = !showAll;
                              });
                            },
                            child: Text(
                              showAll ? 'Weniger anzeigen' : 'Alle ${comments.length} Kommentare anzeigen',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                // Kommentar-Eingabe
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.inversePrimary!.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Theme.of(context).colorScheme.inversePrimary!),
                  ),
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Kommentar hinzufügen...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.send,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () => addComment(postId),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Bitte logge dich ein')));
    }

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
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
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
                          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Motivational Header
              SliverToBoxAdapter(child: _buildMotivationalHeader()),

              // Loading
              if (isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(50),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),

              // Empty State
              if (!isLoading && posts.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Zeit für den ersten Post!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Teile deine Workout-Erfolge mit der Community',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              // Posts
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildPostCard(posts[index]),
                  childCount: posts.length,
                ),
              ),

              // Bottom Padding
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        ),
      ),
    );
  }
}