/* eslint-disable no-unused-expressions */
/* eslint-disable node/no-unpublished-import */
/* eslint-disable node/no-missing-import */
/* eslint-disable camelcase */
import "@nomiclabs/hardhat-ethers";
import { ethers, upgrades, deployments } from "hardhat";
import { ExpandableCollectionFactory, ExpandableCollectionFactory__factory, ExpandableCollection__factory } from "../src/types";

const { expect } = require("chai");

describe("Deployments", function () {
  let beaconAddress:string|undefined;

  it("Should deploy ExpandableCollectionFactory", async function () {
    const Template = await ethers.getContractFactory("ExpandableCollection");
    const template = await Template.deploy();
    expect(template.address).to.be.properAddress;

    const Factory = await ethers.getContractFactory("ExpandableCollectionFactory");
    const factory = await Factory.deploy(template.address);
    expect(factory.address).to.be.properAddress;
  });

  it("Should upgrade ExpandableCollection", async function () {
    const Template = await ethers.getContractFactory("ExpandableCollection");
    const template = await Template.deploy();
    expect(template.address).to.be.properAddress;

    const Factory = await ethers.getContractFactory("ExpandableCollectionFactory");
    const factory = await Factory.deploy(template.address) as ExpandableCollectionFactory;
    expect(factory.address).to.be.properAddress;

    const [deployer] = await ethers.getSigners();
    console.log(await factory.connect(deployer).beacon());

    await factory.deployed();
    console.log(factory.address);
    const tx = await factory.connect(deployer).create({ name: "pippo", symbol: "PIPPO", description: "A nice description" }, 2500, "ipfs://someHash", 1500);
    console.log("pippo");
    const events = (await tx.wait()).events!;
    console.log(tx);
    const instance = ExpandableCollection__factory.connect(events[0]!.args!.contractAddress, deployer);
    console.log(instance.address);
    console.log(await instance.connect(deployer).totalSupply());
    console.log(await instance.totalSupply());

    const Template2 = await ethers.getContractFactory("ExpandableCollection2");
    const template2 = await upgrades.upgradeProxy(beaconAddress as string, Template2);
    await template2.deployed();
    console.log(await instance.totalSupply());
  });
});
