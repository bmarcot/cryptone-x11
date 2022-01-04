import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { ContractTransaction } from 'ethers';
import { ethers } from 'hardhat';
import { CryptoneX11, CryptoneX11__factory } from '../typechain';

describe('CryptoneX11', function () {
    const BASE_TOKEN_URI = 'ipfs://abc/';
    const MAX_SUPPLY = 145;
    const UNIT_PRICE = ethers.utils.parseEther('0.01');

    let cryptone: CryptoneX11;
    let owner: SignerWithAddress;
    let addr1: SignerWithAddress;
    let addr2: SignerWithAddress;
    let addrs: SignerWithAddress[];

    beforeEach(async () => {
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

        const cryptoneFactory = (await ethers.getContractFactory(
            'CryptoneX11'
        )) as CryptoneX11__factory;
        cryptone = await cryptoneFactory
            .deploy(BASE_TOKEN_URI)
            .then((_cryptone) => _cryptone.deployed());
    });

    describe('Contract', () => {
        it('Is owned', async () => {
            expect(await cryptone.owner()).to.equal(owner.address);
        });

        it('Has zero initial balance', async () => {
            expect(
                await cryptone.provider.getBalance(cryptone.address)
            ).to.equal(0);
        });
    });

    describe('Token', () => {
        it('Is mintable by anyone', async () => {
            await expect(
                cryptone.connect(addr1).mint(owner.address, {
                    value: UNIT_PRICE,
                })
            ).to.not.be.reverted;
        });

        it('Is ownable', async () => {
            await cryptone.mint(owner.address, {
                value: UNIT_PRICE,
            });

            expect(await cryptone.balanceOf(owner.address)).to.equal(1);
        });

        it('Is not mintable if value of transaction is below price ', async () => {
            await expect(cryptone.mint(owner.address)).to.be.revertedWith(
                'Not enough ether to purchase'
            );
        });

        it('Has tokenId starting at index 1', async () => {
            expect(
                await cryptone.callStatic.mint(owner.address, {
                    value: UNIT_PRICE,
                })
            ).to.equal(1);
        });

        it('Returns the correct tokenURI', async () => {
            await cryptone.mint(owner.address, {
                value: UNIT_PRICE,
            });

            expect(await cryptone.tokenURI(1)).to.equal(`${BASE_TOKEN_URI}1`);
        });

        it('Is transferable', async () => {
            await cryptone.mint(owner.address, {
                value: UNIT_PRICE,
            });

            await cryptone['safeTransferFrom(address,address,uint256)'](
                owner.address,
                addr1.address,
                1
            );

            expect(await cryptone.balanceOf(owner.address)).to.equal(0);
            expect(await cryptone.balanceOf(addr1.address)).to.equal(1);
            expect(await cryptone.ownerOf(1)).to.equal(addr1.address);
        });
    });

    describe('Transaction', () => {
        it('Credits the contract', async () => {
            await expect(
                await cryptone.mint(owner.address, {
                    value: UNIT_PRICE,
                })
            ).to.changeEtherBalance(
                await ethers.getSigner(cryptone.address),
                UNIT_PRICE
            );
        });
    });

    describe('Balance', () => {
        beforeEach(async () => {
            await cryptone.mint(owner.address, {
                value: UNIT_PRICE,
            });
        });

        it('Is withdrawable by owner', async () => {
            await expect(await cryptone.withdraw()).to.changeEtherBalance(
                owner,
                UNIT_PRICE
            );
        });

        it('Is not withdrawable by anyone', async () => {
            await expect(cryptone.connect(addr1).withdraw()).to.be.reverted;
        });
    });

    describe('Supply', () => {
        let ps: Promise<ContractTransaction>[];

        beforeEach(async () => {
            ps = [...Array(MAX_SUPPLY)].map(() =>
                cryptone.mint(owner.address, {
                    value: UNIT_PRICE,
                })
            );
        });

        it('Is total', async () => {
            ps.map(async (p) => {
                await expect(p).to.not.be.reverted;
            });
        });

        it('Is limited', async () => {
            await Promise.all(ps).then(async () => {
                await expect(
                    cryptone.mint(owner.address, {
                        value: UNIT_PRICE,
                    })
                ).to.be.revertedWith('Max supply reached');
            });
        });
    });
});
