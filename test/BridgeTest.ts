import {Contract, ContractFactory} from "ethers";
import { ethers, network} from 'hardhat';
import { expect, assert } from 'chai';
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";

describe("Bridge contract test", function () {
    let bridgeCF: ContractFactory;
    let currencyCF: ContractFactory;
    let bridgeContract: Contract;
    let currencyContract: Contract;
    let addrs: SignerWithAddress[];


    beforeEach(async function() {
        currencyCF = await ethers.getContractFactory("CurrencyE20");
        currencyContract = await currencyCF.deploy();
        addrs = await ethers.getSigners();
        bridgeCF = await ethers.getContractFactory("Bridge");
        bridgeContract = await bridgeCF.deploy(addrs[1].address, currencyContract.address);

    });



    describe("Transactions", function() {

        it("should bridge correctly", async function(){
            await currencyContract.mint(addrs[2].address, 100);
            expect(await currencyContract.balanceOf(addrs[2].address)).to.equal(100);
            await currencyContract.connect(addrs[2]).approve(bridgeContract.address, 1000);



            await bridgeContract.connect(addrs[2]).swap(addrs[3].address, 100);
            expect(await currencyContract.balanceOf(addrs[2].address)).to.equal(0);
            let msg = ethers.utils.solidityKeccak256(
                ["address", "uint256"],
                    [addrs[3].address, 100]);
            let signature = await addrs[1].signMessage(msg);
            let sig = await ethers.utils.splitSignature(signature);


            await bridgeContract.redeem(addrs[3].address, 100, sig.v, sig.r, sig.s);

            expect(await currencyContract.balanceOf(addrs[3].address)).to.equal(100);
        })
    });
});