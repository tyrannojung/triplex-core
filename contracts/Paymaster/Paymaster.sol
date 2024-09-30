// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { BasePaymaster } from "../utils/core/BasePaymaster.sol";
import { _packValidationData } from "../utils/core/Helpers.sol";
import { IEntryPoint } from "../utils/interfaces/IEntryPoint.sol";
import { UserOperation } from "../utils/interfaces/UserOperation.sol";
import { GasLessUserOperation, GasLessUserOperationLib } from "./GasLessUserOperation.sol";

contract Paymaster is BasePaymaster {
    using GasLessUserOperationLib for GasLessUserOperation;
    using ECDSA for bytes32;

    struct PaymasterAndData {
        address paymasterAddress;
        bytes GasLessUserOperationHash;
        uint48 validAfter;
        uint48 validUntil;
        uint256 chainId;
        bytes signature;
    }

    event UserOperationSponsored(address indexed sender, uint256 actualGasCost);

    constructor(IEntryPoint _entryPoint, address _owner) BasePaymaster(_entryPoint) {
        _transferOwnership(_owner);
    }

    function parsePaymasterAndData(bytes calldata paymasterAndData) internal pure returns (PaymasterAndData memory) {
        address paymasterAddress = address(bytes20(paymasterAndData[:20]));
        (
            bytes memory GasLessUserOperationHash,
            uint48 validAfter,
            uint48 validUntil,
            uint256 chainId,
            bytes memory signature
        ) = abi.decode(paymasterAndData[20:], (bytes, uint48, uint48, uint256, bytes));

        return PaymasterAndData(paymasterAddress, GasLessUserOperationHash, validAfter, validUntil, chainId, signature);
    }

    /**
     * Verify our external signer signed this request and decode paymasterData
     * paymasterData contains the following:
     * token address length 20
     * signature length 64 or 65
     */
    function _validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 ,
        uint256 
    )
        internal
        virtual
        override
        returns (bytes memory context, uint256 validationData)
    {
        PaymasterAndData memory paymasterAndData = parsePaymasterAndData(userOp.paymasterAndData);
        require(paymasterAndData.chainId == block.chainid, "incorrect chainId");
        require(
            paymasterAndData.signature.length == 64 || paymasterAndData.signature.length == 65,
            "CP01: invalid signature length in paymasterAndData"
        );

        GasLessUserOperation memory verifiableUserOp = GasLessUserOperation({
            sender: userOp.sender,
            nonce: userOp.nonce,
            initCode: userOp.initCode,
            callData: userOp.callData,
            maxFeePerGas: userOp.maxFeePerGas,
            maxPriorityFeePerGas: userOp.maxPriorityFeePerGas
        });
        bytes32 GasLessUserOperationHash = verifiableUserOp.hash();
        address recoveredAddress = GasLessUserOperationHash.toEthSignedMessageHash().recover(paymasterAndData.signature);
        if (owner() != recoveredAddress) {
            return ("", _packValidationData(true, uint48(block.timestamp), uint48(block.timestamp)));
        }

        bytes memory _context = abi.encode(userOp, paymasterAndData);
        return (_context, _packValidationData(false, paymasterAndData.validUntil, paymasterAndData.validAfter));
    }

    /**
     * Perform the post-operation to charge the sender for the gas.
     */
    function _postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) internal override {
        if (mode != PostOpMode.postOpReverted) {
            (UserOperation memory userOp, /* PaymasterAndData memory _paymasterAndData */) =
                abi.decode(context, (UserOperation, PaymasterAndData));
            emit UserOperationSponsored(userOp.sender, actualGasCost);
        }
    }
}
