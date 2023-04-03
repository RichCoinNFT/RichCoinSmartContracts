// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./openzeppelin/contracts/utils/Address.sol";
import "./openzeppelin/contracts/utils/Context.sol";
import "./openzeppelin/contracts/utils/Strings.sol";
import "./openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./openzeppelin/contracts/access/Ownable.sol";
import "./Dex.sol";
import "./IRichCoin.sol";


contract RichCoin is ERC721Holder, ERC165, IERC721Metadata, Ownable, IRichCoin{
    
    using Address for address;
    using Strings for uint256;

        mapping(uint256 => string) private _tokenURIs;
        string baseURI = "";
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return string(abi.encodePacked("ipfs://",_tokenURI));
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, tokenId, ".json"));
        }

        return "";
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal { //external onlyOwner
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    //function _setBaseURI(string memory newBaseURI) external onlyOwner{
    //    baseURI = newBaseURI;
    //}
    
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165 ) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC721Receiver).interfaceId;
    }

    function decimals() public pure returns(uint8){
        return 0;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override ended(){
        address owner = this.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override ended() {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = this.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */

    function _burn(uint256 tokenId) internal {
        address owner = this.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(this.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(this.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {}


    using Strings for address;
    uint256 private _tokenId;
    DEX  _dex; 
    bool  _ended = false;
    mapping(address => bool)  _wasOwner;
    mapping(uint256 => address)  _ownerOrder;
    mapping(address => uint256)  _orderToOwner;
    mapping(address => string)  _ownerToMessage;
    mapping(address => uint256)  _earned;
    mapping(address => uint256) _paid;
    uint256 _startPrice;
    uint256 _priceIncrease;
    uint256 _counter;
    event ContractCreated(string ___name, string ___symbol, uint256 _auctionStart, uint256 _deadlineLength, uint256 __startPrice, uint256 __priceIncrease, string __tokenURI);


    modifier byDexOrEndedToTransfer(address to, uint256 tokenId) {
        if(!_ended){
            require(byDex(), "Trasnferer has to be the DEX while auction has not ended");
            require(!_wasOwner[to], "Caller has already been an owner"); 

        }else{
            require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        }
        _;
    }

    modifier ended(){
        require(_ended, "Can't perform this action while auction has not ended");
        _;
    }
    
    function byDex() internal view returns(bool){
        return(msg.sender == address(_dex));
    }

    modifier wasOwner(address _address){
        require(_wasOwner[_address], "Given address was no owner!");
        _;
    }

    modifier validPlace(uint256 _number){
        require(_number>0 && _number <=_counter, "Given place is not valid!");
        _;
    }

    function transferFrom( 
        address from,
        address to,
        uint256 tokenId) public override byDexOrEndedToTransfer(to, tokenId) {
            _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from, 
        address to, 
        uint256 tokenId) public override{
            safeTransferFrom(from, to, tokenId, "");
    }
    
    function safeTransferFrom(
        address from, 
        address to, 
        uint256 tokenId,
        bytes memory _data) public override byDexOrEndedToTransfer(to, tokenId) {
            _safeTransfer(from, to, tokenId, _data);
    }

    constructor( string memory __name, string memory __symbol, uint256 auctionStart, uint256 deadlineLength, uint256 startPrice, uint256 priceIncrease, string memory _tokenURI, string memory _messageInput){
        require(msg.sender == tx.origin, "You can't create an auction from a Smart Contract");
        _startPrice = startPrice;
        _priceIncrease = priceIncrease;
        _name = __name;
        _symbol = __symbol;
        _dex = new DEX(address(this), auctionStart, deadlineLength, startPrice, priceIncrease, _messageInput);
        address _sender = address(msg.sender);
        _tokenId = 0;
        _safeMint(_sender, _tokenId);
        _setTokenURI(0, _tokenURI);
        _addOwner(msg.sender, _messageInput, 0);
        emit ContractCreated(__name, __symbol, auctionStart, deadlineLength, startPrice, priceIncrease, _tokenURI);
    }

    function getEarned(address _address) external view returns(uint256){
        return _earned[_address];
    }

    function addEarning(address _address, uint256 _amount) external override{
        require(byDex(), "Can only be called by DEX");
        _earned[_address] = _earned[_address] + _amount;
    }

    function getDexAddress() external view override returns(address){
        return address(_dex);
    }

    function addNewOwner(address _newOwner, string memory message, uint256 paid) external override{
        require(byDex(), "Can only be called by DEX");
        _addOwner(_newOwner, message, paid);

    }

    function _addOwner(address _newOwner, string memory message, uint256 paid) internal{
        _wasOwner[_newOwner] = true;
        _counter++;
        _ownerOrder[_counter] = _newOwner;
        _orderToOwner[_newOwner] = _counter;
        _ownerToMessage[_newOwner] = message;
        _paid[_newOwner] = paid;

    }

    function getTokenId() external view override returns(uint256){
        return _tokenId;
    }

    function endAuction() external override{
        require(byDex(), "Can only be called by DEX");
        _ended = true;
    }

    function isEnded() external view returns (bool){
        return _ended;
    }

   

    function getOwnerSize() external view returns(uint256){
        return _counter;
    }

    function getRichest() external view returns(address){
        return _ownerOrder[_counter];
    }

    function getOwnerByPlace(uint256 _placeN) external view validPlace(_placeN) returns(address){
        return _ownerOrder[_counter+1-_placeN];
    }

    function getMessageByPlace(uint256 _placeN) external view validPlace(_placeN) returns(string memory){
        return _ownerToMessage[_ownerOrder[_counter+1-_placeN]];
    }

    function getPlaceByOwner(address _address) external view wasOwner(_address) returns(uint256){
        return _counter+1-_orderToOwner[_address];
    }

     function getMessageByOwner(address _address) external view wasOwner(_address) returns(string memory){
        return _ownerToMessage[_address];
    }

    function getOwnerByOrder(uint256 number) external view override validPlace(number) returns(address){
        return _ownerOrder[number];
    }

    function getMessageByOrder(uint256 number) external view validPlace(number) returns(string memory){
        return _ownerToMessage[_ownerOrder[number]];
    }

    function getOrderByOwner(address _address) external view wasOwner(_address) returns(uint256){
        return _orderToOwner[_address];
    }

    function getPaidByOwner(address _address) external view wasOwner(_address) returns(uint256){
        return _paid[_address];

    }

    function addressWasOwner(address _address) external view returns(bool){
        return _wasOwner[_address];
    }

}