// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./FIDOAccount2.sol";

/// @title FIDOAccountFactory
/// @author dawoon jung
/// @notice A factory contract for creating WebauthnAccount instances
contract FIDOAccountFactory2 {
    FIDOAccount2 public immutable accountImplementation;

    constructor(IEntryPoint _entryPoint, address _webAuthnVerifier) {
        accountImplementation = new FIDOAccount2(_entryPoint, _webAuthnVerifier);
    }


    function createAccount(bytes memory anPubkCoordinates, uint256 salt) public returns (FIDOAccount2 ret) {
        address addr = getAddress(anPubkCoordinates, salt);
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return FIDOAccount2(payable(addr));
        }
        ret = FIDOAccount2(payable(new ERC1967Proxy{salt : bytes32(salt)}(
                address(accountImplementation),
                abi.encodeCall(FIDOAccount2.initialize, (anPubkCoordinates))
            )));
    }


    function getAddress(bytes memory anPubkCoordinates, uint256 salt) public view returns (address) {
        return Create2.computeAddress(bytes32(salt), keccak256(abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(
                    address(accountImplementation),
                    abi.encodeCall(FIDOAccount2.initialize, (anPubkCoordinates))
                )
            )));
    }
}



