// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LibOffersMaxHeap} from "../src/LibOffersMaxHeap.sol";

// Simple mock orderbook that just has 1 max heap of offers
contract OrderbookMock {
    using LibOffersMaxHeap for LibOffersMaxHeap.Heap;
    LibOffersMaxHeap.Heap public collectionOffers;

    constructor() {}

    function insertOffer(LibOffersMaxHeap.Offer memory offer) external {
        collectionOffers.insertOffer(offer);
    }

    function deleteOffer(address offerer) external {
        collectionOffers.deleteOffer(offerer);
    }

    function getOffer(
        address offerer
    ) external view returns (LibOffersMaxHeap.Offer memory) {
        return collectionOffers.getOffer(offerer);
    }

    function hasOffer(address offerer) external view returns (bool) {
        return collectionOffers.hasOffer(offerer);
    }

    function modifyOffer(
        address offerer,
        uint256 offerAmount,
        uint256 quantity,
        uint256 deadline
    ) external {
        collectionOffers.modifyOffer(
            offerer,
            offerAmount,
            quantity,
            deadline,
            address(0),
            0,
            address(0)
        );
    }

    function popMax() external returns (LibOffersMaxHeap.Offer memory offer) {
        return collectionOffers.popMax();
    }

    function getMax() external view returns (LibOffersMaxHeap.Offer memory) {
        return collectionOffers.getMax();
    }

    function size() external view returns (uint256) {
        return collectionOffers.size;
    }

    function maxSize() external view returns (uint256) {
        return collectionOffers.maxSize;
    }

    // this is not practical as there will be too many offers to return in reality,
    // but this is helpful for testing
    function offers() external view returns (LibOffersMaxHeap.Offer[] memory) {
        return collectionOffers.offers;
    }

    function parentNode(uint256 pos) external view returns (uint256) {
        return collectionOffers.parentNode(pos);
    }

    function leftChildNode(uint256 pos) external view returns (uint256) {
        return collectionOffers.leftChildNode(pos);
    }

    function rightChildNode(uint256 pos) external view returns (uint256) {
        return collectionOffers.rightChildNode(pos);
    }
}
