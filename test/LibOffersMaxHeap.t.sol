// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./OrderbookMock.sol";
import {LibOffersMaxHeap} from "../src/LibOffersMaxHeap.sol";

contract LibOffersMaxHeapTest is Test {
    // offers in ascending order
    LibOffersMaxHeap.Offer smallestBidder =
        LibOffersMaxHeap.Offer(
            address(1),
            0.1 ether,
            1,
            100,
            address(0),
            0,
            address(0)
        );

    LibOffersMaxHeap.Offer bidder2 =
        LibOffersMaxHeap.Offer(
            address(2),
            0.5 ether,
            1,
            200,
            address(0),
            0,
            address(0)
        );

    LibOffersMaxHeap.Offer bidder3 =
        LibOffersMaxHeap.Offer(
            address(3),
            1 ether,
            1,
            300,
            address(0),
            0,
            address(0)
        );

    LibOffersMaxHeap.Offer bidder4 =
        LibOffersMaxHeap.Offer(
            address(4),
            2 ether,
            1,
            100,
            address(0),
            0,
            address(0)
        );

    LibOffersMaxHeap.Offer bidder5 =
        LibOffersMaxHeap.Offer(
            address(5),
            3 ether,
            1,
            100,
            address(0),
            0,
            address(0)
        );

    LibOffersMaxHeap.Offer bidder6 =
        LibOffersMaxHeap.Offer(
            address(6),
            4 ether,
            1,
            100,
            address(0),
            0,
            address(0)
        );

    LibOffersMaxHeap.Offer largestBidder =
        LibOffersMaxHeap.Offer(
            address(7),
            5 ether,
            1,
            100,
            address(0),
            0,
            address(0)
        );

    OrderbookMock public orderbook;

    function setUp() public {
        orderbook = new OrderbookMock();
    }

    // tests if insertion and heapifyUp() maintains heap property
    function testHeapifyUp() public {
        _setupHeap();
        _assertHeapIsValid();

        LibOffersMaxHeap.Offer memory offer = orderbook.getMax();

        assertEq(offer.offerer, largestBidder.offerer, "max offerer incorrect");
        assertEq(
            offer.offerAmount,
            largestBidder.offerAmount,
            "max offer incorrect"
        );
        assertEq(
            offer.quantity,
            largestBidder.quantity,
            "max quantity incorrect"
        );
        assertEq(
            offer.deadline,
            largestBidder.deadline,
            "max deadline incorrect"
        );

        // new highest bidder
        orderbook.insertOffer(
            LibOffersMaxHeap.Offer(
                address(8),
                10 ether,
                1,
                200,
                address(0),
                0,
                address(0)
            )
        );

        offer = orderbook.getMax();

        assertEq(offer.offerer, address(8), "new max offer incorrect");
        assertEq(offer.offerAmount, 10 ether, "new max offerAmount incorrect");
        assertEq(offer.quantity, 1, "new max quantity incorrect");
        assertEq(offer.deadline, 200, "new max deadline incorrect");
    }

    // revert on trying to add a duplicate offer
    function testRevertDuplicateOfferInsert() public {
        _setupHeap();

        // should revert as largestBidder is already inserted
        vm.expectRevert(LibOffersMaxHeap.OffererHasExistingOffer.selector);
        orderbook.insertOffer(largestBidder);

        _assertHeapIsValid();
    }

    // fuzz
    function testInsertOffer(LibOffersMaxHeap.Offer memory offer) public {
        // ensures we dont fail on fuzz tests when offerer is someone that already has an offer
        if (offer.offerer == largestBidder.offerer) return;
        if (offer.offerer == bidder6.offerer) return;
        if (offer.offerer == bidder5.offerer) return;
        if (offer.offerer == bidder4.offerer) return;
        if (offer.offerer == bidder3.offerer) return;
        if (offer.offerer == bidder2.offerer) return;
        if (offer.offerer == smallestBidder.offerer) return;

        _setupHeap();
        _assertHeapIsValid();
        orderbook.insertOffer(offer);
        _assertHeapIsValid();
    }

    // tests if deletion and heapifyDown() maintains heap property
    function testHeapifyDown() public {
        _setupHeap();

        // delete largest bidder
        LibOffersMaxHeap.Offer memory offer = orderbook.getMax();
        orderbook.deleteOffer(offer.offerer);
        _assertHeapIsValid();

        // should be bidder6
        offer = orderbook.getMax();

        assertEq(offer.offerer, bidder6.offerer, "max offer incorrect");
        assertEq(
            offer.offerAmount,
            bidder6.offerAmount,
            "max offerAmount incorrect"
        );
        assertEq(offer.quantity, bidder6.quantity, "max quantity incorrect");
        assertEq(offer.deadline, bidder6.deadline, "max deadline incorrect");

        orderbook.deleteOffer(offer.offerer);
        _assertHeapIsValid();

        // should be bidder5
        offer = orderbook.getMax();

        assertEq(offer.offerer, bidder5.offerer, "new max offer incorrect");
        assertEq(
            offer.offerAmount,
            bidder5.offerAmount,
            "new max offerAmount incorrect"
        );
        assertEq(
            offer.quantity,
            bidder5.quantity,
            "new max quantity incorrect"
        );
        assertEq(
            offer.deadline,
            bidder5.deadline,
            "new max deadline incorrect"
        );

        // delete bidder5
        orderbook.deleteOffer(offer.offerer);
        _assertHeapIsValid();

        // max now is bidder4
        offer = orderbook.getMax();

        // delete bidder4
        orderbook.deleteOffer(offer.offerer);
        _assertHeapIsValid();

        // max now is bidder3
        offer = orderbook.getMax();

        // delete bidder3
        orderbook.deleteOffer(offer.offerer);
        _assertHeapIsValid();

        // max now is bidder2
        offer = orderbook.getMax();

        // delete bidder2
        orderbook.deleteOffer(offer.offerer);
        _assertHeapIsValid();

        // max now is smallestBidder
        offer = orderbook.getMax();

        assertEq(
            offer.offerer,
            smallestBidder.offerer,
            "new max offer incorrect"
        );
        assertEq(
            offer.offerAmount,
            smallestBidder.offerAmount,
            "new max offerAmount incorrect"
        );
        assertEq(
            offer.quantity,
            smallestBidder.quantity,
            "new max quantity incorrect"
        );
        assertEq(
            offer.deadline,
            smallestBidder.deadline,
            "new max deadline incorrect"
        );

        // delete smallestBidder
        orderbook.deleteOffer(offer.offerer);
        _assertHeapIsValid();

        // revert when deleting deleted offerer
        vm.expectRevert(LibOffersMaxHeap.NoOfferFromOfferer.selector);
        orderbook.deleteOffer(offer.offerer);

        // revert when fetching no bids
        vm.expectRevert(LibOffersMaxHeap.NoOffers.selector);
        offer = orderbook.getMax();
    }

    // revert when trying to delete already deleted offer
    function testRevertOnDeleteOfferDuplicate() public {
        _setupHeap();

        // delete largest bidder
        LibOffersMaxHeap.Offer memory offer = orderbook.getMax();
        orderbook.deleteOffer(offer.offerer);
        _assertHeapIsValid();

        // revert when deleting deleted offer
        vm.expectRevert(LibOffersMaxHeap.NoOfferFromOfferer.selector);
        orderbook.deleteOffer(offer.offerer);
    }

    // test that heap behaves as expected when we delete all offers
    function testRemoveAllBids() public {
        _setupHeap();

        // delete largest bidder
        LibOffersMaxHeap.Offer memory offer = orderbook.getMax();
        orderbook.deleteOffer(offer.offerer);
        _assertHeapIsValid();

        // should be bidder6
        offer = orderbook.getMax();

        // delet bidder6
        orderbook.deleteOffer(offer.offerer);
        _assertHeapIsValid();

        // should be bidder5
        offer = orderbook.getMax();

        // delete bidder5
        orderbook.deleteOffer(offer.offerer);
        _assertHeapIsValid();

        // max now is bidder4
        offer = orderbook.getMax();

        // delete bidder4
        orderbook.deleteOffer(offer.offerer);
        _assertHeapIsValid();

        // max now is bidder3
        offer = orderbook.getMax();

        // delete bidder3
        orderbook.deleteOffer(offer.offerer);
        _assertHeapIsValid();

        // max now is bidder2
        offer = orderbook.getMax();

        // delete bidder2
        orderbook.deleteOffer(offer.offerer);
        _assertHeapIsValid();

        // max now is smallestBidder
        offer = orderbook.getMax();

        // assert we got to the smallest bidder
        assertEq(
            offer.offerer,
            smallestBidder.offerer,
            "new max offer incorrect"
        );
        assertEq(
            offer.offerAmount,
            smallestBidder.offerAmount,
            "new max offerAmount incorrect"
        );
        assertEq(
            offer.quantity,
            smallestBidder.quantity,
            "new max quantity incorrect"
        );
        assertEq(
            offer.deadline,
            smallestBidder.deadline,
            "new max deadline incorrect"
        );

        // delete smallestBidder
        orderbook.deleteOffer(offer.offerer);
        _assertHeapIsValid();

        // revert when fetching max cause no offers
        vm.expectRevert(LibOffersMaxHeap.NoOffers.selector);
        offer = orderbook.getMax();
    }

    // our heap has a dynamic size
    // when we delete an element from the heap, we re-heapify and shrink the size of the heap
    // but not the actual array.
    // e.g. heap size == 5, heap max size == 5
    // when we delete an offer, heap size == 4, heap max size ==5
    // max size still stays the same because we can add 1 more element before needing to expand the array
    // to more memory
    function testHeapProperlyResizes() public {
        _setupHeap();

        // we added 7 offers
        assertEq(orderbook.size(), 7, "heap size incorrect");
        assertEq(orderbook.maxSize(), 7, "heap max size incorrect");

        LibOffersMaxHeap.Offer memory offer = orderbook.getMax();
        orderbook.deleteOffer(offer.offerer);
        _assertHeapIsValid();

        // we deleted 1 offer so size should be 6
        assertEq(orderbook.size(), 6, "heap size should be 6");

        // max size still 7 since we can fill 1 more offer before needing to expand array memory
        assertEq(orderbook.maxSize(), 7, "heap max size should be 7");

        // delete 1 more offer
        offer = orderbook.getMax();
        orderbook.deleteOffer(offer.offerer);
        _assertHeapIsValid();

        assertEq(orderbook.size(), 5, "heap size should be 5");
        assertEq(orderbook.maxSize(), 7, "heap max size should be 7");

        // add 2 more offers
        orderbook.insertOffer(
            LibOffersMaxHeap.Offer(
                address(0x0a),
                0.1 ether,
                1,
                100,
                address(0),
                0,
                address(0)
            )
        );
        orderbook.insertOffer(
            LibOffersMaxHeap.Offer(
                address(0x0b),
                0.1 ether,
                1,
                100,
                address(0),
                0,
                address(0)
            )
        );

        _assertHeapIsValid();

        // shouldve added 2 offers without increasing max size of array
        assertEq(orderbook.size(), 7, "heap size should be 7");
        assertEq(orderbook.maxSize(), 7, "heap max size should be 7");

        orderbook.insertOffer(
            LibOffersMaxHeap.Offer(
                address(0x0c),
                0.1 ether,
                1,
                100,
                address(0),
                0,
                address(0)
            )
        );

        _assertHeapIsValid();

        // shouldve exanded array by 1
        assertEq(orderbook.size(), 8, "heap size should be 8");
        assertEq(orderbook.maxSize(), 8, "heap max size should be 8");
    }

    // test that the max gets popped and returned
    function testPopMax() public {
        _setupHeap();
        LibOffersMaxHeap.Offer memory offer = orderbook.popMax();

        _assertHeapIsValid();

        assertEq(offer.offerer, largestBidder.offerer, "offerer incorrect");
        assertEq(
            offer.offerAmount,
            largestBidder.offerAmount,
            "offer amount incorrect"
        );
        assertEq(offer.quantity, largestBidder.quantity, "quantity incorrect");
        assertEq(offer.deadline, largestBidder.deadline, "deadline incorrect");

        // next largest should be bidder6
        offer = orderbook.getMax();

        assertEq(offer.offerer, bidder6.offerer, "offerer incorrect");
        assertEq(
            offer.offerAmount,
            bidder6.offerAmount,
            "offer amount incorrect"
        );
        assertEq(offer.quantity, bidder6.quantity, "quantity incorrect");
        assertEq(offer.deadline, bidder6.deadline, "deadline incorrect");
    }

    // we are testing that we can always fetch the offer via offerer
    // ensure adding/removing offers updates everything properly
    function testGetOffer() public {
        _setupHeap();

        LibOffersMaxHeap.Offer memory offer = orderbook.getOffer(
            bidder4.offerer
        );

        assertEq(offer.offerer, bidder4.offerer, "offerer incorrect");
        assertEq(
            offer.offerAmount,
            bidder4.offerAmount,
            "offer amount incorrect"
        );
        assertEq(offer.quantity, bidder4.quantity, "quantity incorrect");
        assertEq(offer.deadline, bidder4.deadline, "deadline incorrect");

        // bidder 2
        offer = orderbook.getOffer(bidder2.offerer);
        assertEq(offer.offerer, bidder2.offerer, "bidder2 offerer incorrect");
        assertEq(
            offer.offerAmount,
            bidder2.offerAmount,
            "bidder2 offer amount incorrect"
        );
        assertEq(
            offer.quantity,
            bidder2.quantity,
            "bidder2 quantity incorrect"
        );
        assertEq(
            offer.deadline,
            bidder2.deadline,
            "bidder2 deadline incorrect"
        );

        // largestBidder
        offer = orderbook.getOffer(largestBidder.offerer);
        assertEq(
            offer.offerer,
            largestBidder.offerer,
            "largestBidder offerer incorrect"
        );
        assertEq(
            offer.offerAmount,
            largestBidder.offerAmount,
            "largestBidder offer amount incorrect"
        );
        assertEq(
            offer.quantity,
            largestBidder.quantity,
            "largestBidder quantity incorrect"
        );
        assertEq(
            offer.deadline,
            largestBidder.deadline,
            "largestBidder deadline incorrect"
        );

        // smallestBidder
        offer = orderbook.getOffer(smallestBidder.offerer);
        assertEq(
            offer.offerer,
            smallestBidder.offerer,
            "smallestBidder offerer incorrect"
        );
        assertEq(
            offer.offerAmount,
            smallestBidder.offerAmount,
            "smallestBidder offer amount incorrect"
        );
        assertEq(
            offer.quantity,
            smallestBidder.quantity,
            "smallestBidder quantity incorrect"
        );
        assertEq(
            offer.deadline,
            smallestBidder.deadline,
            "smallestBidder deadline incorrect"
        );

        // add new bidder and assert we can fetch properly
        LibOffersMaxHeap.Offer memory newBidder1 = LibOffersMaxHeap.Offer(
            address(0x0a),
            4 ether,
            1,
            100,
            address(0),
            0,
            address(0)
        );
        orderbook.insertOffer(newBidder1);
        _assertHeapIsValid();

        offer = orderbook.getOffer(newBidder1.offerer);
        assertEq(
            offer.offerer,
            newBidder1.offerer,
            "newBidder1 offerer incorrect"
        );
        assertEq(
            offer.offerAmount,
            newBidder1.offerAmount,
            "newBidder1 offer amount incorrect"
        );
        assertEq(
            offer.quantity,
            newBidder1.quantity,
            "newBidder1 quantity incorrect"
        );
        assertEq(
            offer.deadline,
            newBidder1.deadline,
            "newBidder1 deadline incorrect"
        );

        // add new bidder and assert we can fetch properly
        LibOffersMaxHeap.Offer memory newBidder2 = LibOffersMaxHeap.Offer(
            address(0x0b),
            14 ether,
            1,
            100,
            address(0),
            0,
            address(0)
        );
        orderbook.insertOffer(newBidder2);
        _assertHeapIsValid();

        offer = orderbook.getOffer(newBidder2.offerer);
        assertEq(
            offer.offerer,
            newBidder2.offerer,
            "newBidder2 offerer incorrect"
        );
        assertEq(
            offer.offerAmount,
            newBidder2.offerAmount,
            "newBidder2 offer amount incorrect"
        );
        assertEq(
            offer.quantity,
            newBidder2.quantity,
            "newBidder2 quantity incorrect"
        );
        assertEq(
            offer.deadline,
            newBidder2.deadline,
            "newBidder2 deadline incorrect"
        );

        // delete an offer and see if the indexes still are correct and we can fetch offers
        orderbook.deleteOffer(newBidder1.offerer);
        _assertHeapIsValid();

        // assert values for newBidder2
        offer = orderbook.getOffer(newBidder2.offerer);
        assertEq(
            offer.offerer,
            newBidder2.offerer,
            "newBidder2 offerer incorrect"
        );
        assertEq(
            offer.offerAmount,
            newBidder2.offerAmount,
            "newBidder2 offer amount incorrect"
        );
        assertEq(
            offer.quantity,
            newBidder2.quantity,
            "newBidder2 quantity incorrect"
        );
        assertEq(
            offer.deadline,
            newBidder2.deadline,
            "newBidder2 deadline incorrect"
        );

        // assert values for bidder5
        offer = orderbook.getOffer(bidder5.offerer);
        assertEq(offer.offerer, bidder5.offerer, "bidder5 offerer incorrect");
        assertEq(
            offer.offerAmount,
            bidder5.offerAmount,
            "bidder5 offer amount incorrect"
        );
        assertEq(
            offer.quantity,
            bidder5.quantity,
            "bidder5 quantity incorrect"
        );
        assertEq(
            offer.deadline,
            bidder5.deadline,
            "bidder5 deadline incorrect"
        );
    }

    // revert for offers that don't exist
    function testRevertGetOffer() public {
        _setupHeap();

        vm.expectRevert(LibOffersMaxHeap.NoOfferFromOfferer.selector);
        orderbook.getOffer(address(100));
    }

    // return if an bidder has an open offer
    function testHasOffer() public {
        _setupHeap();

        assertEq(
            orderbook.hasOffer(largestBidder.offerer),
            true,
            "incorrect return"
        );
        assertEq(orderbook.hasOffer(bidder2.offerer), true, "incorrect return");
        assertEq(orderbook.hasOffer(address(0x00)), false, "incorrect return");

        // add new bidder
        LibOffersMaxHeap.Offer memory newBidder1 = LibOffersMaxHeap.Offer(
            address(0x0a),
            4 ether,
            1,
            100,
            address(0),
            0,
            address(0)
        );
        orderbook.insertOffer(newBidder1);
        assertEq(
            orderbook.hasOffer(newBidder1.offerer),
            true,
            "incorrect return"
        );

        // delete offer and see if this returns offers properly
        orderbook.deleteOffer(largestBidder.offerer);
        assertEq(
            orderbook.hasOffer(largestBidder.offerer),
            false,
            "incorrect return"
        );
        assertEq(orderbook.hasOffer(bidder2.offerer), true, "incorrect return");
        assertEq(orderbook.hasOffer(address(0x00)), false, "incorrect return");
    }

    // this test ensures that we can modify offers and that the heap property maintains
    // ie each modifyOffer properly calls heapifyUp or heapifyDown
    function testModifyOffer() public {
        _setupHeap();

        // should still be top offer
        orderbook.modifyOffer(largestBidder.offerer, 15 ether, 2, 400);
        _assertHeapIsValid();

        LibOffersMaxHeap.Offer memory offer = orderbook.getOffer(
            largestBidder.offerer
        );
        assertEq(
            offer.offerer,
            largestBidder.offerer,
            "largestBidder offerer incorrect"
        );
        assertEq(
            offer.offerAmount,
            15 ether,
            "largestBidder offer amount incorrect"
        );
        assertEq(offer.quantity, 2, "largestBidder quantity incorrect");
        assertEq(offer.deadline, 400, "largestBidder deadline incorrect");

        // no longer top offer, should call heapifyDown()
        orderbook.modifyOffer(largestBidder.offerer, 2 ether, 2, 400);
        _assertHeapIsValid();

        // should be bidder6
        offer = orderbook.getMax();

        assertEq(offer.offerer, bidder6.offerer, "bidder6 offerer incorrect");
        assertEq(
            offer.offerAmount,
            bidder6.offerAmount,
            "bidder6 offer amount incorrect"
        );
        assertEq(
            offer.quantity,
            bidder6.quantity,
            "bidder6 quantity incorrect"
        );
        assertEq(
            offer.deadline,
            bidder6.deadline,
            "bidder6 deadline incorrect"
        );

        // send smallest bidder to top bid, should call heapifyUp()
        orderbook.modifyOffer(smallestBidder.offerer, 20 ether, 2, 400);

        // should be smallestBidder
        offer = orderbook.getMax();

        assertEq(
            offer.offerer,
            smallestBidder.offerer,
            "smallestBidder offerer incorrect"
        );
        assertEq(
            offer.offerAmount,
            20 ether,
            "smallestBidder offer amount incorrect"
        );
        assertEq(offer.quantity, 2, "smallestBidder quantity incorrect");
        assertEq(offer.deadline, 400, "smallestBidder deadline incorrect");
    }

    // assert parent nodes are >= to child nodes
    function _assertHeapIsValid() internal {
        // check that maxsize is offers length
        assertEq(orderbook.maxSize(), orderbook.offers().length);

        for (uint256 i = 0; i < orderbook.size(); i++) {
            // root
            if (i == 0) {
                continue;
            }

            // ensure parent nodes have higher offers that children
            assertEq(
                orderbook.offers()[orderbook.parentNode(i)].offerAmount >=
                    orderbook.offers()[i].offerAmount,
                true
            );
        }
    }

    // adds 7 offers to the heap
    function _setupHeap() internal {
        orderbook.insertOffer(smallestBidder);
        orderbook.insertOffer(bidder2);
        orderbook.insertOffer(bidder3);
        orderbook.insertOffer(bidder4);
        orderbook.insertOffer(bidder5);
        orderbook.insertOffer(bidder6);
        orderbook.insertOffer(largestBidder);
    }
}
