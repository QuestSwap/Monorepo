import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {TaskData, TaskDataArguments} from "../types/TaskData";

interface ITaskManager {
    function createTask(PoolId poolId, TaskDataArguments calldata taskData) external returns(TaskData memory);
    function getTask(PoolId poolId) public view returns (bool, TaskData memory);
}