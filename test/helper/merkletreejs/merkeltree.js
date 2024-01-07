const { MerkleTree } = require('merkletreejs')
const SHA256 = require('crypto-js/sha256')
const {
    keccak256
} = require("@ethersproject/keccak256");


const whitelist = [
    '0x7026B763CBE7d4E72049EA67E89326432a50ef84', 
    '0xEb0A3b7B96C1883858292F0039161abD287E3324', 
    '0xcC37919fDb8E2949328cDB49E8bAcCb870d0c9f3', 
    '0x228EBeEbaCb93F12C10d34aBFDCeaF400e894F45'
]
const leaves = whitelist.map(x => keccak256(x))
const tree = new MerkleTree(leaves, keccak256, {sortPairs: true})
const rootHash = tree.getRoot().toString('hex')

console.log(`whitelist merkle root: 0x${rootHash}`)
whitelist.forEach((address) => {
    const proof = tree.getHexProof(keccak256(address))
    console.log(`Address: ${address} - Proof: ${proof}`)
})

const leaf = keccak256('0x7026B763CBE7d4E72049EA67E89326432a50ef84')
const proof = tree.getProof(leaf)
console.log(tree.verify(proof, leaf, rootHash)) // true

const badLeaves = ['0xaA10a84CE7d9AE517a52c6d5cA153b369Af99ecF', '0xEb0A3b7B96C1883858292F0039161abD287E3324', '0xcC37919fDb8E2949328cDB49E8bAcCb870d0c9f3', '0x228EBeEbaCb93F12C10d34aBFDCeaF400e894F45'].map(x => keccak256(x))
const badTree = new MerkleTree(badLeaves, keccak256, {sortPairs: true})
const badLeaf = keccak256('0xaA10a84CE7d9AE517a52c6d5cA153b369Af99ecF')
const badProof = badTree.getHexProof(badLeaf)
console.log(`Address: 0xaA10a84CE7d9AE517a52c6d5cA153b369Af99ecF - Proof: ${badProof}`)
console.log(badTree.verify(badProof, badLeaf, rootHash)) // false
