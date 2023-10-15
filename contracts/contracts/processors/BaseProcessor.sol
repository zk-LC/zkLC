//SPDX-License-Identifier: MIT

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IKeyHashAdapter } from "./keyHashAdapters/IKeyHashAdapter.sol";

pragma solidity ^0.8.18;

contract BaseProcessor is Ownable {

    /* ============ Modifiers ============ */
    modifier onlyEscrow() {
        require(msg.sender == escrow, "Only Escrow can call this function");
        _;
    }
    
    /* ============ Constants ============ */
    uint8 private constant EMAIL_ADDRESS_LENGTH = 21;   // 21 bytes in an email address

    /* ============ State Variables ============ */
    address public immutable escrow;
    IKeyHashAdapter public mailserverKeyHashAdapter;
    bytes public emailFromAddress;

    /* ============ Constructor ============ */
    constructor(
        address _escrow,
        IKeyHashAdapter _mailserverKeyHashAdapter,
        string memory _emailFromAddress
    )
        Ownable()
    {
        require(bytes(_emailFromAddress).length == EMAIL_ADDRESS_LENGTH, "Email from address not properly padded");

        escrow = _escrow;
        mailserverKeyHashAdapter = _mailserverKeyHashAdapter;
        emailFromAddress = bytes(_emailFromAddress);
    }

    /* ============ External Functions ============ */

    function setMailserverKeyHashAdapter(IKeyHashAdapter _mailserverKeyHashAdapter) external onlyOwner {
        mailserverKeyHashAdapter = _mailserverKeyHashAdapter;
    }

    function setEmailFromAddress(string memory _emailFromAddress) external onlyOwner {
        require(bytes(_emailFromAddress).length == EMAIL_ADDRESS_LENGTH, "Email from address not properly padded");

        emailFromAddress = bytes(_emailFromAddress);
    }

    /* ============ External Getters ============ */

    function getEmailFromAddress() external view returns (bytes memory) {
        return emailFromAddress;
    }

    function getMailserverKeyHash() public view returns (bytes32) {
        return IKeyHashAdapter(mailserverKeyHashAdapter).venmoMailserverKeyHash();
    }
}
