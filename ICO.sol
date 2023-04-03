// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ICO is ReentrancyGuard{

    address private _owner;
    uint8 _currentStage;
    ERC20 _rctContract;

    mapping(address => mapping(uint8 => uint256)) private _buyerStageValue;
    mapping(uint8 => uint256) private _stageToAvailableTokens;
    mapping(uint8 => uint256) private _stageToTotalTokens;
    mapping(uint8 => uint256) private _stageToPrice;


    modifier _onlyOwner(){
        require(msg.sender == _owner && tx.origin == _owner, "Caller is not owner");
        _;
    }

    event IcoPurchase(address buyer, uint256 amount);
    event IcoEnded();
    event StageChange(uint8 newStage);

    function buyRct() payable public nonReentrant {
        require(_currentStage > 0 && _currentStage <= 3, "There is an error with the current ICO stage");
        uint8 __currentStage = _currentStage;
        uint256 value = msg.value;
        address recipient = msg.sender;
        uint256 transferable = _computeTransferable(value, recipient);
        _rctContract.transfer(recipient, transferable * 1e18);
        if(__currentStage != _currentStage){
            emit StageChange(_currentStage);
        }
        emit IcoPurchase(recipient, transferable);
    }

    function _computeTransferable(uint256 value, address recipient) internal returns (uint256) {
        uint256 transferable = value / _stageToPrice[_currentStage];
        if (transferable >= _stageToAvailableTokens[_currentStage]){
            transferable = _stageToAvailableTokens[_currentStage];
            _updateValues(transferable, recipient);
            if(_currentStage < 3){
                uint256 leftOver = value - (transferable * _stageToPrice[_currentStage]);
                _currentStage++;
                return transferable + _computeTransferable(leftOver, recipient);
            }
        }else{
            _updateValues(transferable, recipient);
        }
        return transferable;
    }

    function _updateValues(uint256 transferable, address recipient) internal{
        _stageToAvailableTokens[_currentStage] = _stageToAvailableTokens[_currentStage] - transferable;
        _buyerStageValue[recipient][_currentStage] += transferable;
    }

    function getRctByAddressAndStage(address buyer, uint8 stage) external view returns (uint256) {
        return _buyerStageValue[buyer][stage];
    }

    function setStage(uint8 _newStage) public _onlyOwner {
        _currentStage = _newStage;
    }

    function endIco() public _onlyOwner {
        emit IcoEnded();
        selfdestruct(payable(_owner));
    }

    function getStage() external view returns (uint8) {
        return _currentStage;
    }

    function getTotalTokensByStage(uint8 stage) external view returns (uint256) {
        return _stageToTotalTokens[stage];
    }

    function getAvailableTokensByStage(uint8 stage) external view returns (uint256) {
        return _stageToAvailableTokens[stage];
    }

    function getPriceByStage(uint8 stage) external view returns (uint256) {
        return _stageToPrice[stage];
    }

    function getAvailableTokens() external view returns (uint256) {
        return _stageToAvailableTokens[1] + _stageToAvailableTokens[2] + _stageToAvailableTokens[3];
    }

    function redeem(uint256 amount) external _onlyOwner{
        if(msg.sender == tx.origin && msg.sender == _owner){
            payable(_owner).transfer(amount);
        }
    }

    constructor(address _rctAddress){
        _rctContract = ERC20(_rctAddress);
        _owner = msg.sender;
        _currentStage = 1;

        uint256 stage1Token = 1000000;
        uint256 stage2Token = 2000000;
        uint256 stage3Token = 4000000;

        _stageToAvailableTokens[1] = stage1Token;
        _stageToAvailableTokens[2] = stage2Token;
        _stageToAvailableTokens[3] = stage3Token;

        _stageToTotalTokens[1] = stage1Token;
        _stageToTotalTokens[2] = stage2Token;
        _stageToTotalTokens[3] = stage3Token;

        _stageToPrice[1] = 100000000000000;
        _stageToPrice[2] = 300000000000000;
        _stageToPrice[3] = 500000000000000;


    }

    
}