const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

let whitelistAddresses = [
    '0x169841AA3024cfa570024Eb7Dd6Bf5f774092088',
    '0xc12ae5Ba30Da6eB11978939379D383beb5Df9b33',
    '0x0a290c8cE7C35c40F4F94070a9Ed592fC85c62B9',
    '0x43Be076d3Cd709a38D2f83Cd032297a194196517',
    '0xC7FaB03eecA24CcaB940932559C5565a4cE9cFFb',
    '0xE4336D25e9Ca0703b574a6fd1b342A4d0327bcfa',
    '0xeDcB8a28161f966C5863b8291E80dDFD1eB78491',
    '0x77cbd0fa30F83a249da282e9fE90A86d7936FdE7',
    '0xc39F9406284CcAeB426D0039a3F6ADe14573BaFe',
    '0x16Beb6b55F145E4269279B82c040B7435f1088Ee',
    '0x900b2909127Dff529f8b4DB3d83b957E6aE964c2',
    '0xeA2A799793cE3D2eC6BcD066563f385F25401e95',
];
let leafNodes = whitelistAddresses.map(address => keccak256(address));
let tree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });

console.log('Tree: ', tree.toString());


//whitelist mint create proof
let leaf = keccak256('0xc12ae5Ba30Da6eB11978939379D383beb5Df9b33');
let proof = tree.getHexProof(leaf);
console.log('Proof of 0xc12ae5Ba30Da6eB11978939379D383beb5Df9b33: ', proof);
