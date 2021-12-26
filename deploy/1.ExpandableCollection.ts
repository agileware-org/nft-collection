/* eslint-disable node/no-missing-import */
/* eslint-disable node/no-unpublished-import */
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, ethers, upgrades } = hre;
  const { save } = deployments;
  // Deploying
  const factory = await ethers.getContractFactory("ExpandableCollection");
  const instance = await upgrades.deployProxy(factory, {
    initializer: false
  });
  await instance.deployed();

  const artifact = await deployments.getExtendedArtifact("ExpandableCollection");
  await save("ExpandableCollection", { address: instance.address, ...artifact });
};
export default func;
func.tags = ["collection"];
