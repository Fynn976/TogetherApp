import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loginpage/pages/ProfileForOthers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendChatPage extends StatefulWidget {
  final String friendId;
  final String friendUsername;
  final String? friendAvatarUrl;

  const FriendChatPage({
    super.key,
    required this.friendId,
    required this.friendUsername,
    this.friendAvatarUrl,
  });

  @override
  State<FriendChatPage> createState() => _FriendChatPageState();
}

class _FriendChatPageState extends State<FriendChatPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> messages = [];
  RealtimeChannel? _channel;
  Map<String, Map<String, dynamic>> _profileCache = {};
  bool isLoading = true;
  bool isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initChat();
    
    // Auto-scroll bei Keyboard
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollToBottom();
        });
      }
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    try {
      await _loadMessages();
      _subscribeMessages();
    } catch (e) {
      setState(() => _error = 'Fehler beim Laden des Chats: $e');
    } finally {
      setState(() => isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _loadMessages() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) throw 'Nicht eingeloggt';

    // Optimierte Query mit besserer Filter-Syntax
    final response = await supabase
        .from('friends_messages')
        .select('id, message, sender_id, receiver_id, created_at')
        .or('and(sender_id.eq.$currentUserId,receiver_id.eq.${widget.friendId}),and(sender_id.eq.${widget.friendId},receiver_id.eq.$currentUserId)')
        .order('created_at', ascending: true)
        .limit(100); // Limit für Performance

    if (response.isNotEmpty) {
      await _loadProfilesForMessages(response);
      
      final messagesWithProfiles = response.map((msg) {
        final senderId = msg['sender_id'] as String;
        return {
          ...msg,
          'sender': _profileCache[senderId],
        };
      }).toList();

      setState(() => messages = messagesWithProfiles);
    }
  }

  Future<void> _loadProfilesForMessages(List<Map<String, dynamic>> messages) async {
    final senderIds = messages
        .map((msg) => msg['sender_id'] as String)
        .where((id) => !_profileCache.containsKey(id))
        .toSet();

    if (senderIds.isEmpty) return;

    final profiles = await supabase
        .from('profiles')
        .select('id, username, avatar_url')
        .filter('id', 'in', senderIds.toList());

    for (final profile in profiles) {
      _profileCache[profile['id']] = profile;
    }
  }

  void _subscribeMessages() {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    _channel = supabase.channel('friend_chat_${currentUserId}_${widget.friendId}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'friends_messages',
        callback: _handleNewMessage,
      )
      ..subscribe();
  }

  void _handleNewMessage(PostgresChangePayload payload) async {
    final newMsg = Map<String, dynamic>.from(payload.newRecord);
    final senderId = newMsg['sender_id'];
    final receiverId = newMsg['receiver_id'];
    final currentUserId = supabase.auth.currentUser?.id;

    // Prüfe ob Nachricht für diesen Chat relevant ist
    if (!((senderId == currentUserId && receiverId == widget.friendId) ||
          (senderId == widget.friendId && receiverId == currentUserId))) {
      return;
    }

    // Lade Profil falls nicht gecacht
    if (!_profileCache.containsKey(senderId)) {
      try {
        final profile = await supabase
            .from('profiles')
            .select('id, username, avatar_url')
            .eq('id', senderId)
            .single();
        _profileCache[senderId] = profile;
      } catch (e) {
        print('Fehler beim Laden des Profils: $e');
      }
    }

    if (mounted) {
      setState(() {
        messages.add({
          ...newMsg,
          'sender': _profileCache[senderId],
        });
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null || isSending) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => isSending = true);

    try {
      // Optimistisches Update - Message sofort anzeigen
      final tempMessage = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'message': text,
        'sender_id': currentUserId,
        'receiver_id': widget.friendId,
        'created_at': DateTime.now().toIso8601String(),
        'sender': _profileCache[currentUserId],
        'isTemp': true, // Flag für temporäre Message
      };

      setState(() {
        messages.add(tempMessage);
      });
      _controller.clear();
      _scrollToBottom();

      // Tatsächlich senden
      await supabase.from('friends_messages').insert({
        'sender_id': currentUserId,
        'receiver_id': widget.friendId,
        'message': text,
      });

      // Temporäre Message entfernen (echte kommt über Realtime)
      setState(() {
        messages.removeWhere((msg) => msg['isTemp'] == true);
      });

    } catch (e) {
      // Bei Fehler: temporäre Message entfernen und Fehler anzeigen
      setState(() {
        messages.removeWhere((msg) => msg['isTemp'] == true);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Senden: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Erneut versuchen',
              onPressed: () {
                _controller.text = text;
                _sendMessage();
              },
            ),
          ),
        );
      }
    } finally {
      setState(() => isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessage(Map<String, dynamic> message, bool isMe) {
    final isTemp = message['isTemp'] == true;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe 
              ? Theme.of(context).colorScheme.primary.withOpacity(isTemp ? 0.6 : 1.0)
              : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message['message'],
              style: TextStyle(
                fontSize: 16,
                color: isMe 
                    ? Theme.of(context).colorScheme.inversePrimary
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(
                    DateTime.parse(message['created_at']).toLocal(),
                  ),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe 
                        ? Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7)
                        : Colors.grey[600],
                  ),
                ),
                if (isTemp) ...[
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PublicProfilePage(userId: widget.friendId),
              ),
            );
          },
          child: Row(
            children: [
              Hero(
                tag: 'avatar_${widget.friendId}',
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: (widget.friendAvatarUrl?.isNotEmpty == true)
                      ? NetworkImage(widget.friendAvatarUrl!)
                      : null,
                  child: (widget.friendAvatarUrl?.isEmpty != false)
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.friendUsername,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    // Optional: Online-Status hier anzeigen
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _initChat(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_error != null)
              Container(
                width: double.infinity,
                color: Colors.red.shade100,
                padding: const EdgeInsets.all(8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Noch keine Nachrichten',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Schreibe die erste Nachricht!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[messages.length - 1 - index];
                            final currentUserId = supabase.auth.currentUser?.id;
                            final isMe = message['sender_id'] == currentUserId;
                            
                            return _buildMessage(message, isMe);
                          },
                        ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[300]!,
                    width: 0.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(25.0),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'Nachricht schreiben...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 10.0,
                          ),
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.6),
                          ),
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                        maxLines: 3,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(25),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: isSending ? null : _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: isSending
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.inversePrimary,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.send,
                                color: Theme.of(context).colorScheme.inversePrimary,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}