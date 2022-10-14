// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "contracts/Reliquary.sol";
import "contracts/emission_curves/Constant.sol";
import "contracts/nft_descriptors/NFTDescriptorSingle4626.sol";
import "contracts/helpers/DepositHelper.sol";

contract Deploy is Script {
    uint[] wethCurve = [
        0,
        1 hours,
        7 hours,
        1 days,
        15 days,
        30 days,
        60 days,
        120 days
    ];
    uint[] wethLevels = [100, 120, 150, 200, 300, 400, 500, 750];

    bytes32 public constant OPERATOR = keccak256("OPERATOR");
    bytes32 public constant EMISSION_CURVE = keccak256("EMISSION_CURVE");

    address public constant MULTISIG =
        0x4fbe899d37fb7514adf2f41B0630E018Ec275a0C;

    Reliquary public reliquary;
    INFTDescriptor public nftDescriptor;
    DepositHelper public helper;

    function run() external {
        //vm.createSelectFork("fantom", 43052549);

        vm.startBroadcast();

        IERC20 oath = IERC20(0x67af5D428d38C5176a286a2371Df691cDD914Fb8);
        IEmissionCurve curve = IEmissionCurve(address(new Constant()));
        reliquary = new Reliquary(oath, curve);

        nftDescriptor = INFTDescriptor(
            address(new NFTDescriptorSingle4626(IReliquary(address(reliquary))))
        );

        IERC20 wethCrypt = IERC20(0x80dD2B80FbcFB06505A301d732322e987380EcD6);

        reliquary.grantRole(OPERATOR, tx.origin);
        reliquary.addPool(
            100,
            wethCrypt,
            IRewarder(address(0)),
            wethCurve,
            wethLevels,
            "fBeets Pool",
            nftDescriptor
        );

        IERC20 otherCrypt = IERC20(0x1ecDb4cf3e8BAD87bA409475216F72f237e8309B);

        reliquary.addPool(
            100,
            otherCrypt,
            IRewarder(address(0)),
            wethCurve,
            wethLevels,
            "other Pool",
            nftDescriptor
        );

        wethCrypt.approve(address(reliquary), 10000000000000 ether);
        otherCrypt.approve(address(reliquary), 100000000000000 ether);
        reliquary.createRelicAndDeposit( MULTISIG, 0, 10 ether);
        reliquary.createRelicAndDeposit( MULTISIG, 1, 10 ether);

        reliquary.grantRole(reliquary.DEFAULT_ADMIN_ROLE(), MULTISIG);
        reliquary.grantRole(OPERATOR, MULTISIG);
        reliquary.grantRole(EMISSION_CURVE, MULTISIG);
        // reliquary.renounceRole(OPERATOR, tx.origin);
        // reliquary.renounceRole(reliquary.DEFAULT_ADMIN_ROLE(), tx.origin);

        helper = new DepositHelper(reliquary);

        vm.stopBroadcast();
    }
}
