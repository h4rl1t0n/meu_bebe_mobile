import 'package:flutter_modular/flutter_modular.dart';

import 'dss_detail_page.dart';

/// Rota de detalhe (somente leitura) de uma avaliação DSS. Não depende de
/// repositórios: o modelo chega via `Modular.args.data`.
class DssDetailModule extends Module {
  @override
  void routes(r) {
    r.child('/', child: (context) => const DssDetailPage());
  }
}
