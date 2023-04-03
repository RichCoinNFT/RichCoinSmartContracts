// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./openzeppelin/contracts/token/ERC721/IERC721.sol"; 
/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IDex{
    function getCreated() external view returns(uint256);
    function getRichCoin() external view returns(address);
}