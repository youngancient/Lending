// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {Errors, Events} from "../libraries/Utils.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IERC721} from "../interfaces/IERC721.sol";

contract LoanFacet {
    // how to calculate the correct pricing using Oracles
    function getLoan(
        uint256 _nftId,
        address _nftAddress,
        uint256 _loanAmount,
        uint256 _time
    ) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        if (_loanAmount <= 0) {
            revert Errors.LoanCannotBeZero();
        }
        if (_time <= 0) {
            revert Errors.LoanDurationCannotBeZero();
        }

        IERC721 nft = IERC721(_nftAddress);
        if (nft.ownerOf(_nftId) != msg.sender) {
            revert Errors.LoanNFTNotOwned();
        }

        nft.transferFrom(msg.sender, address(this), _nftId);

        uint256 duration = block.timestamp + _time;

        ds.loans[_nftId] = LibDiamond.Loan({
            nftAddress: _nftAddress,
            loanAmount: _loanAmount,
            loanDuration: duration,
            loanStartTime: block.timestamp,
            loanStatus: LibDiamond.LoanStatus.Active,
            borrower: msg.sender,
            tokenId: _nftId
        });

        ++ds.loanCounter;
        ds.borrowerLoans[msg.sender].push(_nftId);

        IERC20 token = IERC20(ds.tokenAddress);
        if (token.balanceOf(address(this)) < _loanAmount) {
            revert Errors.InsufficientBalance();
        }

        token.transferFrom(msg.sender, address(this), _loanAmount);
        emit Events.LoanSentSuccessfully(
            msg.sender,
            _nftId,
            _nftAddress,
            _loanAmount,
            duration
        );
    }

    function repayLoan(uint256 _loanId) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        LibDiamond.Loan memory loan = ds.loans[_loanId];

        if (loan.borrower != address(0)) {
            revert Errors.LoanDoesNotExist();
        }

        if (loan.borrower != msg.sender) {
            revert Errors.InvalidSender();
        }

        if (loan.loanStatus == LibDiamond.LoanStatus.Active) {
            revert Errors.LoanIsNotActive();
        }

        if (loan.loanStatus == LibDiamond.LoanStatus.Repaid) {
            revert Errors.LoanAlreadyRepaid();
        }


        if (loan.loanDuration > block.timestamp) {
            revert Errors.LoanDurationNotExpired();
        }

        IERC20 token = IERC20(ds.tokenAddress);

        uint256 interest = loan.loanAmount; // 10% interest (adjust this later)
        token.transferFrom(loan.borrower, address(this), loan.loanAmount + interest);

        loan.loanStatus = LibDiamond.LoanStatus.Repaid;

        IERC721 nft = IERC721(loan.nftAddress);

        nft.transferFrom(address(this), loan.borrower, loan.tokenId);

        emit Events.LoanRepaidSuccessfully(
            loan.borrower,
            loan.tokenId,
            loan.nftAddress,
            loan.loanAmount,
            interest
        );
    }

    function getAllBorrowerLoans(
        address _user
    ) external view returns (LibDiamond.Loan[] memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256[] memory loanIds = ds.borrowerLoans[_user];
        LibDiamond.Loan[] memory loans = new LibDiamond.Loan[](loanIds.length);
        for (uint256 i = 0; i < loanIds.length; i++) {
            loans[i] = ds.loans[loanIds[i]];
        }
        return loans;
    }

    function getLoan(
        uint256 _nftId
    ) external view returns (LibDiamond.Loan memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.loans[_nftId];
    }
}
