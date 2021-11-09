pragma solidity ^0.8.9;

interface IRewardPool {
    function linkFeeder(uint256 amount) external returns (bool);

    function setGameStatus(address game, bool isActive) external;

    function sendRewards(
        address user,
        uint256 userPayout,
        uint256 houseEdge
    ) external;

    function getBalance() external returns (uint256);
}
