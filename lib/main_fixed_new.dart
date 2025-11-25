// main.dart (REFINED FIXED VERSION)
//
// Same idea as the broken example, but with:
// - flutter_bloc for state management
// - Immutable User model
// - UsersState with copyWith
// - UsersCubit as state holder
// - Repository with HTTP + stream
// - Clear separation of concerns, minimal boilerplate

import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

void main() {
  final client = http.Client();
  final repository = UsersRepository(client: client);

  runApp(
    RepositoryProvider<UsersRepository>.value(
      value: repository,
      child: BlocProvider(
        create: (context) => UsersCubit(repository)..loadUsers(),
        child: const MyApp(),
      ),
    ),
  );
}

/// Root widget: only responsible for app-level UI (theme, routes).
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

/// Immutable user model with correct mapping for jsonplaceholder.
class User extends Equatable {
  final int id;
  final String name;
  final String email;
  final bool isSelected;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.isSelected = false,
  });

  User copyWith({
    int? id,
    String? name,
    String? email,
    bool? isSelected,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, email, isSelected];
}

/// Repository responsible for talking to the network.
/// Exposes both an imperative API and a stream.
class UsersRepository {
  final http.Client client;
  final StreamController<List<User>> _usersController =
      StreamController<List<User>>.broadcast();

  UsersRepository({required this.client});

  Stream<List<User>> get usersStream => _usersController.stream;

  Future<List<User>> fetchUsers() async {
    final response = await client.get(
      Uri.parse('https://jsonplaceholder.typicode.com/users'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load users (code: ${response.statusCode})');
    }

    final List<dynamic> decoded = jsonDecode(response.body) as List<dynamic>;
    final users = decoded
        .map((item) => User.fromJson(item as Map<String, dynamic>))
        .toList();

    _usersController.add(users);
    return users;
  }

  // For a simple demo we skip explicit dispose/close handling.
  // In a real app, whoever creates this (e.g. DI container) should call
  // _usersController.close() and client.close() at app shutdown.
}

/// State object for the Cubit.
///
/// - Immutable
/// - Uses copyWith
/// - Equatable for efficient rebuilds
class UsersState extends Equatable {
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
      // allow explicit null to clear error
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, users, errorMessage];
}

/// Cubit that manages [UsersState].
class UsersCubit extends Cubit<UsersState> {
  final UsersRepository _repository;
  StreamSubscription<List<User>>? _subscription;

  UsersCubit(this._repository) : super(const UsersState()) {
    // Listen to the repository stream and merge it into state.
    _subscription = _repository.usersStream.listen((users) {
      emit(
        state.copyWith(
          users: List<User>.unmodifiable(users),
          errorMessage: null,
        ),
      );
    });
  }

  Future<void> loadUsers() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final users = await _repository.fetchUsers();

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
          errorMessage: 'Could not load users. Please try again.',
        ),
      );
    }
  }

  void toggleUserSelection(User user) {
    final updatedUsers = state.users.map((u) {
      if (u.id == user.id) {
        return u.copyWith(isSelected: !u.isSelected);
      }
      return u;
    }).toList();

    emit(
      state.copyWith(
        users: List<User>.unmodifiable(updatedUsers),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

/// UI widget that consumes [UsersCubit] via [BlocBuilder].
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users (Bloc + Stream)'),
      ),
      body: BlocBuilder<UsersCubit, UsersState>(
        builder: (context, state) {
          if (state.isLoading && state.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null && state.users.isEmpty) {
            return Center(
              child: Text(state.errorMessage!),
            );
          }

          if (state.users.isEmpty) {
            return const Center(
              child: Text('No users available.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<UsersCubit>().loadUsers(),
            child: ListView.builder(
              itemCount: state.users.length,
              itemBuilder: (context, index) {
                final user = state.users[index];

                return ListTile(
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: Checkbox(
                    value: user.isSelected,
                    onChanged: (_) {
                      context.read<UsersCubit>().toggleUserSelection(user);
                    },
                  ),
                  onTap: () {
                    context.read<UsersCubit>().toggleUserSelection(user);
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<UsersCubit>().loadUsers(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
