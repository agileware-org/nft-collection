/* eslint-disable node/no-missing-import */
/* eslint-disable node/no-unpublished-import */
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, get } = deployments;
  const { deployer } = await getNamedAccounts();

  const editions = await get("ExpandableCollection");
  await deploy("ExpandableCollectionFactory", {
    from: deployer,
    args: [editions.address],
    log: true
  });
};
export default func;
func.dependencies = ["ExpandableCollection"];
func.tags = ["editions"];
