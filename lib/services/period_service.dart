import 'api_service.dart';
import '../config/api_config.dart';

/// Service for managing academic periods
class PeriodService {
  final ApiService _apiService = ApiService();

  // ============ PERIOD MANAGEMENT ============
  
  /// Get all periods
  Future<List<Map<String, dynamic>>> getAllPeriods() async {
    try {
      final response = await _apiService.get(ApiConfig.periodes);
      final List<dynamic> data = response is List ? response : (response['results'] ?? []);
      return data.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Failed to fetch periods: $e');
    }
  }

  /// Get period by ID
  Future<Map<String, dynamic>> getPeriodById(int id) async {
    try {
      return await _apiService.get(ApiConfig.periodeDetail(id));
    } catch (e) {
      throw Exception('Failed to fetch period: $e');
    }
  }

  /// Create new period
  Future<Map<String, dynamic>> createPeriod({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
    bool isActive = false,
  }) async {
    try {
      final periodData = {
        'name': name,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        if (description != null) 'description': description,
        'is_active': isActive,
      };
      return await _apiService.post(ApiConfig.periodes, periodData);
    } catch (e) {
      throw Exception('Failed to create period: $e');
    }
  }

  /// Update period
  Future<Map<String, dynamic>> updatePeriod({
    required int id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
    bool? isActive,
  }) async {
    try {
      final periodData = {
        'name': name,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        if (description != null) 'description': description,
        if (isActive != null) 'is_active': isActive,
      };
      return await _apiService.put(ApiConfig.periodeDetail(id), periodData);
    } catch (e) {
      throw Exception('Failed to update period: $e');
    }
  }

  /// Partially update period (PATCH)
  Future<Map<String, dynamic>> patchPeriod(
    int id,
    Map<String, dynamic> updates,
  ) async {
    try {
      return await _apiService.patch(ApiConfig.periodeDetail(id), updates);
    } catch (e) {
      throw Exception('Failed to update period: $e');
    }
  }

  /// Delete period
  Future<void> deletePeriod(int id) async {
    try {
      await _apiService.delete(ApiConfig.periodeDetail(id));
    } catch (e) {
      throw Exception('Failed to delete period: $e');
    }
  }

  // ============ UTILITY METHODS ============
  
  /// Get active periods
  Future<List<Map<String, dynamic>>> getActivePeriods() async {
    try {
      final allPeriods = await getAllPeriods();
      return allPeriods.where((period) => period['is_active'] == true).toList();
    } catch (e) {
      throw Exception('Failed to fetch active periods: $e');
    }
  }

  /// Get current period (most recent active period)
  Future<Map<String, dynamic>?> getCurrentPeriod() async {
    try {
      final activePeriods = await getActivePeriods();
      if (activePeriods.isEmpty) return null;
      
      // Sort by start date descending and return the most recent
      activePeriods.sort((a, b) {
        final dateA = DateTime.parse(a['start_date']);
        final dateB = DateTime.parse(b['start_date']);
        return dateB.compareTo(dateA);
      });
      
      return activePeriods.first;
    } catch (e) {
      throw Exception('Failed to fetch current period: $e');
    }
  }

  /// Check if a period is currently active (within date range)
  bool isPeriodCurrentlyActive(Map<String, dynamic> period) {
    try {
      final now = DateTime.now();
      final startDate = DateTime.parse(period['start_date']);
      final endDate = DateTime.parse(period['end_date']);
      
      return now.isAfter(startDate) && now.isBefore(endDate);
    } catch (e) {
      return false;
    }
  }

  /// Get periods within a date range
  Future<List<Map<String, dynamic>>> getPeriodsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final allPeriods = await getAllPeriods();
      return allPeriods.where((period) {
        try {
          final periodStart = DateTime.parse(period['start_date']);
          final periodEnd = DateTime.parse(period['end_date']);
          
          // Check if period overlaps with the specified range
          return (periodStart.isBefore(endDate) || periodStart.isAtSameMomentAs(endDate)) &&
                 (periodEnd.isAfter(startDate) || periodEnd.isAtSameMomentAs(startDate));
        } catch (e) {
          return false;
        }
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch periods in range: $e');
    }
  }
}
