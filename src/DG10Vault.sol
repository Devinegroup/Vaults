// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
/**
 * @title DG10Vault
 * @dev This contract implements the ERC4626 vault for managing collateral deposits and transfers to Binance sub-accounts.
 * The admin has special permission to transfer underlying collateral to Binance.
 * Users can deposit collateral and receive shares, but only the admin can withdraw underlying collateral for trading.
 */
contract DG10Vault is ERC4626, Ownable, ReentrancyGuard {
    using Math for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant _BASIS_POINT_SCALE = 1e4;

    // Declare the token (ERC20) that this vault will manage
    IERC20 public token;

    // Mapping of vault contract address to the corresponding Binance sub-account wallet address
    mapping(address => address) public vaultToBinanceSubAccount;

    // Event declarations
    event DepositToBinance(address indexed user, uint256 amount, address indexed binanceAddress);
    event TransferToBinance(address indexed admin, uint256 amount, address indexed binanceAddress);
    event WithdrawRequest(address indexed user, uint256 amount, address indexed userAddress);

    /**
     * @dev Initializes the DG10Vault contract.
     * @param asset The underlying asset (ERC20 token) that will be used as collateral in the vault.
     * @param binanceAddress The Binance sub-account address associated with this vault.
     */
    constructor(IERC20 asset, address binanceAddress, address Owner) ERC4626(asset) ERC20("DG10 Vault", "DG10") Ownable(Owner) {
        require(binanceAddress != address(0), "Binance address cannot be the zero address");
        require(address(asset) != address(0), "Asset address cannot be zero");

        // Set the token (ERC20) for the vault
        token = asset;

        // Assign the Binance sub-account address
        vaultToBinanceSubAccount[address(this)] = binanceAddress;
    }

    // == OVERRIDE == //

    /**
     * @dev Deposit the underlying collateral into the vault. 
     * This function will mint shares for the user but transfer the underlying tokens to the vault.
     * Emits a DepositToBinance event for backend processing.
     * @param amount The amount of collateral tokens the user wants to deposit.
     */
    function depositCollateral(uint256 amount) external nonReentrant {
        require(amount > 0, "Deposit amount must be greater than 0");

        // 1. Transfer the underlying collateral (tokens) from the user to the vault
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer of collateral failed");

        // 2. Mint shares to the user based on the deposited collateral (amount)
        uint256 shares = previewDeposit(amount); // Preview how many shares to mint
        _mint(msg.sender, shares); // Mint shares to the user

        // 3. Emit the event for backend to process the deposit and initiate transfer to Binance sub-account
        address binanceAddress = vaultToBinanceSubAccount[address(this)];
        emit DepositToBinance(msg.sender, amount, binanceAddress);
    }

    /**
     * @dev Admin function to transfer collateral from the vault to a Binance sub-account.
     * Only the admin can call this function.
     * Emits a TransferToBinance event for backend processing.
     * @param amount The amount of collateral tokens to transfer from the vault to Binance.
     */
    function transferToBinance(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than 0");

        // Determine the Binance sub-account address for this vault
        address binanceAddress = vaultToBinanceSubAccount[address(this)];
        require(binanceAddress != address(0), "No Binance sub-account assigned");

        // Ensure that the vault has enough collateral to transfer
        uint256 vaultBalance = token.balanceOf(address(this));
        require(vaultBalance >= amount, "Insufficient balance in the vault");

        // Transfer the underlying collateral (tokens) from the vault to the Binance sub-account
        bool successToBinance = token.transfer(binanceAddress, amount);
        require(successToBinance, "Transfer to Binance failed");

        // Emit an event for backend to process the transfer to Binance
        emit TransferToBinance(msg.sender, amount, binanceAddress);
    }

    /**
     * @dev Set the Binance sub-account address for a specific vault. This should be done by the admin.
     * @param vault The address of the vault to assign the Binance sub-account for.
     * @param binanceAddress The Binance sub-account address to receive collateral transfers.
     */
    function setBinanceSubAccount(address vault, address binanceAddress) external onlyOwner {
        require(vault != address(0), "Invalid vault address");
        require(binanceAddress != address(0), "Invalid Binance address");

        vaultToBinanceSubAccount[vault] = binanceAddress;
    }

    /**
     * @dev Function for users to request a withdrawal of tokens from the contract to an external address.
     * This event is emitted for backend processing.
     * @param amount The amount of collateral tokens the user wants to withdraw.
     * @param userAddress The external address to which the withdrawal should be sent.
     */
    function requestWithdrawal(uint256 amount, address userAddress) external nonReentrant {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(userAddress != address(0), "Invalid user address");

        // Ensure that the contract has enough balance to fulfill the withdrawal request
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= amount, "Insufficient balance in the contract");

        // Emit the event to notify the backend that a withdrawal request has been made
        emit WithdrawRequest(msg.sender, amount, userAddress);
    }
}
