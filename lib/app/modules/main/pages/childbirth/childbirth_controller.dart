import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../model/plano_parto/plano_parto_model.dart';
import '../../../../repositories/perfil/perfil_repository.dart';
import '../../../../repositories/plano_parto/plano_parto_repository.dart';

part 'childbirth_controller.g.dart';

class ChildbirthController = ChildbirthControllerBase with _$ChildbirthController;

/// Controlador (somente leitura) da ABA PARTO — `ChildbirthPage`.
///
/// Escopo ativo: [ChildbirthPage] é filha direta da [MainPage] (aba do
/// `TabBarView`), portanto vive no `MainModule`, não em um submódulo roteado.
/// Por isso este controlador e o [PlanoPartoRepository] que ele usa devem ser
/// resolvidos no `MainModule` — exatamente o escopo real em runtime.
///
/// Responsabilidade limitada ao RESUMO: carrega apenas o [PlanoPartoModel] da
/// gestação ativa e o repassa (por parâmetro) ao `ChildbirthResumeCard`. Os 28
/// campos são persistidos pelos submódulos roteados (formulários), cada um com
/// seu próprio controller + repository — este controlador NÃO é um God Object.
abstract class ChildbirthControllerBase with Store {
  final PerfilRepository perfilRepository;
  final PlanoPartoRepository planoPartoRepository;

  ChildbirthControllerBase({
    required this.perfilRepository,
    required this.planoPartoRepository,
  });

  /// Plano de parto consolidado (28 campos), ou `null` se ainda não existe.
  @observable
  PlanoPartoModel? plano;

  @observable
  bool isLoading = false;

  @action
  Future<void> initialize() async {
    isLoading = true;
    try {
      await _loadPlano();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> _loadPlano() async {
    final gestacaoResult = await perfilRepository.getGestacaoAtual();
    final gestacaoId = switch (gestacaoResult) {
      Success() => gestacaoResult.success?.id,
      Error() => null,
    };

    if (gestacaoId == null) {
      plano = null;
      return;
    }

    final result = await planoPartoRepository.getPlanoParto(gestacaoId);
    switch (result) {
      case Success():
        plano = result.success;
      case Error():
        plano = null;
    }
  }
}
