// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Optimized.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract KnwinClub is ERC721Optimized, Ownable, ReentrancyGuard {

    enum Status {
        Waiting,
        Whitelist,
        PublicSale,
        Finished
    }
    Status public status;
    using   Strings for uint256;
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public maxPurchaseWL = 1;
    uint256 public maxPurchasePS = 2; //public sale max purchase

    uint256 public mintPriceWL = 0.001 * 10**18;// 0.001 ETH
    uint256 public mintPricePS = 0.004 * 10**18;// 0.004 ETH
    string  public baseURI;

    event Minted(address indexed mintAddress, uint256 indexed tokenId);
    event PermanentURI(string _value, uint256 indexed _id);
    event StatusChanged(Status status);
    event BaseURIChanged(string newBaseURI);
    event MerkleRootSet(bytes32 _merkleRoot);

    constructor(string memory initBaseURI) ERC721Optimized("KnwinClub", "KNC") {
        baseURI = initBaseURI;
    }

    //giveAway
    function giveAway(address to, uint256 numberOfTokens) public onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            createCollectible(to);
        }
    }


    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(payable(msg.sender), address(this).balance);
    }


    function withdrawTo(uint256 amount, address payable to) public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(to, amount);
    }

    function setStatus(Status _status) public onlyOwner {
        status = _status;
        emit StatusChanged(status);
    }


    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    //setting MintPriceWL
    function setMintPriceWhitelist(uint256 newPrice) public onlyOwner {
        require(newPrice >= 0, "whitlist price must be greater than zero");
        mintPriceWL = newPrice;
    }

    //setting MintPricePublicSale
    function setMintPricePublicSale(uint256 newPrice) public onlyOwner {
        require(newPrice >= 0, "public price must be greater than zero");
        mintPricePS = newPrice;
    }


    /* whitelist mint */
    bytes32 public merkleRoot;

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootSet(merkleRoot);
    }

    mapping(address => bool) whitelistClaimed;
    mapping(address => uint256) whitelistMintedNFTs;
 
    function whitelistMint(uint256 numberOfTokens,bytes32[] calldata _merkleProof) public payable nonReentrant{

     //check status
     require(status == Status.Whitelist,"Whitelist sale is not live");

     //check whitelistClaimed
     require(!whitelistClaimed[msg.sender],"Your whitelist entry has already been claimed");

    //check maxPurchaseWL
     require(numberOfTokens <= maxPurchaseWL, "You whitelist can't mint that many NFTs");

     //check Max_SUPPLE
     require((totalSupply() + numberOfTokens) <= MAX_SUPPLY, "Total supply has been reached");

     //check ETH Balance
     require(mintPriceWL * numberOfTokens <= msg.value, "Not enough ETH");

     //check owner minted number
     require((whitelistMintedNFTs[msg.sender] + numberOfTokens) <= maxPurchaseWL,"You whitelist has mint max NFTs");

     whitelistMintedNFTs[msg.sender] += numberOfTokens;

     //check is whitelist
     bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
     require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),"Oops, can't find you on the whitelist");

     for (uint256 i = 0; i < numberOfTokens; i++) {
        createCollectible(_msgSender());
    }


}

//save mintedNfts
mapping(address => uint256) publicSaleMintedNFTs;

function mint(uint256 numberOfTokens) public payable nonReentrant {

    //check status
    require(status == Status.PublicSale, "Public sale is not live");

    //check maxPurchasePS
    require(numberOfTokens <= maxPurchasePS, "You public sale can't mint that many NFTs");

    //check Max_SUPPLE
    require((totalSupply() + numberOfTokens) <= MAX_SUPPLY, "Total supply has been reached");

    //check ETH Balance
    require((mintPricePS * numberOfTokens) <= msg.value, "Not enough ETH");

    //check owner minted number
    require(publicSaleMintedNFTs[msg.sender] + numberOfTokens <= maxPurchasePS,"You public salse has mint max NFTs");

    publicSaleMintedNFTs[msg.sender] += numberOfTokens;

    for (uint256 i = 0; i < numberOfTokens; i++) {
        createCollectible(_msgSender());
    }

}


//burn
function burnNFT(uint256 tokenId)public payable nonReentrant {
_burn(tokenId);
}

//get owner whitelist minted number
function whitelistMinteds(address owner) public view returns (uint256) {
    return whitelistMintedNFTs[owner];
}

//get owner public minted number
function publicSaleMinteds(address owner) public view returns (uint256) {
    return publicSaleMintedNFTs[owner];
}

function createCollectible(address mintAddress) private {
    uint256 mintIndex = totalSupply();
    if (mintIndex < MAX_SUPPLY) {
        _safeMint(mintAddress, mintIndex);
        emit Minted(mintAddress, mintIndex);
    }
}

function freezeMetadata(uint256 tokenId, string memory ipfsHash) public {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    require(_msgSender() == ERC721Optimized.ownerOf(tokenId), "Caller is not a token owner");
    emit PermanentURI(ipfsHash, tokenId);
}

function _baseURI() internal view virtual returns (string memory) {
    return baseURI;
}

function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
}
}