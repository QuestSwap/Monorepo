import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {TaskData, TaskDataArguments} from "../types/TaskData";

interface IQuestHook {
    function isValidTask(TaskData memory task) private view returns (bool);

    function isCompletedTask(TaskData memory task, address sender) private view returns (bool);

    function _completeTask(address payable particant, uint256 rewardAmount) private;
}