import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/auth/auth_models.dart';
import 'package:meu_bebe/app/model/avaliacao_dss/avaliacao_dss_model.dart';
import 'package:meu_bebe/app/model/gestacao/gestacao_model.dart';
import 'package:meu_bebe/app/model/gestante/gestante_model.dart';
import 'package:meu_bebe/app/modules/formulario/models/formulario_data.dart';
import 'package:meu_bebe/app/modules/main/pages/profile/submodules/dss/dss_controller.dart';
import 'package:meu_bebe/app/repositories/avaliacao_dss/avaliacao_dss_repository.dart';
import 'package:meu_bebe/app/repositories/perfil/perfil_repository.dart';
import 'package:multiple_result/multiple_result.dart';

const _gestacao = GestacaoModel(id: 'ges1', dataUltimaMenstruacao: '2026-01-10');

const _avaliacao = AvaliacaoDssModel(
  id: 'a1',
  schemaVersion: '1.13',
  respostas: <String, dynamic>{},
  createdAt: '2026-08-29T00:00:00Z',
);

class _FakePerfilRepository implements PerfilRepository {
  _FakePerfilRepository(this.onGetGestacaoAtual);

  Future<Result<GestacaoModel?, BackendFailure>> Function() onGetGestacaoAtual;

  @override
  Future<Result<GestacaoModel?, BackendFailure>> getGestacaoAtual() =>
      onGetGestacaoAtual();

  @override
  Future<Result<GestanteModel?, BackendFailure>> getGestante() =>
      throw UnimplementedError();

  @override
  Future<Result<UserResponseModel?, BackendFailure>> getUser() =>
      throw UnimplementedError();

  @override
  Future<Result<GestanteModel, BackendFailure>> createGestante(
    GestanteModel gestante,
  ) => throw UnimplementedError();

  @override
  Future<Result<GestanteModel, BackendFailure>> updateGestante(
    GestanteModel gestante,
  ) => throw UnimplementedError();
}

class _FakeAvaliacaoDssRepository implements AvaliacaoDssRepository {
  _FakeAvaliacaoDssRepository(this.onList);

  Future<Result<List<AvaliacaoDssModel>, BackendFailure>> Function(String)
  onList;

  @override
  Future<Result<List<AvaliacaoDssModel>, BackendFailure>> list(
    String gestacaoId,
  ) => onList(gestacaoId);

  @override
  Future<Result<AvaliacaoDssModel, BackendFailure>> registrar(
    String gestacaoId,
    FormularioData data,
  ) => throw UnimplementedError();
}

void main() {
  DssController controller({
    Future<Result<GestacaoModel?, BackendFailure>> Function()? getGestacao,
    Future<Result<List<AvaliacaoDssModel>, BackendFailure>> Function(String)?
    list,
  }) {
    return DssController(
      _FakePerfilRepository(
        getGestacao ??
            () async => const Success<GestacaoModel?, BackendFailure>(_gestacao),
      ),
      _FakeAvaliacaoDssRepository(
        list ??
            (_) async => const Success(<AvaliacaoDssModel>[_avaliacao]),
      ),
    );
  }

  test('carrega o histórico e encerra sem loading', () async {
    final c = controller();

    await c.initialize();

    expect(c.loading, isFalse);
    expect(c.avaliacoes, hasLength(1));
    expect(c.avaliacoes.first.id, 'a1');
    expect(c.noActiveGestacao, isFalse);
    expect(c.error, isNull);
  });

  test('sem gestação ativa: sinaliza noActiveGestacao', () async {
    final c = controller(
      getGestacao: () async => const Success(null),
    );

    await c.initialize();

    expect(c.loading, isFalse);
    expect(c.noActiveGestacao, isTrue);
    expect(c.avaliacoes, isEmpty);
    expect(c.error, isNull);
  });

  test('erro ao buscar gestação: expõe a mensagem, sem lista', () async {
    final c = controller(
      getGestacao: () async => const Error(UnexpectedFailure()),
    );

    await c.initialize();

    expect(c.loading, isFalse);
    expect(c.error, 'Não foi possível concluir a operação.');
    expect(c.avaliacoes, isEmpty);
    expect(c.noActiveGestacao, isFalse);
  });

  test('erro ao listar avaliações: expõe a mensagem, sem lista', () async {
    final c = controller(
      list: (_) async => const Error(SessionExpiredFailure()),
    );

    await c.initialize();

    expect(c.loading, isFalse);
    expect(c.error, isNotNull);
    expect(c.avaliacoes, isEmpty);
    expect(c.noActiveGestacao, isFalse);
  });
}
