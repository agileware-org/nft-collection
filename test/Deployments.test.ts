/* eslint-disable no-unused-expressions */
/* eslint-disable node/no-unpublished-import */
/* eslint-disable node/no-missing-import */
/* eslint-disable camelcase */
import "@nomiclabs/hardhat-ethers";
import { ethers, upgrades, deployments } from "hardhat";
import { DroppableCollectionFactory, DroppableCollectionFactory__factory, DroppableCollection__factory } from "../src/types";

const { expect } = require("chai");

describe("Deployments", function () {
  let beaconAddress:string|undefined;

  it("Should deploy DroppableCollectionFactory", async function () {
    const Template = await ethers.getContractFactory("DroppableCollection");
    const template = await Template.deploy();
    expect(template.address).to.be.properAddress;

    const Factory = await ethers.getContractFactory("DroppableCollectionFactory");
    const factory = await Factory.deploy(template.address);
    expect(factory.address).to.be.properAddress;
  });

  it("Should upgrade DroppableCollection", async function () {
    const { DroppableCollectionFactory } = await deployments.fixture(["collection"]);
    const [deployer] = await ethers.getSigners();
    const factory = (await ethers.getContractAt("DroppableCollectionFactory", DroppableCollectionFactory.address)) as DroppableCollectionFactory;

    const tx = await factory.connect(deployer).create({
      name: "pippo",
      symbol: "PIPPO",
      description: "A nice description"
    }, 1000, "ipfs://someHash", 1500);

    let contractAddress:string;
    for (const e of (await tx.wait()).events!) {
      if (e.event === "CreatedCollection") {
        contractAddress = e.args!.contractAddress;
      }
    }
    const instance = DroppableCollection__factory.connect(contractAddress!, deployer);
    expect(await instance.totalSupply()).to.be.equal(1000);

    await factory.upgrade((await (await ethers.getContractFactory("DroppableCollectionV2")).deploy()).address);
    expect(await instance.totalSupply()).to.be.equal(2000);
  });
});
