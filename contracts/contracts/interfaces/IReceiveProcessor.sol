//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IProcessor {

    struct Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[10] signals;
    }

    function processProof(
        Proof calldata _proof
    )
        external
    returns(uint256, bytes32, bytes32);
}
