// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Aux3Payments is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) {}

    // emits when payment is received with native token
    event PaymentReceived(uint256 indexed aux3Id, address sender, uint256 amount);

    // emits when payment is received with ERC20 token
    event PaymentReceivedWithERC20(uint256 indexed aux3Id, address sender, address token, uint256 amount);

    // @dev takes payment with native token and forwards to owner
    function payWithNative(uint256 aux3Id) external payable {
        require(msg.value > 0, "Must provide a non-zero amount");
        require(aux3Id > 0, "Must provide a valid aux3 id");
        payable(owner()).transfer(msg.value);
        emit PaymentReceived(aux3Id, msg.sender, msg.value);
    }

    // @dev takes payment with ERC20 token and forwards to owner
    function payWithERC20(uint256 aux3Id, address token, uint256 amount) external {
        require(amount > 0, "Must provide a non-zero amount");
        require(aux3Id > 0, "Must provide a valid aux3 id");
        require(token != address(0), "Must provide a valid token address");
        IERC20(token).transferFrom(msg.sender, owner(), amount);

        emit PaymentReceivedWithERC20(aux3Id, msg.sender, token, amount);
    }
}
