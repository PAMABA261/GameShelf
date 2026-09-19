import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool _isLoading = true;
  List<dynamic> _feed = [];

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    try {
      final feed = await SupabaseService.fetchActivityFeed();
      setState(() {
        _feed = feed;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading feed: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getActionText(String status) {
    switch (status) {
      case 'playing':
        return 'started playing';
      case 'completed':
        return 'completed';
      case 'dropped':
        return 'dropped';
      case 'plan_to_play':
      default:
        return 'added to plan to play';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recent Activity',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1C2228),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : RefreshIndicator(
              color: Colors.greenAccent,
              backgroundColor: const Color(0xFF2C3440),
              onRefresh: _loadFeed,
              child: _feed.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                        ),
                        Text(
                          'Your feed is empty.\nFollow other users in Community to see what they are playing.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: _feed.length,
                      separatorBuilder: (context, index) =>
                          const Divider(color: Colors.grey),
                      itemBuilder: (context, index) {
                        final item = _feed[index];
                        final username = item['username'] ?? 'User';
                        final gameName = item['game_name'] ?? 'a game';
                        final coverUrl = item['cover_url'] ?? '';
                        final actionText = _getActionText(item['status']);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.greenAccent.withValues(
                                  alpha: 0.2,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.greenAccent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '@$username ',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.greenAccent,
                                            ),
                                          ),
                                          TextSpan(text: '$actionText '),
                                          TextSpan(
                                            text: gameName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (item['rating'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Row(
                                          children: [
                                            const Text(
                                              'Rating: ',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Row(
                                              children: List.generate(5, (
                                                starIndex,
                                              ) {
                                                return Icon(
                                                  starIndex <
                                                          (item['rating']
                                                                  as num)
                                                              .toDouble()
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  size: 14,
                                                  color: Colors.amber,
                                                );
                                              }),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  coverUrl,
                                  width: 50,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
