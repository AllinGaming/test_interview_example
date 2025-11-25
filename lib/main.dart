// main.dart (BROKEN VERSION)
// Intentionally bad example for interview-style code review.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

/// Simple app shell with a single screen.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // No theming separation, everything inline.
    return const MaterialApp(
      home: UsersPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Wrong / mutable model.
class User {
  // Mutable fields, no null-safety clarity.
  int id;
  String name;
  String email;
  bool isSelected;

  User({
    this.id = 0,
    this.name = '',
    this.email = '',
    this.isSelected = false,
  });

  /// fromJson is incorrect: wrong keys for most real APIs.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'], // jsonplaceholder uses 'id'
      name: json['username'], // jsonplaceholder uses 'name'
      email: json['mail'], // jsonplaceholder uses 'email'
    );
  }

  /// copyWith is broken: forces non-null, can't keep existing values,
  /// and can't explicitly set something to null.
  User copyWith({
    int? id,
    String? name,
    String? email,
    bool? isSelected,
  }) {
    return User(
      id: id!, // crash if not provided
      name: name!,
      email: email!,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// No bloc, no cubit, just manual setState and side effects.
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  bool isLoading = false;
  List<User> users = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Not loading here, it's loaded from build instead.
  }

  /// "Non-implemented" / half-implemented HTTP request:
  /// - No error handling
  /// - Ignores status code
  /// - Assumes JSON structure
  /// - Uses wrong model mapping
  Future<void> _loadUsers() async {
    isLoading = true; // No setState, UI might not show loading.
    errorMessage = null;

    try {
      // Hardcoded URL, no abstraction, no repository.
      final response = await http
          .get(Uri.parse('https://jsonplaceholder.typicode.com/users'));

      // Ignoring status code and headers.
      final body = response.body;

      // No checks, assumes it's a JSON array.
      final decoded = jsonDecode(body);

      users.clear();
      // `User.fromJson` uses wrong keys, so data will be mostly empty/wrong.
      for (final item in decoded) {
        users.add(User.fromJson(item as Map<String, dynamic>));
      }

      isLoading = false;
      // Single setState at the end, but loading flag changed earlier without it.
      setState(() {});
    } catch (e) {
      // Just store the raw exception message; never shown in UI properly.
      errorMessage = e.toString();
      isLoading = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Trigger side effects from build if no users yet.
    if (users.isEmpty && !isLoading) {
      _loadUsers(); // Side-effect inside build.
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Broken Users List'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? Center(
                  child: Text(
                    errorMessage ?? 'No users loaded.',
                  ),
                )
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];

                    return ListTile(
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      trailing: Checkbox(
                        value: user.isSelected,
                        onChanged: (value) {
                          // Mutating model directly and using setState everywhere.
                          user.isSelected = value ?? false;
                          setState(() {});
                        },
                      ),
                      onTap: () {
                        // Just toggling selection in-place; no separation of concerns.
                        user.isSelected = !user.isSelected;
                        setState(() {});
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUsers,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
