import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class SupabaseService {
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient client = Supabase.instance.client;

  /// Fetch all active restaurants to show on the Splash Screen
  Future<List<Map<String, dynamic>>> getRestaurants() async {
    try {
      final response = await client
          .from('restaurants')
          .select('id, name, colors')
          .eq('is_onboarded', true);
      
      // Map the DB response to the expected format
      return (response as List).map((res) {
        // Fallback colors if none exist
        List<dynamic> rawColors = [];
        if (res['colors'] != null) {
          rawColors = res['colors'];
        }
        
        List<int> parsedColors = rawColors.map((c) => int.tryParse(c.toString()) ?? 0xFF000000).toList();
        
        // If not enough colors, provide fallbacks
        while (parsedColors.length < 4) {
          parsedColors.add(0xFF424242);
        }

        return {
          'id': res['id'],
          'text': res['name'] ?? 'Unknown',
          'colors': parsedColors,
        };
      }).toList();
    } catch (e) {
      print('Error fetching restaurants: $e');
      return [];
    }
  }

  /// Sign in
  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up a new Customer
  Future<AuthResponse> signUpCustomer(String email, String password) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
    );
    
    // Explicitly create a customer profile
    if (response.user != null) {
      // Check if profile exists first to be safe
      final existing = await client.from('profiles').select('id').eq('id', response.user!.id).maybeSingle();
      if (existing == null) {
        await client.from('profiles').insert({'id': response.user!.id, 'role': 'customer'});
      }
    }
    
    return response;
  }

  /// Sign in with Google (OAuth)
  Future<bool> signInWithGoogle() async {
    return await client.auth.signInWithOAuth(OAuthProvider.google);
  }

  /// Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Get User Role
  Future<String> getUserRole(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      
      if (response == null) {
        // If no profile exists, create a default one based on email if needed, 
        // but typically we default to 'customer'. For testing, if email has admin, make admin.
        final user = client.auth.currentUser;
        final role = (user?.email?.contains('admin') == true) ? 'admin' : 'customer';
        await client.from('profiles').insert({'id': userId, 'role': role});
        return role;
      }
      
      return response['role'] as String;
    } catch (e) {
      print('Error getting user role: $e');
      return 'Error: $e';
    }
  }

  /// Check onboarding status
  Future<bool> checkIsOnboarded(String userId) async {
    try {
      final response = await client
          .from('restaurants')
          .select('is_onboarded')
          .eq('owner_id', userId)
          .maybeSingle();
      
      if (response == null) return false;
      
      return response['is_onboarded'] == true;
    } catch (e) {
      print('Error checking onboarding: $e');
      return false;
    }
  }

  /// Complete Onboarding (Upserts Profile & Restaurant)
  Future<void> completeOnboarding(String userId, List<int> colors, String name, String desc) async {
    try {
      // 1. Check if Restaurant exists
      final existingRest = await client.from('restaurants').select('id').eq('owner_id', userId).maybeSingle();
      
      if (existingRest != null) {
        await client.from('restaurants').update({
          'colors': colors,
          'name': name,
          'description': desc,
          'is_onboarded': true,
        }).eq('owner_id', userId);
      } else {
        await client.from('restaurants').insert({
          'owner_id': userId,
          'colors': colors,
          'name': name,
          'description': desc,
          'is_onboarded': true,
        });
      }
    } catch (e) {
      print('Error completing onboarding: $e');
      rethrow;
    }
  }

  /// Fetch Categories and Menu Items for a specific restaurant
  Future<Map<String, List<Map<String, String>>>> getRestaurantMenu(String restaurantId) async {
    try {
      final response = await client
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
    } catch (e) {
      print('Error fetching menu data: $e');
      return {};
    }
  }

  /// Get Restaurant Profile for Dashboard
  Future<Map<String, dynamic>?> getRestaurantProfile(String userId) async {
    try {
      return await client
          .from('restaurants')
          .select('*')
          .eq('owner_id', userId)
          .maybeSingle();
    } catch (e) {
      print('Error fetching restaurant profile: $e');
      return null;
    }
  }

  /// Fetch raw categories for editing
  Future<List<Map<String, dynamic>>> getRawCategories(String restaurantId) async {
    try {
      final response = await client
          .from('categories')
          .select('id, name, menu_items(id, name, price, description, image_url)')
          .eq('restaurant_id', restaurantId);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching raw categories: $e');
      return [];
    }
  }

  /// Add a Category
  Future<void> addCategory(String restaurantId, String name) async {
    await client.from('categories').insert({
      'restaurant_id': restaurantId,
      'name': name,
    });
  }

  /// Delete a Category
  Future<void> deleteCategory(String categoryId) async {
    await client.from('categories').delete().eq('id', categoryId);
  }

  /// Upload Images
  Future<List<String>> uploadMenuItemImages(List<dynamic> files) async {
    List<String> urls = [];
    for (var file in files) {
      try {
        final bytes = await file.readAsBytes();
        final fileExt = file.name.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final filePath = 'menu_items/$fileName';

        await client.storage.from('menu_images').uploadBinary(filePath, bytes);
        
        final publicUrl = client.storage.from('menu_images').getPublicUrl(filePath);
        urls.add(publicUrl);
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
    return urls;
  }

  /// Add a Menu Item
  Future<void> addMenuItem(String categoryId, String name, String desc, double price, List<String> imageUrls) async {
    await client.from('menu_items').insert({
      'category_id': categoryId,
      'name': name,
      'description': desc,
      'price': price,
      'image_url': imageUrls.isNotEmpty ? jsonEncode(imageUrls) : null,
    });
  }

  /// Delete a Menu Item
  Future<void> deleteMenuItem(String menuItemId) async {
    await client.from('menu_items').delete().eq('id', menuItemId);
  }
}
