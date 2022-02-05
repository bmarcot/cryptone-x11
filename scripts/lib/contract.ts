import { Contract } from 'ethers';
import { getContractAt } from '@nomiclabs/hardhat-ethers/internal/helpers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { env } from './env';

export const getContract = (
    name: string,
    hre: HardhatRuntimeEnvironment
): Promise<Contract> => {
    if (hre.network.name === 'localhost')
        return getContractAt(hre, name, env('LOCALHOST_NFT_CONTRACT_ADDRESS'));
    if (hre.network.name === 'rinkeby')
        return getContractAt(hre, name, env('RINKEBY_NFT_CONTRACT_ADDRESS'));

    return getContractAt(hre, name, env('NFT_CONTRACT_ADDRESS'));
};
