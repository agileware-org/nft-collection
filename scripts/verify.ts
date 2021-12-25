/* eslint-disable no-process-exit */
// eslint-disable-next-line node/no-unpublished-import
import { run, deployments } from "hardhat";

const { get } = deployments;

async function verify(contract:string, args: any[]) {
  const deployment = await get(contract);
  try {
    await run("verify:verify", {
      address: deployment.address,
      constructorArguments: args
    });
  } catch (e) {
    console.log((e instanceof Error) ? "WARNING: " + e.message : "ERROR: " + e);
  }
}

async function main() {
  await verify("ExpandableCollection", []);
  await verify("ExpandableCollectionFactory", [(await get("ExpandableCollection")).address]);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
