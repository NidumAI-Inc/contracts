// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

/// @custom:security-contact security@nidum.ai
contract Nidum is ERC20, ERC20Burnable, AccessControl, ERC20Permit, Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public constant MAX_SUPPLY = 2000000000000 * 10 ** 18;
    mapping(address => bool) public blacklisted;

    event Blacklisted(address indexed account);
    event Unblacklisted(address indexed account);
    event RoleTransferred(address indexed oldAdmin, address indexed newAdmin);

    constructor(
        address defaultAdmin,
        address minter,
        address[] memory initialRecipients,
        uint256[] memory initialAllocations
    ) ERC20("Nidum", "NIDUM") ERC20Permit("Nidum") {
        require(
            initialRecipients.length == initialAllocations.length,
            "Mismatched allocation lengths"
        );

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);

        uint256 totalAllocated = 0;
        for (uint256 i = 0; i < initialRecipients.length; i++) {
            _mint(initialRecipients[i], initialAllocations[i]);
            totalAllocated += initialAllocations[i];
        }
        require(
            totalAllocated <= 1000000000 * 10 ** 18,
            "Initial allocation exceeds limit"
        );
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds maximum supply");
        _mint(to, amount);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function blacklist(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            !hasRole(DEFAULT_ADMIN_ROLE, account),
            "Cannot blacklist an admin"
        );
        require(!hasRole(MINTER_ROLE, account), "Cannot blacklist a minter");
        blacklisted[account] = true;
        emit Blacklisted(account);
    }

    function unblacklist(
        address account
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        blacklisted[account] = false;
        emit Unblacklisted(account);
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from != address(0)) {
            require(!blacklisted[from], "Sender is blacklisted");
        }
        require(!blacklisted[to], "Receiver is blacklisted");
        super._update(from, to, amount);
    }

    function updateAdmin(
        address newAdmin
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAdmin != address(0), "New admin cannot be zero address");
        emit RoleTransferred(msg.sender, newAdmin);
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
