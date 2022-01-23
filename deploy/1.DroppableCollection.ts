/* eslint-disable node/no-missing-import */
/* eslint-disable node/no-unpublished-import */
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, upgrades } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("DroppableCollection", {
    from: deployer,
    args: [],
    log: true
  });
};
export default func;
func.tags = ["collection"];
