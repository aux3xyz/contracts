// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
    uint256 public lastAdjustBlockHeight;

    mapping(uint256 => uint256) public supportedChains; // chainId => iterator
    mapping(uint256 => uint256) public chainCostMultipliers;
    mapping(address => uint256) public aux3Ids;
    mapping(uint256 => Aux3EventConfig) public aux3EventIds;
    mapping(uint256 => bytes) public aux3EventActions;
    mapping(uint256 => uint256) public aux3IdBalance;
    mapping(uint256 => uint256) public aux3IdBalanceMultiplier;

    constructor(address initialOwner) Ownable(initialOwner) {}

    event Aux3IdRegistered(address indexed addr, uint256 id);
    event Aux3IdTransferred(address indexed from, address indexed to, uint256 id);
    event Aux3EventRegistered(address indexed contractAddress, uint256 indexed eventId, uint256 indexed aux3Id);
    event Aux3EventUpdated(uint256 indexed eventId);
    event Aux3IdBalanceUpdated(uint256 indexed id, uint256 balance);

    // @dev registers an Aux3Id for an address
    function registerAux3Id(address _addr) public onlyOwner returns (uint256) {
        require(aux3Ids[_addr] == 0, "Address is already registered");
        require(_addr != address(0), "Invalid address");

        lastId++;
        aux3Ids[_addr] = lastId;

        emit Aux3IdRegistered(_addr, lastId);
        return lastId;
    }

    // @dev returns the Aux3Id of an address
    function getAux3Id(address _addr) public view returns (uint256) {
        return aux3Ids[_addr];
    }

    // @dev transfers an Aux3Id of the sender to another address
    function transferAux3Id(address _to) public {
        require(lastId != 0, "Registry is empty");
        require(_to != msg.sender, "Cannot transfer to the same address");
        require(_to != address(0), "Invalid recipient address");
        require(aux3Ids[_to] == 0, "Recipient already has an ID");

        uint256 id = aux3Ids[msg.sender];
        require(id != 0, "Sender does not have an ID");

        delete aux3Ids[msg.sender];
        aux3Ids[_to] = id;

        emit Aux3IdTransferred(msg.sender, _to, id);
        // adjust balance multiplier for the aux3Id #TODO: implement
    }

    // @dev registers an Aux3Event
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

        // adjust balance multiplier for the aux3Id #TODO: implement
    }

    // @dev returns the Aux3Event config and action
    function getAux3Event(uint256 _eventId) public view returns (Aux3EventConfig memory, bytes memory) {
        return (aux3EventIds[_eventId], aux3EventActions[_eventId]);
    }

    // @dev updates the action for an Aux3Event
    function updateAux3EventAction(uint256 _eventId, bytes memory _eventAction) public {
        require(aux3EventIds[_eventId].aux3Id == aux3Ids[msg.sender], "Sender does not own the event's aux3Id");
        aux3EventActions[_eventId] = _eventAction;
        emit Aux3EventUpdated(_eventId);

        // adjust balance multiplier for the aux3Id #TODO: implement
    }

    // @dev updates the balance of an Aux3Id
    function updateAux3IdBalance(uint256 _id, uint256 _balance) external onlyOwner {
        require(_id != 0 && _id <= lastId, "Invalid Aux3Id");
        aux3IdBalance[_id] = _balance;
        emit Aux3IdBalanceUpdated(_id, _balance);
    }

    // @dev sweeps native token from contract to owner
    function sweepNativeToken() external onlyOwner {
        uint256 _balance = address(this).balance;
        (bool success,) = payable(owner()).call{value: _balance}("");
        require(success, "Transfer failed");
    }

    // @dev sweeps ERC20 token from contract to owner
    function sweepToken(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner(), balance), "Transfer failed");
    }

    // @dev adjusts account balance for number of missed blocks
    function adjustForMissedBlocks(uint256 _deployedChainNetBlocksMissed) external onlyOwner {
        // TODO: implement
        // calculate latest balance for when none is missed
        // increase balance by the number of blocks missed * chainCostMultiplier
    }

    // @dev last adjustment timestamp
    function getLastAdjustBlockHeight() public view returns (uint256) {
        return lastAdjustBlockHeight;
    }

    // @dev gets the balance multiplier for the aux3Id
    function getAux3IdBalanceMultiplier(uint256 _id) public view returns (uint256) {
        return aux3IdBalanceMultiplier[_id];
    }

    // @dev updates the balance multiplier for the aux3Id
    function updateAux3IdBalanceMultiplier(uint256 _id) private {
        // TODO: implement
        // calculate the balance multiplier for the aux3Id in deployedChainTerms
    }

    // @dev gets the cost multiplier for the chain
    function getChainCostMultiplier(uint256 _chainId) public view returns (uint256) {
        return chainCostMultipliers[_chainId];
    }

    // @dev updates the cost multiplier for the chain
    function updateChainCostMultiplier(uint256 _chainId, uint256 _newcostMultiplierForChain) external onlyOwner {
        // maybe reconcile before updating it
        chainCostMultipliers[_chainId] = _newcostMultiplierForChain;
    }

    // @dev get current calculated aux3IdBalance
    function getAux3IdBalance(uint256 _id) public view returns (uint256) {
        return aux3IdBalance[_id] - (aux3IdBalanceMultiplier[_id] * (block.number - lastAdjustBlockHeight));
    }
}
