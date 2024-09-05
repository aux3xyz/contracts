// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

struct Aux3EventConfig {
    uint32 chainId;
    uint256 aux3Id;
    address contractAddress;
    bytes32 topic_0;
    bytes32 topic_1;
    bytes32 topic_2;
    bytes32 topic_3;
}

contract Aux3Registry is Ownable {
    uint256 public lastId;
    uint256 public lastAux3EventId;
    mapping(address => uint256) public aux3Ids;
    mapping(uint256 => Aux3EventConfig) public aux3EventIds;
    mapping(uint256 => bytes) public aux3EventActions;

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

        Aux3EventConfig memory config =
            Aux3EventConfig(_chainId, _aux3Id, _contractAddress, _topic_0, _topic_1, _topic_2, _topic_3);

        aux3EventIds[lastAux3EventId] = config;
        aux3EventActions[lastAux3EventId] = _eventAction;

        // Emit an event for registration
        emit Aux3EventRegistered(_contractAddress, lastAux3EventId, _aux3Id);
    }

    // @dev get the aux3 event config for an aux3Event id
    function getAux3Event(uint256 _eventId) public view returns (Aux3EventConfig memory, bytes memory) {
        return (aux3EventIds[_eventId], aux3EventActions[_eventId]);
    }

    // @dev update the aux3 event action for an _eventId
    function updateAux3EventAction(uint256 _eventId, bytes memory _eventAction) public {
        require(aux3EventIds[_eventId].aux3Id == aux3Ids[msg.sender], "Sender does not own the event's aux3Id");

        aux3EventActions[_eventId] = _eventAction;

        emit Aux3EventUpdated(_eventId);
    }
}
