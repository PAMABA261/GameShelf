import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';
import 'lists_screen.dart';
import 'login_screen.dart';
import 'paywall_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _username = 'Cargando...';
  String _bio = '';
  String _avatarUrl = '';
  String _bannerUrl = '';
  List<dynamic> _favoriteGames = [];
  int _gamesCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.client.auth.currentUser!.id;

      final profileData = await SupabaseService.getUserProfile(userId);
      final games = await SupabaseService.fetchUserGames();
      final followers = await SupabaseService.getFollowersCount(userId);
      final following = await SupabaseService.getFollowingCount(userId);

      setState(() {
        if (profileData != null) {
          _username = profileData['username'] ?? 'Usuario';
          _bio = profileData['bio'] ?? '';
          _avatarUrl = profileData['avatar_url'] ?? '';
          _bannerUrl = profileData['banner_url'] ?? '';
          _favoriteGames = profileData['favorite_games'] ?? [];
        }
        _gamesCount = games.length;
        _followersCount = followers;
        _followingCount = following;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage(String type) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      final File file = File(image.path);
      final newUrl = await SupabaseService.uploadProfileImage(file, type);

      if (newUrl != null) {
        setState(() {
          if (type == 'avatar') _avatarUrl = newUrl;
          if (type == 'banner') _bannerUrl = newUrl;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Imagen actualizada con éxito!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al subir imagen: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEditProfileDialog() {
    final usernameCtrl = TextEditingController(text: _username);
    final bioCtrl = TextEditingController(text: _bio);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C3440),
          title: const Text(
            'Editar Perfil',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nombre de usuario',
                  labelStyle: TextStyle(color: Colors.greenAccent),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Biografía',
                  labelStyle: TextStyle(color: Colors.greenAccent),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
              ),
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  await SupabaseService.updateProfile(
                    usernameCtrl.text.trim(),
                    bioCtrl.text.trim(),
                  );
                  _loadProfileData();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al guardar: $e')),
                    );
                  }
                  setState(() => _isLoading = false);
                }
              },
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatColumn(String title, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
      ],
    );
  }

  Widget _buildFavoritesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top 4 Favoritos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) {
            final bool hasGame = index < _favoriteGames.length;
            final game = hasGame ? _favoriteGames[index] : null;

            return GestureDetector(
              onTap: () => _showSelectFavoriteModal(index),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.2,
                height: MediaQuery.of(context).size.width * 0.28,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3440),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasGame ? Colors.transparent : Colors.grey[700]!,
                    width: 1,
                  ),
                ),
                child: hasGame
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          game['cover_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.videogame_asset,
                                color: Colors.grey,
                              ),
                        ),
                      )
                    : const Icon(Icons.add, color: Colors.grey, size: 30),
              ),
            );
          }),
        ),
      ],
    );
  }

  void _showSelectFavoriteModal(int targetIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C2228),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: _FavoriteSearchModal(
            targetIndex: targetIndex,
            currentFavorites: _favoriteGames,
            onFavoritesUpdated: (updatedFavorites) async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await SupabaseService.updateFavoriteGames(updatedFavorites);
                await _loadProfileData();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al guardar favorito: $e')),
                  );
                }
                setState(() => _isLoading = false);
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1C2228),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    GestureDetector(
                      onTap: () => _pickAndUploadImage('banner'),
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 50),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C3440),
                          image: _bannerUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(_bannerUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          gradient: _bannerUrl.isEmpty
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF0F2027),
                                    Color(0xFF203A43),
                                    Color(0xFF2C5364),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () => _pickAndUploadImage('avatar'),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 54,
                              backgroundColor: const Color(0xFF1C2228),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.greenAccent.withValues(
                                  alpha: 0.2,
                                ),
                                backgroundImage: _avatarUrl.isNotEmpty
                                    ? NetworkImage(_avatarUrl)
                                    : null,
                                child: _avatarUrl.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.greenAccent,
                                      )
                                    : null,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF1C2228),
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.black,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Text(
                  '@$_username',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (_bio.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                      left: 16,
                      right: 16,
                    ),
                    child: Text(
                      _bio,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                    ),
                  ),
                const SizedBox(height: 16),
                Center(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey[600]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar perfil'),
                    onPressed: _showEditProfileDialog,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C3440),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('Juegos', _gamesCount),
                      Container(width: 1, height: 40, color: Colors.grey[700]),
                      _buildStatColumn('Seguidores', _followersCount),
                      Container(width: 1, height: 40, color: Colors.grey[700]),
                      _buildStatColumn('Siguiendo', _followingCount),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildFavoritesSection(),
                const SizedBox(height: 32),
                const Divider(color: Colors.grey),
                const SizedBox(height: 8),

                // --- NUEVO BOTÓN PARA EL PAYWALL DE REVENUECAT ---
                ListTile(
                  leading: const Icon(Icons.star, color: Colors.amberAccent),
                  title: const Text(
                    'Backloggd PRO',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaywallScreen(),
                      ),
                    );
                  },
                ),

                // -------------------------------------------------
                ListTile(
                  leading: const Icon(
                    Icons.list_alt,
                    color: Colors.greenAccent,
                  ),
                  title: const Text(
                    'Mis Listas Personalizadas',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ListsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () async {
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF2C3440),
                        title: const Text(
                          'Cerrar Sesión',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          '¿Estás seguro de que quieres salir?',
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
                              'Salir',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmar == true) {
                      await SupabaseService.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
    );
  }
}

class _FavoriteSearchModal extends StatefulWidget {
  final int targetIndex;
  final List<dynamic> currentFavorites;
  final Function(List<dynamic>) onFavoritesUpdated;

  const _FavoriteSearchModal({
    required this.targetIndex,
    required this.currentFavorites,
    required this.onFavoritesUpdated,
  });

  @override
  State<_FavoriteSearchModal> createState() => _FavoriteSearchModalState();
}

class _FavoriteSearchModalState extends State<_FavoriteSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<dynamic> _games = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      final trimmedQuery = query.trim();
      if (trimmedQuery.isNotEmpty) {
        _searchGames(trimmedQuery);
      } else {
        setState(() {
          _games = [];
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _searchGames(String query) async {
    setState(() => _isSearching = true);
    final url = Uri.parse('https://api.igdb.com/v4/games');
    try {
      final response = await http.post(
        url,
        headers: {
          'Client-ID': 'lcgl4fyetyqozygtae145slsb7hup8',
          'Authorization': 'Bearer yhkdljdry753rq5alsul6bahe2c41v',
          'Accept': 'application/json',
        },
        body:
            'search "$query"; fields name, cover.url; where cover != null; limit 20;',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body);
        setState(() {
          _games = decoded;
          _isSearching = false;
        });
      } else {
        setState(() => _isSearching = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasExistingGame =
        widget.currentFavorites.isNotEmpty &&
        widget.targetIndex < widget.currentFavorites.length;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Buscar en IGDB',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (hasExistingGame)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Quitar juego'),
                  onPressed: () {
                    List<dynamic> updatedFavorites = List.from(
                      widget.currentFavorites,
                    );
                    updatedFavorites.removeAt(widget.targetIndex);
                    widget.onFavoritesUpdated(updatedFavorites);
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nombre del juego (ej. Persona 5)...',
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
          const SizedBox(height: 12),
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  )
                : _games.isEmpty
                ? Center(
                    child: Text(
                      'Escribe para buscar...',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    itemCount: _games.length,
                    itemBuilder: (context, index) {
                      final game = _games[index];
                      final rawUrl = game['cover'] != null
                          ? game['cover']['url']
                          : '';
                      final coverUrl = rawUrl.isNotEmpty
                          ? 'https:${rawUrl.replaceFirst('t_thumb', 't_cover_big')}'
                          : 'https://via.placeholder.com/264x352';

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            coverUrl,
                            width: 40,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.videogame_asset,
                                  color: Colors.grey,
                                ),
                          ),
                        ),
                        title: Text(
                          game['name'],
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          List<dynamic> updatedFavorites = List.from(
                            widget.currentFavorites,
                          );

                          final gameDataToSave = {
                            'game_id': game['id'],
                            'game_name': game['name'],
                            'cover_url': coverUrl,
                          };

                          if (widget.targetIndex < updatedFavorites.length) {
                            updatedFavorites[widget.targetIndex] =
                                gameDataToSave;
                          } else {
                            updatedFavorites.add(gameDataToSave);
                          }

                          widget.onFavoritesUpdated(updatedFavorites);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
