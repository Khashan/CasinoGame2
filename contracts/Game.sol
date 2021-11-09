pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IRewardPool.sol";

abstract contract Game is VRFConsumerBase, Ownable {
    using SafeMath for uint256;
    uint256 internal constant wealthTaxRatio = 150 ether;

    uint256 internal roundId;
    uint256 internal minBet;
    uint256 internal maxBet;

    uint256 internal odds;
    uint256 internal houseEdge;

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 internal emergencyFee;
    mapping(bytes32 => uint256) waitingRequest;

    IRewardPool rewardPool;

    constructor(
        uint256 _minBet,
        uint256 _maxBet,
        uint256 _gameOdds,
        uint256 _houseEdge,
        address poolAddress
    )
        VRFConsumerBase(
            0x3d2341ADb2D31f1c5530cDC622016af293177AE0,
            0xb0897686c545045aFc77CF20eC7A532E3120E0F1
        )
    {
        require(maxBet >= minBet, "Invalid betting range");

        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        fee = 0.0001 * 10**18;
        emergencyFee = 0.01 * 10**18;

        odds = _gameOdds.sub(100);
        houseEdge = _houseEdge;
        minBet = _minBet;
        maxBet = _maxBet;

        rewardPool = IRewardPool(poolAddress);
    }

    function getRandomNumberAndChangeRound() internal {
        if (LINK.balanceOf(address(this)) < fee) {
            rewardPool.linkFeeder(emergencyFee);
        }

        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );

        waitingRequest[requestRandomness(keyHash, fee)] = roundId;
        roundId++;
    }

    function withdrawLink() public onlyOwner {
        LINK.transfer(msg.sender, LINK.balanceOf(msg.sender));
    }

    receive() external payable {
        (bool sent, ) = address(rewardPool).call{value: msg.value}("");
        require(sent, "Failed to send reward to house");
    }
}
