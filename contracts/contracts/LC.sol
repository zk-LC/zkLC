//SPDX-License-Identifier: MIT

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { Bytes32ArrayUtils } from "./lib/Bytes32ArrayUtils.sol";
import { Uint256ArrayUtils } from "./lib/Uint256ArrayUtils.sol";

import { Groth16Verifier } from "./verifiers/verifier.sol";

pragma solidity ^0.8.18;

contract LCContract is Groth16Verifier {
    enum FormOfDocCredit { Irrevocable, Irrevocable_Transferable }
    enum ApplicableRules { EUCP_LATEST_VERSION, EUCPURR_LATEST_VERSION, OTHR, UCP_LATEST_VERSION,  UCPURR_LATEST_VERSION }
    enum PartialShipments { NotAllowed, Allowed, Conditional }
    enum Transshipment { NotAllowed, Allowed }
    enum ConfirmationInstructions { Confirm, MayAdd, Without }

    
    // todo: fix this. Make some of it addresses.
    struct AvailableWithBy {
        string BY_ACCEPTANCE;
        string BY_DEF_PAYMENT;
        string BY_MIXED_PYMT;
        string BY_NEGOTIATION;
        string BY_PAYMENT;
    }

    // TODO: 
    // 1. Update docCreditNumber to be a hash of the LC.
    // 2. Update dateAndPlaceOfExpiry to be a struct with date, chainId, and contract address. Currently blocktimestamp..
    // struct DateAndPlaceOfExpiry {
    //     string date; // YYMMDD format
    //     uint256 chainId;
    //     address contractAddress;
    // }
    // 3. Update dateOfIssue to the YYMMDD format.

    // ------------- LC structs -----------------

    struct ActorDetails {
        address addressEOA;
        string addressIRL;
    }

    struct IssueDetails {
        uint256 dateOfIssue;
        string applicableRules;
        uint256 dateAndPlaceOfExpiry;
    }

    struct PortDetails {
        string portOfLoading;
        string portOfDischarge;
    }

    struct ShippingDetails {
        PartialShipments partialShipments;
        Transshipment transshipment;
        PortDetails portDetails;
        // string placeOfFinalDestination;
        // string latestDateOfShipment;
        // string shipmentPeriod;
    }

    struct CurrencyDetails {
        string currencyCode;        // ISO 4217
        address currencyAddress;    // Address of the currency contract.
        uint256 amount;
    }

    struct LC {
        uint256 sequenceOfTotal;
        FormOfDocCredit formOfDocCredit;
        uint256 docCreditNumber;
        // string referenceToPreAdvice;
        IssueDetails issueDetails;
        // string applicantBank
        ActorDetails applicant;
        ActorDetails beneficiary;
        CurrencyDetails currencyDetails;
        // string percentageCreditAmountTolerance
        // string additionalAmountsCovered
        AvailableWithBy availableWithBy;
        // string draftsAt;
        // string drawee;
        // string mixedPaymentDetails;
        // string deferredPaymentDetails;
        ShippingDetails shippingDetails;
        string descriptionOfGoodsAndOrServices;
        string documentsRequired;
        string additionalConditions;
        // string charges;
        uint256 periodForPresentation;
        ConfirmationInstructions confirmationInstructions;
        // string reimbursingBank;
        // string InstructionsToThePayingOrAcceptingOrNegotiatingBank;
        // string adviseThroughBank;
        // string senderToReceiverInformation;
    }

    mapping(address => LC) public creatorToLC;
    mapping(uint256 => LC) public docCreditNumberToLC;
    mapping(uint256 => LC) public acceptedLC;
    uint256 public docCreditNumberCounter;
    IERC20 public usdc;     // Only support USDC for now.

    constructor(address _usdcAddress) {
        usdc = IERC20(_usdcAddress);
    }


    function createLC(
        string memory _applicableRules,
        uint256 _dateAndPlaceOfExpiry,      // Just pass in the block.timestamp for now.
        string memory _applicantAddressIRL,
        ActorDetails memory _beneficiary,
        uint256 _currencyAmount,
        PortDetails memory _portDetails,
        string memory _descriptionOfGoodsAndOrServices,
        ConfirmationInstructions _confirmationInstructions
    ) external {
        LC memory newLC;

        // Standard details
        newLC.sequenceOfTotal = 1;
        newLC.formOfDocCredit = FormOfDocCredit.Irrevocable;
        newLC.docCreditNumber = docCreditNumberCounter;
        newLC.issueDetails.dateOfIssue = block.timestamp;
        newLC.issueDetails.applicableRules = _applicableRules;       // Mohammed To Read more
        newLC.issueDetails.dateAndPlaceOfExpiry = _dateAndPlaceOfExpiry;     // Set to block.timestamp for now.
        
        newLC.applicant = ActorDetails({
            addressIRL: _applicantAddressIRL,
            addressEOA: msg.sender
        });

        newLC.beneficiary = ActorDetails({
            addressIRL: _beneficiary.addressIRL,
            addressEOA: _beneficiary.addressEOA
        });
        
        newLC.currencyDetails = CurrencyDetails({
            currencyCode: "USD",
            currencyAddress: address(usdc),
            amount: _currencyAmount
        });

        // todo: fix this.
        newLC.availableWithBy = AvailableWithBy({
            BY_ACCEPTANCE: "default",
            BY_DEF_PAYMENT: "default",
            BY_MIXED_PYMT: "default",
            BY_NEGOTIATION: "default",
            BY_PAYMENT: "default"
        });


        // Shipping Details
        newLC.shippingDetails.partialShipments = PartialShipments.NotAllowed;   // Only support NotAllowed for now.
        newLC.shippingDetails.transshipment = Transshipment.NotAllowed;     // Only support NotAllowed for now.
        newLC.shippingDetails.portDetails = PortDetails({
            portOfLoading: _portDetails.portOfLoading,
            portOfDischarge: _portDetails.portOfDischarge
        });

        // Other details
        newLC.descriptionOfGoodsAndOrServices = _descriptionOfGoodsAndOrServices;
        newLC.documentsRequired = "Proof of SeaWayBill";
        newLC.additionalConditions = "Tokenized USD will be transferred digitally to this contract address on the Ethereum blockchain.";
        newLC.periodForPresentation = 21 days;
        newLC.confirmationInstructions = _confirmationInstructions;     // Mohammed to read more

        // Add LC to mappings.
        creatorToLC[msg.sender] = newLC;
        docCreditNumberToLC[docCreditNumberCounter] = newLC;
        docCreditNumberCounter++;

        // Transfer in the USDC to this contract.
        usdc.transferFrom(msg.sender, address(this), _currencyAmount);
    }


    function acceptLC(
        uint256 docCreditNumber
    ) external {
        LC memory lc = docCreditNumberToLC[docCreditNumber];
        require(lc.docCreditNumber != 0, "LC does not exist");
        require(lc.beneficiary.addressEOA == msg.sender, "Only beneficiary can accept LC");
        require(lc.issueDetails.dateAndPlaceOfExpiry > block.timestamp, "LC has expired");
        acceptedLC[docCreditNumber] = lc;
    }

    function getLC(uint256 docCreditNumber) external view returns (LC memory) {
        return docCreditNumberToLC[docCreditNumber];
    }


    function completeLC(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[10] calldata signals
    ) public {

        // require(this.verifyProof(a, b, c, signals), "Invalid Proof");

        // validate the sigining domain is GCM??
        // validate the LC has not expired
        // validate the LC has been accepted
        // validate the applicant IRL address matches the one on the seaway bill
        // validate the beneficiary IRL address matches the one on the seaway bill
        // validate the port of loading matches the one on the seaway bill
        // validate the port of discharge matches the one on the seaway bill
        // validate the description of goods matches the one on the seaway bill

    }
}
   