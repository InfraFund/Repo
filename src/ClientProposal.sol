// SPDX-License-Identifier: BSD-3-Clause license
pragma solidity 0.8.17;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


error ZeroAddress();
error NotGranted();
error NotWhiteListed();
error AlreadyAuditRequested();
error NotAuditor();
error AlreadyVerified();
error WrongInput();
error ProposalNotVerified();

/// @title ClientProposal
/// @author Matin Rezaii
/// @notice A contract which covers the tasks from the client side of the protocol
///         This contract is the client companies entry point to the protocol which
///         contains a projects different status.
/// @dev This contract inherits from the OpenZeppelin's Ownable and Pausable contracts

contract ClientProposal is Ownable, Pausable {

    using SafeERC20 for IERC20;

    uint256 private totalProposal;
    uint256 private proposalFee;

    mapping(address => bool) private whiteListed;
    mapping(address => bool) private auditors;
    mapping(uint => ProjectProposal) private projectProposals;

    IERC20 private paymentToken;

    struct ProjectProposal{
        string name;
        string symbol;
        string description;
        address proposer;
        uint projectType;
        bool isVerified;
    }

    event ProposalSubmitted(address indexed proposer, uint indexed proposalId);
    event ProposalVerified(address indexed auditor, uint indexed proposalId);

    modifier onlyWhitelisted(address _address) {
        if(!whiteListed[_address])
            revert NotWhiteListed();
        _;
    }

    modifier onlyAuditor(address _address) {
        if(!auditors[_address])
            revert NotAuditor();
        _;
    }

    constructor(address _token, uint _fee) {

        if(_token == address(0) || _fee == 0)
            revert WrongInput();

        paymentToken = IERC20(_token);
        proposalFee = _fee;
    }

    /// @notice This function is the entry point of the protocol for the clients
    /// @dev Only permissioned clients can call this function
    /// @param name Project proposal name
    /// @param symbol Project proposal symbol
    /// @param description Project proposal description
    /// @param _projectType Type of the proposed project

    function submitProposal(
        string calldata name,
        string calldata symbol,
        string calldata description,
        uint _projectType
    ) 
        external
        onlyWhitelisted(msg.sender)
        whenNotPaused()
    {

        uint proposalId = ++totalProposal;
        ProjectProposal storage _projectProposal;

        paymentToken.safeTransferFrom(msg.sender, address(this), proposalFee);

        _projectProposal.name = name;
        _projectProposal.symbol = symbol;
        _projectProposal.description = description;
        _projectProposal.projectType = _projectType;
        _projectProposal.proposer = msg.sender;

        projectProposals[proposalId] = _projectProposal;
        _requestForAudit(proposalId);

        emit ProposalSubmitted(msg.sender, proposalId);
    }

    /// @notice This function is called to verify a pending proposal
    /// @dev An authorized auditor can call this function
    /// @param proposalId The unique id of a proposal

    function verifyProposal(uint proposalId) external onlyAuditor(msg.sender) {

        bool verified = projectProposals[proposalId].isVerified;
        if(verified)
            revert AlreadyVerified();

        projectProposals[proposalId].isVerified = true;

        emit ProposalVerified(msg.sender, proposalId);
    }

    // TODO: Minimal Proxies (ERC1167)
    function createProject(uint proposalId) external onlyOwner returns(address) {

        ProjectProposal storage _proposal = projectProposals[proposalId];
        bool verified = _proposal.isVerified;
        if(!verified)
            revert ProposalNotVerified();

        string memory _name = _proposal.name;
        string memory _symbol = _proposal.symbol;
        string memory _description = _proposal.description;
        uint _projectType = _proposal.projectType;
        
        if(_projectType == 0) {
            return (address(new equityToken()))
        }

        else if(_projectType == 1) {

        }

        else if(_projectType == 2) {
            
        }

        else {

        }
    }

    function grantAuditor(address _newAuditor) external onlyOwner {

        if(_newAuditor == address(0))
            revert ZeroAddress();

        auditors[_newAuditor] = true;
    }

    function revokeAuditor(address _auditor) external onlyOwner {

        if(!auditors[_auditor])
            revert NotGranted();

        delete auditors[_auditor];
    }

    function grantProposer(address _newAddress) external onlyOwner {

        if(_newAddress == address(0))
            revert ZeroAddress();

        whiteListed[_newAddress] = true;
    }

    function revokeProposer(address _proposer) external onlyOwner {

        if(!whiteListed[_proposer])
            revert NotGranted();

        delete whiteListed[_proposer];
    }

    function changeTokenAddress(address _newToken) external onlyOwner {

        if(_newToken == address(0))
            revert ZeroAddress();

        paymentToken = IERC20(_newToken);
    }

    function changeProposalFee(uint _fee) external onlyOwner {

        if(_fee == 0)
            revert WrongInput();

        proposalFee = _fee;
    }

    function _requestForAudit(address _address) private view {

        if(projectProposals[_address].isVerified)
            revert AlreadyAuditRequested();
    }


}