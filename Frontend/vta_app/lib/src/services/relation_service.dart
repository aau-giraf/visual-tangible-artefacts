import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/modelsDTOs/pairing.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:logging/logging.dart';


final _log = Logger('RelationService');
class RelationService {
  final ApiProvider _apiProvider;
  final Token _token;

  RelationService({ApiProvider? apiProvider, Token? token})
      : _apiProvider = apiProvider ?? GetIt.instance.get<ApiProvider>(),
        _token = token ?? GetIt.instance.get<Token>();

  /// Get all pairings for a specific caregiver
  Future<List<PairingDTO>?> getPairingsForCaregiver(String caregiverId) async {
    try {
      final response = await _apiProvider.fetchAsJson(
        'Relation/caregiver/$caregiverId',
        headers: {
          'Authorization': 'Bearer ${_token.value}',
        },
      );

      if (response != null && response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((pairing) =>
                PairingDTO.fromJson(pairing as Map<String, dynamic>))
            .toList();
      }
      return null;
    } catch (e) {
      _log.info('Error getting pairings: $e');
      return null;
    }
  }
}
