// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../interfaces/IPriceOracle.sol";
import "../interfaces/ILiquidationTarget.sol";

/**
 * @title CrossChainOracleSentinel
 * @author Jahanzaib (@jahanzaib-codes)
 * @notice Production-grade DeFi oracle sentinel and liquidation guardrail.
 * @dev Features dual-oracle failover (Chainlink primary, Pyth secondary), L2 sequencer outage
 *      protection with 3600s grace period, and automated liquidation dispatch.
 */
contract CrossChainOracleSentinel {
    address public immutable protocolOwner;
    address public immutable sequencerUptimeFeed;

    uint256 public constant SEQUENCER_GRACE_PERIOD = 3600; // 1 hour post-restart

    struct OracleConfig {
        address primaryFeed;    // e.g. Chainlink
        address secondaryFeed;  // e.g. Pyth Adapter
        uint32  heartbeatSecs;  // Max staleness allowed
        uint8   decimals;
    }

    // Asset -> Oracle Configuration
    mapping(address => OracleConfig) public oracleConfigs;

    // Authorized liquidation bots & automated keepers
    mapping(address => bool) public authorizedKeepers;

    error Unauthorized();
    error SequencerDown();
    error GracePeriodNotElapsed();
    error OracleUnconfigured(address asset);
    error PrimaryFeedStaleOrInvalid();
    error SecondaryFeedStaleOrInvalid();
    error LiquidationExecutionFailed();

    event OracleConfigured(address indexed asset, address primary, address secondary, uint32 heartbeat);
    event KeeperAuthorized(address indexed keeper, bool status);
    event LiquidationDispatched(address indexed borrower, address indexed collateral, uint256 debtCovered);

    modifier onlyOwner() {
        if (msg.sender != protocolOwner) revert Unauthorized();
        _;
    }

    modifier onlyKeeper() {
        if (!authorizedKeepers[msg.sender] && msg.sender != protocolOwner) revert Unauthorized();
        _;
    }

    constructor(address _sequencerUptimeFeed) {
        protocolOwner = msg.sender;
        sequencerUptimeFeed = _sequencerUptimeFeed;
    }

    function setOracleConfig(
        address asset,
        address primary,
        address secondary,
        uint32 heartbeat,
        uint8 decimals
    ) external onlyOwner {
        require(asset != address(0), "Zero asset");
        oracleConfigs[asset] = OracleConfig({
            primaryFeed: primary,
            secondaryFeed: secondary,
            heartbeatSecs: heartbeat,
            decimals: decimals
        });
        emit OracleConfigured(asset, primary, secondary, heartbeat);
    }

    function setKeeperStatus(address keeper, bool status) external onlyOwner {
        authorizedKeepers[keeper] = status;
        emit KeeperAuthorized(keeper, status);
    }

    /**
     * @notice Returns validated price using dual-feed failover logic.
     * @dev Checks L2 sequencer health first. If primary feed is stale or reverts,
     *      it safely fails over to the secondary Pyth feed.
     */
    function getSafePrice(address asset) public view returns (uint256 price) {
        _verifySequencerHealth();

        OracleConfig storage config = oracleConfigs[asset];
        if (config.primaryFeed == address(0)) revert OracleUnconfigured(asset);

        // Attempt Primary Feed (Chainlink)
        bool primaryOk;
        uint256 primaryPrice;
        (primaryOk, primaryPrice) = _queryFeed(config.primaryFeed, config.heartbeatSecs);

        if (primaryOk) {
            return primaryPrice;
        }

        // Secondary Failover (Pyth)
        if (config.secondaryFeed != address(0)) {
            bool secondaryOk;
            uint256 secondaryPrice;
            (secondaryOk, secondaryPrice) = _queryFeed(config.secondaryFeed, config.heartbeatSecs);
            if (secondaryOk) {
                return secondaryPrice;
            }
            revert SecondaryFeedStaleOrInvalid();
        }

        revert PrimaryFeedStaleOrInvalid();
    }

    /**
     * @notice Liquidates underwater position with pre-verified oracle health.
     */
    function executeLiquidation(
        address lendingPool,
        address borrower,
        address collateralAsset,
        address debtAsset,
        uint256 debtToCover
    ) external onlyKeeper returns (uint256 liquidatedCollateral) {
        // Enforce oracle freshness on both assets before dispatching liquidation
        getSafePrice(collateralAsset);
        getSafePrice(debtAsset);

        liquidatedCollateral = ILiquidationTarget(lendingPool).liquidateUnderwaterPosition(
            borrower,
            collateralAsset,
            debtAsset,
            debtToCover
        );

        emit LiquidationDispatched(borrower, collateralAsset, debtToCover);
    }

    function _verifySequencerHealth() internal view {
        if (sequencerUptimeFeed == address(0)) return; // Skipped on L1 Mainnet

        (, int256 answer, uint256 startedAt, , ) = IPriceOracle(sequencerUptimeFeed).latestRoundData();

        // 0 = Active, 1 = Down
        if (answer == 1) revert SequencerDown();

        // Grace period check to protect against liquidation cascades when transactions unpause
        if (block.timestamp - startedAt < SEQUENCER_GRACE_PERIOD) {
            revert GracePeriodNotElapsed();
        }
    }

    function _queryFeed(address feed, uint32 heartbeat) internal view returns (bool ok, uint256 price) {
        try IPriceOracle(feed).latestRoundData() returns (
            uint80 roundId,
            int256 answer,
            uint256,
            uint256 updatedAt,
            uint80 answeredInRound
        ) {
            if (answer <= 0) return (false, 0);
            if (answeredInRound < roundId) return (false, 0);
            if (block.timestamp - updatedAt > heartbeat) return (false, 0);
            return (true, uint256(answer));
        } catch {
            return (false, 0);
        }
    }
}
