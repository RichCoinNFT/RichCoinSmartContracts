// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IRct.sol";
import "./IDex.sol";
import "./IRichCoin.sol";

contract Rct is ERC20, IRct{

    address private _owner;
    mapping(bytes32 => mapping(bytes32 => uint256)) private _dexRichcoinValidUntil;

    modifier _onlyOwner(){
        require(msg.sender == _owner && tx.origin == _owner, "Caller is not owner");
        _;
    }

    function setOwner(address _newOwner) public _onlyOwner(){
        _owner = _newOwner;
    }

    function getOwner() public view returns(address){
        return _owner;
    }

    function setNameAndSymbol(string memory _newName, string memory _newSymbol) public _onlyOwner(){
        _setName(_newName);
        _setSymbol(_newSymbol);
    }

    constructor() ERC20("RichCoinToken", "RCT"){
        _mint(msg.sender, 10**24);
        _owner = msg.sender;
    }

    function transferTokenToDex(uint256 _amount, address _sender) external override{
        IDex dex = IDex(msg.sender);
        bytes32 dexHashed = address(dex).codehash;
        bytes32 richHashed = address(dex.getRichCoin()).codehash;
        require(_dexRichcoinValidUntil[dexHashed][richHashed] > dex.getCreated(), "Contract pair not valid");
        require(dex.getCreated() > 0, "Dex has been destructed");
        _transferInternal(_sender, address(dex), _amount);
    }

    function insertValidContractByDex(address _dexAddress) public _onlyOwner(){
        require(IDex(_dexAddress).getCreated() > 0, "Dex has been destructed");
        bytes32 dexHashed = _dexAddress.codehash;
        bytes32 richHashed = address(IDex(_dexAddress).getRichCoin()).codehash;
        _dexRichcoinValidUntil[dexHashed][richHashed] = 9999999999;
    }

    function insertValidContractByHashes(bytes32 _dexHash, bytes32 _richHash) public _onlyOwner(){
        _dexRichcoinValidUntil[_dexHash][_richHash] = 9999999999;
    }

    function insertValidContractByRichCoin(address _contractAddress) public _onlyOwner(){
        bytes32 richHashed = _contractAddress.codehash;
        address dexAddress = address(IRichCoin(_contractAddress).getDexAddress());
        require(IDex(dexAddress).getCreated() > 0, "Dex has been destructed");
        bytes32 dexHashed = dexAddress.codehash;
        _dexRichcoinValidUntil[dexHashed][richHashed] = 9999999999;
    }

    function setValidUntilByDex(address _dexAddress, uint256 __dexRichcoinValidUntil) public _onlyOwner() {
        require(IDex(_dexAddress).getCreated() > 0, "Dex has been destructed");
        bytes32 richHashed = address(IDex(_dexAddress).getRichCoin()).codehash;
        _dexRichcoinValidUntil[_dexAddress.codehash][richHashed] = __dexRichcoinValidUntil;
    }

    function setValidUntilByRichCoin(address _contractAddress, uint256 __dexRichcoinValidUntil) public _onlyOwner() {
        address dexAddress = address(IRichCoin(_contractAddress).getDexAddress());    
        require(IDex(dexAddress).getCreated() > 0, "Dex has been destructed");
        bytes32 dexHashed = dexAddress.codehash;
        _dexRichcoinValidUntil[dexHashed][_contractAddress.codehash] = __dexRichcoinValidUntil;
    }

    function isValidUntilByDex(address _dexAddress) public view returns (uint256) {
        bytes32 richHashed = address(IDex(_dexAddress).getRichCoin()).codehash;   
        require(IDex(_dexAddress).getCreated() > 0, "Dex has been destructed");
        return _dexRichcoinValidUntil[_dexAddress.codehash][richHashed];
    }

    function isValidUntilByRichCoin( address _richAddress) public view returns (uint256) {
        address dexAddress = address(IRichCoin(_richAddress).getDexAddress());   
        require(IDex(dexAddress).getCreated() > 0, "Dex has been destructed");
        bytes32 dexHashed = dexAddress.codehash;
        return _dexRichcoinValidUntil[dexHashed][_richAddress.codehash];
    }

    function isValidContractByDexAndRichCoin(address _dexAddress, address _richAddress) public view returns (bool){
        uint256 created = IDex(_dexAddress).getCreated();
        require(created > 0, "Dex has been destructed");
        return created < _dexRichcoinValidUntil[_dexAddress.codehash][_richAddress.codehash];
    }

    function isValidContractByDex(address _dexAddress) public view returns (bool){
        bytes32 richHashed = address(IDex(_dexAddress).getRichCoin()).codehash;
        uint256 created = IDex(_dexAddress).getCreated();
        require(created > 0, "Dex has been destructed");
        return created < _dexRichcoinValidUntil[_dexAddress.codehash][richHashed];
    }

    function isValidContractByRichCoin(address _richAddress) public view returns (bool){
        address dexAddress = address(IRichCoin(_richAddress).getDexAddress());
        uint256 created = IDex(dexAddress).getCreated();
        require(created > 0, "Dex has been destructed");
        bytes32 dexHashed = dexAddress.codehash;
        return created < _dexRichcoinValidUntil[dexHashed][_richAddress.codehash];
    }

    
}