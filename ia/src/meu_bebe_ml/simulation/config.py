"""Carregamento das configurações do gerador sintético de Q_full.

Centraliza o acesso a:

* ``configs/simulation_v1.yaml`` — contrato congelado do DGM (fatores Z, matriz
  de correlação). Usado APENAS como fonte da matriz Z; o DGM em si continua
  fora do escopo desta fase.
* ``configs/generator_q_full_v1.yaml`` — parametrização experimental do gerador.

Nenhum número metodológico deve ser codificado diretamente nos módulos de
geração: todos vivem no YAML de configuração.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import yaml

_CONFIGS_DIR = Path(__file__).resolve().parents[3] / "configs"

SIMULATION_CONFIG_PATH = _CONFIGS_DIR / "simulation_v1.yaml"
GENERATOR_CONFIG_PATH = _CONFIGS_DIR / "generator_q_full_v1.yaml"


def load_simulation_config(path: Path | None = None) -> dict[str, Any]:
    """Carrega ``simulation_v1.yaml`` (contrato congelado do DGM)."""
    with open(path or SIMULATION_CONFIG_PATH, "r", encoding="utf-8") as fh:
        return yaml.safe_load(fh)


def load_generator_config(path: Path | None = None) -> dict[str, Any]:
    """Carrega ``generator_q_full_v1.yaml`` (parametrização experimental)."""
    with open(path or GENERATOR_CONFIG_PATH, "r", encoding="utf-8") as fh:
        return yaml.safe_load(fh)
