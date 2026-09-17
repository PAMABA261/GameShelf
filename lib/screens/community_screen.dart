import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
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

  // Control del menú flotante en abanico
  bool _isFabOpen = false;

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

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
    });
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

  void _showCreateModal({required bool isPoll}) {
    // Cerramos el menú flotante primero
    setState(() => _isFabOpen = false);

    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final List<TextEditingController> optionControllers = [
      TextEditingController(),
      TextEditingController(),
    ];

    bool isSubmitting = false;
    bool isUploadingImage = false;

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
            Future<void> insertImage() async {
              final picker = ImagePicker();
              final image = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 70,
              );
              if (image == null) return;

              setModalState(() => isUploadingImage = true);
              try {
                final url = await SupabaseService.uploadPostImage(
                  File(image.path),
                );
                if (url != null) {
                  final currentText = contentController.text;
                  contentController.text = '$currentText\n![imagen]($url)\n';
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              } finally {
                setModalState(() => isUploadingImage = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isPoll
                              ? 'Nueva Encuesta'
                              : 'Nueva Publicación o Guía',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (!isPoll)
                          TextButton.icon(
                            onPressed: isUploadingImage ? null : insertImage,
                            icon: isUploadingImage
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.image,
                                    color: Colors.greenAccent,
                                  ),
                            label: const Text(
                              'Añadir foto',
                              style: TextStyle(color: Colors.greenAccent),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: isPoll
                            ? 'Pregunta de la encuesta'
                            : 'Título de la guía o reseña',
                        labelStyle: TextStyle(
                          color: isPoll
                              ? Colors.amberAccent
                              : Colors.greenAccent,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C3440),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (!isPoll)
                      TextField(
                        controller: contentController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 8,
                        decoration: InputDecoration(
                          labelText: 'Contenido (Soporta Markdown)',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: const Color(0xFF2C3440),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )
                    else ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Opciones de respuesta:',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(optionControllers.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: optionControllers[index],
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Opción ${index + 1}',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF2C3440),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              if (optionControllers.length > 2)
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    setModalState(() {
                                      optionControllers.removeAt(index);
                                    });
                                  },
                                ),
                            ],
                          ),
                        );
                      }),
                      if (optionControllers.length < 4)
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              optionControllers.add(TextEditingController());
                            });
                          },
                          icon: const Icon(
                            Icons.add,
                            color: Colors.amberAccent,
                            size: 18,
                          ),
                          label: const Text(
                            'Añadir otra opción',
                            style: TextStyle(color: Colors.amberAccent),
                          ),
                        ),
                    ],

                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPoll
                            ? Colors.amber[700]
                            : Colors.green[700],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      onPressed: isSubmitting || isUploadingImage
                          ? null
                          : () async {
                              final title = titleController.text.trim();

                              if (title.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Rellena el campo principal'),
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);
                              try {
                                if (isPoll) {
                                  final validOptions = optionControllers
                                      .map((c) => c.text.trim())
                                      .where((text) => text.isNotEmpty)
                                      .toList();

                                  if (validOptions.length < 2) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Introduce al menos 2 opciones válidas',
                                        ),
                                      ),
                                    );
                                    setModalState(() => isSubmitting = false);
                                    return;
                                  }

                                  await SupabaseService.createPollPost(
                                    title: title,
                                    question: title,
                                    options: validOptions,
                                  );
                                } else {
                                  final content = contentController.text.trim();
                                  if (content.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Rellena el contenido'),
                                      ),
                                    );
                                    setModalState(() => isSubmitting = false);
                                    return;
                                  }
                                  await SupabaseService.createPost(
                                    title: title,
                                    content: content,
                                  );
                                }

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
          final bool isPoll = post['is_poll'] == true;

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
                      Icon(
                        isPoll ? Icons.poll : Icons.person,
                        size: 18,
                        color: isPoll ? Colors.amberAccent : Colors.greenAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '@$username',
                        style: TextStyle(
                          color: isPoll
                              ? Colors.amberAccent
                              : Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isPoll) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amberAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Encuesta',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.amberAccent,
                            ),
                          ),
                        ),
                      ],
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

                  if (isPoll)
                    _PollWidget(postId: post['id'].toString())
                  else ...[
                    () {
                      final rawContent = post['content'] ?? '';
                      final imgMatch = RegExp(
                        r'!\[.*?\]\((.*?)\)',
                      ).firstMatch(rawContent);
                      final String? previewImageUrl = imgMatch?.group(1);
                      final cleanContent = rawContent
                          .replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '')
                          .replaceAll(RegExp(r'[*#_]'), '')
                          .trim();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (cleanContent.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              cleanContent,
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (previewImageUrl != null) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                previewImageUrl,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                          ],
                        ],
                      );
                    }(),
                  ],

                  const SizedBox(height: 12),
                  const Divider(color: Colors.grey),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      if (!isPoll)
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isTabPosts() {
    return _tabController.index == 1;
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
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [_buildUsersTab(), _buildPostsTab()],
          ),
          if (_isTabPosts() && _isFabOpen)
            GestureDetector(
              onTap: _toggleFab,
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
        ],
      ),
      floatingActionButton: _isTabPosts()
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_isFabOpen) ...[
                  FloatingActionButton.extended(
                    heroTag: 'poll_fab',
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                    onPressed: () => _showCreateModal(isPoll: true),
                    icon: const Icon(Icons.poll),
                    label: const Text(
                      'Crear Encuesta',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.extended(
                    heroTag: 'post_fab',
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    onPressed: () => _showCreateModal(isPoll: false),
                    icon: const Icon(Icons.edit_note),
                    label: const Text(
                      'Escribir Guía / Post',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                FloatingActionButton(
                  heroTag: 'main_fab',
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  onPressed: _toggleFab,
                  child: Icon(_isFabOpen ? Icons.close : Icons.add),
                ),
              ],
            )
          : null,
    );
  }
}

class _PollWidget extends StatefulWidget {
  final String postId;

  const _PollWidget({required this.postId});

  @override
  State<_PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<_PollWidget> {
  bool _isLoading = true;
  List<dynamic> _options = [];
  String? _userVotedOptionId;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    _loadPollData();
  }

  Future<void> _loadPollData() async {
    try {
      final options = await SupabaseService.fetchPollData(widget.postId);
      final votedId = await SupabaseService.getUserPollVote(widget.postId);
      if (mounted) {
        setState(() {
          _options = options;
          _userVotedOptionId = votedId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVote(String optionId) async {
    setState(() => _isVoting = true);
    try {
      await SupabaseService.votePoll(widget.postId, optionId);
      await _loadPollData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al emitir voto: $e')));
      }
    } finally {
      if (mounted) setState(() => _isVoting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.amberAccent,
            ),
          ),
        ),
      );
    }

    int totalVotes = 0;
    for (var opt in _options) {
      totalVotes += (opt['votes_count'] as num?)?.toInt() ?? 0;
    }

    final bool hasVoted = _userVotedOptionId != null;

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        children: _options.map((option) {
          final optionId = option['id'].toString();
          final optionText = option['option_text'] ?? '';
          final int votes = (option['votes_count'] as num?)?.toInt() ?? 0;
          final double percentage = totalVotes > 0 ? votes / totalVotes : 0.0;
          final bool isSelected = _userVotedOptionId == optionId;

          if (hasVoted) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF14181C),
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(color: Colors.amberAccent, width: 1.5)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          optionText,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.amberAccent
                                : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      Text(
                        '${(percentage * 100).toStringAsFixed(1)}% ($votes)',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: const Color(0xFF2C3440),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isSelected ? Colors.amberAccent : Colors.grey[600]!,
                    ),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            );
          } else {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
                onPressed: _isVoting ? null : () => _handleVote(optionId),
                child: Text(
                  optionText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }
        }).toList(),
      ),
    );
  }
}
