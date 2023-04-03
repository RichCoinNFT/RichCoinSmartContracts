// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./openzeppelin/contracts/token/ERC721/IERC721.sol"; 
/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IRichCoin is IERC721{
    function getDexAddress() external view returns(address);
    function addNewOwner(address sender, string memory message, uint256 paid) external;
    function getOwnerByOrder(uint256 personenZaehler) external view returns(address);
    function addEarning(address earner, uint256 amount) external;
    function getTokenId() external view returns(uint256);
    function endAuction() external;
}