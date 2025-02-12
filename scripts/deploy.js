const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log(`Deploying contracts with the account: ${deployer.address}`);

    const MachineRegistry = await hre.ethers.getContractFactory("MachineRegistry");
    const contract = await MachineRegistry.deploy();

    await contract.deployed();
    console.log(`MachineRegistry deployed at: ${contract.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
