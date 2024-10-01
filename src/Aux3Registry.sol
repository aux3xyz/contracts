// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Configuration struct for Aux3Events
struct Aux3EventConfig {
    uint32 chainId;
    uint256 aux3Id;
    address contractAddress;
    bytes32 topic_0;
    bytes32 topic_1;
    bytes32 topic_2;
    bytes32 topic_3;
}

/// @title Aux3Registry
contract Aux3Registry is Ownable {
    uint256 public lastId;
    uint256 public lastAux3EventId;

    using SafeERC20 for IERC20;

    /// @notice Mapping of addresses to their Aux3Ids
    mapping(address => uint256) public aux3Ids;
    /// @notice Mapping of Aux3Event IDs to their configurations
    mapping(uint256 => Aux3EventConfig) public aux3EventIds;
    /// @notice Mapping of Aux3Event IDs to their actions
    mapping(uint256 => bytes) public aux3EventActions;

    constructor(address initialOwner) Ownable(initialOwner) {}

    // Events
    event Aux3IdRegistered(address indexed addr, uint256 id);
    event Aux3IdTransferred(address indexed from, address indexed to, uint256 id);
    event Aux3EventRegistered(address indexed contractAddress, uint256 indexed eventId, uint256 indexed aux3Id);
    event Aux3EventUpdated(uint256 indexed eventId);
    event Aux3IdDeleted(address indexed addr, uint256 id);
    event Aux3EventDeleted(uint256 indexed eventId);
    event NativeTokenSwept(address indexed owner, uint256 amount);
    event ERC20TokenSwept(address indexed token, address indexed owner, uint256 amount);

    /// @notice Registers an Aux3Id for the sender
    /// @return The newly registered Aux3Id
    function registerAux3Id() public returns (uint256) {
        require(aux3Ids[msg.sender] == 0, "Address is already registered");

        lastId++;
        aux3Ids[msg.sender] = lastId;

        emit Aux3IdRegistered(msg.sender, lastId);
        return lastId;
    }

    /// @notice Retrieves the Aux3Id of a given address
    /// @param _addr The address to query
    /// @return The Aux3Id associated with the address
    function getAux3Id(address _addr) public view returns (uint256) {
        return aux3Ids[_addr];
    }

    /// @notice Transfers the sender's Aux3Id to another address
    /// @param _to The recipient address
    function transferAux3Id(address _to) public {
        require(_to != msg.sender, "Cannot transfer to the same address");
        require(_to != address(0), "Invalid recipient address");
        require(aux3Ids[_to] == 0, "Recipient already has an ID");

        uint256 id = aux3Ids[msg.sender];
        require(id != 0, "Sender does not have an ID");

        delete aux3Ids[msg.sender];
        aux3Ids[_to] = id;

        emit Aux3IdTransferred(msg.sender, _to, id);
    }

    /// @notice Deletes the sender's Aux3Id
    function deleteAux3Id() public {
        require(aux3Ids[msg.sender] != 0, "Sender does not own any Aux3Id");

        uint256 idToDelete = aux3Ids[msg.sender];
        delete aux3Ids[msg.sender];
        emit Aux3IdDeleted(msg.sender, idToDelete);
    }

    /// @notice Registers a new Aux3Event
    /// @param _chainId The chain ID for the event
    /// @param _contractAddress The contract address for the event
    /// @param _topic_0 The first topic (event signature)
    /// @param _topic_1 The second topic (optional)
    /// @param _topic_2 The third topic (optional)
    /// @param _topic_3 The fourth topic (optional)
    /// @param _eventAction The action associated with the event
    function registerAux3Event(
        uint32 _chainId,
        address _contractAddress,
        bytes32 _topic_0,
        bytes32 _topic_1,
        bytes32 _topic_2,
        bytes32 _topic_3,
        bytes memory _eventAction
    ) public {
        uint256 _aux3Id = aux3Ids[msg.sender];

        require(_aux3Id != 0, "Sender does not have an ID");
        require(_contractAddress != address(0), "Invalid contract address");
        require(_topic_0 != bytes32(0), "Invalid event signature");
        require(_eventAction.length > 0, "Invalid event action");
        require(_chainId != 0, "Invalid chain ID");

        lastAux3EventId++;

        // create Aux3EventConfig
        Aux3EventConfig memory config =
            Aux3EventConfig(_chainId, _aux3Id, _contractAddress, _topic_0, _topic_1, _topic_2, _topic_3);

        aux3EventIds[lastAux3EventId] = config;
        aux3EventActions[lastAux3EventId] = _eventAction;

        emit Aux3EventRegistered(_contractAddress, lastAux3EventId, _aux3Id);
    }

    /// @notice Retrieves the configuration and action of an Aux3Event
    /// @param _eventId The ID of the Aux3Event
    /// @return The Aux3EventConfig and the associated action
    function getAux3Event(uint256 _eventId) public view returns (Aux3EventConfig memory, bytes memory) {
        require(aux3EventIds[_eventId].aux3Id != 0, "Event does not exist");
        return (aux3EventIds[_eventId], aux3EventActions[_eventId]);
    }

    /// @notice Deletes an Aux3Event
    /// @param _eventId The ID of the Aux3Event to delete
    function deleteAux3Event(uint256 _eventId) public {
        require(aux3EventIds[_eventId].aux3Id != 0, "Event does not exist");
        require(aux3EventIds[_eventId].aux3Id == aux3Ids[msg.sender], "Sender does not own the event's aux3Id");

        delete aux3EventIds[_eventId];
        delete aux3EventActions[_eventId];
        emit Aux3EventDeleted(_eventId);
    }

    /// @notice Updates the action for an Aux3Event
    /// @param _eventId The ID of the Aux3Event to update
    /// @param _eventAction The new action for the Aux3Event
    function updateAux3EventAction(uint256 _eventId, bytes memory _eventAction) public {
        require(aux3EventIds[_eventId].aux3Id == aux3Ids[msg.sender], "Sender does not own the event's aux3Id");
        aux3EventActions[_eventId] = _eventAction;
        emit Aux3EventUpdated(_eventId);
    }

    /// @notice Sweeps native tokens from the contract to the owner
    function sweepNativeToken() external onlyOwner {
        uint256 balance = address(this).balance;
        address payable ownerPayable = payable(owner());
        (bool success,) = ownerPayable.call{value: balance}("");
        require(success, "Native token transfer failed");

        emit NativeTokenSwept(ownerPayable, balance);
    }

    /// @notice Sweeps ERC20 tokens from the contract to the owner
    /// @param token The IERC20 token to sweep
    function sweepToken(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to sweep");
        token.safeTransfer(owner(), balance);

        emit ERC20TokenSwept(address(token), owner(), balance);
    }
}
