import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'lists_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _userGames = [];
  String _sortMethod = 'date_desc';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadLibrary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    setState(() => _isLoading = true);
    final games = await SupabaseService.fetchUserGames();
    setState(() {
      _userGames = games;
      _isLoading = false;
    });
  }

  List<dynamic> _getFilteredAndSortedGames(String filter) {
    List<dynamic> filtered = _userGames;

    if (filter != 'all') {
      filtered = _userGames.where((game) => game['status'] == filter).toList();
    }

    List<dynamic> sorted = List.from(filtered);

    if (_sortMethod == 'rating_desc') {
      sorted.sort((a, b) {
        final ratingA = (a['rating'] as num?)?.toDouble() ?? -1.0;
        final ratingB = (b['rating'] as num?)?.toDouble() ?? -1.0;
        return ratingB.compareTo(ratingA);
      });
    } else if (_sortMethod == 'name_asc') {
      sorted.sort((a, b) {
        final nameA = (a['game_name'] ?? '').toString().toLowerCase();
        final nameB = (b['game_name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });
    }

    return sorted;
  }

  void _showEditDeleteModal(Map<String, dynamic> item) {
    String currentStatus = item['status'] ?? 'plan_to_play';
    double currentRating = item['rating'] != null
        ? (item['rating'] as num).toDouble()
        : 0.0;

    String? currentPlatform = item['platform'];

    List<String> modalPlatforms = [];
    if (item['available_platforms'] != null) {
      modalPlatforms = List<String>.from(item['available_platforms']);
    } else {
      modalPlatforms = ['PC', 'Nintendo Switch', 'Emulator', 'Other'];
    }

    if (currentPlatform != null &&
        currentPlatform.isNotEmpty &&
        !modalPlatforms.contains(currentPlatform)) {
      modalPlatforms.insert(0, currentPlatform);
    }

    final TextEditingController reviewController = TextEditingController(
      text: item['review'] ?? '',
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['game_name'] ?? 'Edit game',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Status',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: currentStatus,
                      dropdownColor: const Color(0xFF2C3440),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF2C3440),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'playing',
                          child: Text('Playing'),
                        ),
                        DropdownMenuItem(
                          value: 'plan_to_play',
                          child: Text('Plan to Play'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem(
                          value: 'dropped',
                          child: Text('Dropped'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => currentStatus = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Rating',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < currentRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setModalState(
                              () => currentRating = (index + 1).toDouble(),
                            );
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Review',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reviewController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Update your review...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: const Color(0xFF2C3440),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Platform',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue:
                          (currentPlatform != null &&
                              currentPlatform!.isNotEmpty)
                          ? currentPlatform
                          : null,
                      dropdownColor: const Color(0xFF2C3440),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Select platform',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: const Color(0xFF2C3440),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: modalPlatforms.map((String platform) {
                        return DropdownMenuItem<String>(
                          value: platform,
                          child: Text(platform),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => currentPlatform = val);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[800],
                            ),
                            icon: const Icon(Icons.delete, color: Colors.white),
                            label: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () async {
                              await SupabaseService.deleteGame(item['game_id']);
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              _loadLibrary();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Game removed from library'),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                            ),
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: const Text(
                              'Save',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () async {
                              await SupabaseService.updateGame(
                                gameId: item['game_id'],
                                status: currentStatus,
                                rating: currentRating > 0
                                    ? currentRating
                                    : null,
                                review: reviewController.text.isNotEmpty
                                    ? reviewController.text
                                    : null,
                                platform: currentPlatform,
                              );
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              _loadLibrary();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Game successfully updated'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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

  String _getStatusText(String status) {
    switch (status) {
      case 'playing':
        return 'Playing';
      case 'completed':
        return 'Completed';
      case 'dropped':
        return 'Dropped';
      case 'plan_to_play':
      default:
        return 'Plan to Play';
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

  Widget _buildGameGrid(List<dynamic> gamesList) {
    if (gamesList.isEmpty) {
      return Center(
        child: Text(
          'No games in this section.',
          style: TextStyle(color: Colors.grey[500], fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: gamesList.length,
      itemBuilder: (context, index) {
        final item = gamesList[index];
        final coverUrl = item['cover_url'] ?? '';
        final gameName = item['game_name'] ?? 'Game';

        final statusText = _getStatusText(item['status']);
        final statusColor = _getStatusColor(item['status']);

        final rating = item['rating'];
        final review = item['review'];
        final platform = item['platform'];

        return GestureDetector(
          onTap: () => _showEditDeleteModal(item),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C2228),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    child: Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gameName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (platform != null && platform.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.blueAccent.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              platform.toString(),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10,
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (rating != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '$rating',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      if (review != null && review.toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '"$review"',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
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
          'My Library',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1C2228),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.greenAccent),
            tooltip: 'My Lists',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ListsScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.greenAccent),
            tooltip: 'Sort',
            onSelected: (value) {
              setState(() {
                _sortMethod = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date_desc',
                child: Text('Most Recent'),
              ),
              const PopupMenuItem(
                value: 'rating_desc',
                child: Text('Highest Rated'),
              ),
              const PopupMenuItem(
                value: 'name_asc',
                child: Text('Alphabetical (A-Z)'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.greenAccent,
          labelColor: Colors.greenAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Playing'),
            Tab(text: 'Plan to Play'),
            Tab(text: 'Completed'),
            Tab(text: 'Dropped'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGameGrid(_getFilteredAndSortedGames('all')),
                _buildGameGrid(_getFilteredAndSortedGames('playing')),
                _buildGameGrid(_getFilteredAndSortedGames('plan_to_play')),
                _buildGameGrid(_getFilteredAndSortedGames('completed')),
                _buildGameGrid(_getFilteredAndSortedGames('dropped')),
              ],
            ),
    );
  }
}
