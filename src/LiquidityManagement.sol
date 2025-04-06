pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract LiquidityManagement is ERC721Upgradeable, OwnableUpgradeable {
    uint256 public initPoolNFTAmount; 
    uint256 public nextId;           

    event LiquidityInit(uint256 nftAmount);
    event LiquidityDeposit(uint256 nftAmount);
    event LiquidityWithdraw(uint256 nftAmount);

    function initLiquidity(uint256 nftAmount) public onlyOwner {
        require(initPoolNFTAmount == 0, "already initialized");

        for (uint256 i = 0; i < nftAmount; i++) {
            _safeMint(address(this), nextId);
            nextId++;
        }
        initPoolNFTAmount = nftAmount;

        emit LiquidityInit(nftAmount);
    }

    function depositLiquidity(uint256[] calldata tokenIds) public onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }
        initPoolNFTAmount += tokenIds.length;

        emit LiquidityDeposit(tokenIds.length);
    }

    function withdrawLiquidity(uint256[] calldata tokenIds) public onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeTransferFrom(address(this), msg.sender, tokenIds[i]);
        }
        initPoolNFTAmount -= tokenIds.length;

        emit LiquidityWithdraw(tokenIds.length);
    }
}