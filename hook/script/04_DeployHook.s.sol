// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolSwapTest} from "v4-core/src/test/PoolSwapTest.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {CurrencyLibrary, Currency} from "v4-core/src/types/Currency.sol";

import {Constants} from "./base/Constants.sol";
import {Config} from "./base/Config.sol";
import {QuestHook} from "../src/QuestHook.sol";

contract DeployHook is Script, Constants, Config {
    function run() external {
        vm.broadcast();
        QuestHook hook = new QuestHook(IPoolManager(POOLMANAGER));
        vm.stopBroadcast();
    }
}
