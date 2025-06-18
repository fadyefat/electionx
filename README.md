<<<<<<< HEAD
# election

A new Flutter project with smart contract

##smart contract
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Elections{

    address public owner ;
    mapping (address=>string) private addcandidate;
    string[]  private  candidateNames;
    uint256[]  private  candidateNam ;
    uint256 private endTime; // add varible to end time
    uint256 private max = 0;
    uint256 private winnerIndex = 0;
    mapping (address => bool) private hasVoted;

    constructor (uint256 _duration) // add prameters take time
    { 
        owner = msg.sender;
        endTime = block.timestamp + _duration; // caculate time
       
    }
    
    modifier onlyOwner()
    { 
        require (msg.sender == owner,"Only the owner can perform this action");
        _;
    }

     modifier votingOpen()  //add moddifier to end time
     {
        require(block.timestamp < endTime, "Voting has ended");
        _;
    }
    
    function AddConduation(address _candidate,string memory _name) public onlyOwner
    {
        require (_candidate != address(0),"address cannot be null");
        require(bytes(addcandidate[_candidate]).length == 0, "Candidate already exists");

        addcandidate[_candidate] = _name;
        candidateNames.push(_name);
        candidateNam.push(0);
        
    }

     function getAllCandidateNames() public view returns (string[] memory) {
        return candidateNames;
    }

    function voting(string  memory _nam)   public votingOpen   // add mdifier in function
    {
        require(!hasVoted[msg.sender], "You have already voted");
        for(uint256  i = 0 ; i < candidateNames.length ;i++)
        {
            if(keccak256(abi.encodePacked(candidateNames[i])) == keccak256(abi.encodePacked(_nam)))
            {
                candidateNam[i]+= 1;
                hasVoted[msg.sender] = true;
                return;
            }
          

        }
         revert("Candidate not found"); 
    }

    function get_NumOfVoting() public  view onlyOwner  returns (uint256[] memory) {
        return candidateNam;
    }

    
    function result ()public onlyOwner returns (string memory) // add moddifier to function
    { 
        require(block.timestamp >= endTime, "Voting is still ongoing");
       for (uint256 i = 0 ;i <candidateNames.length; i++)
        {
            if (candidateNam[i] > max) 
            {   
                max = candidateNam[i];
                winnerIndex = i;
            }
            
        }
         return string(abi.encodePacked("The winner is: ", candidateNames[winnerIndex])); 
    }

}

