// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Aux3Registry {
    uint public lastId;
    mapping(address => uint) public aux3Ids;

    // Event declarations
    event Aux3IdRegistered(address indexed addr, uint id);
    event Aux3IdTransferred(address indexed from, address indexed to, uint id);

    // @dev register an address for an aux3 id
    function registerAux3Id(address _addr) public returns (uint) {
        require(aux3Ids[_addr] == 0, "Address is already registered");
        require(_addr != address(0), "Invalid address");

        lastId++;
        aux3Ids[_addr] = lastId;

        // Emit an event for registration
        emit Aux3IdRegistered(_addr, lastId);

        return lastId;
    }

    // @dev get the aux3 id for an address
    function getAux3Id(address _addr) public view returns (uint) {
        return aux3Ids[_addr];
    }

    // @dev transfer the aux3 id to another address
    function transferAux3Id(address _to) public {
        require(lastId > 0, "Registry is empty");
        require(_to != msg.sender, "Cannot transfer to the same address");
        require(_to != address(0), "Invalid recipient address");

        uint id = aux3Ids[msg.sender];
        require(id != 0, "Sender does not have an ID");

        delete aux3Ids[msg.sender];
        aux3Ids[_to] = id;

        // Emit an event for transfer
        emit Aux3IdTransferred(msg.sender, _to, id);
    }
    
}
