//! Arbitrum Stylus Rust Smart Contract: Cross-Chain Liquidation Sentinel
//! Author: Jahanzaib (@jahanzaib-codes)
//! Description: Executes high-speed WebAssembly liquidation math, health factor modeling,
//! and volatility boundary validation at 10x-100x lower gas cost than standard EVM opcodes.

#![cfg_attr(not(feature = "export-abi"), no_main)]
extern crate alloc;

use alloc::vec::Vec;
use stylus_sdk::{alloy_primitives::U256, prelude::*};

sol_storage! {
    #[entrypoint]
    pub struct StylusLiquidationSentinel {
        uint256 liquidation_threshold_bps; // e.g. 8000 = 80.00%
        uint256 total_liquidations_evaluated;
        address sentinel_admin;
    }
}

#[public]
impl StylusLiquidationSentinel {
    /// Initialize admin and liquidation threshold (basis points)
    pub fn init(
        &mut self,
        admin: stylus_sdk::alloy_primitives::Address,
        threshold_bps: U256
    ) -> Result<(), Vec<u8>> {
        self.sentinel_admin.set(admin);
        self.liquidation_threshold_bps.set(threshold_bps);
        Ok(())
    }

    /// High-precision Health Factor calculation in WebAssembly.
    /// HealthFactor = (CollateralValueUSD * LiquidationThreshold) / DebtValueUSD
    /// Returns 18-decimal precision health factor.
    pub fn compute_health_factor(
        &mut self,
        collateral_usd: U256,
        debt_usd: U256
    ) -> Result<U256, Vec<u8>> {
        if debt_usd == U256::ZERO {
            // Infinite health if no debt outstanding
            return Ok(U256::MAX);
        }

        let threshold = self.liquidation_threshold_bps.get();
        // (collateral * threshold * 1e18) / (debt * 10000)
        let scaled_collateral = collateral_usd
            .saturating_mul(threshold)
            .saturating_mul(U256::from(10).pow(U256::from(18)));
        
        let denominator = debt_usd.saturating_mul(U256::from(10000));
        let health_factor = scaled_collateral / denominator;

        let eval_count = self.total_liquidations_evaluated.get();
        self.total_liquidations_evaluated.set(eval_count + U256::from(1));

        Ok(health_factor)
    }

    /// Evaluates if position is underwater (Health Factor < 1.0e18)
    pub fn is_liquidatable(&self, collateral_usd: U256, debt_usd: U256) -> Result<bool, Vec<u8>> {
        if debt_usd == U256::ZERO {
            return Ok(false);
        }
        let threshold = self.liquidation_threshold_bps.get();
        let scaled_collateral = collateral_usd.saturating_mul(threshold);
        let required_collateral = debt_usd.saturating_mul(U256::from(10000));
        Ok(scaled_collateral < required_collateral)
    }

    pub fn get_evaluation_count(&self) -> Result<U256, Vec<u8>> {
        Ok(self.total_liquidations_evaluated.get())
    }
}
