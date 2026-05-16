import '../core/extensions/enum_extensions.dart';

enum Alternatives { yes, no, dontKnow }

class Expectation {
  static const _sentinel = Object();

  final int id;
  final Alternatives companion;
  final Alternatives shaveIntimateHair;
  final Alternatives bowelWashOrSuppository;
  final Alternatives lowLightEnvironment;
  final Alternatives listenToMusic;
  final Alternatives drinkLiquids;
  final Alternatives recordPhotosOrVideos;
  final String? createdAt;

  const Expectation({
    required this.id,
    required this.companion,
    required this.shaveIntimateHair,
    required this.bowelWashOrSuppository,
    required this.lowLightEnvironment,
    required this.listenToMusic,
    required this.drinkLiquids,
    required this.recordPhotosOrVideos,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companion': companion.index,
      'shave_intimate_hair': shaveIntimateHair.index,
      'bowel_wash_or_suppository': bowelWashOrSuppository.index,
      'low_light_environment': lowLightEnvironment.index,
      'listen_to_music': listenToMusic.index,
      'drink_liquids': drinkLiquids.index,
      'record_photos_or_videos': recordPhotosOrVideos.index,
      'created_at': createdAt,
    };
  }

  factory Expectation.fromMap(Map<String, dynamic> map) {
    return Expectation(
      id: map['id'] ?? 0,
      companion: Alternatives.values.safeGet(map['companion'], Alternatives.no),
      shaveIntimateHair: Alternatives.values.safeGet(map['shave_intimate_hair'], Alternatives.no),
      bowelWashOrSuppository: Alternatives.values.safeGet(map['bowel_wash_or_suppository'], Alternatives.no),
      lowLightEnvironment: Alternatives.values.safeGet(map['low_light_environment'], Alternatives.no),
      listenToMusic: Alternatives.values.safeGet(map['listen_to_music'], Alternatives.no),
      drinkLiquids: Alternatives.values.safeGet(map['drink_liquids'], Alternatives.no),
      recordPhotosOrVideos: Alternatives.values.safeGet(map['record_photos_or_videos'], Alternatives.no),
      createdAt: map['created_at'],
    );
  }

  Expectation copyWith({
    int? id,
    Alternatives? companion,
    Alternatives? shaveIntimateHair,
    Alternatives? bowelWashOrSuppository,
    Alternatives? lowLightEnvironment,
    Alternatives? listenToMusic,
    Alternatives? drinkLiquids,
    Alternatives? recordPhotosOrVideos,
    Object? createdAt = _sentinel,
  }) {
    return Expectation(
      id: id ?? this.id,
      companion: companion ?? this.companion,
      shaveIntimateHair: shaveIntimateHair ?? this.shaveIntimateHair,
      bowelWashOrSuppository: bowelWashOrSuppository ?? this.bowelWashOrSuppository,
      lowLightEnvironment: lowLightEnvironment ?? this.lowLightEnvironment,
      listenToMusic: listenToMusic ?? this.listenToMusic,
      drinkLiquids: drinkLiquids ?? this.drinkLiquids,
      recordPhotosOrVideos: recordPhotosOrVideos ?? this.recordPhotosOrVideos,
      createdAt: identical(createdAt, _sentinel) ? this.createdAt : createdAt as String?,
    );
  }

  @override
  String toString() {
    return 'Expectation(id: $id, companion: $companion, shaveIntimateHair: $shaveIntimateHair, bowelWashOrSuppository: $bowelWashOrSuppository, lowLightEnvironment: $lowLightEnvironment, listenToMusic: $listenToMusic, drinkLiquids: $drinkLiquids, recordPhotosOrVideos: $recordPhotosOrVideos, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expectation &&
        other.id == id &&
        other.companion == companion &&
        other.shaveIntimateHair == shaveIntimateHair &&
        other.bowelWashOrSuppository == bowelWashOrSuppository &&
        other.lowLightEnvironment == lowLightEnvironment &&
        other.listenToMusic == listenToMusic &&
        other.drinkLiquids == drinkLiquids &&
        other.recordPhotosOrVideos == recordPhotosOrVideos &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        companion.hashCode ^
        shaveIntimateHair.hashCode ^
        bowelWashOrSuppository.hashCode ^
        lowLightEnvironment.hashCode ^
        listenToMusic.hashCode ^
        drinkLiquids.hashCode ^
        recordPhotosOrVideos.hashCode ^
        createdAt.hashCode;
  }
}
