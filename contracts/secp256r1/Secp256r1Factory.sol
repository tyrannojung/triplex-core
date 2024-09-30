// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./Secp256r1Account.sol";

/// @title FIDOAccountFactory
/// @author dawoon jung
/// @notice A factory contract for creating WebauthnAccount instances
contract Secp256r1Factory {
    Secp256r1Account public immutable accountImplementation;

    constructor(IEntryPoint _entryPoint, address _webAuthnVerifier) {
        accountImplementation = new Secp256r1Account(_entryPoint, _webAuthnVerifier);
    }


    function createAccount(bytes memory anPubkCoordinates, uint256 salt) public returns (Secp256r1Account ret) {
        address addr = getAddress(anPubkCoordinates, salt);
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return Secp256r1Account(payable(addr));
        }
        ret = Secp256r1Account(payable(new ERC1967Proxy{salt : bytes32(salt)}(
                address(accountImplementation),
                abi.encodeCall(Secp256r1Account.initialize, (anPubkCoordinates))
            )));
    }


    function getAddress(bytes memory anPubkCoordinates, uint256 salt) public view returns (address) {
        return Create2.computeAddress(bytes32(salt), keccak256(abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(
                    address(accountImplementation),
                    abi.encodeCall(Secp256r1Account.initialize, (anPubkCoordinates))
                )
            )));
    }
}



