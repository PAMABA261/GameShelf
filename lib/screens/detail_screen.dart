import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class DetailScreen extends StatefulWidget {
  final dynamic game;
  final String coverUrl;

  const DetailScreen({super.key, required this.game, required this.coverUrl});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  double _rating = 0.0;
  final TextEditingController _reviewController = TextEditingController();

  String? _selectedPlatform;
  List<String> _platforms = [];

  @override
  void initState() {
    super.initState();
    _platforms = _extractPlatforms();
  }

  List<String> _extractPlatforms() {
    final platformsList = widget.game['platforms'];
    List<String> extracted = [];

    if (platformsList != null && platformsList is List) {
      extracted = platformsList.map((p) => p['name'] as String).toList();
    }

    extracted.addAll(['Emulador']);

    return extracted.toSet().toList();
  }

  Future<void> _saveGame(String status) async {
    try {
      await SupabaseService.saveGame(
        gameId: widget.game['id'],
        gameName: widget.game['name'],
        coverUrl: widget.coverUrl,
        status: status,
        rating: _rating > 0 ? _rating : null,
        review: _reviewController.text.isNotEmpty
            ? _reviewController.text
            : null,
        platform: _selectedPlatform,
        availablePlatforms: _platforms,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Guardado en tu biblioteca con éxito!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  // --- MODAL PARA AÑADIR A LISTAS PERSONALIZADAS ---
  void _showAddToListModal(BuildContext context) async {
    List<dynamic> lists = [];
    try {
      lists = await SupabaseService.fetchUserLists();
    } catch (e) {
      debugPrint('Error cargando listas: $e');
    }

    if (!context.mounted) return;

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
                    'Añadir a una lista',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (lists.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(
                        child: Text(
                          'No tienes listas creadas todavía.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: lists.length,
                        itemBuilder: (context, index) {
                          final list = lists[index];
                          return ListTile(
                            title: Text(
                              list['title'],
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: list['description'] != null
                                ? Text(
                                    list['description'],
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing: const Icon(
                              Icons.add_circle_outline,
                              color: Colors.greenAccent,
                            ),
                            onTap: () async {
                              try {
                                await SupabaseService.addGameToList(
                                  listId: list['id'],
                                  gameId: widget.game['id'],
                                  gameName: widget.game['name'],
                                  coverUrl: widget.coverUrl,
                                );
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '¡Añadido a "${list['title']}"!',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'El juego ya está en esta lista.',
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),

                  const Divider(color: Colors.grey),
                  const SizedBox(height: 8),

                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.greenAccent,
                      side: const BorderSide(color: Colors.greenAccent),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    icon: const Icon(Icons.create_new_folder),
                    label: const Text('Crear nueva lista'),
                    onPressed: () {
                      Navigator.pop(context);
                      _showCreateListModal(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateListModal(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C2228),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
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
                'Nueva Lista Personalizada',
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
                  labelText: 'Título (ej. Top RPGs)',
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
                controller: descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
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
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) return;

                  try {
                    await SupabaseService.createList(
                      titleController.text.trim(),
                      descController.text.trim(),
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('¡Lista creada con éxito!')),
                    );
                    _showAddToListModal(context);
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al crear lista: $e')),
                    );
                  }
                },
                child: const Text('Crear y continuar'),
              ),
            ],
          ),
        );
      },
    );
  }
  // ----------------------------------------------------

  String _getReleaseYear() {
    final timestamp = widget.game['first_release_date'];
    if (timestamp == null) return 'Desconocido';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return date.year.toString();
  }

  String _getGenres() {
    final genresList = widget.game['genres'];
    if (genresList == null || genresList is! List || genresList.isEmpty) {
      return 'No especificado';
    }
    return genresList.map((g) => g['name'] as String).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.game['name'] ?? 'Detalle',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF1C2228),
        actions: [
          // Botón para desplegar el modal de listas
          IconButton(
            icon: const Icon(Icons.playlist_add, color: Colors.greenAccent),
            tooltip: 'Añadir a lista',
            onPressed: () => _showAddToListModal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Hero(
                tag: widget.game['id'].toString(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.coverUrl,
                    height: 280,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.game['name'] ?? 'Sin título',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Lanzamiento: ${_getReleaseYear()}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.category,
                      size: 14,
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Géneros: ${_getGenres()}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 30, color: Colors.grey),

            const Text(
              'Tu Puntuación',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 28,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = (index + 1).toDouble();
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _reviewController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Escribe tu reseña sobre el juego...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF2C3440),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: _selectedPlatform,
              decoration: InputDecoration(
                labelText: 'Plataforma / Emulador',
                labelStyle: const TextStyle(color: Colors.greenAccent),
                filled: true,
                fillColor: const Color(0xFF2C3440),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              dropdownColor: const Color(0xFF2C3440),
              style: const TextStyle(color: Colors.white),
              items: _platforms.map((String platform) {
                return DropdownMenuItem<String>(
                  value: platform,
                  child: Text(platform),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPlatform = newValue;
                });
              },
            ),
            const SizedBox(height: 24),

            Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _saveGame('playing'),
                    icon: const Icon(Icons.videogame_asset),
                    label: const Text('Jugando'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _saveGame('plan_to_play'),
                    icon: const Icon(Icons.bookmark_add),
                    label: const Text('Pendiente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _saveGame('completed'),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Completado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _saveGame('dropped'),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Abandonado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[800],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sinopsis',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.game['summary'] ??
                  'No hay descripción disponible para este título.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[300],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
