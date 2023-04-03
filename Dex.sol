
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IRichCoin.sol";
import "./openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRct.sol";
import "./IDex.sol";

contract DEX is ERC721Holder, ReentrancyGuard, IDex{
    IRct private rct;
    IRichCoin private coin;
    uint256 private _priceIncrease;
    uint256 private _deadline;
    uint256 private _auctionStart;
    uint256 private _created;
    bool private _auctionStarted = false;
    uint256 private _deadlineLength;
    uint256 private _startPrice;
    uint256 private _commission = 2;
    uint256 _ownerNumber = 1;
    event NewOwner(address indexed _owner, uint256 _counter, uint256 _pricePaid, string _message);
    event NewDeadline(uint256 _deadline);
    event AuctionEnded(bool _ended);
    uint256 private _amountToPay;
    uint256 private _amountOld;

    constructor(address richCoinAddress, uint256 auctionStart, uint256 deadlineLength, uint256 startPrice, uint256 priceIncrease, string memory message) {
        require(priceIncrease > 100, "Base is too low");
        require((startPrice*priceIncrease)/100 > startPrice, "Invalid price increase");
        require(deadlineLength < 31622400, "Deadline length is too big");
        _created = block.timestamp;
        _auctionStart = auctionStart;
        _deadlineLength = deadlineLength;
        _startPrice = startPrice;
        _priceIncrease = priceIncrease;
        _amountOld = startPrice;
        _amountToPay = ((_amountOld*_priceIncrease)/100);
        coin = IRichCoin(richCoinAddress);
        rct = IRct(0xe869165E993FD8e1B28B50ead4791e862942cB53); //Proxy?
        newDeadline(_auctionStart + _deadlineLength);
        emit NewOwner(tx.origin, _ownerNumber, _startPrice, message);
    }

    function newDeadline(uint256 _newDeadline) internal {
        _deadline = _newDeadline;
        emit NewDeadline(_deadline);
    }

    fallback() external payable{
    }

    receive() external payable{

    }

    function addNewOwner(address _newOwner, string memory message) internal{
        _ownerNumber++;
        emit NewOwner(_newOwner, _ownerNumber, _amountToPay, message);
        coin.addNewOwner(_newOwner, message, _amountToPay);
    }

    function paybackLastOne(uint256 _amount) internal{
        bool sent = rct.transfer(coin.getOwnerByOrder(_ownerNumber), _amount);
        if(sent){
            coin.addEarning(coin.getOwnerByOrder(_ownerNumber), _amount); 
        }
    }

        function paybackAll(uint256 rest) internal{
            for(uint256 i=1; i<=_ownerNumber; i++){                                                
                uint256 amountToSend = (rest/(2**(i)));
                if(i == _ownerNumber){
                    amountToSend += amountToSend;
                }
                if(amountToSend!=0){
                    bool sent = rct.transfer(coin.getOwnerByOrder(i), amountToSend);
                    if(sent){
                    coin.addEarning(coin.getOwnerByOrder(i), amountToSend);
                    }
                }
            }
        }

        function paybackProvision(uint256 remaining) internal {
            bool sent = rct.transfer(0x2d48A3957C7246f5630A2CFF2fcBDf737e0177b4, remaining);
            if(sent){
                coin.addEarning(0x2d48A3957C7246f5630A2CFF2fcBDf737e0177b4, remaining);
            }
        }

    function transact(string memory _message, uint256 _amount) internal{
            require(_amount >= _amountToPay , "You have to pay the right price!");
            rct.transferTokenToDex(_amountToPay, msg.sender);
            uint256 payback = ((_amountToPay-_amountOld)/2)+_amountOld;
            uint256 rest = _amountToPay-payback;
            uint256 valueLastOne = payback*(100-_commission)/100;
            paybackLastOne(valueLastOne);
            uint256 valueAll = rest*(100-_commission)/100;
            paybackAll(valueAll);
            uint256 valueRemaining = _amount - valueLastOne - valueAll;
            paybackProvision(valueRemaining);
            coin.safeTransferFrom(coin.ownerOf(coin.getTokenId()),msg.sender, coin.getTokenId());
            addNewOwner(msg.sender, _message);
            newDeadline(block.timestamp + _deadlineLength);
            _amountOld = _amountToPay;
            _amountToPay = ((_amountOld*_priceIncrease)/100);
    }

    function buyRichCoin(string memory _message, uint256 _amount) nonReentrant external {
        if(!_auctionStarted){
            require(block.timestamp >= _auctionStart, "The auction hasn't started yet!");
            _auctionStarted = true;
        }
        if(block.timestamp >= _deadline){
            coin.endAuction();
            emit AuctionEnded(true);
            selfdestruct(payable(coin.getOwnerByOrder(1))); 
        }else{
            transact(_message, _amount);
        }
    }

    function getPrice() external view returns(uint256){
        return _amountToPay;
    }

    function isStarted() external view returns(bool){
        return _auctionStarted;
    }

    function getAuctionStart() external view returns(uint256){
        return _auctionStart;
    }

    function getDeadlineLength() external view returns(uint256){
        return _deadlineLength;
    }

    function getDeadlineRemaining() external view returns(uint256){
        return _deadline;
    }

    function getStartPrice() external view returns(uint256){
        return _startPrice;
    }

    function getBasis() external view returns(uint256){
        return _priceIncrease;
    }

    function getRichCoin() external view override returns(address) {
        return address(coin);
    }

    function getCreated() external view override returns(uint256){
        return _created;
    }

}