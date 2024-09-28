import { ethers } from "hardhat";

async function main() {
  // Named accounts retrieval

  // Define contract addresses
  const entryPointAddress = '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789'; // EntryPoint 주소
  const ownerAddress = '0x46897603e2A82755E9c416eF828Bd1515536b3D5'; // 소유자 주소

  // Deploy WebAuthn256r1 Contract
  const WebAuthn256r1 = await ethers.getContractFactory("WebAuthn256r1");
  
  const webAuthn256r1 = await WebAuthn256r1.deploy();
  await webAuthn256r1.waitForDeployment();

  console.log('Deployed WebAuthn256r1 at address:', await webAuthn256r1.getAddress());

  // Deploy FIDOAccountFactory2 Contract
  const FIDOAccountFactory2 = await ethers.getContractFactory("FIDOAccountFactory2");
  const fidoFactory = await FIDOAccountFactory2.deploy(entryPointAddress, await webAuthn256r1.getAddress());
  await fidoFactory.waitForDeployment();

  console.log('Deployed FIDOAccountFactory2 at address:', await fidoFactory.getAddress());

  // Deploy Paymaster Contract
  const Paymaster = await ethers.getContractFactory("Paymaster");
  const paymaster = await Paymaster.deploy(entryPointAddress, ownerAddress);
  await paymaster.waitForDeployment();

  console.log('Deployed Paymaster at address:', await paymaster.getAddress());

  /** ===================== secp256k1 simple account contract deploy ========================== */
  const SimpleAccountFactory = await ethers.getContractFactory("SimpleAccountFactory");
  const simpleAccountFactory = await SimpleAccountFactory.deploy(entryPointAddress);
  await simpleAccountFactory.waitForDeployment();
  
  console.log('Deployed simpleAccountFactory at address:', await simpleAccountFactory.getAddress());
}

// Handle errors
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});