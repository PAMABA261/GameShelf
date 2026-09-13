import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  List<dynamic> _games = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;

  String _currentQuery = '';
  int _offset = 0;
  final int _limit = 50;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isFetchingMore &&
        _currentQuery.isNotEmpty) {
      _fetchGames(isRefresh: false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      final trimmedQuery = query.trim();
      if (trimmedQuery.isNotEmpty) {
        setState(() {
          _currentQuery = trimmedQuery;
          _offset = 0;
          _games = [];
        });
        _fetchGames(isRefresh: true);
      } else {
        setState(() {
          _currentQuery = '';
          _games = [];
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    });
  }

  Future<void> _fetchGames({required bool isRefresh}) async {
    if (isRefresh) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isFetchingMore = true);
    }

    final url = Uri.parse('https://api.igdb.com/v4/games');
    try {
      final response = await http.post(
        url,
        headers: {
          'Client-ID': '###',
          'Authorization': 'Bearer ###',
          'Accept': 'application/json',
        },
        body:
            'search "$_currentQuery"; fields name, cover.url, summary, first_release_date, genres.name, category, involved_companies.company.name, platforms.name; where cover != null; limit $_limit; offset $_offset;',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body);

        final forbiddenKeywords = [
          'rom hack',
          'romhack',
          'hack',
          'fangame',
          'fan-game',
          'fan game',
          'mod',
          'demake',
          'remake',
          'kaizo',
          'randomizer',
          'unofficial',
          'no oficial',
          'clone',
          'port',
          'homebrew',
          'bootleg',
        ];

        final mainGames = decoded.where((game) {
          final cat = game['category'];
          if (cat != null && cat != 0) return false;

          final name = (game['name'] ?? '').toLowerCase();
          final summary = (game['summary'] ?? '').toLowerCase();

          final fullText = '$name $summary';
          for (var word in forbiddenKeywords) {
            if (fullText.contains(word)) return false;
          }

          return true;
        }).toList();

        setState(() {
          if (isRefresh) {
            _games = mainGames;
          } else {
            _games.addAll(mainGames);
          }
          _offset += _limit;
        });
      } else {
        debugPrint('Error de red: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Excepción: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Catálogo de Juegos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1C2228),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Escribe para buscar juegos...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF2C3440),
                prefixIcon: const Icon(Icons.search, color: Colors.greenAccent),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _games = [];
                      _currentQuery = '';
                      _offset = 0;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Colors.greenAccent),
              ),
            )
          else
            Expanded(
              child: _games.isEmpty
                  ? Center(
                      child: Text(
                        'Escribe el nombre de un juego para empezar',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    )
                  : Stack(
                      children: [
                        GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(10),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.68,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          itemCount: _games.length,
                          itemBuilder: (context, index) {
                            final game = _games[index];
                            final rawUrl = game['cover'] != null
                                ? game['cover']['url']
                                : '';
                            final coverUrl = rawUrl.isNotEmpty
                                ? 'https:${rawUrl.replaceFirst('t_thumb', 't_cover_big')}'
                                : 'https://via.placeholder.com/264x352';

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailScreen(
                                      game: game,
                                      coverUrl: coverUrl,
                                    ),
                                  ),
                                );
                              },
                              child: Hero(
                                tag: game['id'].toString(),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    coverUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.grey[850],
                                              child: const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: Colors.white54,
                                                ),
                                              ),
                                            ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        if (_isFetchingMore)
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1C2228),
                                  shape: BoxShape.circle,
                                ),
                                child: const CircularProgressIndicator(
                                  color: Colors.greenAccent,
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}
