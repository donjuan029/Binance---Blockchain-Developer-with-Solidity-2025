// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleDAO {

    struct Proposal {
        string description;
        uint256 voteYes;
        uint256 voteNo;
        uint256 deadline;
        bool executed;
        address payable recipient;
        uint256 amount;
    }

    mapping(address => bool) public members;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    Proposal[] public proposals;
    address public owner;

    modifier onlyMember() {
        require(members[msg.sender], "Nao e membro da DAO");
        _;
    }

    constructor() {
        owner = msg.sender;
        members[msg.sender] = true;
    }

    // Adiciona novos membros (ex: DAO privada)
    function addMember(address _member) external {
        require(msg.sender == owner, "Apenas o criador pode adicionar");
        members[_member] = true;
    }

    // Criar proposta
    function createProposal(
        string memory _description,
        address payable _recipient,
        uint256 _amount,
        uint256 _duration
    ) external onlyMember {
        proposals.push(
            Proposal({
                description: _description,
                voteYes: 0,
                voteNo: 0,
                deadline: block.timestamp + _duration,
                executed: false,
                recipient: _recipient,
                amount: _amount
            })
        );
    }

    // Votar
    function vote(uint256 _proposalId, bool _support) external onlyMember {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp < proposal.deadline, "Votacao encerrada");
        require(!hasVoted[_proposalId][msg.sender], "Ja votou");

        hasVoted[_proposalId][msg.sender] = true;

        if (_support) {
            proposal.voteYes++;
        } else {
            proposal.voteNo++;
        }
    }

    // Executar proposta
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp >= proposal.deadline, "Ainda em votacao");
        require(!proposal.executed, "Ja executada");
        require(proposal.voteYes > proposal.voteNo, "Proposta rejeitada");
        require(address(this).balance >= proposal.amount, "Saldo insuficiente");

        proposal.executed = true;
        proposal.recipient.transfer(proposal.amount);
    }

    // Receber ETH
    receive() external payable {}
}
