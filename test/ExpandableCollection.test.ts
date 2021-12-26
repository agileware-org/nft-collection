import "@nomiclabs/hardhat-ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ExpandableCollectionFactory, ExpandableCollection } from "../src/types";

const { expect } = require("chai");
const { ethers, deployments } = require("hardhat");

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
    const { ExpandableCollectionFactory } = await deployments.fixture(["editions"]);
    [deployer, artist, shareholder, other] = await ethers.getSigners();
    factory = (await ethers.getContractAt("ExpandableCollectionFactory", ExpandableCollectionFactory.address)) as ExpandableCollectionFactory;
    await factory.grantRole(await factory.ARTIST_ROLE(), await artist.address);
  });

  it("Should emit a CreatedCollection event upon create", async function () {
    expect(await factory.instances()).to.be.equal(0);
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
    expect(await factory.byName("Roberto")).not.to.be.null();
  });
});
