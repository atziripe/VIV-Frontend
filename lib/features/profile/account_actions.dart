import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../auth/auth_repository.dart';

/// Revokes Sign in with Apple for Apple accounts before the account goes
/// away (App Store 5.1.1(v)). Returns false when the user backed out of the
/// Apple sheet, which callers treat as "not now". A failed revoke never
/// blocks the deletion itself.
Future<bool> revokeAppleIfNeeded(WidgetRef ref) async {
  final auth = ref.read(authRepositoryProvider);
  if (!auth.isAppleUser) return true;
  try {
    await auth.revokeAppleAccess();
  } on SignInCancelled {
    return false;
  } catch (e) {
    debugPrint('Apple token revoke failed: $e');
  }
  return true;
}

/// After the server has deleted the account: clear on-device state and sign
/// out. The router then sends the user to Welcome.
Future<void> endSessionLocally(WidgetRef ref) async {
  await ref.read(sharedPreferencesProvider).clear();
  await ref.read(authRepositoryProvider).signOut();
}
