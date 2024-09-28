// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import "../core/BaseAccount.sol";
import "../samples/callback/TokenCallbackHandler.sol";
import { WebAuthn256r1 } from "./WebAuthn256r1.sol";

contract FIDOAccount2 is BaseAccount, TokenCallbackHandler, UUPSUpgradeable, Initializable {
    using ECDSA for bytes32;

    uint256[2] public public_key_coordinates;

    IEntryPoint private immutable _entryPoint;
    address public immutable _webauthnVerifier;

    event WebauthnAccountInitialized(IEntryPoint indexed entryPoint);

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    receive() external payable {}

    constructor(IEntryPoint anEntryPoint, address _webAuthnVerifier) {
        _entryPoint = anEntryPoint;
        _webauthnVerifier = _webAuthnVerifier;
        _disableInitializers();
    }

    function _onlyOwner() internal view {
        require(msg.sender == address(this), "only owner");
    }

    function execute(address dest, uint256 value, bytes calldata func) external {
        _requireFromEntryPointOrOwner();
        _call(dest, value, func);
    }

    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata func) external {
        _requireFromEntryPointOrOwner();
        require(dest.length == func.length && (value.length == 0 || value.length == func.length), "wrong array lengths");
        if (value.length == 0) {
            for (uint256 i = 0; i < dest.length; i++) {
                _call(dest[i], 0, func[i]);
            }
        } else {
            for (uint256 i = 0; i < dest.length; i++) {
                _call(dest[i], value[i], func[i]);
            }
        }
    }

    function initialize(bytes memory anPubkCoordinates) public virtual {
        _initialize(anPubkCoordinates);
    }

    function _initialize(bytes memory anPubkCoordinate) internal virtual {
        public_key_coordinates = abi.decode(anPubkCoordinate, (uint256[2]));
        emit WebauthnAccountInitialized(_entryPoint);
    }

    function _requireFromEntryPointOrOwner() internal view {
        require(msg.sender == address(entryPoint()) || msg.sender == address(this), "account: not Owner or EntryPoint");
    }


    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
    internal override virtual returns (uint256 validationData) {
        bytes memory signature;
        bool check = false;
        // simulation check
        if(userOp.signature.length > 0){
            signature = userOp.signature;
            check = _validateWebAuthnSignature(signature, userOpHash);
        }

        // no simulation
        else {
           signature = hex"050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000180000000000000000000000000000000000000000000000000000000000000024000000000000000000000000000000000000000000000000000000000000000249b0a3397f24677f039e5c96a937f1c94a4e5e19acd814d2ac1eb386e3a926909591ea7ffad59ac0448094c15816bbd3a2129dcb689b4511fbf48aa96ad3ea1c3f8fb00bd6e1c5f399e39c0db7deaa8049040f3fcf07eae4ec4f6ccc76f90386cd2728f856da05c444ca8ba77bc5fb4b1618d56f627c4aa203af8ef2f226cc288000000000000000000000000000000000000000000000000000000000000002549960de5880e8c687434170f6476605b8fe4aeb9a28632c7995cf3ba831d9763050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000867b2274797065223a22776562617574686e2e676574222c226368616c6c656e6765223a227a4c5f6d674c314a32546e6a43415449776b76467a5861596d6c3855356d73644a5365664a4668724a3477222c226f726967696e223a22687474703a2f2f6c6f63616c686f73743a33303030222c2263726f73734f726967696e223a66616c73657d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020ccbfe680bd49d939e30804c8c24bc5cd76989a5f14e66b1d25279f24586b278c";   
           check =  _validateSimulationWebAuthnSignature(signature);
        }

        if(check)
                return 0;
        
        return SIG_VALIDATION_FAILED;    
    }

    function _validateSimulationWebAuthnSignature(
        bytes memory signature
    ) 
        internal 
        returns (bool)
    {
        (
            bytes1 authenticatorDataFlagMask,
            bytes memory authenticatorData,
            bytes memory clientData,
            bytes memory clientChallenge,
            uint256 clientChallengeOffset,
            uint256[2] memory rs,
            uint256[2] memory Q
        )
        = abi.decode(signature, (bytes1, bytes, bytes, bytes, uint256, uint256[2], uint256[2]));
        
        require(
             Q[0] == 112617070168935382511011943491291277865700737689123905367624804756076983498860 &&
             Q[1] == 95188109314816183394815512387712305147816165847177924588157699820171058528904,
            "The provided public key does not match the owner's"
        );

        bytes32 simulateChallenge = 0xce52e62b011ecab9206f4335d71918a7a66b74713fd0e0a84557b6d560c8b51d;
        
        require(
            keccak256(clientChallenge) == simulateChallenge,
            "clientChallenge & simulateChallenge mismatch"
        );

        return WebAuthn256r1(_webauthnVerifier).verify(authenticatorDataFlagMask, authenticatorData, clientData, clientChallenge, clientChallengeOffset, rs, Q);
        
    }

    function _validateWebAuthnSignature(
        bytes memory signature,
        bytes32 userOpHash
    ) 
        internal 
        returns (bool)
    {
        (
            bytes1 authenticatorDataFlagMask,
            bytes memory authenticatorData,
            bytes memory clientData,
            bytes memory clientChallenge,
            uint256 clientChallengeOffset,
            uint256[2] memory rs
        )
        = _parseLoginServiceData(signature);
        
        require(
            bytes32(clientChallenge) == userOpHash,
            "challenge & userOpHash mismatch"
        );

        return WebAuthn256r1(_webauthnVerifier).verify(authenticatorDataFlagMask, authenticatorData, clientData, clientChallenge, clientChallengeOffset, rs, public_key_coordinates);
        
    }



    function _parseLoginServiceData(bytes memory loginServiceData)
        internal
        pure
        returns (
            bytes1 authenticatorDataFlagMask,
            bytes memory authenticatorData,
            bytes memory clientData,
            bytes memory clientChallenge,
            uint256 clientChallengeOffset,
            uint256[2] memory rs
        )
    {
        return abi.decode(loginServiceData, (bytes1, bytes, bytes, bytes, uint256, uint256[2]));
    }


    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value : value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    function addDeposit() public payable {
        entryPoint().depositTo{value : msg.value}(address(this));
    }

    function withdrawDepositTo(address payable withdrawAddress, uint256 amount) public onlyOwner {
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal view override {
        (newImplementation);
        _onlyOwner();
    }

}

