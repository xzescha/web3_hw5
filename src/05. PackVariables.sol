// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./Interfaces.sol";

contract PackVariables is IPackVariables {
    uint8 one;
    uint256 two;
    bytes18 three;
    uint8[30] four;
    bytes14 five;
    uint8 six;

    function setValues(uint8 _one, uint256 _two, bytes18 _three, uint8[30] calldata _four, bytes14 _five, uint8 _six)
        public
    {
        one = _one;
        two = _two;
        three = _three;
        four = _four;
        five = _five;
        six = _six;
    }
}

contract PackVariablesOptimized is IPackVariables {
    // Reordered for optimal packing:
    // slot 0: bytes18 (18) + bytes14 (14) = 32 bytes
    // slot 1: uint8 (1) + uint8 (1) = 2 bytes
    // slot 2: uint256 (32) = 32 bytes
    // slot 3: uint8[30] (30) = 30 bytes
    bytes18 three;
    bytes14 five;
    uint8 one;
    uint8 six;
    uint256 two;
    uint8[30] four;

    function setValues(uint8 _one, uint256 _two, bytes18 _three, uint8[30] calldata _four, bytes14 _five, uint8 _six)
        public
    {
        three = _three;
        five = _five;
        one = _one;
        six = _six;
        two = _two;
        four = _four;
    }
}
