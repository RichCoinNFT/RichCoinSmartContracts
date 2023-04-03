// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./openzeppelin/contracts/token/ERC20/IERC20.sol"; 
/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IRct is IERC20{
    function transferTokenToDex(uint256 _amount, address _sender) external;
}