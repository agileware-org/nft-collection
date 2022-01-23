/* eslint-disable node/no-missing-import */
/* eslint-disable node/no-unpublished-import */
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, upgrades } = hre;
  const { deploy, get } = deployments;
  const { deployer } = await getNamedAccounts();

  const DroppableCollection = await hre.ethers.getContractFactory("DroppableCollection");

  const beacon = await upgrades.deployBeacon(DroppableCollection);
  await beacon.deployed();

  await deploy("DroppableCollectionFactory", {
    from: deployer,
    args: [beacon.address],
    log: true
  });
  await beacon.transferOwnership((await get("DroppableCollectionFactory")).address);
};
export default func;
func.dependencies = ["DroppableCollection"];
func.tags = ["collection"];
