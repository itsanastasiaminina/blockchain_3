pragma solidity ^0.8.22;

import "./LiquidityManagement.sol";
import "./BCCalculate.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract BCNFTMarketplace is LiquidityManagement, UUPSUpgradeable, IERC721Receiver {
    uint256 public startPrice;  
    uint256 public b;  
    uint256 public a;  
    uint256 public delta;  

    event NFTBought(address indexed buyer, uint256 amount, uint256 totalCost);
    event NFTSold(address indexed seller, uint256 amount, uint256 totalPay);

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _startPrice,
        uint256 _linCoeff,
        uint256 _quadCoeff,
        uint256 _delta
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        
        startPrice = _startPrice;
        b = _linCoeff;
        a = _quadCoeff;
        delta = _delta;
        nextId = 0;
    }

    function getCurrPrice() public view returns (uint256) {
        uint256 PoolNFTAmount = balanceOf(address(this));
        require(PoolNFTAmount <= initPoolNFTAmount, "invalid state");
        uint256 sold = initPoolNFTAmount - PoolNFTAmount;
        return BCCalculate.getBuyPrice(startPrice, b, a, sold);
    }

    function buy(uint256 amount) external payable {
        require(amount > 0, "amount not > 0");
        uint256 PoolNFTAmount = balanceOf(address(this));
        require(PoolNFTAmount >= amount, "not enough NFT in pool");

        uint256 sold = initPoolNFTAmount - PoolNFTAmount;
        uint256 totalCost = 0;
        for (uint256 i = 0; i < amount; i++) {
            totalCost += BCCalculate.getBuyPrice(startPrice, b, a, sold + i);
        }

        if (sold > 0) {
            uint256 currentBuyPrice = BCCalculate.getBuyPrice(startPrice, b, a, sold);
            uint256 currentSellPrice = BCCalculate.getSellPrice(startPrice, b, a, sold);
            require(currentBuyPrice >= currentSellPrice + delta, "arbitrage condition");
        }

        require(msg.value >= totalCost, "ETH sent");

        uint256 transfered = 0;
        uint256 tokenId = 0;
        while (transfered < amount && tokenId < nextId) {
            if (ownerOf(tokenId) == address(this)) {
                _safeTransfer(address(this), msg.sender, tokenId, "");
                transfered++;
            }
            tokenId++;
        }
        require(transfered == amount, "not enough");

        uint256 excess = msg.value - totalCost;
        if (excess > 0) {
            (bool success, ) = payable(msg.sender).call{value: excess}("");
            require(success, "failed");
        }

        emit NFTBought(msg.sender, amount, totalCost);
    }

    function sell(uint256[] calldata tokenIds) external {
        require(tokenIds.length > 0, "no tokenIds");

        uint256 PoolNFTAmount = balanceOf(address(this));
        uint256 sold = initPoolNFTAmount - PoolNFTAmount;
        uint256 totalPay = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "not owner");
            uint256 salePrice = BCCalculate.getSellPrice(startPrice, b, a, sold);
            totalPay += salePrice;
            if (sold > 0) {
                sold--;
            }
        }

        uint256 currentBuyPrice = BCCalculate.getBuyPrice(startPrice, b, a, initPoolNFTAmount - PoolNFTAmount);
        uint256 hypotheticalSellPrice = BCCalculate.getSellPrice(startPrice, b, a, initPoolNFTAmount - PoolNFTAmount);
        require(currentBuyPrice >= hypotheticalSellPrice + delta, "arbitrage condition");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }
        require(address(this).balance >= totalPay, "not enough");
        (bool success, ) = payable(msg.sender).call{value: totalPay}("");
        require(success, "failed");

        emit NFTSold(msg.sender, tokenIds.length, totalPay);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
    
    receive() external payable {}
    fallback() external payable {}
}