import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/auth/auth_models.dart';
import 'package:meu_bebe/app/model/gestacao/gestacao_model.dart';
import 'package:meu_bebe/app/model/gestante/gestante_model.dart';
import 'package:meu_bebe/app/model/plano_parto/plano_parto_model.dart';
import 'package:meu_bebe/app/repositories/gestacao/gestacao_repository.dart';
import 'package:meu_bebe/app/repositories/perfil/perfil_repository.dart';
import 'package:meu_bebe/app/repositories/plano_parto/plano_parto_repository.dart';
import 'package:multiple_result/multiple_result.dart';

/// Fakes compartilhados pelos testes das seções do PLANO DE PARTO (FASE 9E).

class FakePerfilRepository implements PerfilRepository {
  FakePerfilRepository({
    this.onGetGestante,
    this.onGetGestacaoAtual,
    this.onCreateGestante,
    this.onUpdateGestante,
  });

  Future<Result<GestanteModel?, BackendFailure>> Function()? onGetGestante;
  Future<Result<GestacaoModel?, BackendFailure>> Function()? onGetGestacaoAtual;
  Future<Result<GestanteModel, BackendFailure>> Function(GestanteModel)?
  onCreateGestante;
  Future<Result<GestanteModel, BackendFailure>> Function(GestanteModel)?
  onUpdateGestante;

  int getGestacaoAtualCalls = 0;

  @override
  Future<Result<UserResponseModel?, BackendFailure>> getUser() =>
      throw UnimplementedError();

  @override
  Future<Result<GestanteModel?, BackendFailure>> getGestante() =>
      onGetGestante?.call() ??
      Future.value(const Success<GestanteModel?, BackendFailure>(null));

  @override
  Future<Result<GestacaoModel?, BackendFailure>> getGestacaoAtual() {
    getGestacaoAtualCalls++;
    return onGetGestacaoAtual?.call() ??
        Future.value(const Success<GestacaoModel?, BackendFailure>(null));
  }

  @override
  Future<Result<GestanteModel, BackendFailure>> createGestante(
    GestanteModel gestante,
  ) => onCreateGestante?.call(gestante) ?? Future.value(Success(gestante));

  @override
  Future<Result<GestanteModel, BackendFailure>> updateGestante(
    GestanteModel gestante,
  ) => onUpdateGestante?.call(gestante) ?? Future.value(Success(gestante));
}

class FakePlanoPartoRepository implements PlanoPartoRepository {
  FakePlanoPartoRepository({this.onGet, this.onUpsert});

  Future<Result<PlanoPartoModel?, BackendFailure>> Function(String)? onGet;
  Future<Result<PlanoPartoModel, BackendFailure>> Function(
    String,
    PlanoPartoModel,
  )?
  onUpsert;

  int getCalls = 0;
  int upsertCalls = 0;
  String? lastUpsertedGestacaoId;
  PlanoPartoModel? lastUpserted;

  @override
  Future<Result<PlanoPartoModel?, BackendFailure>> getPlanoParto(
    String gestacaoId,
  ) {
    getCalls++;
    return onGet?.call(gestacaoId) ??
        Future.value(const Success<PlanoPartoModel?, BackendFailure>(null));
  }

  @override
  Future<Result<PlanoPartoModel, BackendFailure>> upsertPlanoParto(
    String gestacaoId,
    PlanoPartoModel plano,
  ) {
    upsertCalls++;
    lastUpsertedGestacaoId = gestacaoId;
    lastUpserted = plano;
    return onUpsert?.call(gestacaoId, plano) ??
        Future.value(Success(plano));
  }
}

class FakeGestacaoRepository implements GestacaoRepository {
  FakeGestacaoRepository({this.onCreate, this.onUpdate});

  Future<Result<GestacaoModel, BackendFailure>> Function(GestacaoModel)?
  onCreate;
  Future<Result<GestacaoModel, BackendFailure>> Function(GestacaoModel)?
  onUpdate;

  @override
  Future<Result<GestacaoModel, BackendFailure>> createGestacao(
    GestacaoModel gestacao,
  ) => onCreate?.call(gestacao) ?? Future.value(Success(gestacao));

  @override
  Future<Result<GestacaoModel, BackendFailure>> updateGestacao(
    GestacaoModel gestacao,
  ) => onUpdate?.call(gestacao) ?? Future.value(Success(gestacao));
}

Result<GestanteModel?, BackendFailure> gestanteResult(GestanteModel? g) =>
    Success<GestanteModel?, BackendFailure>(g);

Result<GestacaoModel?, BackendFailure> gestacaoResult(GestacaoModel? g) =>
    Success<GestacaoModel?, BackendFailure>(g);

const gestacaoAtiva = GestacaoModel(
  id: 'ges-1',
  dataUltimaMenstruacao: '2026-01-10',
  localPreNatal: 'UBS Centro',
  profissionalPreNatal: 'Dra. Ana',
  contatoLocalPreNatal: '(92) 99999-0000',
);

const gestanteAtiva = GestanteModel(
  id: 'g1',
  nome: 'Maria Silva',
  nomeSocial: 'Má',
  dataNascimento: '1995-03-20',
  cpf: '12345678901',
  cns: '898000000000000',
);
