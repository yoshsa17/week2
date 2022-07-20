pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

// reference:
// 1. https://github.com/tornadocash/tornado-core/blob/master/circuits/merkleTree.circom#L1
// 2. https://github.com/privacy-scaling-explorations/incrementalquintree/blob/master/circom/checkRoot.circom

template HasherPoseidon() {
  signal input left;
  signal input right;
  signal output hash;

  component hasher = Poseidon(2);
  hasher.inputs[0] <== left;
  hasher.inputs[1] <== right;
  hash <== hasher.out;
}

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;
    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves
    
    // set hashers with the number of nodes above the lowest level
    var hasherCount = 2**n - 1;
    component hashers[hasherCount];

    // initialize the hashers
    var i;
    for (i = 0; i < hasherCount; i++) {
      hashers[i] = HasherPoseidon();
    }
    
    // connect the leaves to the leaf hashers
    for(i = 0; i < 2**(n-1); i++) {
      hashers[i].left <== leaves[i*2];
      hashers[i].right <== leaves[i*2+1];
    }

    // caliculate the remaining hashers
    var j = 0;
    for(i = 2**(n-1); i < hasherCount; i++) {
      hashers[i].left <== hashers[j*2].hash;
      hashers[i].right <== hashers[j*2+1].hash;
      j++;
    }
    
    // set the last hash to the root
    root <== hashers[hasherCount-1].hash;
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    component hashers[n];
    component mux[n];
    var i;

    for(i = 0; i < n; i++) {
      mux[i] = MultiMux1(2);
      mux[i].c[0][0] <== i == 0 ? leaf : hashers[i-1].hash;
      mux[i].c[0][1] <== path_elements[i];
      mux[i].c[1][0] <== path_elements[i];
      mux[i].c[1][1] <== i == 0 ? leaf : hashers[i-1].hash;
      mux[i].s <== path_index[i];

      hashers[i] = HasherPoseidon();
      hashers[i].left <== mux[i].out[0];
      hashers[i].right <== mux[i].out[1];
    }
    
    root <== hashers[n-1].hash;
}