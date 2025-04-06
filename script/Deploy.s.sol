pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "../src/BCNFTMarketplace.sol";
import "../src/BCNFTMarketplaceProxy.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        uint256 startPrice = 0.1 ether;
        uint256 a = 0.0005 ether;
        uint256 b = 0.0001 ether;
        uint256 delta = 0.025 ether;

        BCNFTMarketplace logic = new BCNFTMarketplace();
        bytes memory initData = abi.encodeWithSelector(
            BCNFTMarketplace.initialize.selector,
            "NFT MARKETPLACE",
            "NFTM",
            startPrice,
            b,
            a,
            delta
        );

        BCNFTMarketplaceProxy proxy = new BCNFTMarketplaceProxy(address(logic), initData);
        BCNFTMarketplace marketplace = BCNFTMarketplace(payable(address(proxy)));
        marketplace.initLiquidity(10);
        vm.stopBroadcast();
    }
}