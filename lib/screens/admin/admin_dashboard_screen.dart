import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../customer/widgets/restaurant_list_view.dart';
import '../../core/utils/localization_helper.dart';
import '../../core/widgets/sheets/app_bottom_sheets.dart';
import 'package:splash_screen/core/widgets/custom_loader.dart';

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
          .select('id, name, name_ar, name_en, description, description_ar, description_en, is_onboarded, owner_id')
          .order('created_at', ascending: false);

      setState(() {
        _restaurants = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
                  MaterialPageRoute(builder: (_) => RestaurantListScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AppBottomSheets.showCreateRestaurantSheet(
          context: context,
          onSuccess: _fetchRestaurants,
        ),
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CustomLoader())
          : _restaurants.isEmpty
          ? const Center(
              child: Text(
                'No restaurants created yet.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _restaurants.length,
              itemBuilder: (context, index) {
                final res = _restaurants[index];
                return Card(
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
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
                                  context.getLocalized(res, 'name'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  res['is_onboarded'] == true
                                      ? 'Onboarded'
                                      : 'Pending Setup',
                                  style: TextStyle(
                                    color: res['is_onboarded'] == true
                                        ? Colors.greenAccent
                                        : Colors.orangeAccent,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white54,
                            ),
                            onPressed: () =>
                                AppBottomSheets.showRestaurantOptionsSheet(
                                  context: context,
                                  restaurant: res,
                                  onDeleteSuccess: _fetchRestaurants,
                                ),
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
