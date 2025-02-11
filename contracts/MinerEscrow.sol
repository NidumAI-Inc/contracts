// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact security@nidum.ai
contract MinerEscrow is ReentrancyGuard, Ownable {
    IERC20 public immutable token;
    address public payer;
    address public recipient;
    uint256 public amount;
    bool public isFunded;
    bool public isReleased;
    bool public isPaused;
    uint256 public depositTimestamp;
    uint256 public constant TIMEOUT = 7 days;

    event Deposited(
        address indexed payer,
        address indexed recipient,
        uint256 amount
    );
    event Released(address indexed recipient, uint256 amount);
    event Refunded(address indexed payer, uint256 amount);
    event Paused();
    event Unpaused();

    constructor(IERC20 _token) Ownable(msg.sender) {
        token = _token;
    }

    modifier whenNotPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }

    function pause() external onlyOwner {
        isPaused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        isPaused = false;
        emit Unpaused();
    }

    function deposit(
        address _recipient,
        uint256 _amount
    ) external whenNotPaused nonReentrant {
        require(!isFunded, "Funds already deposited");
        require(_amount > 0, "Amount must be greater than zero");
        require(_recipient != address(0), "Invalid recipient");

        payer = msg.sender;
        recipient = _recipient;
        amount = _amount;
        isFunded = true;
        depositTimestamp = block.timestamp;

        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );
        emit Deposited(msg.sender, _recipient, _amount);
    }

    function release() external whenNotPaused nonReentrant {
        require(isFunded, "No funds deposited");
        require(!isReleased, "Funds already released");
        require(msg.sender == payer || msg.sender == recipient, "Unauthorized");
        require(recipient != address(0), "Invalid recipient");

        isReleased = true;
        isFunded = false;
        require(token.transfer(recipient, amount), "Transfer failed");
        emit Released(recipient, amount);
    }

    function refund() external whenNotPaused nonReentrant {
        require(isFunded, "No funds deposited");
        require(!isReleased, "Funds already released");
        require(
            msg.sender == payer ||
                block.timestamp >= depositTimestamp + TIMEOUT,
            "Unauthorized"
        );
        require(
            block.timestamp >= depositTimestamp + (2 * TIMEOUT),
            "Extended timeout required for refund"
        );

        isFunded = false;
        require(token.transfer(payer, amount), "Refund failed");
        emit Refunded(payer, amount);
    }
}
