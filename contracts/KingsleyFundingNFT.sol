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
    Interval private interval;

    uint256 public rewardPerSec;

    mapping(uint256 => uint256) private _tokenUpdateTime;

    constructor() ERC721("Kingsley Funding NFT", "KF-NFT") {
        interval.time0 = uint128(block.timestamp);
        interval.time1 = uint128(block.timestamp);
        rewardPerSec = 0;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        _tokenUpdateTime[tokenId] = block.timestamp;
    }

    function mint() external payable whenNotPaused {
        require(msg.value > TOKEN_PRICE, "not enough fund");
        uint256 newTokenId = totalSupply();
        require(newTokenId < MAX_SUPPLY, "sold out");

        _safeMint(_msgSender(), newTokenId);
        _tokenUpdateTime[newTokenId] = block.timestamp;
    }

    function startClaim() external payable onlyOwner {
        interval.time1 = uint128(block.timestamp);
        rewardPerSec =
            msg.value /
            totalSupply() /
            (interval.time1 - interval.time0);
        _pause();
    }

    function endClaim() external onlyOwner {
        interval.time0 = uint128(block.timestamp);
        _unpause();
    }

    function claim() external whenPaused {
        uint256 tokenCount = balanceOf(_msgSender());
        uint256 totalReward = 0;
        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_msgSender(), i);
            uint256 tokenUpdateTime = _tokenUpdateTime[tokenId];
            if (tokenUpdateTime >= interval.time0) {
                totalReward = (interval.time1 - tokenUpdateTime) * rewardPerSec;
            }
            _tokenUpdateTime[tokenId] = interval.time1;
        }
        Address.sendValue(payable(_msgSender()), totalReward);
    }

    function ownerClaim() external whenNotPaused {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    receive() external payable {
        require(!paused(), "can't receive when paused");
    }
}
