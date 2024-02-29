//SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.0.0;

contract Lottery {
    address payable[] public players;
    //declare array of type address payable - players
    address public manager;

    constructor() {
        manager = msg.sender;
        //address that deploys the contract
    }

    //receive ETH
    receive() payable external {
        require(msg.value == 0.1 ether); //player have to send exactly 0.1ETH
        players.push(payable(msg.sender));
    }

    //Get contract's balance
    //require manager
    function getBalance() public view returns(uint) {
        require(msg.sender == manager);
        return address(this).balance;
    }

    //a big random integer
    function random() internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, players.length)));
    }

    //Choose the winner
    function pickWinner() public {
        require(msg.sender == manager);
        require(players.length >= 3);
        uint ran = random();
        address payable winner;
        uint win_index = ran % players.length;
        winner = players[win_index];
        winner.transfer(getBalance()); // transfer contract's balane to the winner

        players = new address payable[](0); //reset game
    }
}
