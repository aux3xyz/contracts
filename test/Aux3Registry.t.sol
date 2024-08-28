// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Aux3Registry.sol";

contract Aux3RegistryTest is Test {
    Aux3Registry public registry;

    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public user3 = address(0x3);

    function setUp() public {
        registry = new Aux3Registry();
    }

    function testRegisterAux3Id() public {
        uint256 id = registry.registerAux3Id(user1);
        assertEq(id, 1);
        assertEq(registry.getAux3Id(user1), 1);

        // Try registering the same address again (should fail)
        vm.expectRevert("Address is already registered");
        registry.registerAux3Id(user1);
    }

    function testRegisterMultipleUsers() public {
        uint256 id1 = registry.registerAux3Id(user1);
        uint256 id2 = registry.registerAux3Id(user2);

        assertEq(id1, 1);
        assertEq(id2, 2);
        assertEq(registry.getAux3Id(user1), 1);
        assertEq(registry.getAux3Id(user2), 2);
    }

    function testTransferAux3Id() public {
        registry.registerAux3Id(user1);

        // Transfer from user1 to user2
        vm.prank(user1);
        registry.transferAux3Id(user2);

        assertEq(registry.getAux3Id(user1), 0);
        assertEq(registry.getAux3Id(user2), 1);
    }

    function testTransferAux3IdFailsForNonOwner() public {
        registry.registerAux3Id(user1);

        // Try to transfer from user2 (should fail)
        vm.prank(user2);
        vm.expectRevert("Sender does not have an ID");
        registry.transferAux3Id(user3);
    }

    function testTransferAux3IdToSelf() public {
        registry.registerAux3Id(user1);

        // Try to transfer to self (should fail)
        vm.prank(user1);
        vm.expectRevert("Cannot transfer to the same address");
        registry.transferAux3Id(user1);
    }

    function testTransferToInvalidAddress() public {
        registry.registerAux3Id(user1);

        // Try to transfer to the zero address (should fail)
        vm.prank(user1);
        vm.expectRevert("Invalid recipient address");
        registry.transferAux3Id(address(0));
    }

    function testEmptyRegistryTransfer() public {
        // Try to transfer when registry is empty (should fail)
        vm.prank(user1);
        vm.expectRevert("Registry is empty");
        registry.transferAux3Id(user2);
    }
}
