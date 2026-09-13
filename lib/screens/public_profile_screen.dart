import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'lists_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  final String username;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isFollowing = false;

  List<dynamic> _userGames = [];
  List<dynamic> _userLists = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final following = await SupabaseService.isFollowing(widget.userId);
      final games = await SupabaseService.fetchPublicUserGames(widget.userId);
      final lists = await SupabaseService.fetchPublicUserLists(widget.userId);

      setState(() {
        _isFollowing = following;
        _userGames = games;
        _userLists = lists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error cargando perfil público: $e');
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => _isFollowing = !_isFollowing);
    try {
      if (_isFollowing) {
        await SupabaseService.followUser(widget.userId);
      } else {
        await SupabaseService.unfollowUser(widget.userId);
      }
    } catch (e) {
      setState(() => _isFollowing = !_isFollowing);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'playing':
        return 'Jugando';
      case 'completed':
        return 'Completado';
      case 'dropped':
        return 'Abandonado';
      case 'plan_to_play':
      default:
        return 'Pendiente';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'playing':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'dropped':
        return Colors.red;
      case 'plan_to_play':
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '@${widget.username}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1C2228),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: const Color(0xFF1C2228),
                  padding: const EdgeInsets.only(bottom: 16, top: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.greenAccent.withValues(
                          alpha: 0.2,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '@${widget.username}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing
                              ? Colors.transparent
                              : Colors.greenAccent,
                          foregroundColor: _isFollowing
                              ? Colors.white
                              : Colors.black,
                          side: _isFollowing
                              ? const BorderSide(color: Colors.grey)
                              : BorderSide.none,
                          minimumSize: const Size(140, 40),
                        ),
                        child: Text(
                          _isFollowing ? 'Siguiendo' : 'Seguir',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.greenAccent,
                  labelColor: Colors.greenAccent,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'Juegos'),
                    Tab(text: 'Listas'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _userGames.isEmpty
                          ? Center(
                              child: Text(
                                'Sin juegos.',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(10),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.72,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                              itemCount: _userGames.length,
                              itemBuilder: (context, index) {
                                final item = _userGames[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C2228),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(8),
                                              ),
                                          child: Image.network(
                                            item['cover_url'] ?? '',
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['game_name'] ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  _getStatusText(
                                                    item['status'],
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: _getStatusColor(
                                                      item['status'],
                                                    ),
                                                  ),
                                                ),
                                                if (item['rating'] != null)
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.star,
                                                        size: 12,
                                                        color: Colors.amber,
                                                      ),
                                                      Text(
                                                        '${item['rating']}',
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.amber,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                      _userLists.isEmpty
                          ? Center(
                              child: Text(
                                'Sin listas.',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _userLists.length,
                              itemBuilder: (context, index) {
                                final list = _userLists[index];
                                return Card(
                                  color: const Color(0xFF2C3440),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    title: Text(
                                      list['title'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: list['description'] != null
                                        ? Text(
                                            list['description'],
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                            ),
                                          )
                                        : null,
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.greenAccent,
                                      size: 16,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ListDetailScreen(
                                                listId: list['id'],
                                                listTitle: list['title'],
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
