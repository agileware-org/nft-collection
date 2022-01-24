/* eslint-disable node/no-missing-import */
/* eslint-disable node/no-unpublished-import */
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, upgrades } = hre;
  const { deploy, get } = deployments;
  const { deployer } = await getNamedAccounts();

  const template = await get("DroppableCollection");

  await deploy("DroppableCollectionFactory", {
    from: deployer,
    args: [template.address],
    log: true
  });
};
export default func;
func.dependencies = ["DroppableCollection"];
func.tags = ["collection"];
