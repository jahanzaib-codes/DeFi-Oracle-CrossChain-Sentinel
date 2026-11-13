# Contributing to DeFi-Oracle-CrossChain-Sentinel

Thank you for your interest in contributing to **DeFi-Oracle-CrossChain-Sentinel**. This repository implements high-performance multi-oracle routing and automated liquidation sentinels using Arbitrum Stylus (Rust WASM) and Solidity on Base and Arbitrum.

## Guidelines

1. **Rust & Solidity Standards**:
   - Write memory-safe Rust using `stylus-sdk`.
   - Maintain gas-optimized Solidity `0.8.24` with custom errors.
2. **Commit Conventions**:
   Follow [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat(...)`: New features
   - `fix(...)`: Bug fixes
   - `docs(...)`: Documentation updates
   - `infra(...)`: CI/CD or Docker configurations
3. **Pull Request Workflow**:
   - Run `python cli.py demo` locally before submitting PRs.
   - Ensure zero warnings under `flake8`.
