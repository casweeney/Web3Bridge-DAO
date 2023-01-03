// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IERC20} from "../interfaces/IERC20.sol";
import {IAccessControl, Dto} from "../interfaces/IAccessControl.sol";

/// @title Vault10 Contract
/// @author https://github.com/Ultra-Tech-code, https://github.com/Adebara123
/// The Vault10 contract is used as a reward token disbursing contract for past cohort interns
/// The owner will open the vault(set withdrawTimeReached to true) for withdrawal
contract Vault10 {

    //Error
    error ALREADY_INITIALIZIED();
    error notAdmin(string);

    // ===========================
    // STATE VARIABLE
    // ===========================
    bool withdrawTimeReached;
    uint216 amountDepositedForSharing;
    uint8 numberOfPaidUsers;
    IERC20 tokenContract;
    address diamond;
    bool isInitialized;

    /// @param _tokenContract: this would be the address of the token that will be disbursed.

    constructor(address _tokenContract) {
        tokenContract = IERC20(_tokenContract);
    }

    function init(address _diamond) external {
        if(isInitialized) {
            revert ALREADY_INITIALIZIED();
        }
        diamond = _diamond;
        isInitialized = true;
    }

    struct earlyPayment {
        address earlyPayers;
        bool withdrawn;
    }

    mapping(address => earlyPayment) EarlyPayers;

    /// @dev A function to deposit into the vault
    function depositIntoVault(uint216 _amount) external {
        amountDepositedForSharing += _amount;
        IERC20(tokenContract).transferFrom(msg.sender, address(this), _amount);
    }

    function addAddressOfEarlyPayment() external {
        numberOfPaidUsers += 1;
        earlyPayment storage EP = EarlyPayers[msg.sender];
        EP.earlyPayers = msg.sender;
    }

    /// @dev A function to withdraw share
    function withdrawShare() external {
        require(withdrawTimeReached == true, "Vault not open");
        earlyPayment storage EP = EarlyPayers[msg.sender];
        assert(EP.withdrawn == false);
        uint216 share = individualShare();
        amountDepositedForSharing -= share;
        EP.withdrawn = true;
        IERC20(tokenContract).transfer(msg.sender, share);
        numberOfPaidUsers -= 1;
    }

    /// @dev A function to calculate individual share
    function individualShare() private view returns (uint216 share) {
        share = amountDepositedForSharing / numberOfPaidUsers;
    }

    /// @dev A function to open the vault for withdrawal
    /// @notice this function can only be called by the owner
    function openVault() public {
        if (IAccessControl(diamond).hasRole(Dto.Roles.VAULT_MANAGER, msg.sender)) {
            withdrawTimeReached = true;

        }else{
            revert notAdmin("Not an Admin");
        }   
    }

    /// @dev A view function to return the balance of the vault
    function returnVaultBalace() public view returns(uint216 vaultBalance) {
        vaultBalance = amountDepositedForSharing;
    }

    /// @dev A view function to return the status of withdrawTimeReached
    function checkIfWithdrawTimeReached () public view returns(bool open) {
        open = withdrawTimeReached;
    }
}
