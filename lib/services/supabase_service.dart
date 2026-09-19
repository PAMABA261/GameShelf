import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://vbexbxxxagdfyvrxuyqp.supabase.co',
      publishableKey: 'sb_publishable_5WwmzrhIrx_T60sjaRgcJQ_zxUndOxt',
    );
  }

  static Future<bool> ensureAuthenticated() async {
    if (client.auth.currentUser != null) return true;

    try {
      await client.auth.signInWithPassword(
        email: 'test@test.com',
        password: '12345',
      );
      return true;
    } catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    }
  }

  static Future<void> saveGame({
    required int gameId,
    required String gameName,
    required String coverUrl,
    required String status,
    double? rating,
    String? review,
    String? platform,
    List<String>? availablePlatforms,
  }) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('Could not authenticate user.');

    final userId = client.auth.currentUser!.id;

    await client.from('user_games').upsert({
      'user_id': userId,
      'game_id': gameId,
      'game_name': gameName,
      'cover_url': coverUrl,
      'status': status,
      'platform': platform,
      'available_platforms': availablePlatforms,
      ...?(rating != null ? {'rating': rating} : null),
      ...?(review != null ? {'review': review} : null),
    }, onConflict: 'user_id, game_id');
  }

  static Future<List<dynamic>> fetchUserGames() async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) return [];

    final userId = client.auth.currentUser!.id;

    final response = await client
        .from('user_games')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return response;
  }

  static Future<void> updateGame({
    required int gameId,
    required String status,
    double? rating,
    String? review,
    String? platform,
  }) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('Could not authenticate user.');

    final userId = client.auth.currentUser!.id;

    await client
        .from('user_games')
        .update({
          'status': status,
          'rating': rating,
          'review': review,
          'platform': platform,
        })
        .eq('user_id', userId)
        .eq('game_id', gameId);
  }

  static Future<void> deleteGame(int gameId) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('Could not authenticate user.');

    final userId = client.auth.currentUser!.id;

    await client
        .from('user_games')
        .delete()
        .eq('user_id', userId)
        .eq('game_id', gameId);
  }

  static Future<List<dynamic>> fetchUserLists() async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) return [];

    final userId = client.auth.currentUser!.id;
    final response = await client
        .from('custom_lists')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response;
  }

  static Future<void> createList(String title, String description) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('Could not authenticate user.');

    final userId = client.auth.currentUser!.id;
    await client.from('custom_lists').insert({
      'user_id': userId,
      'title': title,
      'description': description,
    });
  }

  static Future<void> addGameToList({
    required String listId,
    required int gameId,
    required String gameName,
    required String coverUrl,
  }) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('Not authenticated.');

    try {
      await client.from('list_games').insert({
        'list_id': listId,
        'game_id': gameId,
        'game_name': gameName,
        'cover_url': coverUrl,
      });
    } catch (e) {
      throw Exception('Game is already in this list or an error occurred.');
    }
  }

  static Future<List<dynamic>> fetchGamesForList(String listId) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) return [];

    final response = await client
        .from('list_games')
        .select()
        .eq('list_id', listId)
        .order('added_at', ascending: false);

    return response;
  }

  static Future<List<dynamic>> searchUsers(String query) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) return [];

    final myId = client.auth.currentUser!.id;

    final response = await client
        .from('profiles')
        .select()
        .ilike('username', '%$query%')
        .neq('id', myId)
        .limit(20);

    return response;
  }

  static Future<List<dynamic>> fetchPublicUserGames(String targetUserId) async {
    final response = await client
        .from('user_games')
        .select()
        .eq('user_id', targetUserId)
        .order('created_at', ascending: false);
    return response;
  }

  static Future<bool> isFollowing(String targetUserId) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) return false;

    final myId = client.auth.currentUser!.id;
    final response = await client
        .from('followers')
        .select()
        .eq('follower_id', myId)
        .eq('following_id', targetUserId);

    return response.isNotEmpty;
  }

  static Future<void> followUser(String targetUserId) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('Not authenticated.');

    final myId = client.auth.currentUser!.id;
    await client.from('followers').insert({
      'follower_id': myId,
      'following_id': targetUserId,
    });
  }

  static Future<void> unfollowUser(String targetUserId) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('Not authenticated.');

    final myId = client.auth.currentUser!.id;
    await client
        .from('followers')
        .delete()
        .eq('follower_id', myId)
        .eq('following_id', targetUserId);
  }

  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  static Future<void> updateProfile(String newUsername, String newBio) async {
    final userId = client.auth.currentUser!.id;
    await client
        .from('profiles')
        .update({'username': newUsername, 'bio': newBio})
        .eq('id', userId);
  }

  static Future<int> getFollowersCount(String userId) async {
    final response = await client
        .from('followers')
        .select('follower_id')
        .eq('following_id', userId);
    return (response as List).length;
  }

  static Future<int> getFollowingCount(String userId) async {
    final response = await client
        .from('followers')
        .select('following_id')
        .eq('follower_id', userId);
    return (response as List).length;
  }

  static Future<List<dynamic>> fetchPublicUserLists(String targetUserId) async {
    final response = await client
        .from('custom_lists')
        .select()
        .eq('user_id', targetUserId)
        .order('created_at', ascending: false);
    return response;
  }

  static Future<List<dynamic>> fetchActivityFeed() async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) return [];

    final myId = client.auth.currentUser!.id;

    final followingData = await client
        .from('followers')
        .select('following_id')
        .eq('follower_id', myId);

    final followingIds = followingData.map((f) => f['following_id']).toList();

    if (followingIds.isEmpty) return [];

    final response = await client
        .from('activity_feed')
        .select()
        .inFilter('user_id', followingIds)
        .order('created_at', ascending: false)
        .limit(30);

    return response;
  }

  static Future<void> updateFavoriteGames(List<dynamic> newFavorites) async {
    final userId = client.auth.currentUser!.id;
    await client
        .from('profiles')
        .update({'favorite_games': newFavorites})
        .eq('id', userId);
  }

  static Future<String?> uploadProfileImage(File file, String type) async {
    try {
      final userId = client.auth.currentUser!.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${userId}_${type}_$timestamp.jpg';

      await client.storage
          .from('perfiles')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl = client.storage.from('perfiles').getPublicUrl(fileName);

      await client
          .from('profiles')
          .update({'${type}_url': publicUrl})
          .eq('id', userId);

      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  static Future<void> createPost({
    required String title,
    required String content,
    int? gameId,
    String? gameName,
  }) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('Not authenticated.');

    final userId = client.auth.currentUser!.id;

    await client.from('posts').insert({
      'user_id': userId,
      'title': title,
      'content': content,
      if (gameId != null) 'game_id': gameId,
      if (gameName != null) 'game_name': gameName,
    });
  }

  static Future<List<dynamic>> fetchAllPosts() async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) return [];

    final response = await client
        .from('posts')
        .select('*, profiles!posts_user_id_fkey(username, avatar_url)')
        .order('created_at', ascending: false);

    return response;
  }

  static Future<void> deletePost(String postId) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('Not authenticated.');

    final userId = client.auth.currentUser!.id;

    await client.from('posts').delete().eq('id', postId).eq('user_id', userId);
  }

  static Future<void> updatePost({
    required String postId,
    required String title,
    required String content,
  }) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('Not authenticated.');

    final userId = client.auth.currentUser!.id;

    await client
        .from('posts')
        .update({'title': title, 'content': content})
        .eq('id', postId)
        .eq('user_id', userId);
  }

  static Future<int> getPostLikesCount(String postId) async {
    final response = await client
        .from('post_likes')
        .select('user_id')
        .eq('post_id', postId);
    return (response as List).length;
  }

  static Future<bool> hasUserLikedPost(String postId) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) return false;

    final userId = client.auth.currentUser!.id;
    final response = await client
        .from('post_likes')
        .select('user_id')
        .eq('post_id', postId)
        .eq('user_id', userId);

    return response.isNotEmpty;
  }

  static Future<void> toggleLike(String postId, bool isCurrentlyLiked) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('Not authenticated.');

    final userId = client.auth.currentUser!.id;

    if (isCurrentlyLiked) {
      await client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    } else {
      await client.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
    }
  }

  static Future<List<dynamic>> fetchComments(String postId) async {
    final response = await client
        .from('post_comments')
        .select('*, profiles(username, avatar_url)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return response;
  }

  static Future<void> addComment(String postId, String content) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('Not authenticated.');

    final userId = client.auth.currentUser!.id;
    await client.from('post_comments').insert({
      'post_id': postId,
      'user_id': userId,
      'content': content,
    });
  }

  static Future<void> deleteComment(String commentId) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('Not authenticated.');

    final userId = client.auth.currentUser!.id;

    await client
        .from('post_comments')
        .delete()
        .eq('id', commentId)
        .eq('user_id', userId);
  }

  static Future<String?> uploadPostImage(File file) async {
    try {
      final userId = client.auth.currentUser!.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${userId}_post_$timestamp.jpg';

      await client.storage
          .from('posts')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      return client.storage.from('posts').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Error uploading post image: $e');
      rethrow;
    }
  }

  static Future<void> createPollOptions(
    String postId,
    List<String> options,
  ) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('Not authenticated.');

    for (var option in options) {
      if (option.trim().isNotEmpty) {
        await client.from('poll_options').insert({
          'post_id': postId,
          'option_text': option.trim(),
        });
      }
    }
  }

  static Future<List<dynamic>> fetchPollData(String postId) async {
    final response = await client
        .from('poll_options')
        .select()
        .eq('post_id', postId);
    return response;
  }

  static Future<void> votePoll(String postId, String optionId) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('Not authenticated.');

    final userId = client.auth.currentUser!.id;

    await client.from('poll_votes').upsert({
      'user_id': userId,
      'post_id': postId,
      'poll_option_id': optionId,
    }, onConflict: 'user_id, post_id');
  }

  static Future<void> createPollPost({
    required String title,
    required String question,
    required List<String> options,
  }) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('Not authenticated.');

    final userId = client.auth.currentUser!.id;

    final postResponse = await client
        .from('posts')
        .insert({
          'user_id': userId,
          'title': title,
          'content': question,
          'is_poll': true,
        })
        .select()
        .single();

    final postId = postResponse['id'].toString();
    await createPollOptions(postId, options);
  }

  static Future<String?> getUserPollVote(String postId) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) return null;

    final userId = client.auth.currentUser!.id;
    final response = await client
        .from('poll_votes')
        .select('poll_option_id')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    return response != null ? response['poll_option_id'].toString() : null;
  }
}
