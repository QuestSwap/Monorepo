// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {TaskData} from "./types.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract QuestHook is BaseHook, Ownable {
    using PoolIdLibrary for PoolKey;
    using BalanceDeltaLibrary for BalanceDelta global;

    TaskManger public taskManager;

    mapping(PoolId => mapping(address user => uint256 count)) private swapsCount;
    mapping(PoolId => mapping(address user => PairVolume volume)) private totalVolume;

    mapping(TaskData task => mapping(address user => uint256 count)) private tasksSwapCount;
    mapping(TaskData task => mapping(address user => PairVolume volume)) private tasksSwapVolume;

    mapping(TaskData task => address[] eligibleUsers) private taskEligibleUsers;

    constructor(IPoolManager _poolManager, address initialOwner) BaseHook(_poolManager) Ownable(initialOwner) {}

    function createTask(PoolId poolId, TaskData taskData) external;
    function getTask(PoolId poolId) view returns (bool, TaskData);

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: true,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: true,
            beforeSwap: false,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: true,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: true
        });
    }

    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }

    function isValidTask(TaskData task) private pure returns (bool) {
        return !task.isCompleted || task.particantsNumber <= task.maxParticantsNumber || 
            (block.timestamp >= task.startTime && block.timestamp <= task.endTime);
    }

    function _completeTask(address particant, TaskData task) {
        activeTask.particantsNumber += 1;
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata swapParams,
        BalanceDelta delta,
        bytes calldata hookData
    ) external returns (bytes4, int128) {
        PoolId poolId = key.toId();

        uint256 token0Volume = uint256(abs(delta.amount0()));
        uint256 token1Volume = uint256(abs(delta.amount1()));
        totalVolume[poolId][sender] += (token0Volume, token1Volume);
        swapsCount[poolId][sender] += 1;

        (bool taskExists, TaskData activeTask) = taskManager.getTask();
        if (taskExists) {
            if (!isValidTask(activeTask)) {
                return (BaseHook.afterSwap.selector, 0);
            }

            tasksSwapCount[activeTask][sender] += 1;
            tasksSwapVolume[activeTask][sender] += (token0Volume, token1Volume);

            if (
                tasksSwapVolume[activeTask][sender] >= activeTask.expectedVolume && 
                tasksSwapCount[activeTask][sender] >= activeTask.expectedTxs
            ) {
                
            }
        }

        return (BaseHook.afterSwap.selector, 0);
    }
}
