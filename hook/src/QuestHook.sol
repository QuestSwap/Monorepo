// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {TaskData, TaskDataArguments} from "../types/TaskData.sol";
import {PairVolume} from "../types/PairVolume.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract QuestHook is BaseHook, Ownable {
    using PoolIdLibrary for PoolKey;
    using BalanceDeltaLibrary for BalanceDelta;

    mapping(PoolId => mapping(address user => uint256 count)) private swapsCount;
    mapping(PoolId => mapping(address user => PairVolume volume)) private totalVolume;

    mapping(PoolId => TaskData task) private poolTask;

    mapping(uint32 taskId => mapping(address user => uint256 count)) private tasksSwapCount;
    mapping(uint32 taskId => mapping(address user => PairVolume volume)) private tasksSwapVolume;

    mapping(uint32 taskId => address[] eligibleUsers) private taskEligibleUsers;

    uint32 public lastTaskId = 0;

    constructor(IPoolManager _poolManager, address initialOwner) BaseHook(_poolManager) Ownable(initialOwner) {}

    function createTask(PoolId poolId, TaskDataArguments calldata taskData) external {
        lastTaskId += 1;
        TaskData memory newTaskData = TaskData({
            taskId: lastTaskId,
            poolId: taskData.poolId,
            rewardAmount: taskData.rewardAmount,
            expectedVolume: taskData.expectedVolume,
            expectedTxs: taskData.expectedTxs,
            startTime: taskData.startTime,
            endTime: taskData.endTime,
            isCompleted: taskData.isCompleted,
            maxParticantsNumber: taskData.maxParticantsNumber,
            particantsNumber: taskData.particantsNumber
        });

        poolTask[poolId] = newTaskData;
    }

    function getTask(PoolId poolId) public view returns (bool, TaskData memory) {
        TaskData memory task = poolTask[poolId];
        return (task.taskId != 0, task);
    }

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

    function isValidTask(TaskData memory task) private view returns (bool) {
        return !task.isCompleted || task.particantsNumber <= task.maxParticantsNumber || 
            (block.timestamp >= task.startTime && block.timestamp <= task.endTime);
    }

    function isCompletedTask(TaskData memory task, address sender) private view returns (bool) {
        PairVolume memory pairVolume = tasksSwapVolume[task.taskId][sender];
        (uint256 volume0, uint256 volume1) = (pairVolume.token0Volume, pairVolume.token1Volume);

        return volume0 + volume1 >= task.expectedVolume && 
            tasksSwapCount[task.taskId][sender] >= task.expectedTxs;
    }

    function _completeTask(address payable particant, uint256 rewardAmount) private {
        (bool sent, ) = particant.call{value: rewardAmount}("");
        require(sent, "Failed to send Ether");
    }

    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        BalanceDelta delta,
        bytes calldata
    ) external override returns (bytes4, int128) {
        PoolId poolId = key.toId();

        uint256 token0Volume = uint256(abs(delta.amount0()));
        uint256 token1Volume = uint256(abs(delta.amount1()));
        totalVolume[poolId][sender].token0Volume += token0Volume;
        totalVolume[poolId][sender].token1Volume += token1Volume;

        swapsCount[poolId][sender] += 1;

        (bool taskExists, TaskData memory activeTask) = getTask(poolId);
        if (taskExists) {
            if (!isValidTask(activeTask)) {
                return (BaseHook.afterSwap.selector, 0);
            }

            tasksSwapCount[activeTask.taskId][sender] += 1;
            tasksSwapVolume[activeTask.taskId][sender].token0Volume += token0Volume;
            tasksSwapVolume[activeTask.taskId][sender].token1Volume += token1Volume;

            if (
                isCompletedTask(activeTask, sender)
            ) {
                activeTask.particantsNumber += 1;
                _completeTask(payable(sender), activeTask.rewardAmount);
            }
        }

        return (BaseHook.afterSwap.selector, 0);
    }
}
