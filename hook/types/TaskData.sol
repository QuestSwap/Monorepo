// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.26;

import {PoolId} from "v4-core/src/types/PoolId.sol";

struct TaskData {
    PoolId poolId;
    uint256 rewardAmount;
    uint256 expectedVolume;
    uint256 expectedTxs;
    uint256 startTime;
    bool isCompleted;
    uint16 maxParticantsNumber;
    uint16 particantsNumber;
}