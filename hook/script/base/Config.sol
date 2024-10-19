// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20Mintable} from "forge-std/interfaces/IERC20Mintable.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Currency} from "v4-core/src/types/Currency.sol";

/// @notice Shared configuration between scripts
contract Config {
    /// @dev populated with default anvil addresses
    IERC20Mintable constant token0 = IERC20Mintable(address(0x83c84Ad6614E8e6e31D2e7A8FbeD660b90c06a79));
    IERC20Mintable constant token1 = IERC20Mintable(address(0xB2F2366FF8aA4DfCcb07603cD69D0D7a84feA689));
    IHooks constant hookContract = IHooks(address(0x6e2fE782139c13CEB11b7d216617541D907bb3b6));

    Currency constant currency0 = Currency.wrap(address(token0));
    Currency constant currency1 = Currency.wrap(address(token1));
}
