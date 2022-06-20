// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMethodUpdate {
    enum MethodUpdateAction {Add, Replace, Remove}

    struct MethodUpdateData {
        address methodAddress;
        MethodUpdateAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _methodUpdate Contains the method addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function methodUpdate(
        MethodUpdateData[] calldata _methodUpdate,
        address _init,
        bytes calldata _calldata
    ) external;

    event MethodUpdate(MethodUpdateData[] _methodUpdate, address _init, bytes _calldata);
}
