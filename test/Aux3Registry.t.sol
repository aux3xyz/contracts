// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Aux3Registry.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Aux3RegistryTest is Test {
    Aux3Registry registry;
    address owner = address(0x1);
    address addr1 = address(0x2);
    address addr2 = address(0x3);
    address token = address(0x4);

    function setUp() public {
        vm.prank(owner);
        registry = new Aux3Registry(owner);
    }

    function testRegisterAux3Id() public {
        vm.prank(owner);
        uint256 aux3Id = registry.registerAux3Id(addr1);
        assertEq(aux3Id, 1);
        assertEq(registry.getAux3Id(addr1), 1);
    }

    function testFailRegisterSameAddress() public {
        vm.prank(owner);
        registry.registerAux3Id(addr1);
        registry.registerAux3Id(addr1); // Should revert because the address is already registered
    }

    function testTransferAux3Id() public {
        vm.prank(owner);
        registry.registerAux3Id(addr1);
        vm.prank(addr1);
        registry.transferAux3Id(addr2);
        assertEq(registry.getAux3Id(addr2), 1);
        assertEq(registry.getAux3Id(addr1), 0);
    }

    function testFailTransferAux3IdToSameAddress() public {
        vm.prank(addr1);
        registry.registerAux3Id(addr1);

        vm.prank(addr1);
        vm.expectRevert("Cannot transfer to the same address"); // Expect a revert with the specific error message
        registry.transferAux3Id(addr1);
    }

    function testRegisterAux3Event() public {
        bytes32 topic_0 = keccak256("EventSignature");
        bytes memory eventAction = abi.encode("EventAction");

        vm.prank(owner);
        registry.registerAux3Id(addr1);

        vm.prank(addr1);
        registry.registerAux3Event(
            1,
            address(this),
            topic_0,
            "",
            "",
            "",
            eventAction
        );

        (Aux3EventConfig memory config, bytes memory action) = registry
            .getAux3Event(1);
        assertEq(config.aux3Id, 1);
        assertEq(config.chainId, 1);
        assertEq(config.contractAddress, address(this));
        assertEq(config.topic_0, topic_0);
        assertEq(action, eventAction);
    }

    function testUpdateAux3EventAction() public {
        bytes32 topic_0 = keccak256("EventSignature");
        bytes memory initialAction = abi.encode("InitialAction");
        bytes memory updatedAction = abi.encode("UpdatedAction");

        vm.prank(owner);
        registry.registerAux3Id(addr1);

        vm.prank(addr1);
        registry.registerAux3Event(
            1,
            address(this),
            topic_0,
            "",
            "",
            "",
            initialAction
        );

        vm.prank(addr1);
        registry.updateAux3EventAction(1, updatedAction);

        (, bytes memory action) = registry.getAux3Event(1);
        assertEq(action, updatedAction);
    }

    function testUpdateAux3IdBalance() public {
        vm.prank(owner);
        registry.registerAux3Id(addr1);

        vm.prank(owner);
        registry.updateAux3IdBalance(1, 1000);

        assertEq(registry.getAux3IdBalance(1), 1000);
    }

    function testSweepNativeToken() public {
        // Fund the contract with some Ether
        vm.deal(address(registry), 10 ether);
        assertEq(address(registry).balance, 10 ether);

        uint256 ownerInitialBalance = owner.balance;

        // Sweep the native token to the owner
        vm.prank(owner);
        registry.sweepNativeToken();

        // Check the balances
        assertGt(owner.balance, ownerInitialBalance); // Owner balance should increase
        assertEq(address(registry).balance, 0); // Registry balance should be zero after the sweep
    }

    function testSweepERC20Token() public {
        // Mock ERC20 contract
        vm.mockCall(
            token,
            abi.encodeWithSelector(
                IERC20.balanceOf.selector,
                address(registry)
            ),
            abi.encode(1000)
        );
        vm.mockCall(
            token,
            abi.encodeWithSelector(IERC20.transfer.selector, owner, 1000),
            abi.encode(true)
        );

        vm.prank(owner);
        registry.sweepToken(token);
    }
}
