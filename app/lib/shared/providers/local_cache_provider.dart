import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:mindpal_app/shared/services/local_cache_service.dart';

part 'local_cache_provider.g.dart';

@riverpod
LocalCacheService localCacheService(Ref ref) {
  return LocalCacheService();
}
