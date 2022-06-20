// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Utils {
    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        /* ensures a contract has code */
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}
