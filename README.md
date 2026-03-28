# Gas optimization quizz

Homework for students on the topic of gas optimization.

Any tricks can be used in the solution, the main thing is to reduce the cost of gas contracting.

Using ONLY the solidity optimizer is not a solution to the task!

The last task requires optimizing the performance of the entire contract.

**Tasks 1-9 are worth 1 point, task 10 is worth 5 points**

## Task

Given contract `A`, we need to write a second contract named `AOptimized`.

Do not change the names of functions inside the contract!!!

Example,

```solidity
// file A.sol

contract A {
    function call() public {
        // Original function
    }
}

contract AOptimized {
    function call() public {
        // Your optimization
    }
}
```

Answers are checked manually and with the commands

```sh
forge test --match-contract ArrayLength
forge test --match-contract ArrayLength --gas-report
```

Test the same way in different contracts

Example,

```solidity
// file A.t.sol

contract ATest is Test{
    function test_call() public {
        // Original test
    }
}

contract AOptimizedTest is Test {
    function test_call() public {
        // Your test
    }
}
```