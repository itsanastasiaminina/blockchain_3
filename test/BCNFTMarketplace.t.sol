pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/BCNFTMarketplace.sol";
import "../src/BCNFTMarketplaceProxy.sol";

contract BCNFTMarketplaceTest is Test {
    BCNFTMarketplace logic;
    BCNFTMarketplace marketplace;
    BCNFTMarketplaceProxy proxy;

    address user1 = address(0x1001);
    address user2 = address(0x1002);

    function setUp() public {
        logic = new BCNFTMarketplace();

        bytes memory initData = abi.encodeWithSelector(
            BCNFTMarketplace.initialize.selector,
            "NFT MARKETPLACE",
            "NFTM",
            0.01 ether,   
            0.002 ether, 
            0.0005 ether, 
            0.001 ether   
        );

        proxy = new BCNFTMarketplaceProxy(address(logic), initData);
        marketplace = BCNFTMarketplace(payable(address(proxy)));

        marketplace.initLiquidity(10);

        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

    
    function testInitialPrice() public {
        uint256 price = marketplace.getCurrPrice();
        assertEq(price, 0.01 ether, "Init price should be 0.01");
    }

    function testBuyOneNFT() public {
        uint256 poolBefore = marketplace.balanceOf(address(marketplace));
        vm.prank(user1);
        marketplace.buy{value: 0.01 ether}(1);

        uint256 poolAfter = marketplace.balanceOf(address(marketplace));
        assertEq(poolBefore - poolAfter, 1);
        address ownerOf0 = marketplace.ownerOf(0);
        assertEq(ownerOf0, user1, "User1 should own tokenId 0");
    }

    function testSellOneNFT() public {
        vm.prank(user1);
        marketplace.buy{value: 0.01 ether}(1);
        uint256 balanceBefore = user1.balance;

        uint256 tokenId = 0;
        vm.prank(user1);
        marketplace.approve(address(marketplace), tokenId);

        uint256[] memory tokenIds = new uint256[](1);

        tokenIds[0] = tokenId;

        vm.prank(user1);
        marketplace.sell(tokenIds);

        uint256 balanceAfter = user1.balance;
        assertTrue(balanceAfter > balanceBefore, "User1 should earn ETH from selling NFT");
        address ownerOf0 = marketplace.ownerOf(0);
        assertEq(ownerOf0, address(marketplace), "Return to pool NFT");
    }

    function testBuyMultipleNFT() public {
        uint256 poolBefore = marketplace.balanceOf(address(marketplace));
        vm.prank(user1);
        marketplace.buy{value: 0.05 ether}(3);

        uint256 poolAfter = marketplace.balanceOf(address(marketplace));
        assertEq(poolBefore - poolAfter, 3, "Pool need lose 3 NFT");
    }

    function testSellMultipleNFT() public {
        vm.prank(user1);
        marketplace.buy{value: 0.05 ether}(3);

        uint256 amount = 0;
        uint256[] memory sellIds = new uint256[](3);
        uint256 totalMinted = marketplace.nextId(); 
        for (uint256 id = 0; id < totalMinted; id++) {
            if (marketplace.ownerOf(id) == user1) {
                sellIds[amount] = id;
                amount++;
                if (amount == 3) break;
            }
        }
        for (uint256 i = 0; i < sellIds.length; i++) {
            vm.prank(user1);
            marketplace.approve(address(marketplace), sellIds[i]);
        }

        uint256 balanceBefore = user1.balance;
        vm.prank(user1);
        marketplace.sell(sellIds);
        uint256 balanceAfter = user1.balance;

        assertTrue(balanceAfter > balanceBefore, "User1 should earn ETH from selling NFT");
    }

    function testInsufficientFundsBuy() public {
        vm.prank(user1);
        vm.expectRevert(bytes("ETH sent"));
        marketplace.buy{value: 0.005 ether}(1);
    }


    function testSellNotOwner() public {
        vm.prank(user1);
        marketplace.buy{value: 0.01 ether}(1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;

        vm.prank(user2);
        vm.expectRevert(bytes("not owner"));
        marketplace.sell(tokenIds);
    }

    function testNotEnoughETHInPoolForSell() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;

        vm.prank(user1);
        vm.expectRevert(); 
        marketplace.sell(tokenIds);
    }
}