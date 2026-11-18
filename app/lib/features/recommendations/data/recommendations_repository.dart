import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:mindpal_app/constants.dart';
import 'package:mindpal_app/features/recommendations/domain/models.dart';
import 'package:mindpal_app/shared/providers/core_providers.dart';

part 'recommendations_repository.g.dart';

class RecommendationsRepository {
  RecommendationsRepository(this._dio);

  final Dio _dio;

  String _normalizeCategory(String category) => category.trim().toLowerCase();

  Future<List<RecommendationItem>> today({required String category}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/recommendations/today',
      queryParameters: <String, Object?>{
        'user_id': kUserId,
        'category': _normalizeCategory(category),
      },
    );
    final raw = response.data?['items'] as List<dynamic>? ?? const <dynamic>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(RecommendationItem.fromJson)
        .toList(growable: false);
  }

  Future<List<RecommendationItem>> generate({required String category}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/recommendations/generate',
      data: <String, Object?>{
        'user_id': kUserId,
        'category': _normalizeCategory(category),
      },
    );
    final raw = response.data?['items'] as List<dynamic>? ?? const <dynamic>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(RecommendationItem.fromJson)
        .toList(growable: false);
  }

  Future<List<HabitChecklistItem>> checklist() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/recommendations/habits/checklist',
      queryParameters: <String, Object?>{'user_id': kUserId},
    );
    final raw = response.data?['habits'] as List<dynamic>? ?? const <dynamic>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(HabitChecklistItem.fromJson)
        .toList(growable: false);
  }

  Future<void> addHabit(String name) async {
    await _dio.post<void>(
      '/recommendations/habits',
      data: <String, Object?>{'user_id': kUserId, 'name': name},
    );
  }

  Future<void> deleteHabit(String id) async {
    await _dio.delete<void>(
      '/recommendations/habits/$id',
      queryParameters: <String, Object?>{'user_id': kUserId},
    );
  }

  Future<void> setHabitChecked({
    required String id,
    required bool completed,
  }) async {
    await _dio.put<void>(
      '/recommendations/habits/$id/check',
      data: <String, Object?>{
        'user_id': kUserId,
        'date': DateTime.now().toIso8601String().split('T').first,
        'completed': completed,
      },
    );
  }

  Future<RecommendationItem> completeItem(String itemId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/recommendations/items/$itemId/complete',
      queryParameters: <String, Object?>{'user_id': kUserId},
    );
    return RecommendationItem.fromJson(response.data ?? {});
  }

  Future<void> adoptHabit(String itemId) async {
    await _dio.post<void>(
      '/recommendations/items/$itemId/habit',
      data: <String, Object?>{'user_id': kUserId},
    );
  }

  Future<void> skipItem(String itemId) async {
    await _dio.post<void>(
      '/recommendations/items/$itemId/interactions',
      data: <String, Object?>{
        'user_id': kUserId,
        'event_type': 'skipped',
        'payload': <String, Object?>{},
      },
    );
  }
}

@riverpod
RecommendationsRepository recommendationsRepository(Ref ref) {
  return RecommendationsRepository(ref.watch(dioProvider));
}
