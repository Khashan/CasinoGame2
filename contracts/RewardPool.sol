pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./interfaces/IRewardPool.sol";
import "./libs/BPSMath.sol";

contract RewardPool is Ownable, IRewardPool {
    IUniswapV2Router02 immutable router02;
    uint256 constant serviceFee = 100;
    uint256 initialInvestisment;

    mapping(address => bool) games;
    event RewardPoolUpdated(uint256 newBalance);

    address[] pathToLink = new address[](2);

    modifier onlyGame() {
        require(games[msg.sender], "Only active games can call this.");
        _;
    }

    constructor() {
        router02 = IUniswapV2Router02(
            0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
        );
        pathToLink[0] = router02.WETH();
        pathToLink[1] = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    }

    function linkFeeder(uint256 amount)
        external
        override
        onlyGame
        returns (bool)
    {
        if (this.getBalance() < amount) {
            return false;
        }

        router02.swapExactETHForTokens(
            amount,
            pathToLink,
            msg.sender,
            block.timestamp + 5 minutes
        );

        return true;
    }

    //This is to payback the dev from his initial investisment to be sure the platform can start.
    //IT DOES NOT TAKE THE ECOSYSTEM MONEY
    function takeInitatialInvestisment() public onlyOwner {
        require(initialInvestisment > 0, "Investisment already claimed.");

        initialInvestisment = 0;
        _sendEth(msg.sender, initialInvestisment);
    }

    function setGameStatus(address game, bool isActive)
        external
        override
        onlyOwner
    {
        games[game] = isActive;
    }

    function sendRewards(
        address user,
        uint256 userPayout,
        uint256 housePayout
    ) external override onlyGame {
        _sendEth(user, userPayout);
        _sendEth(owner(), housePayout);
    }

    function getBalance() external view override returns (uint256) {
        return address(this).balance;
    }

    function _sendEth(address to, uint256 amount) private {
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Failed to send ETH to address");
    }

    receive() external payable {
        if (games[msg.sender]) {
            router02.swapExactETHForTokens(
                BPSMath.calculate(msg.value, serviceFee),
                pathToLink,
                msg.sender,
                block.timestamp + 5 minutes
            );
        }
    }
}
