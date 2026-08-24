/// Modelos dos corpos de erro da API DSS.
///
/// O contrato (congelado) diferencia dois formatos:
///   - `422` (validação) → **plano** `{code, message, details}`;
///   - `500`/`503`       → **envelope** `{error: {code, message, details}}`.
///
/// `details` é uma lista de `{loc, msg, type}` — a API já omite o valor
/// rejeitado (`input`) por privacidade. O parsing é defensivo: `tryParse`
/// retorna `null` (ou ignora itens malformados) em vez de lançar.
library;

class ApiErrorDetailModel {
  final List<String> loc;
  final String msg;
  final String type;

  const ApiErrorDetailModel({
    required this.loc,
    required this.msg,
    required this.type,
  });

  static ApiErrorDetailModel? tryParse(Object? data) {
    if (data is! Map) return null;

    final loc = data['loc'];
    final msg = data['msg'];
    final type = data['type'];
    if (loc is! List || msg is! String || type is! String) return null;

    return ApiErrorDetailModel(
      loc: loc.map((e) => e.toString()).toList(),
      msg: msg,
      type: type,
    );
  }
}

class ApiErrorModel {
  final String code;
  final String message;
  final List<ApiErrorDetailModel> details;

  const ApiErrorModel({
    required this.code,
    required this.message,
    this.details = const [],
  });

  static ApiErrorModel? tryParse(Object? data) {
    if (data is! Map) return null;

    final code = data['code'];
    final message = data['message'];
    if (code is! String || message is! String) return null;

    final details = <ApiErrorDetailModel>[];
    final rawDetails = data['details'];
    if (rawDetails is List) {
      for (final item in rawDetails) {
        final detail = ApiErrorDetailModel.tryParse(item);
        if (detail != null) details.add(detail);
      }
    }

    return ApiErrorModel(code: code, message: message, details: details);
  }
}

class ApiErrorEnvelopeModel {
  final ApiErrorModel error;

  const ApiErrorEnvelopeModel({required this.error});

  static ApiErrorEnvelopeModel? tryParse(Object? data) {
    if (data is! Map) return null;

    final error = ApiErrorModel.tryParse(data['error']);
    if (error == null) return null;

    return ApiErrorEnvelopeModel(error: error);
  }
}
