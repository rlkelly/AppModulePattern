// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IMethodUpdate } from "../interfaces/IMethodUpdate.sol";
import { ModuleRepositoryLib } from "../libraries/ModuleRepositoryLib.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

contract MethodUpdateModule is IMethodUpdate {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    function methodUpdate(
        MethodUpdateData[] calldata _methodUpdateData,
        address _init,
        bytes calldata _calldata
    ) external override {
        ModuleRepositoryLib.methodUpdate(_methodUpdateData, _init, _calldata);
    }
}
