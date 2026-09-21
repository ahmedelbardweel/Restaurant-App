import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignInRequested(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpCustomerRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignUpCustomerRequested(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class AuthGoogleSignInRequested extends AuthEvent {}

class AuthSignOutRequested extends AuthEvent {}
