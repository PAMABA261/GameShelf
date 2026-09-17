import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Map<String, dynamic> _currentPost;
  bool _isSubmitting = false;
  bool _hasChanges = false;

  int _likeCount = 0;
  bool _isLiked = false;
  bool _isLoadingLikes = true;

  List<dynamic> _comments = [];
  bool _isLoadingComments = true;
  bool _isSubmittingComment = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentPost = Map<String, dynamic>.from(widget.post);
    _loadLikesData();
    _loadCommentsData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadLikesData() async {
    try {
      final postId = _currentPost['id'].toString();
      final count = await SupabaseService.getPostLikesCount(postId);
      final liked = await SupabaseService.hasUserLikedPost(postId);

      if (mounted) {
        setState(() {
          _likeCount = count;
          _isLiked = liked;
          _isLoadingLikes = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando likes: $e');
      if (mounted) setState(() => _isLoadingLikes = false);
    }
  }

  Future<void> _handleToggleLike() async {
    final wasLiked = _isLiked;

    setState(() {
      _isLiked = !wasLiked;
      _likeCount += wasLiked ? -1 : 1;
    });

    try {
      await SupabaseService.toggleLike(_currentPost['id'].toString(), wasLiked);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          _likeCount += wasLiked ? 1 : -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar el like: $e')),
        );
      }
    }
  }

  Future<void> _loadCommentsData() async {
    try {
      final postId = _currentPost['id'].toString();
      final comments = await SupabaseService.fetchComments(postId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando comentarios: $e');
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmittingComment = true);
    try {
      await SupabaseService.addComment(_currentPost['id'].toString(), text);
      _commentController.clear();
      FocusScope.of(context).unfocus();
      await _loadCommentsData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al comentar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  Future<void> _handleDeleteComment(String commentId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3440),
        title: const Text(
          'Borrar comentario',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Quieres borrar este comentario?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Borrar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await SupabaseService.deleteComment(commentId);
        await _loadCommentsData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Comentario borrado')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al borrar: $e')));
        }
      }
    }
  }

  void _showEditModal() {
    final titleController = TextEditingController(text: _currentPost['title']);
    final contentController = TextEditingController(
      text: _currentPost['content'],
    );

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
                    'Editar Publicación',
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
                      labelStyle: const TextStyle(color: Colors.blueAccent),
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
                      labelText: 'Contenido',
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
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            final newTitle = titleController.text.trim();
                            final newContent = contentController.text.trim();

                            if (newTitle.isEmpty || newContent.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Rellena título y contenido'),
                                ),
                              );
                              return;
                            }

                            setModalState(() => _isSubmitting = true);
                            try {
                              await SupabaseService.updatePost(
                                postId: _currentPost['id'].toString(),
                                title: newTitle,
                                content: newContent,
                              );

                              setState(() {
                                _currentPost['title'] = newTitle;
                                _currentPost['content'] = newContent;
                                _hasChanges = true;
                              });

                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Publicación editada'),
                                ),
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error al editar: $e'),
                                  ),
                                );
                              }
                            } finally {
                              setModalState(() => _isSubmitting = false);
                            }
                          },
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Guardar cambios'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _currentPost['profiles'];
    final username = profile != null ? profile['username'] : 'Desconocido';
    final date = _currentPost['created_at'] != null
        ? _currentPost['created_at'].toString().substring(0, 10)
        : '';

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = currentUserId == _currentPost['user_id'];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasChanges);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF14181C),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          title: const Text(
            'Publicación',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF1C2228),
          actions: [
            if (isOwner)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                tooltip: 'Editar publicación',
                onPressed: _showEditModal,
              ),
            if (isOwner)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                tooltip: 'Borrar publicación',
                onPressed: () async {
                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF2C3440),
                      title: const Text(
                        'Borrar publicación',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        '¿Estás seguro de que quieres eliminar esta publicación para siempre?',
                        style: TextStyle(color: Colors.grey),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Borrar',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmar == true) {
                    try {
                      await SupabaseService.deletePost(
                        _currentPost['id'].toString(),
                      );
                      if (context.mounted) {
                        Navigator.pop(context, true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Publicación borrada con éxito'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al borrar: $e')),
                        );
                    }
                  }
                },
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.greenAccent.withValues(alpha: 0.2),
                    radius: 24,
                    backgroundImage:
                        profile != null && profile['avatar_url'] != null
                        ? NetworkImage(profile['avatar_url'])
                        : null,
                    child: profile == null || profile['avatar_url'] == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.greenAccent,
                            size: 24,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@$username',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        date,
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _currentPost['title'] ?? 'Sin título',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _currentPost['content'] ?? '',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),

              // Barra de Likes
              _isLoadingLikes
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: Colors.redAccent),
                    )
                  : Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked ? Colors.redAccent : Colors.grey,
                            size: 28,
                          ),
                          onPressed: _handleToggleLike,
                        ),
                        Text(
                          '$_likeCount',
                          style: TextStyle(
                            color: _isLiked ? Colors.redAccent : Colors.grey,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

              const Divider(color: Colors.grey, height: 40),

              const Text(
                'Comentarios',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Escribe un comentario...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: const Color(0xFF2C3440),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSubmittingComment
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.greenAccent,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.greenAccent,
                          ),
                          onPressed: _submitComment,
                        ),
                ],
              ),
              const SizedBox(height: 24),

              _isLoadingComments
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.greenAccent,
                      ),
                    )
                  : _comments.isEmpty
                  ? Center(
                      child: Text(
                        'Aún no hay comentarios.\n¡Sé el primero en opinar!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        final commentProfile = comment['profiles'];
                        final commentUsername = commentProfile != null
                            ? commentProfile['username']
                            : 'Usuario';
                        final isCommentOwner =
                            currentUserId == comment['user_id'];

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C2228),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.greenAccent
                                        .withValues(alpha: 0.2),
                                    backgroundImage:
                                        commentProfile != null &&
                                            commentProfile['avatar_url'] != null
                                        ? NetworkImage(
                                            commentProfile['avatar_url'],
                                          )
                                        : null,
                                    child:
                                        commentProfile == null ||
                                            commentProfile['avatar_url'] == null
                                        ? const Icon(
                                            Icons.person,
                                            color: Colors.greenAccent,
                                            size: 14,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '@$commentUsername',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isCommentOwner)
                                    GestureDetector(
                                      onTap: () => _handleDeleteComment(
                                        comment['id'].toString(),
                                      ),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                comment['content'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
