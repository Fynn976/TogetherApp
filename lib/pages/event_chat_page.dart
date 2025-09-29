import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventChatPage extends StatefulWidget {
  final String eventId;
  const EventChatPage({super.key, required this.eventId});

  @override
  State<EventChatPage> createState() => _EventChatPageState();
}

class _EventChatPageState extends State<EventChatPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  RealtimeChannel? _channel;

  bool isCreator = false;
  bool isLoading = true;
  String? creatorId;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    await _checkIfCreator();
    await _loadMessages();
    await _loadSenderAvatars();
    _subscribeMessages();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _checkIfCreator() async {
    final response = await supabase
        .from('events')
        .select('created_by')
        .eq('id', widget.eventId)
        .maybeSingle();

    final currentUserId = supabase.auth.currentUser!.id;

    if (response != null) {
      creatorId = response['created_by'] as String;
      isCreator = creatorId == currentUserId;
    }
  }

  Future<void> _loadMessages() async {
    final response = await supabase
        .from('event_messages')
        .select('id, message, sender_id, created_at')
        .eq('event_id', widget.eventId)
        .order('created_at');

    setState(() {
      messages = response != null
          ? List<Map<String, dynamic>>.from(response)
          : [];
    });
  }

  Future<void> _loadSenderAvatars() async {
    final senderIds = messages
        .map((m) => m['sender_id'] as String)
        .toSet()
        .toList();
    if (senderIds.isEmpty) return;

    final avatarsResponse = await supabase
        .from('profiles')
        .select('id, avatar_url')
        .filter('id', 'in', senderIds);

    final avatarsList = avatarsResponse != null
        ? List<Map<String, dynamic>>.from(avatarsResponse)
        : [];

    final avatarsMap = <String, String>{};
    for (var profile in avatarsList) {
      avatarsMap[profile['id']] = profile['avatar_url'] ?? '';
    }

    setState(() {
      for (var msg in messages) {
        msg['sender_avatar_url'] = avatarsMap[msg['sender_id']] ?? '';
      }
    });
  }

  void _subscribeMessages() {
    _channel = supabase.channel('event_chat_${widget.eventId}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'event_messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'event_id',
          value: widget.eventId,
        ),
        callback: (payload) async {
          final newMsg = Map<String, dynamic>.from(payload.newRecord);

          // Avatar laden
          final profile = await supabase
              .from('profiles')
              .select('avatar_url')
              .eq('id', newMsg['sender_id'])
              .maybeSingle();

          newMsg['sender_avatar_url'] = profile?['avatar_url'] ?? '';

          setState(() {
            messages.add(newMsg);
          });
        },
      )
      ..subscribe();
  }

  Future<void> _sendMessage() async {
    if (!isCreator) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      await supabase.from('event_messages').insert({
        'event_id': widget.eventId,
        'sender_id': supabase.auth.currentUser!.id,
        'message': text,
      });
      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fehler beim Senden der Nachricht!')),
      );
    }
  }

  @override
  void dispose() {
    if (_channel != null) supabase.removeChannel(_channel!);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Event-Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isCreatorMessage = msg['sender_id'] == creatorId;

                return Align(
                  alignment: isCreatorMessage
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isCreatorMessage)
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                              msg['sender_avatar_url'] ?? ''),
                          radius: 16,
                        ),
                      if (!isCreatorMessage) const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.7),
                        decoration: BoxDecoration(
                          color: isCreatorMessage
                              ? Colors.blueAccent
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['message'],
                              style: TextStyle(
                                  color: isCreatorMessage
                                      ? Colors.white
                                      : Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('HH:mm dd.MM.')
                                  .format(DateTime.parse(msg['created_at'])),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isCreatorMessage
                                      ? Colors.white70
                                      : Colors.black45),
                            ),
                          ],
                        ),
                      ),
                      if (isCreatorMessage) const SizedBox(width: 6),
                      if (isCreatorMessage)
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                              msg['sender_avatar_url'] ?? ''),
                          radius: 16,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: isCreator,
                    decoration: InputDecoration(
                      hintText: isCreator
                          ? "Nachricht eingeben..."
                          : "Nur der Ersteller darf schreiben",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: isCreator ? _sendMessage : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
