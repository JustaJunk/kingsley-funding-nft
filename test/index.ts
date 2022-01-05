import { expect } from "chai";
import { assert } from "console";
import { ethers, deployments, network } from "hardhat";
import { KingsleyFundingNFT__factory } from "../typechain";

describe("KingsleyFundingNFT", function () {
  it("Simple flow", async function () {
    // Accounts
    const [owner, client0, client1, client2, client3] = await ethers.getSigners();

    // Deployment
    console.log("deploy");
    await deployments.fixture(["kingsleyNFT"]);
    const contractDeployment = await deployments.get("KingsleyFundingNFT");
    const contractAddr = contractDeployment.address
    const contract = KingsleyFundingNFT__factory.connect(
      contractAddr,
      owner
    );
    if (!owner.provider) return;

    // Contract settings
    const baseURI = "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    const tokenPrice = ethers.utils.parseEther("0.888");

    // Clients mint
    console.log("Clients mint");
    await (await contract.connect(client0).mint({value: tokenPrice})).wait();
    await (await contract.connect(client1).mint({value: tokenPrice})).wait();
    await (await contract.connect(client2).mint({value: tokenPrice})).wait();
    assert(
      (await contract.tokenURI(0)) === baseURI + "0",
      "tokenURI(0) error"
    );
    assert(
      (await contract.balanceOf(client1.address)).eq(1),
      "balanceOf() error"
    );
    const contractBalance = await owner.provider.getBalance(contractAddr);
    assert(
      (await contract.totalSupply()).eq(3),
      "contract total supply error"
    );
    assert(
      contractBalance.eq(tokenPrice.mul(3)),
      "contract balance error"
    );
    await network.provider.send("evm_setNextBlockTimestamp", [(new Date()).getTime()/1000 + 10]);
    await network.provider.send("evm_mine");
    await (await contract.connect(client2).transferFrom(client2.address, client3.address, 2)).wait();
    assert(
      (await contract.tokenOfOwnerByIndex(client3.address, 0)).eq(2),
      "tokenOfOwnerByIndex() error"
    );

    // Owner claim
    console.log("Owner claim");
    const ownerBalanceBefore = await owner.getBalance();
    const receipt = await (await contract.ownerClaim()).wait();
    assert(
      (await owner.provider.getBalance(contractAddr))?.eq(0),
      "contract balance should be empty after owner claim"
    );
    const ownerBalanceAfter = await owner.getBalance();
    assert(
      ownerBalanceAfter.eq(
        ownerBalanceBefore
        .sub(receipt.gasUsed.mul(receipt.effectiveGasPrice))
        .add(contractBalance)),
      "owner balance error"
    );
    expect(contract.connect(client0).claim())
    .to.be.revertedWith("Pausable: not paused");

    // Owner start claim
    console.log("Start claim");
    const rewards = contractBalance.mul(8).div(10);
    expect(contract.connect(client0).startClaim())
    .to.be.revertedWith("Ownable: caller is not the owner");
    await (await contract.startClaim({value: rewards})).wait();
    assert(
      (await owner.provider.getBalance(contractAddr))?.eq(rewards),
      "contract rewards error"
    );
    
    // Clients claim
    console.log("Clients claim");
    const rewardPerSec = await contract.rewardPerSec();
    console.log("rewards rate:", ethers.utils.formatEther(rewardPerSec), "eth/s")
    const b0 = await owner.provider.getBalance(contractAddr);
    await (await contract.connect(client0).claim()).wait();
    const b1 = await owner.provider.getBalance(contractAddr);
    await (await contract.connect(client3).claim()).wait();
    const b2 = await owner.provider.getBalance(contractAddr);
    const client0Receive = b0.sub(b1);
    const client3Receive = b1.sub(b2);
    console.log(ethers.utils.formatEther(client0Receive));
    console.log(ethers.utils.formatEther(client3Receive));
    assert(
      client0Receive.gt(client3Receive),
      "client rewards error"
    );
  });
});
