// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface ILiquidationTarget {
    function liquidateUnderwaterPosition(
        address borrower,
        address collateralAsset,
        address debtAsset,
        uint256 debtToCover
    ) external returns (uint256 liquidatedCollateral);
}
