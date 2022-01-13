const { expect, assert } = require("chai");
const { ethers, waffle } = require("hardhat");

describe("Game", function () {

  const provider = waffle.provider;

  const Election = Object.freeze({
    Empty:   Symbol("Empty"),
    Rock:  Symbol("Rock"),
    Paper: Symbol("Paper"),
    Scissors: Symbol("Scissors")
});

  before(async function(){
    [this.contrato, this.tomi, this.luisito] = await hre.ethers.getSigners();
    const Game = await hre.ethers.getContractFactory("RockPaperScissor");
    this.contract = await Game.deploy();
    await this.contract.deployed();
    this.cTom = await this.contract.connect(this.tomi);
    this.cLuisito = await this.contract.connect(this.luisito);

    await this.cTom.initGame({ value: ethers.utils.parseEther("100") })
    await this.cLuisito.initGame({ value: ethers.utils.parseEther("100") });
  })

  it('Check player 1 init', async function(){
    const p1 = await this.contract.player1();
    expect(p1).to.equal(this.tomi.address);
  })

  it('Check player 2 init', async function(){
    const p2 = await this.contract.player2();
    expect(p2).to.equal(this.luisito.address);
  })

  it('Check both players plays', async function(){
    const playTom = await this.cTom.playGame("tomi", 1);
    const playLu = await this.cLuisito.playGame("luisito", 2);
    expect(await this.contract.bothPlayersPlay()).to.be.equal(true);
  })

  it('Check both players reveal and finish game', async function(){
    await this.cTom.reveal("tomi",1)
    await this.cLuisito.reveal("luisito",2)
    assert.isOk('Ok','Ok')
  })

  it('Check finishGame', async function(){
    const result = await this.contract.finishGame();
    assert.isOk('Ok','Ok')
  })

  it('Check player win', async function(){
    expect(await this.contract._winner()).to.equal(this.luisito.address);
  })

  it('Check balance', async function(){
    balance0ETH = await provider.getBalance(this.tomi.address);
    balance1ETH = await provider.getBalance(this.luisito.address);
    const result = ethers.utils.formatEther(balance1ETH).split('.')[0];

    expect(result).to.equal('10099');
  })
});
