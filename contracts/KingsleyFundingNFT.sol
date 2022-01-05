//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract KingsleyFundingNFT is ERC721Enumerable, Pausable, Ownable {
    uint16 private constant MAX_SUPPLY = 444;
    uint256 private constant TOKEN_PRICE = 0.888 ether;

    struct Interval {
        uint128 time0;
        uint128 time1;
    }
    Interval private _interval;

    uint256 public rewardPerSec;

    mapping(uint256 => uint256) private _tokenTimer;

    constructor() ERC721("Kingsley Funding NFT", "KF-NFT") {
        _interval.time0 = uint128(block.timestamp);
        _interval.time1 = uint128(block.timestamp);
        rewardPerSec = 0;
    }

    function claim() external whenPaused {
        uint256 tokenCount = balanceOf(_msgSender());
        uint256 totalReward = 0;
        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_msgSender(), i);
            uint256 tokenTime = _tokenTimer[tokenId];
            if (tokenTime >= _interval.time0) {
                totalReward = (_interval.time1 - tokenTime) * rewardPerSec;
            }
            _tokenTimer[tokenId] = _interval.time1;
        }
        Address.sendValue(payable(_msgSender()), totalReward);
    }

    function mint() external payable whenNotPaused {
        require(!Address.isContract(_msgSender()), "can't from contract");
        require(msg.value >= TOKEN_PRICE, "not enough fund");
        uint256 newTokenId = totalSupply();
        require(newTokenId < MAX_SUPPLY, "sold out");

        _safeMint(_msgSender(), newTokenId);
        _tokenTimer[newTokenId] = block.timestamp;
    }

    function startClaim() external payable onlyOwner {
        _interval.time1 = uint128(block.timestamp);
        rewardPerSec =
            msg.value /
            totalSupply() /
            (_interval.time1 - _interval.time0);
        _pause();
    }

    function endClaim() external onlyOwner {
        _interval.time0 = uint128(block.timestamp);
        Address.sendValue(payable(owner()), address(this).balance);
        _unpause();
    }

    function ownerClaim() external whenNotPaused {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        _tokenTimer[tokenId] = block.timestamp;
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
