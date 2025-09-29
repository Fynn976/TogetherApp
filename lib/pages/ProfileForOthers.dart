import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublicProfilePage extends StatefulWidget {
  final String userId;

  const PublicProfilePage({super.key, required this.userId});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> with TickerProviderStateMixin {
  Map<String, dynamic>? profileData;
  List<dynamic> userPosts = [];
  bool isLoading = true;
  bool isRequestSent = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    loadProfile();
    fetchUserPosts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('username, avatar_url, favorite_sport, display_name')
          .eq('id', widget.userId)
          .maybeSingle();

      setState(() {
        profileData = response;
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden des Profils: $e')),
      );
    }
  }

  Future<void> fetchUserPosts() async {
    try {
      final response = await Supabase.instance.client
          .from('posts')
          .select('id, image_url, created_at, likes, caption')
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);

      setState(() {
        userPosts = response;
      });
    } catch (e) {
      print('Fehler beim Laden der Posts: $e');
    }
  }

  Future<void> sendFriendRequest(String receiverId) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      _showSnackBar('Du musst eingeloggt sein');
      return;
    }
    if (currentUserId == receiverId) {
      _showSnackBar('Du kannst dir selbst keine Freundschaftsanfrage senden');
      return;
    }

    try {
      await Supabase.instance.client.from('friend_requests').insert({
        'requester_id': currentUserId,
        'receiver_id': receiverId,
        'status': 'pending',
      });

      setState(() => isRequestSent = true);
      _showSnackBar('Freundschaftsanfrage gesendet!', isSuccess: true);
    } catch (e) {
      _showSnackBar('Fehler beim Senden der Anfrage');
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            Theme.of(context).colorScheme.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color:Theme.of(context).colorScheme.inversePrimary, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style:  TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style:  TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportBadge(String sport) {
    final sportIcons = {
      'Fußball': Icons.sports_soccer,
      'Basketball': Icons.sports_basketball,
      'Tennis': Icons.sports_tennis,
      'Laufen': Icons.directions_run,
      'Schwimmen': Icons.pool,
      'Radfahren': Icons.directions_bike,
      'Fitness': Icons.fitness_center,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sportIcons[sport] ?? Icons.sports,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            sport,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Profil wird geladen...'),
            ],
          ),
        ),
      );
    }

    if (profileData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil nicht gefunden')),
        body: const Center(child: Text('Profil konnte nicht geladen werden')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Sport-inspirierte App Bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      // Profilbild mit Sport-Ring
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          backgroundImage: profileData!['avatar_url'] != null
                              ? NetworkImage(profileData!['avatar_url'])
                              : null,
                          child: profileData!['avatar_url'] == null
                              ?  Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.primary)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profileData!['display_name'] ?? '@${profileData!['username']}',
                        style:  TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${profileData!['username']}',
                        style:  TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (profileData!['favorite_sport'] != null)
                        _buildSportBadge(profileData!['favorite_sport']),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Posts',
                          '${userPosts.length}',
                          Icons.photo_library,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Aktivität',
                          'Hoch',
                          Icons.local_fire_department,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Level',
                          '12',
                          Icons.emoji_events,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isRequestSent ? null : () => sendFriendRequest(widget.userId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRequestSent ? Colors.grey : Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 3,
                      ),
                      icon: Icon(
                        isRequestSent ? Icons.check : Icons.person_add,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                      label: Text(
                        isRequestSent ? 'Anfrage gesendet' : 'Freund hinzufügen',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Posts Section Header
                  Row(
                    children: [
                      Icon(
                        Icons.grid_on,
                        color: Theme.of(context).colorScheme.inversePrimary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Trainings-Posts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          // Posts Grid
          userPosts.isEmpty
              ? SliverToBoxAdapter(
                  child: Container(
                    height: 200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Noch keine Posts',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Erste Trainings-Erfolge teilen!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = userPosts[index];
                        return _buildPostTile(post);
                      },
                      childCount: userPosts.length,
                    ),
                  ),
                ),
          
          // Bottom Spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildPostTile(Map<String, dynamic> post) {
    return GestureDetector(
      onTap: () => _showPostDetail(post),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                post['image_url'],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.grey),
                  );
                },
              ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostDetail(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        post['image_url'],
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Caption if available
                    if (post['caption'] != null) ...[
                      Text(
                        post['caption'],
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Stats
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text('${post['likes'] ?? 0} Likes'),
                        const SizedBox(width: 20),
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateTime.parse(post['created_at']).day.toString() + '.' +
                          DateTime.parse(post['created_at']).month.toString() + '.' +
                          DateTime.parse(post['created_at']).year.toString(),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}