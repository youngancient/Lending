// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/LoanFacet.sol";
import "../contracts/Diamond.sol";
import "../contracts/interfaces/IERC721.sol";

import "./helpers/DiamondUtils.sol";

contract DiamondDeployer is DiamondUtils, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    LoanFacet loanF;
    IERC721 nft;
    IERC20 token;

    address borrower = 0x3f70b9f355cd2cB39ad96fAE12FB44cd22306314;

    address daiTokenContract = 0x68194a729C2450ad26072b3D33ADaCbcef39D574;

    address trustFund = 0xC214a6884d5d3A20325d9939B88e9C0b12deAeF7;

    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        loanF = new LoanFacet();
        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](3);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        cut[2] = (
            FacetCut({
                facetAddress: address(loanF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("LoanFacet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();

        nft = IERC721(0x19422aD584A93979b729fB93831C8db2De86b151);
        token = IERC20(daiTokenContract);
        // BAYC and CrypotoPunks
        address[] memory allowedNFTs = new address[](2);
        allowedNFTs[0] = 0x19422aD584A93979b729fB93831C8db2De86b151;
        allowedNFTs[1] = 0x7dc1BE8f47eE5805095c9bABa7123ED9AB2aB178;

        // initialize loan facet
        LoanFacet(address(diamond)).initialize(allowedNFTs, daiTokenContract);

        // set some tokens to be lent

        vm.prank(trustFund);
        token.transfer(address(diamond), 20000e18);
    }

    function testLoan() public {
        // deploy
        setUp();
        /*==================== Deployment test ====================*/
        console.log("Testing diamond: ");
        assertEq(
            DiamondLoupeFacet(address(diamond)).facetAddresses().length,
            4
        );
        assertEq(nft.balanceOf(borrower), 50);
        (
            uint256 maxLoanAmount,
            uint256 minLoanAmount,
            uint256 interestRateBps
        ) = LoanFacet(address(diamond)).getLoanDetails();
        assertEq(maxLoanAmount, 5000e18);
        assertEq(minLoanAmount, 100e18);
        assertEq(interestRateBps, 1000);
        assertEq(
            LoanFacet(address(diamond)).getTokenDetails(),
            daiTokenContract
        );
        assertEq(token.balanceOf(address(diamond)), 20000e18);

        /*==================== Test Borrowing ====================*/
        uint256 validNftId = 51;

        vm.startPrank(borrower);
        assertEq(nft.ownerOf(validNftId),borrower);
        nft.approve(address(diamond), validNftId);
        
        LoanFacet(address(diamond)).initiateLoan(validNftId, address(nft), 1000e18, 60 * 60 * 1);
        assertEq(nft.ownerOf(validNftId), address(diamond));

        LibDiamond.Loan memory loan = LoanFacet(address(diamond)).getLoan(validNftId);
        assertEq(loan.borrower, borrower);
        /*==================== Test Repayment ====================*/
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
