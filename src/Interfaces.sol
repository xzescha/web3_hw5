// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IAddition {
    function addition(uint256 value) external;
}

interface IDivision {
    function divisionBy2(uint256 number) external pure returns (uint256);
    function divisionBy128(uint256 number) external pure returns (uint256);
}

interface ISubtraction {
    function subtraction(uint256 value) external;
}

interface IArrayLength {
    function callFor() external view;
}

interface ICalldataMemory {
    function add(uint256[] memory myArray) external pure returns (uint256 sum);
}

interface ILoops {
    function loopFor() external pure;
    function loopWhile() external pure;
    function loopDoWhile() external pure;
}

interface IPackVariables {
    function setValues(uint8 _one, uint256 _two, bytes18 _three, uint8[30] calldata _four, bytes14 _five, uint8 _six)
        external;
}

interface IErrors {
    function call() external view;
}

interface ISwap {
    function swap(uint256 a, uint256 b) external pure returns (uint256, uint256);
}

interface IArrayType {
    function initArray() external;
}

interface INestedIf {
    function call(uint256 number) external pure returns (bool);
}
