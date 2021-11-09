// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library BPSMath {
    using SafeMath for uint256;

    uint256 constant MAX_BPS = 10000;

    function calculate(uint256 value, uint256 bps)
        internal
        pure
        returns (uint256)
    {
        return value.mul(bps).div(MAX_BPS);
    }

    function leftOver(uint256 bps) internal pure returns (uint256) {
        require(bps <= MAX_BPS, "invalid BPS");
        return MAX_BPS.sub(bps);
    }
}
