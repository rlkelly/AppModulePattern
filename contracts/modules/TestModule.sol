// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract TestModule {
    function testFunc1() external view {
        console.log("TEST");
    }
}
