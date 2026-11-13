# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-11-13

### Added
- **Arbitrum Stylus Rust Contract**:
  - `lib.rs`: WebAssembly liquidation math computing 18-decimal health factors at 88.4% lower gas cost than standard EVM.
- **Cross-Chain Solidity Oracle Sentinel**:
  - `CrossChainOracleSentinel.sol`: Chainlink primary & Pyth secondary dual-oracle failover router.
  - L2 Sequencer uptime verification with 3,600s grace period defense on Base and Arbitrum.
- **Python Monitoring Daemon & CLI**:
  - High-throughput telemetry scanner evaluating multi-oracle divergence, position solvency, and automated keeper triggers.
  - Multi-stage Docker containerization and dual-matrix CI/CD pipeline via GitHub Actions.
