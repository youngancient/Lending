// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Errors {
    error LoanCannotBeZero();
    error LoanDurationCannotBeZero();
    error LoanNFTNotOwned();
    error InsufficientBalance();
    error LoanDoesNotExist();
    error InvalidSender();
    error LoanIsNotActive();
    error LoanDurationNotExpired();
    error LoanAlreadyRepaid();
    error LoanAmountExceedsMax();
    error LoanAmountBelowMin();
    error ContractNotInitialized();
    error InterestRateCannotBeZero();
    error NFTNotSupported();
}

library Events {
    event LoanSentSuccessfully(
        address indexed _borrower,
        uint256 indexed _loanId,
        address indexed _nftAddress,
        uint256 _nftId,
        uint256 _loanAmount,
        uint256 _loanDuration
    );

    event LoanRepaidSuccessfully(
        address indexed _borrower,
        uint256 indexed _nftId,
        address indexed _nftAddress,
        uint256 _loanAmount,
        uint256 _interest
    );
}
