import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void showCreateRestaurantDialog({
  required BuildContext context,
  required VoidCallback onSuccess,
}) {
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
      return StatefulBuilder(builder: (context, setSheetState) {
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
              const Text('Create Restaurant',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Restaurant Name',
                  hintStyle:
                      const TextStyle(color: Colors.white38, fontSize: 14),
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Email',
                  hintStyle:
                      const TextStyle(color: Colors.white38, fontSize: 14),
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  hintStyle:
                      const TextStyle(color: Colors.white38, fontSize: 14),
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isCreating ? null : () => Navigator.pop(ctx),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: isCreating
                        ? null
                        : () async {
                            if (emailController.text.isEmpty ||
                                passwordController.text.isEmpty) {
                              return;
                            }
                            setSheetState(() => isCreating = true);

                            try {
                              final email = emailController.text.trim();
                              final password = passwordController.text.trim();

                              final url = Uri.parse(
                                  'https://srawlltewvegexdjbsxy.supabase.co/auth/v1/signup');
                              final request = await HttpClient().postUrl(url);
                              request.headers.add('apikey',
                                  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNyYXdsbHRld3ZlZ2V4ZGpic3h5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk5NzE1NjAsImV4cCI6MjEwNTU0NzU2MH0.8puCn7lM2-yFBJ8J2w-QaeO5RQhLugADbr0TAVlDf0o');
                              request.headers
                                  .add('Content-Type', 'application/json');
                              request.write(jsonEncode(
                                  {'email': email, 'password': password}));
                              final apiResponse = await request.close();
                              final responseBody = await apiResponse
                                  .transform(utf8.decoder)
                                  .join();

                              if (apiResponse.statusCode >= 200 &&
                                  apiResponse.statusCode < 300) {
                                final data = jsonDecode(responseBody);
                                final userId = data['id'] ??
                                    (data['user'] != null
                                        ? data['user']['id']
                                        : null);

                                if (userId != null) {
                                  final mainClient = Supabase.instance.client;

                                  await mainClient.from('profiles').insert(
                                      {'id': userId, 'role': 'restaurant'});

                                  await mainClient.from('restaurants').insert({
                                    'id': userId,
                                    'owner_id': userId,
                                    'name': nameController.text.trim().isEmpty
                                        ? 'New Restaurant'
                                        : nameController.text.trim(),
                                    'is_onboarded': false,
                                  });

                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    onSuccess();
                                  }
                                } else {
                                  throw Exception(
                                      'Could not retrieve user ID from signup response');
                                }
                              } else {
                                final errorData = jsonDecode(responseBody);
                                throw Exception(errorData['msg'] ??
                                    errorData['message'] ??
                                    'Signup failed');
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Error: $e')));
                              }
                            } finally {
                              setSheetState(() => isCreating = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                    ),
                    child: isCreating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Create',
                            style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      });
    },
  );
}
