// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Aux3Registry.sol";

contract Aux3RegistryTest is Test {
    Aux3Registry public registry;
    address public owner;
    address public user1;
    address public user2;

    event Aux3IdRegistered(address indexed addr, uint256 id);
    event Aux3IdTransferred(address indexed from, address indexed to, uint256 id);
    event Aux3EventRegistered(address indexed contractAddress, uint256 indexed eventId, uint256 indexed aux3Id);
    event Aux3EventUpdated(uint256 indexed eventId);
    event Aux3IdDeleted(address indexed addr, uint256 id);
    event Aux3EventDeleted(uint256 indexed eventId);

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        registry = new Aux3Registry(owner);
    }

    function testRegisterAux3Id() public {
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit Aux3IdRegistered(user1, 1);
        uint256 id = registry.registerAux3Id();
        assertEq(id, 1, "First registered ID should be 1");
        assertEq(registry.getAux3Id(user1), 1, "User1 should have ID 1");
    }

    function testCannotRegisterTwice() public {
        vm.startPrank(user1);
        registry.registerAux3Id();
        vm.expectRevert("Address is already registered");
        registry.registerAux3Id();
        vm.stopPrank();
    }

    function testTransferAux3Id() public {
        vm.prank(user1);
        uint256 id = registry.registerAux3Id();

        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit Aux3IdTransferred(user1, user2, id);
        registry.transferAux3Id(user2);

        assertEq(registry.getAux3Id(user1), 0, "User1 should no longer have an ID");
        assertEq(registry.getAux3Id(user2), id, "User2 should now have the transferred ID");
    }

    function testCannotTransferToSelf() public {
        vm.prank(user1);
        registry.registerAux3Id();

        vm.prank(user1);
        vm.expectRevert("Cannot transfer to the same address");
        registry.transferAux3Id(user1);
    }

    function testCannotTransferWithoutId() public {
        vm.prank(user1);
        vm.expectRevert("Sender does not have an ID");
        registry.transferAux3Id(user2);
    }

    function testDeleteAux3Id() public {
        vm.prank(user1);
        uint256 id = registry.registerAux3Id();

        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit Aux3IdDeleted(user1, id);
        registry.deleteAux3Id();

        assertEq(registry.getAux3Id(user1), 0, "User1 should no longer have an ID after deletion");
    }

    function testCannotDeleteNonexistentId() public {
        vm.prank(user1);
        vm.expectRevert("Sender does not own any Aux3Id");
        registry.deleteAux3Id();
    }

    function testRegisterAux3Event() public {
        vm.prank(user1);
        registry.registerAux3Id();

        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit Aux3EventRegistered(address(0x123), 1, 1);
        registry.registerAux3Event(
            1, // chainId
            address(0x123), // contractAddress
            bytes32(uint256(1)), // topic_0
            bytes32(0), // topic_1
            bytes32(0), // topic_2
            bytes32(0), // topic_3
            abi.encodePacked("action") // eventAction
        );

        (Aux3EventConfig memory config, bytes memory action) = registry.getAux3Event(1);
        assertEq(config.chainId, 1, "ChainId should match");
        assertEq(config.contractAddress, address(0x123), "Contract address should match");
        assertEq(config.topic_0, bytes32(uint256(1)), "Topic 0 should match");
        assertEq(action, abi.encodePacked("action"), "Event action should match");
    }

    function testUpdateAux3EventAction() public {
        vm.prank(user1);
        registry.registerAux3Id();

        vm.prank(user1);
        registry.registerAux3Event(
            1, address(0x123), bytes32(uint256(1)), bytes32(0), bytes32(0), bytes32(0), abi.encodePacked("action")
        );

        vm.prank(user1);
        vm.expectEmit(true, false, false, false);
        emit Aux3EventUpdated(1);
        registry.updateAux3EventAction(1, abi.encodePacked("new action"));

        (, bytes memory newAction) = registry.getAux3Event(1);
        assertEq(newAction, abi.encodePacked("new action"), "Event action should be updated");
    }

    function testDeleteAux3Event() public {
        vm.prank(user1);
        registry.registerAux3Id();

        vm.prank(user1);
        registry.registerAux3Event(
            1, address(0x123), bytes32(uint256(1)), bytes32(0), bytes32(0), bytes32(0), abi.encodePacked("action")
        );

        vm.prank(user1);
        vm.expectEmit(true, false, false, false);
        emit Aux3EventDeleted(1);
        registry.deleteAux3Event(1);

        vm.expectRevert("Event does not exist");
        registry.getAux3Event(1);
    }

    function testSweepNativeToken() public {
        // Send some Ether to the contract
        vm.deal(address(registry), 1 ether);

        uint256 initialBalance = address(owner).balance;

        vm.prank(owner);
        registry.sweepNativeToken();

        assertEq(address(registry).balance, 0, "Contract should have 0 balance after sweep");
        assertEq(address(owner).balance, initialBalance + 1 ether, "Owner should receive the swept Ether");
    }

    // Add this function to allow the contract to receive Ether
    receive() external payable {}

    function testSweepERC20Token() public {
        // Deploy a mock ERC20 token
        MockERC20 token = new MockERC20();
        token.mint(address(registry), 1000);

        registry.sweepToken(IERC20(address(token)));

        assertEq(token.balanceOf(address(registry)), 0, "Contract should have 0 token balance after sweep");
        assertEq(token.balanceOf(owner), 1000, "Owner should receive the swept tokens");
    }
}

// Mock ERC20 token for testing
contract MockERC20 is IERC20 {
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    uint256 public override totalSupply;

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(allowance[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }

    function mint(address to, uint256 amount) public {
        balanceOf[to] += amount;
        totalSupply += amount;
    }
}
