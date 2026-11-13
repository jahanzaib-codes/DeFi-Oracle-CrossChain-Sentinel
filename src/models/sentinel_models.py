"""Data models for cross-chain oracle feeds, sequencer health, and liquidations."""

from pydantic import BaseModel, Field
from typing import Optional, List


class OraclePriceReport(BaseModel):
    asset_symbol: str
    chain: str  # "Arbitrum" | "Base" | "Ethereum"
    primary_oracle: str  # "Chainlink"
    secondary_oracle: str  # "Pyth Network"
    primary_price_usd: float
    secondary_price_usd: float
    active_price_usd: float
    divergence_bps: int
    primary_stale: bool = False
    failover_active: bool = False
    latency_ms: float


class CollateralPosition(BaseModel):
    account_id: str
    borrower_address: str
    collateral_asset: str
    collateral_amount: float
    collateral_value_usd: float
    debt_asset: str
    debt_amount: float
    debt_value_usd: float
    liquidation_threshold_pct: float = 80.0  # 80% LTV threshold


class LiquidationEvaluation(BaseModel):
    account_id: str
    health_factor: float
    is_underwater: bool
    status: str  # "HEALTHY" | "AT_RISK" | "LIQUIDATABLE" | "CIRCUIT_BROKEN"
    liquidation_bonus_usd: float
    gas_saved_wasm_pct: float
    execution_verdict: str
    security_alerts: List[str] = Field(default_factory=list)
    sequencer_healthy: bool = True
