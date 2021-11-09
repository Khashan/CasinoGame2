pragma solidity ^0.8.9;

import "./libs/BPSMath.sol";
import "./Game.sol";

contract CoinFlip is Game {
    using SafeMath for uint256;

    struct Round {
        address player;
        uint256 bet;
        uint256 choice;
        uint256 payout;
        uint256 result;
        uint256 odds;
        uint256 houseEdge;
        bool isCompleted;
    }

    mapping(uint256 => Round) rounds;

    event RoundStarted(
        uint256 indexed roundId,
        address indexed user,
        uint256 betAmount,
        uint256 choice
    );

    event RoundEnded(
        uint256 indexed roundId,
        address indexed user,
        uint256 result,
        uint256 payout
    );

    constructor(
        uint256 _minBet,
        uint256 _maxBet,
        uint256 _gameOdds,
        uint256 _houseEdge,
        address poolAddress
    ) Game(_minBet, _maxBet, _gameOdds, _houseEdge, poolAddress) {}

    function takeBet(uint256 _choice) public payable {
        require(_choice <= 1, "Invalid choice");
        require(
            msg.value >= minBet && msg.value <= maxBet,
            "Doesn't respect the bet limitation."
        );

        _playBet(msg.sender, msg.value, _choice);
    }

    function _playBet(
        address _user,
        uint256 _bet,
        uint256 _choice
    ) private {
        Round storage currentRound = rounds[roundId];
        uint256 roundHouseEdge = houseEdge.mul(_bet.div(wealthTaxRatio));

        currentRound.player = _user;
        currentRound.bet = _bet;
        currentRound.choice = _choice;
        currentRound.odds = odds.sub(roundHouseEdge);
        currentRound.houseEdge = roundHouseEdge;

        getRandomNumberAndChangeRound();
        emit RoundStarted(roundId, _user, _bet, _choice);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint256 endRoundId = waitingRequest[requestId];
        Round storage endRound = rounds[endRoundId];
        uint256 result = randomness.mod(2);

        endRound.result = result;
        endRound.isCompleted = true;

        if (endRound.choice == result) {
            uint256 userPayout = BPSMath.calculate(endRound.bet, endRound.odds);
            uint256 housePayout = BPSMath.calculate(
                userPayout,
                endRound.houseEdge
            );

            endRound.payout = userPayout;
            rewardPool.sendRewards(endRound.player, userPayout, housePayout);
        }

        emit RoundEnded(endRoundId, endRound.player, result, endRound.payout);
    }
}
