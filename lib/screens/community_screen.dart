import 'package:flutter/material.dart';
import 'dart:async';
import '../services/supabase_service.dart';
import 'public_profile_screen.dart';
import 'post_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<dynamic> _users = [];
  bool _isLoadingUsers = false;

  List<dynamic> _posts = [];
  bool _isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final trimmedQuery = query.trim();
      if (trimmedQuery.isNotEmpty) {
        setState(() => _isLoadingUsers = true);
        try {
          final results = await SupabaseService.searchUsers(trimmedQuery);
          setState(() {
            _users = results;
            _isLoadingUsers = false;
          });
        } catch (e) {
          setState(() => _isLoadingUsers = false);
          debugPrint('Error buscando usuarios: $e');
        }
      } else {
        setState(() {
          _users = [];
          _isLoadingUsers = false;
        });
      }
    });
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoadingPosts = true);
    try {
      final posts = await SupabaseService.fetchAllPosts();
      setState(() {
        _posts = posts;
        _isLoadingPosts = false;
      });
    } catch (e) {
      debugPrint('Error cargando posts: $e');
      setState(() => _isLoadingPosts = false);
    }
  }

  void _showCreatePostModal() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C2228),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nueva Publicación',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Título de la guía o reseña',
                      labelStyle: const TextStyle(color: Colors.greenAccent),
                      filled: true,
                      fillColor: const Color(0xFF2C3440),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: 'Contenido (escribe lo que quieras...)',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFF2C3440),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final title = titleController.text.trim();
                            final content = contentController.text.trim();

                            if (title.isEmpty || content.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Rellena título y contenido'),
                                ),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);
                            try {
                              await SupabaseService.createPost(
                                title: title,
                                content: content,
                              );
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              _loadPosts();
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Publicar'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar usuarios...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: const Color(0xFF2C3440),
              prefixIcon: const Icon(Icons.search, color: Colors.greenAccent),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (_isLoadingUsers)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            ),
          )
        else
          Expanded(
            child: _users.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Busca a tus amigos por su nombre.'
                          : 'No se encontraron usuarios.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.greenAccent.withValues(
                            alpha: 0.2,
                          ),
                          backgroundImage: user['avatar_url'] != null
                              ? NetworkImage(user['avatar_url'])
                              : null,
                          child: user['avatar_url'] == null
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.greenAccent,
                                )
                              : null,
                        ),
                        title: Text(
                          '@${user['username'] ?? 'Usuario'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PublicProfileScreen(
                                userId: user['id'],
                                username: user['username'],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
      ],
    );
  }

  Widget _buildPostsTab() {
    if (_isLoadingPosts) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.greenAccent),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Text(
          'No hay publicaciones aún.\n¡Anímate a escribir la primera!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.greenAccent,
      backgroundColor: const Color(0xFF2C3440),
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          final profile = post['profiles'];
          final username = profile != null
              ? profile['username']
              : 'Desconocido';

          return Card(
            color: const Color(0xFF2C3440),
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 18,
                        color: Colors.greenAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '@$username',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        post['created_at'] != null
                            ? post['created_at'].toString().substring(0, 10)
                            : '',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post['title'] ?? 'Sin título',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post['content'] ?? '',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.grey),

                  // --- AQUÍ ESTÁ EL CAMBIO ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // El contador de likes
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${post['like_count'] ?? 0}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      // El botón de leer más
                      TextButton(
                        onPressed: () async {
                          final hasChanges = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PostDetailScreen(post: post),
                            ),
                          );

                          if (hasChanges == true && context.mounted) {
                            _loadPosts();
                          }
                        },
                        child: const Text(
                          'Leer más',
                          style: TextStyle(color: Colors.greenAccent),
                        ),
                      ),
                    ],
                  ),

                  // --- FIN DEL CAMBIO ---
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Comunidad',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1C2228),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.greenAccent,
          labelColor: Colors.greenAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Usuarios'),
            Tab(text: 'Publicaciones'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildUsersTab(), _buildPostsTab()],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              onPressed: _showCreatePostModal,
              child: const Icon(Icons.edit),
            )
          : null,
    );
  }
}
