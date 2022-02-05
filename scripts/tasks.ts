import { task } from 'hardhat/config';
import { Contract } from 'ethers';
import { TransactionResponse } from '@ethersproject/abstract-provider';
import { env } from './lib/env';
import { getContract } from './lib/contract';

task('deploy-contract', 'Deploy the CryptoneX11 contract').setAction(
    async (_, hre) => {
        const BASE_TOKEN_URI =
            'ipfs://QmWrzgPNvKqRAW96hztUwc6ZHsutkri4GwThzxvMYbNLMm/';
        //'https://gateway.pinata.cloud/ipfs/QmULTZGBLMUQLi4fAS7gqVWHyi1cGUs5ZC5Hb1tJPqv6ts/';

        return hre.ethers
            .getContractFactory('CryptoneX11')
            .then(
                async (contractFactory) =>
                    await contractFactory.deploy(BASE_TOKEN_URI)
            )
            .then(async (cryptone) => await cryptone.deployed())
            .then((cryptone) => {
                //console.log(`hre network ${hre.network.name}`);

                process.stdout.write(`Contract address: ${cryptone.address}\n`);
            });
    }
);

task('mint-nft', 'Mint a NFT').setAction(async (_, hre) => {
    return getContract('CryptoneX11', hre)
        .then(async (contract: Contract) => {
            const NFT_UNIT_PRICE = hre.ethers.utils.parseEther('0.01');

            let recipient: string;

            if (hre.network.name === 'localhost') {
                const [_, _recipient] = await hre.ethers.getSigners();
                recipient = _recipient.address;
            } else {
                recipient = env('ETH_PUBLIC_KEY');
            }

            return contract.mint(recipient, {
                value: NFT_UNIT_PRICE,
                gasLimit: 500_000,
            });
        })
        .then((tr: TransactionResponse) => {
            process.stdout.write(`TX hash: ${tr.hash}\n`);
        });
});

task('withdraw', 'Withdraw balance').setAction(async (_, hre) => {
    return getContract('CryptoneX11', hre).then(async (contract: Contract) => {
        await contract.withdraw();
    });
});
