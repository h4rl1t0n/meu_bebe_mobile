"""Estado de geração de um único registro sintético.

``SimulationState`` agrega, durante a geração de UMA gestante, os fatores
latentes Z, os contextos C_* e os auxiliares internos (M_sim) necessários às
dimensões. Os campos de ``Q_full`` vão sendo acumulados em ``record`` na ordem
canônica de ``constants.Q_FULL``.

Os sinais de adversidade ordinal (``*_adv``) são preenchidos por cada módulo
após gerar a variável correspondente, para uso por módulos posteriores.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

import numpy as np

# Barreiras organizacionais de acesso (compartilhadas entre saúde e habitação).
ORGANIZATIONAL_BARRIERS: frozenset[str] = frozenset(
    {
        "dificuldade_agendamento",
        "demora_atendimento",
        "horario_incompativel",
        "falta_profissional",
        "falta_exames",
    }
)


@dataclass
class SimulationState:
    rng: np.random.Generator
    config: dict[str, Any]

    # Fatores latentes Z (M_sim)
    z_ses: float = 0.0
    z_lab: float = 0.0
    z_terr: float = 0.0
    z_infra: float = 0.0
    z_serv: float = 0.0

    # Contextos C_* (M_sim)
    c_lab: float = 0.0
    c_infra: float = 0.0
    c_access: float = 0.0
    c_food: float = 0.0

    # Sinais de adversidade ordinal (M_sim), preenchidos sob demanda.
    escolaridade_adv: float = 0.0
    income_adv: float = 0.0
    distancia_adv: float = 0.0
    seguranca_adv: float = 0.0
    n_pessoas_std: float = 0.0

    # Auxiliares internos (M_sim)
    latent_income_band: str | None = None
    income_was_masked: bool = False
    has_piped_water: bool = False
    has_internal_bathroom: bool = False
    has_separate_kitchen: bool = False
    density_target: float = 1.4

    # Registro Q_full em construção.
    record: dict[str, Any] = field(default_factory=dict)

    def signals(self) -> dict[str, float]:
        """Mapa de sinais resolvíveis por ``random_utils.linear_delta``."""
        return {
            "z_ses": self.z_ses,
            "z_lab": self.z_lab,
            "z_terr": self.z_terr,
            "z_infra": self.z_infra,
            "z_serv": self.z_serv,
            "c_lab": self.c_lab,
            "c_infra": self.c_infra,
            "c_access": self.c_access,
            "c_food": self.c_food,
            "escolaridade_adv": self.escolaridade_adv,
            "income_adv": self.income_adv,
            "distancia_adv": self.distancia_adv,
            "seguranca_adv": self.seguranca_adv,
            "n_pessoas_std": self.n_pessoas_std,
        }
