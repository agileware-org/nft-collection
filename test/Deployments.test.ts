/* eslint-disable node/no-unpublished-import */
/* eslint-disable node/no-missing-import */
/* eslint-disable camelcase */
import "@nomiclabs/hardhat-ethers";
import { Contract } from "ethers";

import { ethers, upgrades, deployments } from "hardhat";
import { ExpandableCollectionFactory, ExpandableCollectionFactory__factory, ExpandableCollection, ExpandableCollection__factory } from "../src/types";

describe("Deployments", function () {
  let beaconAddress:string|undefined;

  it("Should deploy ExpandableCollectionFactory", async function () {
    const Template = await ethers.getContractFactory("ExpandableCollection");
    const template = await Template.deploy();

    const Factory = await ethers.getContractFactory("ExpandableCollectionFactory");
    await Factory.deploy(template.address);
  });

  it("Should upgrade ExpandableCollection", async function () {
    const factoryAddress = (await deployments.get("ExpandableCollectionFactory")).address;
    const [deployer] = await ethers.getSigners();
    const factory = ExpandableCollectionFactory__factory.connect(factoryAddress, deployer) as ExpandableCollectionFactory;
    const tx = await factory.create({ name: "pippo", symbol: "PIPPO", description: "A nice description" }, 2500, "ipfs://someHash", 1500);

    const events = (await tx.wait()).events!;
    const instance = ExpandableCollection__factory.connect(events[0]!.args!.contractAddress, deployer);
    console.log(instance.address);
    console.log(await instance.connect(deployer).totalSupply());

    const Template = await ethers.getContractFactory("ExpandableCollection2");
    const template = await upgrades.upgradeProxy(beaconAddress as string, Template);
    console.log(await instance.totalSupply());
    await template.deployed();
  });
});
