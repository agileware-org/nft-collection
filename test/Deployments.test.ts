/* eslint-disable node/no-missing-import */
/* eslint-disable camelcase */
import "@nomiclabs/hardhat-ethers";

import { ethers } from "hardhat";
import { DroppableCollectionFactory, DroppableCollectionFactory__factory } from "../src/types";

describe("Deployments", function () {
  it("Should deploy DroppableCollectionFactory", async function () {
    const DroppableCollection = await ethers.getContractFactory("DroppableCollection");
    const template = await DroppableCollection.deploy();

    const DroppableCollectionFactory = await ethers.getContractFactory("DroppableCollectionFactory");
    await DroppableCollectionFactory.deploy(template.address);
  });
});
