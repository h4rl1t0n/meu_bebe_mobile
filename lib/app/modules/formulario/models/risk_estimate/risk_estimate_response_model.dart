/// Modelos da resposta `200` de `POST /api/v1/risk-estimate`.
///
/// Espelham o contrato congelado em `api/API_CONTRACT_V1.md` §4.1:
///   `{ result: {target, probability}, model: {name, schema_version,
///     raw_feature_count, transformed_feature_count}, notice }`.
///
/// São DTOs de leitura (somente `tryParse`) com serialização manual, sem code
/// generation, seguindo o padrão do projeto. `probability` é validada: deve
/// ser um `num` finito em `[0, 1]`, convertida para `double` sem arredondamento.
library;

class RiskEstimateResultModel {
  final String target;
  final double probability;

  const RiskEstimateResultModel({
    required this.target,
    required this.probability,
  });

  /// Retorna `null` quando o payload não tem a forma esperada (incluindo
  /// `probability` ausente, não numérica, infinita ou fora de `[0, 1]`).
  static RiskEstimateResultModel? tryParse(Object? data) {
    if (data is! Map) return null;

    final target = data['target'];
    final probability = data['probability'];
    if (target is! String || probability is! num) return null;

    final value = probability.toDouble();
    if (!value.isFinite || value < 0.0 || value > 1.0) return null;

    return RiskEstimateResultModel(target: target, probability: value);
  }
}

class RiskEstimateModelMetadata {
  final String name;
  final String schemaVersion;
  final int rawFeatureCount;
  final int transformedFeatureCount;

  const RiskEstimateModelMetadata({
    required this.name,
    required this.schemaVersion,
    required this.rawFeatureCount,
    required this.transformedFeatureCount,
  });

  static RiskEstimateModelMetadata? tryParse(Object? data) {
    if (data is! Map) return null;

    final name = data['name'];
    final schemaVersion = data['schema_version'];
    final rawFeatureCount = data['raw_feature_count'];
    final transformedFeatureCount = data['transformed_feature_count'];

    if (name is! String ||
        schemaVersion is! String ||
        rawFeatureCount is! int ||
        transformedFeatureCount is! int) {
      return null;
    }

    return RiskEstimateModelMetadata(
      name: name,
      schemaVersion: schemaVersion,
      rawFeatureCount: rawFeatureCount,
      transformedFeatureCount: transformedFeatureCount,
    );
  }
}

class RiskEstimateResponseModel {
  final RiskEstimateResultModel result;
  final RiskEstimateModelMetadata model;
  final String notice;

  const RiskEstimateResponseModel({
    required this.result,
    required this.model,
    required this.notice,
  });

  static RiskEstimateResponseModel? tryParse(Object? data) {
    if (data is! Map) return null;

    final result = RiskEstimateResultModel.tryParse(data['result']);
    final model = RiskEstimateModelMetadata.tryParse(data['model']);
    final notice = data['notice'];

    if (result == null || model == null || notice is! String) return null;

    return RiskEstimateResponseModel(
      result: result,
      model: model,
      notice: notice,
    );
  }
}
