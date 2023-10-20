import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

import { BigNumber } from "ethers";

const circom = require("circomlibjs");

import { usdc } from "../utils/common/units";

// const SERVER_KEY_HASH = "0x2cf6a95f35c0d2b6160f07626e9737449a53d173d65d1683263892555b448d8f";
// const FROM_EMAIL = "venmo@venmo.com".padEnd(21, "\0");

const USDC = {};
const USDC_MINT_AMOUNT = usdc(1000000);
const USDC_RECIPIENT = "0x1d2033DC6720e3eCC14aBB8C2349C7ED77E831ad";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deploy } = await hre.deployments
  const network = hre.deployments.getNetworkName();

  const [deployer, sellerAddress] = await hre.getUnnamedAccounts();

  let usdcAddress;
  if (!USDC[network]) {
    const usdcToken = await deploy("USDCMock", {
      from: deployer,
      args: [USDC_MINT_AMOUNT, "USDC", "USDC"],
    });
    usdcAddress = usdcToken.address;
    console.log("USDC deployed...");
  } else {
    usdcAddress = USDC[network];
  }

  const lcContractDeployed = await deploy("LCContract", {
    from: deployer,
    args: [
      usdcAddress,
    ],
  });
  console.log("LCContract deployed...");

  // const keyHashAdapter = await deploy("ManagedKeyHashAdapter", {
  //   from: deployer,
  //   args: [SERVER_KEY_HASH],
  // });

  // const registrationProcessor = await deploy("VenmoRegistrationProcessor", {
  //   from: deployer,
  //   args: [ramp.address, keyHashAdapter.address, FROM_EMAIL],
  // });

  // console.log("Processors deployed...");

  const lcContract = await ethers.getContractAt("LCContract", lcContractDeployed.address);

  const buyer = await ethers.getSigner(deployer);
  const seller = await ethers.getSigner(sellerAddress);
  const dateOfExpiry = "2023-12-31";
  const expiryTimestamp = Math.floor(new Date(dateOfExpiry).getTime() / 1000);

  // Approve 1 USDC
  const usdcContract = await ethers.getContractAt("USDCMock", usdcAddress);
  await usdcContract.approve(lcContract.address, 1000000);

  // Create LC example
  await lcContract.connect(buyer).createLC(
    expiryTimestamp,
    "Bangalore, India",
    {
      "addressEOA": sellerAddress,
      "addressIRL": "London, India"
    },
    1000000,
    {
      "portOfLoading": "Chennai",
      "portOfDischarge": "London"
    },
    "Description of Goods and Servcies"
  );

  // Fetch LC details
  const lcDetails = await lcContract.getLC(buyer.address);
  console.log("Created LC", lcDetails);

  // Accept LC
  await lcContract.connect(seller).acceptLC(buyer.address);

  const isLCAccepted = await lcContract.isLCAccepted(buyer.address);
  console.log("LC Accepted", isLCAccepted);

  if (network == "goerli") {
    const usdcContract = await ethers.getContractAt("USDCMock", usdcAddress);
    await usdcContract.transfer(USDC_RECIPIENT, USDC_MINT_AMOUNT);
  }

  console.log("Deploy finished...");
};

export default func;
