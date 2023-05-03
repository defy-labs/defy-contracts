// Import hre (Hardhat Runtime Environment)
const hre = require("hardhat");

async function main() {
    // Retrieve the DEFYForge contract artifact
    const DEFYForge = await hre.ethers.getContractFactory("DEFYForge");

    // Replace with the address of the deployed contract
    const DEFYForgeContractAddress =
        "0x5B4e29202a2C3C9510b45D8227293345C9609a4A";

    // Attach to the deployed contract instance
    const defyForge = DEFYForge.attach(DEFYForgeContractAddress);

    // Check if the contract is deployed
    console.log(
        `DEFYForge is deployed at ${DEFYForgeContractAddress}:`,
        await defyForge.deployed()
    );

    // TODO: MANUALLY NEED TO INPUT FORGEJOB ID FROM ENDING 24 HOURS AGO
    const forgeJobsCount = 9600;

    for (var i = 0; i < forgeJobsCount; i++) {
        const forgeJob = await defyForge.getForgeJob();

        // checks if forge job is processing
        if (forgeJob.forgeJobState == 0) {
            await defyForge.completeForgeJob(i);
        }
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
