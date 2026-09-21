import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; 

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Map<String, dynamic>> _restaurants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('restaurants')
          .select('id, name, description, is_onboarded, owner_id')
          .order('created_at', ascending: false);
      
      setState(() {
        _restaurants = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateRestaurantDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    bool isCreating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Create Restaurant', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Restaurant Name',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(color: Color(0xFF333333)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(color: Color(0xFF333333)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(color: Color(0xFF333333)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isCreating ? null : () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: isCreating ? null : () async {
                          if (emailController.text.isEmpty || passwordController.text.isEmpty) return;
                          setSheetState(() => isCreating = true);
                          
                          try {
                            final email = emailController.text.trim();
                            final password = passwordController.text.trim();
                            
                            // Make direct API call to avoid logging out the Admin or hanging the Supabase client
                            final url = Uri.parse('https://srawlltewvegexdjbsxy.supabase.co/auth/v1/signup');
                            final request = await HttpClient().postUrl(url);
                            request.headers.add('apikey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNyYXdsbHRld3ZlZ2V4ZGpic3h5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk5NzE1NjAsImV4cCI6MjEwNTU0NzU2MH0.8puCn7lM2-yFBJ8J2w-QaeO5RQhLugADbr0TAVlDf0o');
                            request.headers.add('Content-Type', 'application/json');
                            request.write(jsonEncode({'email': email, 'password': password}));
                            final apiResponse = await request.close();
                            final responseBody = await apiResponse.transform(utf8.decoder).join();
                            
                            if (apiResponse.statusCode >= 200 && apiResponse.statusCode < 300) {
                              final data = jsonDecode(responseBody);
                              final userId = data['id'] ?? (data['user'] != null ? data['user']['id'] : null);
                              
                              if (userId != null) {
                                final mainClient = Supabase.instance.client;
                                
                                // Insert into profiles
                                await mainClient.from('profiles').insert({'id': userId, 'role': 'restaurant'});
                                
                                // Insert basic restaurant info
                                await mainClient.from('restaurants').insert({
                                  'id': userId,
                                  'owner_id': userId,
                                  'name': nameController.text.trim().isEmpty ? 'New Restaurant' : nameController.text.trim(),
                                  'is_onboarded': false,
                                });
                                
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  _fetchRestaurants();
                                }
                              } else {
                                throw Exception('Could not retrieve user ID from signup response');
                              }
                            } else {
                              final errorData = jsonDecode(responseBody);
                              throw Exception(errorData['msg'] ?? errorData['message'] ?? 'Signup failed');
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                          } finally {
                            setSheetState(() => isCreating = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        ),
                        child: isCreating 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Create', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showRestaurantOptions(Map<String, dynamic> restaurant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: const Text('Edit Details', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  // TODO: Show edit dialog
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Delete Restaurant', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(ctx);
                  // Confirm delete
                  _confirmDelete(restaurant['id'], restaurant['name']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        title: const Text('Delete Restaurant', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "$name"? This action cannot be undone.', style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.from('restaurants').delete().eq('id', id);
                _fetchRestaurants();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RestaurantListScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRestaurantDialog,
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _restaurants.isEmpty
              ? const Center(
                  child: Text('No restaurants created yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _restaurants.length,
                  itemBuilder: (context, index) {
                    final res = _restaurants[index];
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      child: InkWell(
                        onTap: () {
                          // TODO: Navigate to view restaurant menu/details
                        },
                        borderRadius: BorderRadius.circular(5),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      res['name'] ?? 'Unknown',
                                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      res['is_onboarded'] == true ? 'Onboarded' : 'Pending Setup',
                                      style: TextStyle(
                                        color: res['is_onboarded'] == true ? Colors.greenAccent : Colors.orangeAccent,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert, color: Colors.white54),
                                onPressed: () => _showRestaurantOptions(res),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
