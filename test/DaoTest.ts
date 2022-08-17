import {Contract, ContractFactory} from "ethers";
import { ethers, network} from 'hardhat';
import { expect, assert } from 'chai';
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import Web3 from "web3";

describe("Bridge contract test", function () {
    const web3 = new Web3();
    let daoCF: ContractFactory;
    let currencyCF: ContractFactory;
    let daoContract: Contract;
    let currencyContract: Contract;
    let addrs: SignerWithAddress[];

    enum VoteStatus{Active, FinishedPositive, FinishedNegative, Cancelled}


    beforeEach(async function() {
        currencyCF = await ethers.getContractFactory("CurrencyE20");
        currencyContract = await currencyCF.deploy();
        addrs = await ethers.getSigners();
        daoCF = await ethers.getContractFactory("Dao");
        daoContract = await daoCF.deploy(currencyContract.address, 110, 0);

        await currencyContract.mint(addrs[1].address, 100);
        await currencyContract.mint(addrs[2].address, 200);
        await currencyContract.connect(addrs[1]).approve(daoContract.address, 1000);
        await currencyContract.connect(addrs[2]).approve(daoContract.address, 1000);
        await daoContract.connect(addrs[1]).deposit(100);
        await daoContract.connect(addrs[2]).deposit(200);

        let signature = web3.eth.abi.encodeFunctionCall({
            "inputs": [
                {
                    "internalType": "bool",
                    "name": "val",
                    "type": "bool"
                }
            ],
            "name": "testCall",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        }, ["true"]);
        await daoContract.connect(addrs[0]).addProposal(signature, currencyContract.address, "sample vote");

    });



    describe("Transactions", function() {

        it("affirmative vote scenario", async function(){

            await daoContract.connect(addrs[1]).vote(0, false);
            await daoContract.connect(addrs[2]).vote(0, true);
            await daoContract.finishVote(0);
            expect(await currencyContract.flag()).to.equal(true);
        })

        it("negative vote scenario", async function(){

            await daoContract.connect(addrs[1]).vote(0, true);
            await daoContract.finishVote(0);
            let vote = await daoContract.votes(0);
            console.log(vote.status);
            console.log(vote);
            expect(vote.status).to.equal(3);
        })


    });
});