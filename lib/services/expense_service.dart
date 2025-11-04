import 'api_client.dart';
import 'endpoints.dart';

class ExpenseService {
  ExpenseService(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> getAll({required String userId, int page = 1, int limit = 50}) async {
    final res = await _api.getJson(
      Endpoints.allExpense,
      query: {
        'page': page,
        'limit': limit,
        'sortBy': 'createdAt',
        'sortType': 'desc',
        'userId': userId,
      },
    ) as Map<String, dynamic>;
    final data = res['Data'] as Map<String, dynamic>?;
    final docs = data == null ? const [] : (data['docs'] as List<dynamic>? ?? const []);
    return docs.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> total() async {
    final res = await _api.getJson(Endpoints.totalExpense) as Map<String, dynamic>;
    return (res['Data'] as Map<String, dynamic>? ) ?? <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> monthlyCategory({required int month, required int year}) async {
    final res = await _api.getJson(
      Endpoints.monthlyCategorySpending,
      query: {'month': month, 'year': year},
    ) as Map<String, dynamic>;
    return (res['Data'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
  }
}


