//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract RockPaperScissor{ 
    enum Election { Empty, Rock, Paper, Scissors }

    struct Move{
        bytes32 electionEncrypt;
        Election move;
    }

    mapping(Election => mapping(Election => uint8)) public results;
    mapping(address => Move) private playerMove;

    uint256 private initial_bet = 0;
    address payable public player1;
    address payable public player2;
    address payable public _winner;
    bool private in_live = false;

    uint private start = 0;
    uint constant bet_min = 1;
    uint constant time = 120;

    event finish(address);
    
    /**************************************************************************/
    /*************************** MODIFIERS ***************************/
    /**************************************************************************/

    modifier _isLive(){
        require(in_live);
        _;
    }
    
    modifier _adversaryElection(address payable player){
        if(player1 == player)
            require(playerMove[player2].electionEncrypt != "");

        if(player2 == player)
            require(playerMove[player1].electionEncrypt != "");

        _;
    }

    modifier betOkey(){
        require(msg.value > bet_min);
        require(initial_bet == 0 || initial_bet == msg.value);
        _;
    }

    modifier timeOver(){
        require(start + time > block.timestamp, "time is over");
        _;
    }

    /**************************************************************************/
    /*************************** CONFING PHASE ***************************/
    /**************************************************************************/

    constructor(){
        _configGame();
    }

    function _configGame() private {
        results[Election.Rock][Election.Scissors] = 1;
        results[Election.Rock][Election.Paper] = 2;
        results[Election.Paper][Election.Rock] = 1;
        results[Election.Paper][Election.Scissors] = 2;
        results[Election.Scissors][Election.Paper] = 1;
        results[Election.Scissors][Election.Rock] = 2;
        results[Election.Rock][Election.Rock] = 3;
        results[Election.Scissors][Election.Scissors] = 3;
        results[Election.Paper][Election.Paper] = 3;
    } 

    /**************************************************************************/
    /*************************** INITIAL PHASE ***************************/
    /**************************************************************************/

    function initGame() public payable betOkey returns(bool){
        initial_bet = msg.value;
        if(player1 == address(0))
            player1 = payable(msg.sender);
        else if(player2 == address(0))
            player2 = payable(msg.sender);
        if(!in_live)
            in_live = true;

        return true;
    }

    /**************************************************************************/
    /*************************** PLAY PHASE ***************************/
    /**************************************************************************/

    function encryptElection(string calldata _password, Election _move) private view returns(bytes32) {
        return keccak256(abi.encodePacked(address(this), _password, _move));
    }

    function playGame(string calldata _password, uint _move) public{
        if(start == 0)
            start = block.timestamp;
        playerMove[msg.sender] = Move(encryptElection(_password, Election(_move)), Election.Empty);
    }

    /**************************************************************************/
    /*************************** REVEAL PHASE ***************************/
    /**************************************************************************/

    function reveal(string calldata _password, Election _move) public _isLive _adversaryElection(payable(msg.sender)) timeOver returns(bool){
        _isSameElection(_password, _move);
        return true;
    }

    function _isSameElection(string calldata _password, Election _move) private{
        require(_move != Election.Empty);
        require(encryptElection(_password, _move) == playerMove[msg.sender].electionEncrypt);
        playerMove[msg.sender].move = _move;
    }

    /**************************************************************************/
    /*************************** FINISH PHASE ***************************/
    /**************************************************************************/

    function finishGame() public{
        _finishGame();
    }

    function _finishGame() private returns(bool){
        //matchs.push(Match(player1,playerMove[player1].move,player2,playerMove[player2].move,results[playerMove[player1].move][playerMove[player2].move],pool));
        _selectWinner();
        address payable _from = _winner;
        //_reset();
        if(_from != address(0))
            pay(_from);
        in_live = false;
        return true;
        //emit finish(_from);        
    }

    function _reset() private{
        player1 = payable(address(0));
        player2 = payable(address(0));
        _winner = payable(address(0));
        start = 0;
        initial_bet = 0;
    }

    function _selectWinner() private {
        if(results[playerMove[player1].move][playerMove[player2].move] == 1)
            _winner = player1;
        else if(results[playerMove[player1].move][playerMove[player2].move] == 2)
            _winner = player2;
        else
            _winner = payable(address(0));
    }

    function pay(address payable from) public payable{
        from.transfer(address(this).balance);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function timeLeft() public view returns(uint){
        return block.timestamp - (start + time);
    }

    function startTime()public view returns(uint){
        return start;
    }

    function bothPlayersPlay() public view returns(bool){
        if(playerMove[player1].electionEncrypt != "" && playerMove[player2].electionEncrypt != "")
            return true;

        return false;
    }
}