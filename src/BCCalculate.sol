pragma solidity ^0.8.22;

library BCCalculate {
   
    function getBuyPrice(
        uint256 startPrice,
        uint256 b,
        uint256 a,
        uint256 sold
    ) internal pure returns (uint256) {
        return startPrice + (b * sold) + (a * (sold * sold));
    }

    function getSellPrice(
        uint256 startPrice,
        uint256 b,
        uint256 a,
        uint256 sold
    ) internal pure returns (uint256) {
        require(sold > 0, "no nft sold");
        uint256 newSold = sold - 1;
        return startPrice + (b * newSold) + (a * (newSold * newSold));
    }
}