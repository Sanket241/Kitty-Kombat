// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { VRFConsumerBaseV2Plus, IVRFCoordinatorV2Plus } from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import { VRFV2PlusClient } from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract KittyCombat is ERC721, VRFConsumerBaseV2Plus {
    // errors
    error KittyCombat__IncorrectFeesSent();

    // enums
    enum VirusType {
        Whisker_Woes,        // 70
        Furrball_Fiasco,     // 25
        Clawdemic            // 5    (deadliest)
    }

    // structs
    struct CatInfection {
        bool isInfected;
        uint256 lockupDuration;
        uint256 infectedBy;  // virus token id
        uint256 healedBy;    // token id of angel cat
        uint256 chainIdForHealLockUp;
        uint256 coolDownDeadline;
    }

    struct CatInfo {
        uint256 tokenId;
        uint256 immunity;
        uint256 lives;
        CatInfection catInfectionInfo;
        bool colour;
        bool isAngelCat;
    }

    struct VirusInfo {
        uint256 tokenId;
        VirusType virusType;
        uint256 strength;
        uint256 transmissionRate;
        uint256 growthFactor;
        uint256 coolDownDeadline;
    }

    // variables
    address public immutable i_cattyNip;
    uint256 public constant MAX_COOLDOWN_DEADLINE = 5 days;
    uint256 public constant MAX_IMMUNITY = 100;
    uint256 public constant INIT_LIVES = 9;
    uint256 public tokenIdToMint = 1;
    CatInfo[] public catInfo;
    VirusInfo[] public virusInfo;
    uint256 public constant INIT_FEE = 0.001 ether;
    uint256 public constant FEE_LINEAR_INC = 0.0001 ether;
    uint256 public currentFee; 
    mapping(uint256 reqId => address user) public reqIdToUser;

    // chainlink vrd parameters
    bytes32 public keyHash;
    uint32 public callbackGaslimit;
    uint16 public requestConfirmations;
    uint32 public numWords = 2;
    uint256 public subscriptionId;

    

    // events
    event MintRequested(uint256 requestId, address user);



    constructor(
        address _cattyNip, 
        address _vrfCoordinator, 
        uint32 _callbackGaslimit, 
        uint16 _requestConfirmations,
        uint256 _subscriptionId,
        bytes32 _keyHash
    ) ERC721("KittyCombat", "KC") VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_cattyNip = _cattyNip;
        currentFee = INIT_FEE;
        keyHash = _keyHash;
        callbackGaslimit = _callbackGaslimit;
        requestConfirmations = _requestConfirmations;
        subscriptionId = _subscriptionId;
    }

    function mintKittyOrVirus() external payable {
        uint256 _fee = currentFee;

        if (msg.value != _fee) {
            revert KittyCombat__IncorrectFeesSent();
        }

        currentFee += FEE_LINEAR_INC;

        // Request chainlink vrf for 2 random numbers
        // first will be used to decide a cat(80) or a virus(20)
        
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGaslimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: false
                    })
                )
            })
        );

        reqIdToUser[requestId] = msg.sender;

        emit MintRequested(requestId, msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        address user = reqIdToUser[requestId];

        _mint(user, tokenIdToMint);
        // 1. decide whether to mint a cat or a virus
        uint256 catOrVirus = randomWords[0] % 100;
        uint256 traitsDeciding = randomWords[1];
        if (catOrVirus < 80) {
            // mint a cat
        }
        else {
            // mint a virus


        }

    }
}