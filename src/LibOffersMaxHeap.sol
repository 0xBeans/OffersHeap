// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// This is a max heap that orders `Offers` based on the `offerAmount`.
/// We achieve O(lgN) search and deletion in this heap because we store the
/// indexes of the offers in a mapping - we can retrieve the index of the offer
/// we want to delete in O(1) and delete the offer directly, the we proceed to
/// run the proper heapify instructions.

library LibOffersMaxHeap {
    error OffererHasExistingOffer();
    error NoOfferFromOfferer();
    error NoOffers();
    error NoOffersToPop();

    struct Heap {
        uint256 size; // current size of the heap
        uint256 maxSize; // the biggest size the heap has ever been, used to prevent unnecessary operations and memory expansions
        Offer[] offers; // the heap itself
        mapping(address => uint256) indexes; // maps offerer to the index in heap for O(1) search and O(lgN) remove
    }

    struct Offer {
        address offerer; // address that made the offer
        uint256 offerAmount; // value of offer
        uint256 quantity; // number of offers, this will be 1 for individual tokens and X for collection offers
        uint256 deadline; // when the offer expires, for collection offers there will be no deadline
        address referrer; // referrers can take fees on top
        uint256 feePercentage; // referrer fee
        address hook; // hook address
    }

    // returns index of parent node
    function parentNode(
        Heap storage heap,
        uint256 pos
    ) internal pure returns (uint256) {
        return (pos - 1) >> 1;
    }

    // returns index of left child node
    // we check if the node is valid in the funcs that call this
    function leftChildNode(
        Heap storage heap,
        uint256 pos
    ) internal pure returns (uint256) {
        return (pos << 1) + 1;
    }

    // returns index of right child node
    // we check if the node is valid in the funcs that call this
    function rightChildNode(
        Heap storage heap,
        uint256 pos
    ) internal pure returns (uint256) {
        return (pos << 1) + 2;
    }

    // inserts a new offer into the heap by adding the offer as a leaf node
    // and heapifying upwards.
    // If heap.size == heap.maxSize, we expand the array by pushing the heap into the heap array.
    // If heap.size < heap.maxSize (meaning an offer was deleted), we overwrite the offer that is at
    // index `size` and then increase `size`. The reason for this is such we don't have to keep shrinking
    // and expanding the array everytime we delete and insert.
    function insertOffer(Heap storage heap, Offer memory offer) internal {
        // every offerer can only have 1 offer on the heap
        if (heap.indexes[offer.offerer] != 0) revert OffererHasExistingOffer();

        // if curr size is max size,
        // we need to expand the array memory so increase both vals
        if (heap.size >= heap.maxSize) {
            // push new offer and heapify
            heap.offers.push(offer);
            heapifyUp(heap, heap.size);

            unchecked {
                ++heap.size;
                ++heap.maxSize; // increase maxSize as we pushed a new offer into the array
            }
        } else {
            // if size < maxSize, just override the element at index `size` with the offer we want to insert
            // this scenario happens if we are inserting an offer after a deletion
            heap.offers[heap.size] = offer;
            heapifyUp(heap, heap.size);

            // no need to increase maxSize as we can simply overwrite the value
            // at index `size`
            unchecked {
                ++heap.size;
            }
        }
    }

    // we delete offers by replacing the offer we want to delete with a leaf node
    // and doing `heapifyDown`
    function deleteOffer(Heap storage heap, address offerer) internal {
        if (!hasOffer(heap, offerer)) {
            revert NoOfferFromOfferer();
        }

        // index in heap of offer we want to delete
        uint256 index = indexValue(heap.indexes[offerer], false);

        // leaf offer that we will use to replace the deleted offer
        Offer memory leafOffer = heap.offers[heap.size - 1];

        // replace deleted node with a leaf node
        heap.offers[index] = leafOffer;

        // set leafnode index to current index it was replaced to
        heap.indexes[leafOffer.offerer] = indexValue(index, true);

        // decrease heap size
        heap.size--;

        // remove the index for the deleted offer
        delete heap.indexes[offerer];

        heapifyDown(heap, index);
    }

    // returns root offer
    function getMax(Heap storage heap) internal view returns (Offer memory) {
        if (heap.size == 0) revert NoOffers();

        return heap.offers[0];
    }

    // returns root offer and deletes from heap
    function popMax(Heap storage heap) internal returns (Offer memory offer) {
        if (heap.size == 0) revert NoOffersToPop();

        offer = heap.offers[0];

        deleteOffer(heap, offer.offerer);

        return offer;
    }

    // will fetch offer from offerer in O(1)
    function getOffer(
        Heap storage heap,
        address offerer
    ) internal view returns (Offer memory) {
        if (!hasOffer(heap, offerer)) {
            revert NoOfferFromOfferer();
        }
        uint256 index = indexValue(heap.indexes[offerer], false);

        return heap.offers[index];
    }

    // return if an offerer has an offer on the heap
    function hasOffer(
        Heap storage heap,
        address offerer
    ) internal view returns (bool) {
        return heap.indexes[offerer] > 0;
    }

    // modifies an offer and runs proper heapify functions
    function modifyOffer(
        Heap storage heap,
        address offerer,
        uint256 offerAmount,
        uint256 quantity,
        uint256 deadline,
        address referrer,
        uint256 feePercentage,
        address hook
    ) internal {
        if (!hasOffer(heap, offerer)) {
            revert NoOfferFromOfferer();
        }

        uint256 index = indexValue(heap.indexes[offerer], false);
        Offer storage offer = heap.offers[index];
        uint256 prevOfferAmount = offer.offerAmount;

        offer.offerAmount = offerAmount;
        offer.quantity = quantity;
        offer.deadline = deadline;
        offer.referrer = referrer;
        offer.feePercentage = feePercentage;
        offer.hook = hook;

        if (prevOfferAmount < offerAmount) {
            heapifyUp(heap, index);
        } else {
            heapifyDown(heap, index);
        }
    }

    // send node (at index `pos`) towards the leaf nodes
    // used during deletion as we replace the node that was
    // deleted with a leaf and proceed to heapify downwards
    function heapifyDown(
        Heap storage heap,
        uint256 pos
    ) public returns (uint256) {
        uint256 left;
        uint256 right;
        uint256 largest;

        Offer memory leftOffer;
        Offer memory rightOffer;
        Offer memory posOffer;
        Offer memory largestOffer;

        while (true) {
            left = leftChildNode(heap, pos);
            right = rightChildNode(heap, pos);

            // if pos is already a leaf node, return
            if (left >= heap.size || right >= heap.size) {
                return pos;
            }

            // left child offer
            leftOffer = heap.offers[leftChildNode(heap, pos)];

            // right child offer
            rightOffer = heap.offers[rightChildNode(heap, pos)];

            // curr position offer
            posOffer = heap.offers[pos];

            // check if left node has larger offer than current offer
            if (leftOffer.offerAmount > posOffer.offerAmount) {
                largest = left;
            } else {
                largest = pos;
            }

            largestOffer = heap.offers[largest];

            // check if right node is the largest
            if (rightOffer.offerAmount > largestOffer.offerAmount) {
                largest = right;
                largestOffer = heap.offers[largest];
            }

            // if current position has the highest offer, offer is in the right place
            // and we return early
            if (largest == pos) {
                // update index for final position
                heap.indexes[largestOffer.offerer] = indexValue(pos, true);
                return pos;
            }

            // swap node with child because child is larger
            heap.offers[pos] = largestOffer;
            heap.offers[largest] = posOffer;

            // every 'swap' between parent and child nodes needs to set the parent index
            // because parent index is now the childs'
            heap.indexes[largestOffer.offerer] = indexValue(pos, true);

            // update pos and continue looping
            pos = largest;
        }

        // something really fucked happened
        revert();
    }

    // sends nodes towards the root
    // used during insertions as we insert new offers as leaves and
    // proceed to heapify upwards
    function heapifyUp(
        Heap storage heap,
        uint256 pos
    ) internal returns (uint256) {
        // offer to insert
        Offer memory newOffer = heap.offers[pos];
        Offer memory parentOffer;

        // while we're not the root node && newOffer has a larger offer than the parent node
        while (
            pos > 0 &&
            newOffer.offerAmount >
            heap.offers[parentNode(heap, pos)].offerAmount
        ) {
            parentOffer = heap.offers[parentNode(heap, pos)];

            // swap parent with curr node as it's larger
            heap.offers[pos] = parentOffer;

            // update parents index because it just swapped with child
            heap.indexes[parentOffer.offerer] = indexValue(pos, true);

            // set pos to parentNode and continue looping
            pos = parentNode(heap, pos);
        }

        // pos is now set to the correct index in the heap that we should
        // insert offer into
        heap.offers[pos] = newOffer;
        heap.indexes[newOffer.offerer] = indexValue(pos, true);

        return pos;
    }

    // when we set an offer's index, we add 1 because we use index '0'
    // to mean 'user has no offer currently'. So when we set an offerer's index,
    // `isSet` == true and we add 1 to its actual index in the heap.
    // When we retrieve an index for the purpose of grabbing an offer from the heap,
    // `isSet` == false and we -1 to account for the +1 when we set the index.
    // ie, if an offer is index 2 in the heap array, we set the index to be 3 in the
    // `indexes` mapping, when we try to grab an offer in the heap using the index
    // in the indexes mapping, we return 3 - 1 (the proper index).
    function indexValue(
        uint256 pos,
        bool isSet
    ) internal pure returns (uint256) {
        if (isSet) {
            return pos + 1;
        }

        return pos - 1;
    }
}
