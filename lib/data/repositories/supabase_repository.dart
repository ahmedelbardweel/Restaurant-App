import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class SupabaseRepository {
  final SupabaseClient _client;

  SupabaseRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  // ==========================================
  // Auth Methods
  // ==========================================
  
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  
  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpCustomer(String email, String password) async {
    final response = await _client.auth.signUp(email: email, password: password);
    if (response.user != null) {
      final existing = await _client.from('profiles').select('id').eq('id', response.user!.id).maybeSingle();
      if (existing == null) {
        await _client.from('profiles').insert({'id': response.user!.id, 'role': 'customer'});
      }
    }
    return response;
  }

  Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.splashscreen://login-callback/',
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<String> getUserRole(String userId) async {
    try {
      final response = await _client.from('profiles').select('role').eq('id', userId).maybeSingle();
      
      if (response == null) {
        final role = (currentUser?.email?.contains('admin') == true) ? 'admin' : 'customer';
        await _client.from('profiles').insert({'id': userId, 'role': role});
        return role;
      }
      return response['role'] as String;
    } catch (e) {
      throw Exception('Failed to get user role: $e');
    }
  }

  // ==========================================
  // Restaurant Methods
  // ==========================================

  Future<List<Map<String, dynamic>>> getActiveRestaurants() async {
    try {
      final response = await _client.from('restaurants').select('id, name, colors').eq('is_onboarded', true);
      
      return (response as List).map((res) {
        List<dynamic> rawColors = res['colors'] ?? [];
        List<int> parsedColors = rawColors.map((c) => int.tryParse(c.toString()) ?? 0xFF000000).toList();
        while (parsedColors.length < 4) {
          parsedColors.add(0xFF424242);
        }
        return {
          'id': res['id'],
          'text': res['name'] ?? 'Unknown',
          'colors': parsedColors.map((c) => Color(c)).toList(),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch restaurants: $e');
    }
  }

  Future<bool> checkIsOnboarded(String userId) async {
    try {
      final response = await _client.from('restaurants').select('is_onboarded').eq('owner_id', userId).maybeSingle();
      return response?['is_onboarded'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> completeOnboarding(String userId, List<int> colors, String name, String desc) async {
    final existingRest = await _client.from('restaurants').select('id').eq('owner_id', userId).maybeSingle();
    final data = {
      'colors': colors,
      'name': name,
      'description': desc,
      'is_onboarded': true,
    };

    if (existingRest != null) {
      await _client.from('restaurants').update(data).eq('owner_id', userId);
    } else {
      data['owner_id'] = userId;
      await _client.from('restaurants').insert(data);
    }
  }

  Future<Map<String, dynamic>?> getRestaurantProfile(String userId) async {
    return await _client.from('restaurants').select('*').eq('owner_id', userId).maybeSingle();
  }

  Future<void> updateRestaurantInfo(String userId, Map<String, dynamic> data) async {
    await _client.from('restaurants').update(data).eq('owner_id', userId);
  }

  // ==========================================
  // Menu & Categories Methods
  // ==========================================

  Future<Map<String, List<Map<String, String>>>> getRestaurantMenu(String restaurantId) async {
    final response = await _client
        .from('categories')
        .select('id, name, menu_items(name, price, description, image_url)')
        .eq('restaurant_id', restaurantId);

    Map<String, List<Map<String, String>>> menuData = {};
    for (var category in response as List) {
      String categoryName = category['name'];
      List<Map<String, String>> itemsList = [];
      var menuItems = category['menu_items'] as List?;
      
      if (menuItems != null) {
        for (var item in menuItems) {
          itemsList.add({
            'name': item['name'].toString(),
            'price': '\$${item['price'].toString()}',
            'description': item['description']?.toString() ?? '',
            'image_url': item['image_url']?.toString() ?? '',
          });
        }
      }
      if (itemsList.isNotEmpty) {
        menuData[categoryName] = itemsList;
      }
    }
    return menuData;
  }

  Future<List<Map<String, dynamic>>> getRawCategories(String restaurantId) async {
    final response = await _client
        .from('categories')
        .select('id, name, menu_items(id, name, price, description, image_url)')
        .eq('restaurant_id', restaurantId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addCategory(String restaurantId, String name) async {
    await _client.from('categories').insert({'restaurant_id': restaurantId, 'name': name});
  }

  Future<void> deleteCategory(String categoryId) async {
    await _client.from('categories').delete().eq('id', categoryId);
  }

  Future<List<String>> uploadMenuItemImages(List<dynamic> files) async {
    List<String> urls = [];
    for (var file in files) {
      final bytes = await file.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final filePath = 'menu_items/$fileName';

      await _client.storage.from('menu_images').uploadBinary(filePath, bytes);
      urls.add(_client.storage.from('menu_images').getPublicUrl(filePath));
    }
    return urls;
  }

  Future<void> addMenuItem(String categoryId, String name, String desc, double price, List<String> imageUrls) async {
    await _client.from('menu_items').insert({
      'category_id': categoryId,
      'name': name,
      'description': desc,
      'price': price,
      'image_url': imageUrls.isNotEmpty ? jsonEncode(imageUrls) : null,
    });
  }

  Future<void> deleteMenuItem(String menuItemId) async {
    await _client.from('menu_items').delete().eq('id', menuItemId);
  }
}
