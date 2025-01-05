// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol"; // Adjust if the path differs
import {DG10Vault} from "src/DG10Vault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployDG10Vault is Script {
    DG10Vault private dG10Vault;

    function run() external returns (address) {
        vm.startBroadcast();

        // Sepolia USDC Address
        IERC20 usdc = IERC20(0x5fd84259d66Cd46123540766Be93DFE6D43130D7);

        // Deploy DG10Vault with USDC as the underlying asset
        dG10Vault = new DG10Vault(usdc);

        vm.stopBroadcast();

        return address(dG10Vault);
    }
}
