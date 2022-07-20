//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract
import "hardhat/console.sol"; 

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root
    uint256 public _treeLevel = 3;

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves
        
        // initialize the leaf nodes (the first 8 element of the array)
        uint256 i;
        for(i = 0; i < 2**_treeLevel; i++) {
          hashes.push(0);
        }

        // push all hashes until we fill the remaining nodes 
        uint256 j = 0;
        uint256 remainingCount = 2**_treeLevel - 1;
        while(j  <= remainingCount - 1) {
          hashes.push(
            PoseidonT3.poseidon([hashes[j*2], hashes[j*2+1]])
          );
          j++;
        }
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        require(index != 2**_treeLevel - 1, "Merkle tree is full");

        // update the leaf node
        hashes[index] = hashedLeaf;

        // update the parent node until we reach the root
        uint256 current = index; 
        uint256 parent;
        uint256 right;
        uint256 left; 
        uint256 baseIndex = 2**_treeLevel;
        while(current < hashes.length - 1) {
          parent = baseIndex + current / 2;
          if(current % 2 == 0){
            left = current;
            right = current + 1;
          } else {
            left = current - 1;
            right = current;
          }
          // console.log("left: ", left);
          // console.log("right: ", right);
          hashes[parent] = PoseidonT3.poseidon([hashes[left], hashes[right]]);
          current = parent;
        }

        // set the root with the last node
        root = hashes[hashes.length - 1];

        // increment the index
        unchecked {
          index++;
        }
      
        // return theroot
        return root;
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {

        // [assignment] verify an inclusion proof and check that the proof root matches current root
        return (verifyProof(a,b,c,input) && root == input[0]);
    }
}
