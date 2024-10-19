// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "v4-core/src/types/Currency.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
import {LiquidityAmounts} from "v4-core/test/utils/LiquidityAmounts.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";

import {EasyPosm} from "../test/utils/EasyPosm.sol";
import {Constants} from "./base/Constants.sol";
import {Config} from "./base/Config.sol";

contract AddLiquidityScript is Script, Constants, Config {
    using CurrencyLibrary for Currency;
    using EasyPosm for IPositionManager;
    using StateLibrary for IPoolManager;

    /////////////////////////////////////
    // --- Parameters to Configure --- //
    /////////////////////////////////////

    // --- pool configuration --- //
    // fees paid by swappers that accrue to liquidity providers
    uint24 lpFee = 3000; // 0.50%
    int24 tickSpacing = 60;

    // --- liquidity position configuration --- //
    uint256 public token0Amount = 1e18;
    uint256 public token1Amount = 1e18;

    // range of the position
    int24 tickLower = -600; // must be a multiple of tickSpacing
    int24 tickUpper = 600;
    /////////////////////////////////////
    // =) ^_^ =3 :3 -_- :D =D ^_^ ;D :P ^-^ ^_~ ^_~ ^_^
    // =) ^_^ =3 :3 -_- :D =D ^_^ ;D :P ^-^ ^_~ ^_~ ^_^
    // =) ^_^ =3 :3 -_- :D =D ^_^ ;D :P ^-^ ^_~ ^_~ ^_^
    // =) ^_^ =3 :3 -_- :D =D ^_^ ;D :P ^-^ ^_~ ^_~ ^_^ 

    /**
            __  ___           __          ____      __  
           /  |/  /___ ______/ /_  ____ _/ / /___ _/ /_ 
          / /|_/ / __ `/ ___/ __ \/ __ `/ / / __ `/ __ \
         / /  / / /_/ (__  ) / / / /_/ / / / /_/ / / / /
        /_/  /_/\__,_/____/_/ /_/\__,_/_/_/\__,_/_/ /_/ 
     */
    function run() external {
        // vm.startBroadcast();
        // token0.mint(address(this), token0Amount * 1000);
        // token1.mint(address(this), token1Amount * 1000);
        // vm.stopBroadcast();

        PoolKey memory pool = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: lpFee,
            tickSpacing: tickSpacing,
            hooks: hookContract
        });

        (uint160 sqrtPriceX96,,,) = POOLMANAGER.getSlot0(pool.toId());

        // Converts token amounts to liquidity units
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            token0Amount,
            token1Amount
        );

        // slippage limits
        uint256 amount0Max = token0Amount + 1 wei;
        uint256 amount1Max = token1Amount + 1 wei;

        bytes memory hookData = new bytes(0);

        // vm.startBroadcast();
        // tokenApprovals();
        // token0.approve(address(posm), type(uint256).max);
        // token1.approve(address(posm), type(uint256).max);
        // vm.stopBroadcast();

        vm.startBroadcast();
        IPositionManager(address(posm)).mint(
            pool, tickLower, tickUpper, liquidity, amount0Max, amount1Max, msg.sender, block.timestamp + 60, hookData
        );
        vm.stopBroadcast();
    }

    function tokenApprovals() public {
        if (!currency0.isAddressZero()) {
            token0.approve(address(PERMIT2), type(uint256).max);
            PERMIT2.approve(address(token0), address(posm), type(uint160).max, type(uint48).max);
        }
        if (!currency1.isAddressZero()) {
            token1.approve(address(PERMIT2), type(uint256).max);
            PERMIT2.approve(address(token1), address(posm), type(uint160).max, type(uint48).max);
        }
    }
}
