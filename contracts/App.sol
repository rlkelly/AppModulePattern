// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/ModuleRepositoryLib.sol";
import "./interfaces/IMethodUpdate.sol";

contract App {
    constructor(address _contractOwner, address _methodUpdateAddress) payable {
        // setContractOwner(_contractOwner);

        // Add the initial method to allow for method updates
        IMethodUpdate.MethodUpdateData[] memory methods = new IMethodUpdate.MethodUpdateData[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IMethodUpdate.methodUpdate.selector;
        methods[0] = IMethodUpdate.MethodUpdateData({
            methodAddress: _methodUpdateAddress,
            action: IMethodUpdate.MethodUpdateAction.Add,
            functionSelectors: functionSelectors
        });
        ModuleRepositoryLib.methodUpdate(methods, address(0), "");
    }

    // Find module for function that is called and execute the
    // function if a module is found and return any value.
    fallback() external payable {
        ModuleRepositoryLib.RepositoryStorage storage rs = ModuleRepositoryLib.repositoryStorage();
        address delegatedAddress = rs.selectorToModuleAndPosition[msg.sig].moduleAddress;
        require(delegatedAddress != address(0), "Function does not exist");

        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function in the delegatedAddress
            let result := delegatecall(gas(), delegatedAddress, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }
}
