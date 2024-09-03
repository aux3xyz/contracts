// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

struct Aux3EventConfig {
    address contractAddress;
    bytes32 eventSignature;
    bytes32 eventAction;
    uint256 aux3Id;
    uint32 chainId;
    uint8 eventTopic;
}

contract Aux3Registry is Ownable {
    uint256 public lastId;
    uint256 public lastAux3EventId;
    mapping(address => uint256) public aux3Ids;
    mapping(uint256 => Aux3EventConfig) public aux3EventIds;

    // initialize the contract
    constructor(address _owner) Ownable(_owner) {}

    // event declarations
    // aux3 ID related
    event Aux3IdRegistered(address indexed addr, uint256 id);
    event Aux3IdTransferred(address indexed from, address indexed to, uint256 id);

    // aux3 events related
    event Aux3EventRegistered(address indexed contractAddress, uint256 indexed eventId, uint256 indexed aux3Id);
    event Aux3EventUpdated(uint256 indexed eventId);

    // @dev register an address for an aux3 id
    function registerAux3Id(address _addr) public returns (uint256) {
        require(aux3Ids[_addr] == 0, "Address is already registered");
        require(_addr != address(0), "Invalid address");

        lastId++;
        aux3Ids[_addr] = lastId;

        // Emit an event for registration
        emit Aux3IdRegistered(_addr, lastId);

        return lastId;
    }

    // @dev get the aux3 id for an address
    function getAux3Id(address _addr) public view returns (uint256) {
        return aux3Ids[_addr];
    }

    // @dev transfer the aux3 id to another address
    function transferAux3Id(address _to) public {
        require(lastId > 0, "Registry is empty");
        require(_to != msg.sender, "Cannot transfer to the same address");
        require(_to != address(0), "Invalid recipient address");

        uint256 id = aux3Ids[msg.sender];
        require(id != 0, "Sender does not have an ID");

        delete aux3Ids[msg.sender];
        aux3Ids[_to] = id;

        // Emit an event for transfer
        emit Aux3IdTransferred(msg.sender, _to, id);
    }

    // @dev register an event for user having an aux3 id
    function registerAux3Event(
        address _contractAddress,
        bytes32 _eventSignature,
        bytes32 _eventAction,
        uint32 _chainId,
        uint8 _eventTopic
    ) public {
        require(aux3Ids[msg.sender] != 0, "Sender does not have an ID");
        require(_contractAddress != address(0), "Invalid contract address");
        require(_eventSignature != bytes32(0), "Invalid event signature");
        require(_eventAction != bytes32(0), "Invalid event action");
        require(_chainId != 0, "Invalid chain ID");
        require(_eventTopic != 0, "Invalid event topic");

        uint256 _eventId = ++lastAux3EventId;

        Aux3EventConfig memory config =
            Aux3EventConfig(_contractAddress, _eventSignature, _eventAction, aux3Ids[msg.sender], _chainId, _eventTopic);

        aux3EventIds[_eventId] = config;

        // Emit an event for registration
        emit Aux3EventRegistered(_contractAddress, _eventId, aux3Ids[msg.sender]);
    }

    // @dev get the aux3 event config for an aux3Event id
    function getAux3EventConfig(uint256 _eventId) public view returns (Aux3EventConfig memory) {
        return aux3EventIds[_eventId];
    }

    // @dev update the aux3 event action for an _eventId
    function updateAux3EventConfig(uint256 _eventId, bytes32 _eventAction) public {
        require(aux3EventIds[_eventId].aux3Id == aux3Ids[msg.sender], "Sender does not own the event's aux3Id");

        Aux3EventConfig memory config = Aux3EventConfig(
            aux3EventIds[_eventId].contractAddress,
            aux3EventIds[_eventId].eventSignature,
            _eventAction,
            aux3EventIds[_eventId].aux3Id,
            aux3EventIds[_eventId].chainId,
            aux3EventIds[_eventId].eventTopic
        );

        aux3EventIds[_eventId] = config;

        emit Aux3EventUpdated(_eventId);
    }
}
