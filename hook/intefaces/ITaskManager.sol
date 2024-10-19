import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {TaskData} from "../types/TaskData";

interface ITaskManager {
    function createTask(PoolId poolId, TaskData taskData) external;
    function getTask(PoolId poolId) view returns (bool, TaskData);
}