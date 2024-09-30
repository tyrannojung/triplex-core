import "dotenv/config";
import { ethers, parseEther } from "ethers";

const privateKey = process.env.PRIVATE_KEY as string;
const providerUrl = process.env.SEPOLIA_URL as string;

const provider = new ethers.JsonRpcProvider(providerUrl);
const wallet = new ethers.Wallet(privateKey, provider);

// 트랜잭션 데이터 정의
const transaction = {
  from: "0x84207aCCB87EC578Bef5f836aeC875979C1ABA85",
  to: "0x680578C31F892b9c5Af6f62381E78ea5Ec42E408",
  value: parseEther("0.2"), // 0.2 ETH
  data: "0xd0e30db0", // 이더리움은 함수 시그니처를 고유하게 식별하기 위해 Keccak-256 해시 함수를 사용 -> 출력 256바이트 중 앞 4바이트를 잘라서 사용
  // Paymaster.sol 의 BasePaymaster 의 deposit()를 위와 같이 변환한 데이터다.
};

// 트랜잭션 전송
async function sendTransaction() {
  try {
    const tx = await wallet.sendTransaction(transaction);
    const receipt = await tx.wait();
    console.log("Transaction receipt:", receipt);
  } catch (error) {
    console.error("Error sending transaction:", error);
  }
}

sendTransaction();
