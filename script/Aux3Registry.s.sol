// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/Aux3Registry.sol";

contract Aux3Script is Script {
    Aux3Registry public aux3Registry;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        aux3Registry = new Aux3Registry(msg.sender);

        vm.stopBroadcast();
    }
}
