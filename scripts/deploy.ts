import { ethers, run } from "hardhat";

async function main() {
  const Erc20my = await ethers.getContractFactory("Erc20my");
  const Erc20myInstance = await Erc20my.deploy("Erc20my", "EMY", 18, '1000000000000000000000000');
  await Erc20myInstance.deployed();

  const MyDao = await ethers.getContractFactory("MyDao");
  const MyDaoInstance = await MyDao.deploy((await ethers.getSigners())[0].address, Erc20myInstance.address, 1000, 150);
  await MyDaoInstance.deployed();

  console.log("verifing");
  try {
    await run("verify:verify", {
      address: Erc20myInstance.address,
      constructorArguments: [
        "Erc20my",
        "EMY",
        18,
        '1000000000000000000000000'
      ],
    });
  }
  catch (ex) {
    console.log("verify failed", Erc20myInstance.address);
  }
  try {
    await run("verify:verify", {
      address: MyDaoInstance.address,
      constructorArguments: [
        (await ethers.getSigners())[0].address, Erc20myInstance.address, 1000, 150
      ],
    });
  }
  catch (ex) {
    console.log("verify failed", MyDaoInstance.address);
  }

  console.log("Erc20my deployed to:", Erc20myInstance.address);
  console.log("MyDao deployed to:", MyDaoInstance.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
