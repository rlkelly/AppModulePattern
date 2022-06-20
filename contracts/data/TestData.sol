// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library TestData {
    bytes32 public constant TESTDATA_POSITION = keccak256("test.data.demo.data");

    struct MyStruct {
        uint var1;
        bytes var2;
        mapping (address => uint) var3;
    }

    // function initialize(bytes storage initData) public returns (MyStruct storage ms) {        
    // }

    function myStructStorage()
        internal
        pure
        returns (MyStruct storage mystruct)
    {
        bytes32 position = TESTDATA_POSITION;

        assembly {
            mystruct.slot := position
        }
    }
}
