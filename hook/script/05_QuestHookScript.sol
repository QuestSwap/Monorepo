// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";

import {Constants} from "./base/Constants.sol";
import {QuestHook} from "../src/QuestHook.sol";
import {HookMiner} from "../test/utils/HookMiner.sol";

/// @notice Mines the address and deploys the QuestHook.sol Hook contract
contract QuestHookScript is Script, Constants {
    function setUp() public {}

    function run() public {
        // hook contracts must have specific flags encoded in the address
        uint160 flags = uint160(
            Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG
        );

        // Mine a salt that will produce a hook address with the correct flags
        bytes memory constructorArgs = abi.encode(address(POOLMANAGER));
        (address hookAddress, bytes32 salt) =
            HookMiner.find(CREATE2_DEPLOYER, flags, type(QuestHook).creationCode, constructorArgs);
        require(uint160(address(hookAddress)) & Hooks.ALL_HOOK_MASK == flags, "Fucc");

        // Deploy the hook using CREATE2
        vm.broadcast();
        QuestHook questHook = new QuestHook{salt: salt}(IPoolManager(POOLMANAGER));
        require(address(questHook) == hookAddress, "QuestHookScript: hook address mismatch");
    }
}
