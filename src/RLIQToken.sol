// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RLIQToken is ERC1155, ERC1155Burnable, Ownable {
    uint256 public nextSeriesId;

    constructor(address initialOwner) ERC1155("") Ownable(initialOwner) {}

    function mint(address account, uint256 id, uint256 amount)
        public
        onlyOwner
    {
        _mint(account, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function newSeries(address to, uint256 amount) external onlyOwner returns (uint256 seriesId) {
        seriesId = ++nextSeriesId;
        _mint(to, seriesId, amount, "");
    }
}