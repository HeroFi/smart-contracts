//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IRewardManager {
    function mintReward(address _to, uint256 _reward) external;
}

contract RewardPremium is Ownable {
    IRewardManager private rewardManager;
    
    mapping(uint256 => bytes32) roots;
    
    mapping(uint256 => mapping(address => bool)) claimed;
    
    event MerkleRootUpdated(uint256 timestamp, bytes32 merkleRoot);
    
    event RewardClaim(address user, uint256 reward, uint256 timestamp);
    
    uint256 public claimLimit;
    
    constructor(address _rewardManager) {
        rewardManager = IRewardManager(_rewardManager); 
    }
    
    function claimReward(uint256 _timestamp, address _user, uint256 _reward, bytes32[] memory _proof) external {
        bytes32 leaf = keccak256(abi.encodePacked(_user, _reward));
        require(MerkleProof.verify(_proof, roots[_timestamp], leaf), "proof not valid");
        require(!claimed[_timestamp][_user], "claimed");
        claimed[_timestamp][_user] = true;
        rewardManager.mintReward(_user, _reward);
        emit RewardClaim(_user, _reward, _timestamp);
    }
    
    function claimRewards(uint256[] memory _timestamps, address _user, uint256[] memory _rewards, bytes32[][] memory _proofs) public {
        uint256 len = _timestamps.length;
        require(len == _proofs.length, "Mismatching inputs");

        uint256 total = 0;
        
        for(uint256 i = 0; i < len; i++) {
            bytes32 leaf = keccak256(abi.encodePacked(_user, _rewards[i]));
            require(MerkleProof.verify(_proofs[i], roots[_timestamps[i]], leaf), "proof not valid");
            require(!claimed[_timestamps[i]][_user], "claimed");
            claimed[_timestamps[i]][_user] = true;
            total += _rewards[i];
        }
        
        rewardManager.mintReward(_user, total);
    }
    
    function updateMerkleRoot(uint256 _timestamp, bytes32 _root) external onlyOwner {
        roots[_timestamp] = _root;

        emit MerkleRootUpdated(_timestamp, _root);
    }
    
    function verifyMerkleProof(uint256 _timestamp, address _user, uint256 _reward, bytes32[] memory _proof) public view returns (bool valid) {
        bytes32 leaf = keccak256(abi.encodePacked(_user, _reward));
        return MerkleProof.verify(_proof, roots[_timestamp], leaf);
    }
    
    function updateRewardManager(address _newAddress) external onlyOwner {
        rewardManager = IRewardManager(_newAddress);
    }
    
    function getRoot(uint256 _timestamp) public view returns (bytes32) {
        return roots[_timestamp];
    }
}