// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Optimized.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";



contract Uzuki is ERC721Optimized, Ownable, ReentrancyGuard {

    enum Status {
        Waiting,
        Started,
        Finished
    }
    Status public status;
    using Strings for uint256;


    //public variable
    uint256 public supply = 10;//supply
    uint256 public mintPrice = 0.001 * 10**18;// 0.001 ETH
    uint256 public tradeFeePrecent = 25;
    string  public baseURI;

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event BaseURIChanged(string newBaseURI);
    event Log(uint256 value);

    constructor(string memory initBaseURI) ERC721Optimized("Uzuki", "UZK") {
        baseURI = initBaseURI;
    }


    //提现
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(payable(msg.sender), address(this).balance);      
    }

    //设置状态
    function setStatus(Status _status) public onlyOwner {
        status = _status;
        emit StatusChanged(status);
    }
    //设置元素URI
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    //设置交易费比例
     function setTradeFeePrecent(uint256 newTradeFeePrecent) public onlyOwner {
        require(newTradeFeePrecent > 0, "trade fee percent must be greater than zero");
        tradeFeePrecent = newTradeFeePrecent;
    }


    //设置总提供量
    function setSupply(uint256 newSupply) public onlyOwner {
        require(newSupply >= 0, "supply must be greater than zero");
        supply = newSupply;
    }


    //设置mint价格
    function setMintPrice(uint256 newMintPrice) public onlyOwner {
        require(newMintPrice >= 0, "Mint price must be greater than zero");
        mintPrice = newMintPrice;
    }



    //设置单个tokenId价格
    mapping(uint256 => uint256) tokenIdsPrice;
    function SetTokenIdPrice(uint256 tokenId,uint256 newTokenPrice) public nonReentrant {
        require(tokenId >= 0, "tokenId must be greater than zero");
        require(newTokenPrice > 0, "tokenId price must be greater than zero");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        tokenIdsPrice[tokenId]=newTokenPrice;
    }


     //赠送Id
    function giveAway(address to, uint256 tokenIdNumber) public onlyOwner {

        _safeMint(to, tokenIdNumber);
    }

    //Mint
   mapping(address => bool) minted;
    function mint() public payable nonReentrant {

        //check status
        require(status == Status.Started, "Mint is not live");

        //不能超过预设值
        require((totalSupply() + 1) <= supply, "Supply has been reached");

        //check minted
        require(!minted[msg.sender],"Address minted");
        minted[msg.sender] =true ;

       //这里的numberOfTokens是编号从 1 --> suppy
       uint256 tokenIdNumber=totalSupply()+1;

        //mint
        _safeMint(msg.sender, tokenIdNumber);
        emit Minted(msg.sender,tokenIdNumber);
        refundIfOver(mintPrice);
    }

    //扣除mint ETH
    function refundIfOver(uint256 price) private{
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    //购买
    function buy(uint256 tokenId) public payable nonReentrant{

        //检查tokenId
        require(tokenId >= 0, "tokenId must be greater than zero");

        //获取卖出地址
        address sellOwner = ERC721Optimized.ownerOf(tokenId);

        //检查当前余额要大于购买的金额
        uint256 amount=tokenIdsPrice[tokenId];

        //发送方向合约转账
        refundIfOver(amount);

        //计算交易费
        uint256 tradeFee = (amount * tradeFeePrecent) / 1000;

        //合约向开发者方转手续费,[此步省略交易费保留在合约中节约GAS,其他情况可以转入到开发者指定的地址中]
        //emit Log(tradeFee);
        //address author = 0x8c5283176f4585D99A2967426e4ff3750110B5fA;
        //Address.sendValue(payable(author), tradeFee);

        //合约向出售方式转账（扣除交易费后)
        uint256 tradeAmount = amount - tradeFee;
        emit Log(tradeAmount);
        Address.sendValue(payable(sellOwner), tradeAmount);

        //tokenId转入给买入方
         _beforeTokenTransfer(sellOwner, msg.sender, tokenId);

        // 清空授权并tokenId拥有权转给买方式
        _approve(address(0), tokenId);
        _owners[tokenId] = msg.sender;
        
        //通知系统
        emit Transfer(sellOwner, msg.sender, tokenId);
    }

    //查询tokenId价格
    function getTokenPrice(uint256 tokenId) public view returns (uint256){
     return tokenIdsPrice[tokenId];
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