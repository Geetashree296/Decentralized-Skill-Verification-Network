// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Project is ERC721, Ownable, ReentrancyGuard {
    
    uint256 private _nextTokenId = 1;
    
    struct Skill {
        uint256 tokenId;
        string skillName;
        string description;
        address holder;
        uint256 endorsementCount;
        uint256 reputationScore;
        uint256 createdAt;
        bool isVerified;
    }
    
    struct Endorsement {
        address endorser;
        uint256 skillTokenId;
        string comment;
        uint256 timestamp;
    }
    
    // Mappings
    mapping(uint256 => Skill) public skills;
    mapping(uint256 => Endorsement[]) public skillEndorsements;
    mapping(address => uint256[]) public userSkills;
    mapping(address => bool) public verifiedEndorsers;
    
    // Events
    event SkillMinted(uint256 indexed tokenId, address indexed holder, string skillName);
    event SkillEndorsed(uint256 indexed tokenId, address indexed endorser, string comment);
    event EndorserVerified(address indexed endorser);
    event ReputationUpdated(uint256 indexed tokenId, uint256 newScore);
    
    constructor() ERC721("SkillVerificationNFT", "SVNFT") Ownable(msg.sender) {}
    
    /**
     * @dev Core Function 1: Mint a new skill NFT
     * @param skillName The name of the skill
     * @param description Detailed description of the skill
     */
    function mintSkill(string memory skillName, string memory description) external nonReentrant {
        require(bytes(skillName).length > 0, "Skill name cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");
        
        uint256 tokenId = _nextTokenId++;
        
        _safeMint(msg.sender, tokenId);
        
        skills[tokenId] = Skill({
            tokenId: tokenId,
            skillName: skillName,
            description: description,
            holder: msg.sender,
            endorsementCount: 0,
            reputationScore: 0,
            createdAt: block.timestamp,
            isVerified: false
        });
        
        userSkills[msg.sender].push(tokenId);
        
        emit SkillMinted(tokenId, msg.sender, skillName);
    }
    
    /**
     * @dev Core Function 2: Endorse a skill NFT
     * @param tokenId The ID of the skill NFT to endorse
     * @param comment Optional comment for the endorsement
     */
    function endorseSkill(uint256 tokenId, string memory comment) external nonReentrant {
        require(_ownerOf(tokenId) != address(0), "Skill NFT does not exist");
        require(ownerOf(tokenId) != msg.sender, "Cannot endorse your own skill");
        
        Skill storage skill = skills[tokenId];
        skill.endorsementCount++;
        
        // Calculate reputation boost based on endorser verification status
        uint256 reputationBoost = verifiedEndorsers[msg.sender] ? 10 : 5;
        skill.reputationScore += reputationBoost;
        
        skillEndorsements[tokenId].push(Endorsement({
            endorser: msg.sender,
            skillTokenId: tokenId,
            comment: comment,
            timestamp: block.timestamp
        }));
        
        // Auto-verify skill if it reaches certain thresholds
        if (skill.endorsementCount >= 5 && skill.reputationScore >= 30) {
            skill.isVerified = true;
        }
        
        emit SkillEndorsed(tokenId, msg.sender, comment);
        emit ReputationUpdated(tokenId, skill.reputationScore);
    }
    
    /**
     * @dev Core Function 3: Query and verify skills by address
     * @param user The address to query skills for
     * @return skillTokenIds Array of skill token IDs owned by the user
     * @return skillNames Array of skill names
     * @return reputationScores Array of reputation scores
     * @return verificationStatus Array of verification statuses
     */
    function getSkillsByUser(address user) 
        external 
        view 
        returns (
            uint256[] memory skillTokenIds,
            string[] memory skillNames,
            uint256[] memory reputationScores,
            bool[] memory verificationStatus
        ) 
    {
        uint256[] memory userTokens = userSkills[user];
        uint256 length = userTokens.length;
        
        skillTokenIds = new uint256[](length);
        skillNames = new string[](length);
        reputationScores = new uint256[](length);
        verificationStatus = new bool[](length);
        
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = userTokens[i];
            Skill memory skill = skills[tokenId];
            
            skillTokenIds[i] = tokenId;
            skillNames[i] = skill.skillName;
            reputationScores[i] = skill.reputationScore;
            verificationStatus[i] = skill.isVerified;
        }
        
        return (skillTokenIds, skillNames, reputationScores, verificationStatus);
    }
    
    // Additional utility functions
    
    /**
     * @dev Verify an endorser (only owner can call this)
     * @param endorser Address to verify as a trusted endorser
     */
    function verifyEndorser(address endorser) external onlyOwner {
        verifiedEndorsers[endorser] = true;
        emit EndorserVerified(endorser);
    }
    
    /**
     * @dev Get detailed skill information
     * @param tokenId The skill NFT token ID
     */
    function getSkillDetails(uint256 tokenId) 
        external 
        view 
        returns (Skill memory) 
    {
        require(_ownerOf(tokenId) != address(0), "Skill NFT does not exist");
        return skills[tokenId];
    }
    
    /**
     * @dev Get endorsements for a specific skill
     * @param tokenId The skill NFT token ID
     */
    function getSkillEndorsements(uint256 tokenId) 
        external 
        view 
        returns (Endorsement[] memory) 
    {
        require(_ownerOf(tokenId) != address(0), "Skill NFT does not exist");
        return skillEndorsements[tokenId];
    }
    
    /**
     * @dev Check if a skill is verified
     * @param tokenId The skill NFT token ID
     */
    function isSkillVerified(uint256 tokenId) external view returns (bool) {
        require(_ownerOf(tokenId) != address(0), "Skill NFT does not exist");
        return skills[tokenId].isVerified;
    }
    
    // Override required functions
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        override(ERC721) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
}
