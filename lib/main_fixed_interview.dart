// main.dart
//
// Ultra-simple Cubit + copyWith example:
// - No Equatable
// - No repository class
// - No toggling / no selection
// - Only loadUsers()
// - BlocProvider inside UsersPage
// - Single-screen minimal BLoC architecture

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

/// Root widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UsersPage(),
    );
  }
}

/// Page that creates the Cubit
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UsersCubit()..loadUsers(),
      child: const UsersView(),
    );
  }
}

/// UI that listens to Cubit state
class UsersView extends StatelessWidget {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: BlocBuilder<UsersCubit, UsersState>(
        builder: (context, state) {
          if (state.isLoading && state.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null && state.users.isEmpty) {
            return Center(child: Text(state.errorMessage!));
          }

          if (state.users.isEmpty) {
            return const Center(child: Text('No users available.'));
          }

          return RefreshIndicator(
            onRefresh: () => context.read<UsersCubit>().loadUsers(),
            child: ListView.builder(
              itemCount: state.users.length,
              itemBuilder: (_, index) {
                final user = state.users[index];
                return ListTile(
                  title: Text(user.name),
                  subtitle: Text(user.email),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: () => context.read<UsersCubit>().loadUsers(),
      ),
    );
  }
}

/// Simple User model
class User {
  final int id;
  final String name;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
  });

  User copyWith({
    int? id,
    String? name,
    String? email,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}

/// State object
class UsersState {
  final bool isLoading;
  final List<User> users;
  final String? errorMessage;

  const UsersState({
    this.isLoading = false,
    this.users = const [],
    this.errorMessage,
  });

  UsersState copyWith({
    bool? isLoading,
    List<User>? users,
    String? errorMessage,
  }) {
    return UsersState(
      isLoading: isLoading ?? this.isLoading,
      users: users ?? this.users,
      errorMessage: errorMessage,
    );
  }
}

/// Cubit that loads users
class UsersCubit extends Cubit<UsersState> {
  UsersCubit() : super(const UsersState());

  Future<void> loadUsers() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final response = await http.get(
        Uri.parse('https://jsonplaceholder.typicode.com/users'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load users');
      }

      final List<dynamic> decoded = jsonDecode(response.body);
      final users = decoded
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList();

      emit(
        state.copyWith(
          isLoading: false,
          users: List<User>.unmodifiable(users),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load users.',
        ),
      );
    }
  }
}
