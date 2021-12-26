/* eslint-disable no-unused-expressions */
import "@nomiclabs/hardhat-ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { DroppableCollectionFactory, DroppableCollection, DroppableCollection__factory, DroppableCollectionV2 } from "../src/types";

const { expect } = require("chai");
const { ethers, deployments, upgrades } = require("hardhat");

describe("DroppableCollectionFactory", function () {
  let deployer: SignerWithAddress;
  let artist: SignerWithAddress;
  let shareholder: SignerWithAddress;
  let other: SignerWithAddress;
  let factory: DroppableCollectionFactory;

  const info = {
    name: "Roberto Lo Giacco",
    symbol: "RLG",
    description: "**Me**, _myself_ and I."
  };

  beforeEach(async () => {
    const { DroppableCollectionFactory } = await deployments.fixture(["collection"]);
    [deployer, artist, shareholder, other] = await ethers.getSigners();
    factory = (await ethers.getContractAt("DroppableCollectionFactory", DroppableCollectionFactory.address)) as DroppableCollectionFactory;
    await factory.grantRole(await factory.ARTIST_ROLE(), artist.address);
  });

  it("Should allow upgrading", async function () {
    const tx = await factory.connect(artist).create(
      {
        name: "Roberto",
        symbol: "RLG",
        description: "**Me**, _myself_ and I. A gentle reminder to take care of our inner child, avoiding to take ourselves too seriously, no matter the circumstances: we are just _'a blade of grass'_. See [my website](http://www.agileware.org)",
      },
      1000,
      "https://ipfs.io/ipfs/bafybeib52yyp5jm2vwifd65mv3fdmno6dazwzyotdklpyq2sv6g2ajlgxu",
      250);

    let contractAddress:string;
    for (const e of (await tx.wait()).events!) {
      if (e.event === "CreatedCollection") {
        contractAddress = e.args!.contractAddress;
      }
    }
    const instance = (await ethers.getContractAt("DroppableCollection", contractAddress!)) as DroppableCollection;
    expect(await instance.totalSupply()).to.be.equal(1000);

    await factory.connect(deployer).upgrade((await (await ethers.getContractFactory("DroppableCollectionV2")).deploy()).address);
    expect(await instance.totalSupply()).to.be.equal(2000);
  });

  it("Should emit a CreatedCollection event upon create", async function () {
    await expect(factory.connect(artist).create(
      {
        name: "Roberto",
        symbol: "RLG",
        description: "**Me**, _myself_ and I. A gentle reminder to take care of our inner child, avoiding to take ourselves too seriously, no matter the circumstances: we are just _'a blade of grass'_. See [my website](http://www.agileware.org)",
      },
      1000,
      "https://ipfs.io/ipfs/bafybeib52yyp5jm2vwifd65mv3fdmno6dazwzyotdklpyq2sv6g2ajlgxu",
      250))

      .to.emit(factory, "CreatedCollection");

    expect(await factory.instances()).to.be.equal(1);
    expect(await factory.byName("Roberto")).to.be.properAddress;
    const instance = (await ethers.getContractAt("DroppableCollection", await factory.byName("Roberto"))) as DroppableCollection;
    expect(await instance.owner()).to.be.equal(artist.address);
  });
});
