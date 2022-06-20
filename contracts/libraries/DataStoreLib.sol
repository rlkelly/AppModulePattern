// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Utils.sol";
    
library DataStoreLib {
    bytes32 public constant DATA_STORAGE_POSITION = keccak256("module.standard.data.storage");

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
        bytes32 position = DATA_STORAGE_POSITION;
        assembly {
            rs.slot := position
        }
    }
}
