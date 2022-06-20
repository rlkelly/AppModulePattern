// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Utils.sol";
import "../interfaces/IMethodUpdate.sol";

library ModuleRepositoryLib {
    bytes32 public constant MODULE_STORAGE_POSITION = keccak256("module.standard.module.storage");

    struct ModuleAddressAndPosition {
        address moduleAddress;
        uint96 functionSelectorPosition; // position in moduleFunctionSelectors.functionSelectors array
    }

    struct ModuleFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 moduleAddressPosition; // position of moduleAddress in moduleAddresses array
    }

    struct RepositoryStorage {
        // maps function selector to the module address and
        // the position of the selector in the moduleFunctionSelectors.selectors array
        mapping(bytes4 => ModuleAddressAndPosition) selectorToModuleAndPosition;
        // maps module addresses to function selectors
        mapping(address => ModuleFunctionSelectors) moduleFunctionSelectors;
        // module addresses
        address[] moduleAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function repositoryStorage() internal pure returns (RepositoryStorage storage rs) {
        bytes32 position = MODULE_STORAGE_POSITION;
        assembly {
            rs.slot := position
        }
    }

    function initializeModule(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "calldata is not empty");
        } else {
            require(_calldata.length > 0, "_calldata is empty");
            if (_init != address(this)) {
                Utils.enforceHasContractCode(_init, "_init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    revert(string(error));
                } else {
                    revert("_init function reverted");
                }
            }
        }
    }

    function addModule(RepositoryStorage storage rs, address _moduleAddress) internal {
        Utils.enforceHasContractCode(_moduleAddress, "New module has no code");
        rs.moduleFunctionSelectors[_moduleAddress].moduleAddressPosition = rs.moduleAddresses.length;
        rs.moduleAddresses.push(_moduleAddress);
    }

    function addFunction(RepositoryStorage storage rs, bytes4 _selector, uint96 _selectorPosition, address _moduleAddress) internal {
        rs.selectorToModuleAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        rs.moduleFunctionSelectors[_moduleAddress].functionSelectors.push(_selector);
        rs.selectorToModuleAndPosition[_selector].moduleAddress = _moduleAddress;
    }

    function removeFunction(RepositoryStorage storage rs, address _moduleAddress, bytes4 _selector) internal {
        require(_moduleAddress != address(0), "Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_moduleAddress != address(this), "Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = rs.selectorToModuleAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = rs.moduleFunctionSelectors[_moduleAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = rs.moduleFunctionSelectors[_moduleAddress].functionSelectors[lastSelectorPosition];
            rs.moduleFunctionSelectors[_moduleAddress].functionSelectors[selectorPosition] = lastSelector;
            rs.selectorToModuleAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        rs.moduleFunctionSelectors[_moduleAddress].functionSelectors.pop();
        delete rs.selectorToModuleAndPosition[_selector];

        // if no more selectors for module address then delete the module address
        if (lastSelectorPosition == 0) {
            // replace module address with last module address and delete last module address
            uint256 lastModuleAddressPosition = rs.moduleAddresses.length - 1;
            uint256 moduleAddressPosition = rs.moduleFunctionSelectors[_moduleAddress].moduleAddressPosition;
            if (moduleAddressPosition != lastModuleAddressPosition) {
                address lastModuleAddress = rs.moduleAddresses[lastModuleAddressPosition];
                rs.moduleAddresses[moduleAddressPosition] = lastModuleAddress;
                rs.moduleFunctionSelectors[lastModuleAddress].moduleAddressPosition = moduleAddressPosition;
            }
            rs.moduleAddresses.pop();
            delete rs.moduleFunctionSelectors[_moduleAddress].moduleAddressPosition;
        }
    }

    function methodUpdate(
        IMethodUpdate.MethodUpdateData[] memory _methodUpdate,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 methodIndex; methodIndex < _methodUpdate.length; methodIndex++) {
            IMethodUpdate.MethodUpdateAction action = _methodUpdate[methodIndex].action;
            if (action == IMethodUpdate.MethodUpdateAction.Add) {
                addFunctions(_methodUpdate[methodIndex].methodAddress, _methodUpdate[methodIndex].functionSelectors);
            // } else if (action == IMethodUpdate.FacetCutAction.Replace) {
            //     replaceFunctions(_methodUpdate[methodIndex].moduleAddress, _methodUpdate[methodIndex].functionSelectors);
            // } else if (action == IMethodUpdate.FacetCutAction.Remove) {
            //     removeFunctions(_methodUpdate[methodIndex].moduleAddress, _methodUpdate[methodIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        // emit DiamondCut(_diamondCut, _init, _calldata);
        // initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _moduleAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "No selectors in module");
        RepositoryStorage storage rs = repositoryStorage();
        require(_moduleAddress != address(0), "Add module can't be address(0)");
        uint96 selectorPosition = uint96(rs.moduleFunctionSelectors[_moduleAddress].functionSelectors.length);

        // add new module address if it does not exist
        if (selectorPosition == 0) {
            addModule(rs, _moduleAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = rs.selectorToModuleAndPosition[selector].moduleAddress;
            require(oldFacetAddress == address(0), "Function already exists");
            addFunction(rs, selector, selectorPosition, _moduleAddress);
            selectorPosition++;
        }
    }
}
