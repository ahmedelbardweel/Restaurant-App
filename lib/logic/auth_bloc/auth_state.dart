import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  final String role; // 'admin', 'restaurant', 'customer'
  final bool isOnboarded; // specific to restaurant role

  const AuthAuthenticated({
    required this.user,
    required this.role,
    this.isOnboarded = false,
  });

  @override
  List<Object?> get props => [user, role, isOnboarded];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
