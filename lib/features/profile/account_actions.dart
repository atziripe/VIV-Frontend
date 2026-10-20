import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../auth/auth_repository.dart';

/// After the server has deleted the account: clear on-device state and sign
/// out. The router then sends the user to Welcome.
Future<void> endSessionLocally(WidgetRef ref) async {
  await ref.read(sharedPreferencesProvider).clear();
  await ref.read(authRepositoryProvider).signOut();
}
