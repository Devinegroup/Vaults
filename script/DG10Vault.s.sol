// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol"; // Adjust if the path differs
import {DG10Vault} from "src/DG10Vault.sol";  // Import your contract
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployDG10Vault is Script {
    DG10Vault private dG10Vault;

    function run() external returns (address) {
        vm.startBroadcast();

        // Define the token address for the collateral
        IERC20 usdc = IERC20(0x582E68bDe36703fad9F82Eee42D77f28b986214e); // Sepolia USDC Address (replace with the real address on mainnet or testnet)

        // Define the Binance sub-account address for this vault
        address binanceSubAccountAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;  // Replace with your Binance Sub-Account address

        address owner = 0x0Ef1ffEd8aBa84D20FC649B99763F3550f1E1617;

        // Deploy DG10Vault with the specified token and Binance sub-account address
        dG10Vault = new DG10Vault(usdc, binanceSubAccountAddress, owner);

        vm.stopBroadcast();

        return address(dG10Vault);
    }
}
