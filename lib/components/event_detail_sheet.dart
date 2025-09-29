import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loginpage/components/EventMap.dart';

class ModernEventDetailSheet extends StatefulWidget {
  final Map<String, dynamic> event;
  final VoidCallback onJoin;

  const ModernEventDetailSheet({
    Key? key,
    required this.event,
    required this.onJoin,
  }) : super(key: key);

  @override
  State<ModernEventDetailSheet> createState() => _ModernEventDetailSheetState();
}

class _ModernEventDetailSheetState extends State<ModernEventDetailSheet> {
  int _currentImageIndex = 0;
  bool isJoined = false;

  final Map<String, IconData> sportIcons = {
    'Fußball': Icons.sports_soccer,
    'Basketball': Icons.sports_basketball,
    'Tennis': Icons.sports_tennis,
    'Laufen': Icons.directions_run,
    'Schwimmen': Icons.pool,
    'Radfahren': Icons.directions_bike,
    'Fitness': Icons.fitness_center,
    'Volleyball': Icons.sports_volleyball,
    'Handball': Icons.sports_handball,
    'Klettern': Icons.terrain,
    'Yoga': Icons.self_improvement,
    'Boxen': Icons.sports_mma,
  };

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'Kein Datum verfügbar';
    
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('EEEE, d. MMMM yyyy • HH:mm', 'de_DE')
          .format(dateTime.toLocal());
    } catch (e) {
      return 'Ungültiges Datum';
    }
  }

  Widget _buildHeader() {
    final event = widget.event;
    final imageUrls = (event['image_urls'] as List<dynamic>?)?.cast<String>() ?? [];
    
    return Container(
      height: 300,
      child: Stack(
        children: [
          // Background Image/Placeholder
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: imageUrls.isNotEmpty
                ? PageView.builder(
                    itemCount: imageUrls.length,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderContent(),
                      );
                    },
                  )
                : _buildPlaceholderContent(),
          ),
          
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          
          // Content Overlay
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sportIcons[event['sport']] ?? Icons.sports,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        event['sport'] ?? 'Sport',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  event['title'] ?? 'Kein Titel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDateTime(event['time_and_date']),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // Image Indicators
          if (imageUrls.length > 1)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(imageUrls.length, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            sportIcons[widget.event['sport']] ?? Icons.sports,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            widget.event['sport'] ?? 'Sport Event',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsCard() {
    final event = widget.event;
    final current = event['current_participants'] ?? 0;
    final max = event['max_participants'] ?? 0;
    final percentage = max > 0 ? (current / max) : 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.group,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Teilnehmer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '$current',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                ' / $max',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                '${(percentage * 100).toInt()}% voll',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage > 0.8 ? Colors.red : Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final double latitude = (event['latitude'] as num?)?.toDouble() ?? 0;
    final double longitude = (event['longitude'] as num?)?.toDouble() ?? 0;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Join Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    margin: const EdgeInsets.only(bottom: 24),
                    child: ElevatedButton(
                      onPressed: isJoined ? null : widget.onJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isJoined 
                            ? Colors.green 
                            : Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isJoined ? Icons.check : Icons.group_add,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isJoined ? 'Bereits angemeldet' : 'Event beitreten',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Participants Card
                  _buildParticipantsCard(),
                  
                  // Event Info Cards
                  if (event['description'] != null && event['description'].toString().isNotEmpty)
                    _buildInfoCard(
                      title: 'Beschreibung',
                      content: event['description'],
                      icon: Icons.description,
                    ),
                  
                  _buildInfoCard(
                    title: 'Ort',
                    content: event['location_name'] ?? 'Ort nicht angegeben',
                    icon: Icons.location_on,
                  ),
                  
                  if (event['time_and_date'] != null)
                    _buildInfoCard(
                      title: 'Datum & Uhrzeit',
                      content: _formatDateTime(event['time_and_date']),
                      icon: Icons.schedule,
                    ),
                  
                  // Map placeholder
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: EventMap(latitude: latitude, longitude: longitude),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}