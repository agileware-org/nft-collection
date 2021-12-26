/* eslint-disable no-unused-expressions */
import "@nomiclabs/hardhat-ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ExpandableCollectionFactory, ExpandableCollection, ExpandableCollection__factory, ExpandableCollection2 } from "../src/types";

const { expect } = require("chai");
const { ethers, deployments, upgrades } = require("hardhat");

describe("ExpandableCollectionFactory", function () {
  let deployer: SignerWithAddress;
  let artist: SignerWithAddress;
  let shareholder: SignerWithAddress;
  let other: SignerWithAddress;
  let factory: ExpandableCollectionFactory;

  const info = {
    name: "Roberto Lo Giacco",
    symbol: "RLG",
    description: "**Me**, _myself_ and I."
  };

  beforeEach(async () => {
    const { ExpandableCollectionFactory } = await deployments.fixture(["collection"]);
    [deployer, artist, shareholder, other] = await ethers.getSigners();
    factory = (await ethers.getContractAt("ExpandableCollectionFactory", ExpandableCollectionFactory.address)) as ExpandableCollectionFactory;
    await factory.grantRole(await factory.ARTIST_ROLE(), artist.address);
  });

  it.only("Should allow upgrading", async function () {
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
    const instance = (await ethers.getContractAt("ExpandableCollection", contractAddress!)) as ExpandableCollection;
    const beaconAddress = (await factory.beacon());
    expect(await instance.totalSupply()).to.be.equal(1000);
    console.log(await factory.hasRole(await factory.DEFAULT_ADMIN_ROLE(), deployer.address));

    const Template2 = await ethers.getContractFactory("ExpandableCollection2");
    console.log("pippo");
    await factory.connect(deployer).upgrade((await Template2.deploy()).address);
    console.log("pluto");
    const instance2 = (await ethers.getContractAt("ExpandableCollection2", contractAddress!)) as ExpandableCollection2;
    console.log(await instance2.totalSupply());
    expect(await instance2.totalSupply()).to.be.equal(2000);
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
    const instance = (await ethers.getContractAt("ExpandableCollection", await factory.byName("Roberto"))) as ExpandableCollection;
    expect(await instance.owner()).to.be.equal(artist.address);
  });
});