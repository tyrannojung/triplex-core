import { ethers } from "hardhat";

async function main() {
  // Named accounts retrieval

  // Define contract addresses
  const entryPointAddress = "0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789"; // EntryPoint 주소
  const ownerAddress = "0x46897603e2A82755E9c416eF828Bd1515536b3D5"; // 소유자 주소

  // Deploy WebAuthn256r1 Contract
  const WebAuthn256r1 = await ethers.getContractFactory("WebAuthn256r1");

  const webAuthn256r1 = await WebAuthn256r1.deploy();
  await webAuthn256r1.waitForDeployment();

  console.log(
    "Deployed WebAuthn256r1 at address:",
    await webAuthn256r1.getAddress()
  );

  // Deploy Secp256r1Factory Contract
  const Secp256r1Factory = await ethers.getContractFactory("Secp256r1Factory");
  const fidoFactory = await Secp256r1Factory.deploy(
    entryPointAddress,
    await webAuthn256r1.getAddress()
  );
  await fidoFactory.waitForDeployment();

  console.log(
    "Deployed Secp256r1Factory at address:",
    await fidoFactory.getAddress()
  );

  // Deploy Paymaster Contract
  const Paymaster = await ethers.getContractFactory("Paymaster");
  const paymaster = await Paymaster.deploy(entryPointAddress, ownerAddress);
  await paymaster.waitForDeployment();

  console.log("Deployed Paymaster at address:", await paymaster.getAddress());

  /** ===================== secp256k1 simple account contract deploy ========================== */
  const Secp256k1Factory = await ethers.getContractFactory(
    "SimpleAccountFactory"
  );
  const secp256k1Factory = await Secp256k1Factory.deploy(entryPointAddress);
  await secp256k1Factory.waitForDeployment();

  console.log(
    "Deployed secp256k1Factory at address:",
    await secp256k1Factory.getAddress()
  );
}

// Handle errors
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
