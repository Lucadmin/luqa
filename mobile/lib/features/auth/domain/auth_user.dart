class AuthUser {
  const AuthUser({required this.id, required this.email, required this.name});

  final String id;
  final String email;
  final String? name;

  String get displayName =>
      name?.trim().isNotEmpty == true ? name!.trim() : email;

  String get initial {
    final value = displayName.trim();
    return value.isEmpty
        ? 'L'
        : String.fromCharCode(value.runes.first).toUpperCase();
  }
}

class AuthState {
  const AuthState._({this.user});

  const AuthState.signedOut() : this._();

  const AuthState.signedIn(AuthUser user) : this._(user: user);

  final AuthUser? user;

  bool get isAuthenticated => user != null;
}
