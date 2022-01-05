import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { BigNumber } from "@ethersproject/bignumber";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deploy } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();
  const kingsleyNFT = await deploy("KingsleyFundingNFT", {
    from: deployer,
    gasPrice: BigNumber.from("100000000000"),
  });
  console.log("KingsleyFundingNFT deployed to:", kingsleyNFT.address);
};
export default func;
func.tags = ["kingsleyNFT"];
