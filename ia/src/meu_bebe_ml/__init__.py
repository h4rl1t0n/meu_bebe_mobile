"""Componente de IA/ML do projeto Meu Bebê.

Experimento técnico com dataset sintético para validação do pipeline de
classificação de descontinuidade do pré-natal. NÃO é um modelo clínico.

Subpacotes:
  * ``schema``       — contrato de dados DSS 1.13 e validadores/invariantes;
  * ``features``     — seleção determinística de campos (X_model / X_sens);
  * ``simulation``   — (fase futura) geração do dataset sintético (DGM);
  * ``iv_dss``       — (fase futura) índice descritivo experimental;
  * ``preprocessing``— (fase futura) one-hot/multi-hot, imputação etc.;
  * ``training``     — (fase futura) treinamento dos modelos;
  * ``evaluation``   — (fase futura) métricas de avaliação.
"""

__version__ = "0.1.0"
