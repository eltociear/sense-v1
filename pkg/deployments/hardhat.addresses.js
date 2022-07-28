const CHAINS = {
    MAINNET: 1,
    GOERLI: 5,
    HARDHAT: 111,
    ARBITRUM: 42161,
}

// For dev scenarios ------------

// ------------------------------------

// For mainnet scenarios ------------

const DIVIDER_CUP = new Map();
DIVIDER_CUP.set("1", "0x6C4f62b3187bC7e8A8f948Bb50ABec694719D8d3"); // Sense multisig
DIVIDER_CUP.set("111", "0x6C4f62b3187bC7e8A8f948Bb50ABec694719D8d3");
// TODO: Arbitrum

const SENSE_MULTISIG = new Map();
SENSE_MULTISIG.set("1", "0xDd76360C26Eaf63AFCF3a8d2c0121F13AE864D57");
SENSE_MULTISIG.set("5", "0xf13519734649f7464e5be4aa91987a35594b2b16");
SENSE_MULTISIG.set("111", "0xDd76360C26Eaf63AFCF3a8d2c0121F13AE864D57");
// TODO(launch): Arbitrum

COMP_TOKEN = new Map();
COMP_TOKEN.set("1", "0xc00e94cb662c3520282e6f5717214004a7f26888");
COMP_TOKEN.set("111", "0xc00e94cb662c3520282e6f5717214004a7f26888");
// TODO: Arbitrum

const DAI_TOKEN = new Map();
DAI_TOKEN.set("1", "0x6b175474e89094c44da98b954eedeac495271d0f");
DAI_TOKEN.set("111", "0x6b175474e89094c44da98b954eedeac495271d0f");
// TODO: Arbitrum

const CDAI_TOKEN = new Map();
CDAI_TOKEN.set("1", "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643");
CDAI_TOKEN.set("111", "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643");
// TODO: Arbitrum

const WETH_TOKEN = new Map();
WETH_TOKEN.set("1", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2");
WETH_TOKEN.set("5", "0xffc94fb06b924e6dba5f0325bbed941807a018cd");
WETH_TOKEN.set("42", "0xa1C74a9A3e59ffe9bEe7b85Cd6E91C0751289EbD");
WETH_TOKEN.set("111", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2");
// TODO: Arbitrum

const CUSDC_TOKEN = new Map();
CUSDC_TOKEN.set("1", "0x39AA39c021dfbaE8faC545936693aC917d5E7563");
CUSDC_TOKEN.set("111", "0x39AA39c021dfbaE8faC545936693aC917d5E7563");
// TODO: Arbitrum

const CUSDT_TOKEN = new Map();
CUSDT_TOKEN.set("1", "0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9");
CUSDT_TOKEN.set("111", "0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9");
// TODO: Arbitrum

const WSTETH_TOKEN = new Map();
WSTETH_TOKEN.set("1", "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0");
WSTETH_TOKEN.set("111", "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0");
// TODO: Arbitrum

const STETH_TOKEN = new Map();
STETH_TOKEN.set("1", "0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84");
STETH_TOKEN.set("111", "0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84");
// TODO: Arbitrum

const F18DAI_TOKEN = new Map();
F18DAI_TOKEN.set("1", "0x8E4E0257A4759559B4B1AC087fe8d80c63f20D19");
F18DAI_TOKEN.set("111", "0x8E4E0257A4759559B4B1AC087fe8d80c63f20D19");

const OLYMPUS_POOL_PARTY = new Map();
OLYMPUS_POOL_PARTY.set("1", "0x621579DD26774022F33147D3852ef4E00024b763");
OLYMPUS_POOL_PARTY.set("111", "0x621579DD26774022F33147D3852ef4E00024b763");

const F156FRAX3CRV_TOKEN = new Map();
F156FRAX3CRV_TOKEN.set("1", "0x2ec70d3Ff3FD7ac5c2a72AAA64A398b6CA7428A5");
F156FRAX3CRV_TOKEN.set("111", "0x2ec70d3Ff3FD7ac5c2a72AAA64A398b6CA7428A5");

const FRAX3CRV_TOKEN = new Map();
FRAX3CRV_TOKEN.set("1", "0xd632f22692fac7611d2aa1c0d552930d43caed3b");
FRAX3CRV_TOKEN.set("111", "0xd632f22692fac7611d2aa1c0d552930d43caed3b");
// TODO: Arbitrum

const CONVEX_TOKEN = new Map();
CONVEX_TOKEN.set("1", "0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b");
CONVEX_TOKEN.set("111", "0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b");
// TODO: Arbitrum

const CRV_TOKEN = new Map();
CRV_TOKEN.set("1", "0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b");
CRV_TOKEN.set("111", "0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b");
// TODO: Arbitrum

const TRIBE_CONVEX = new Map();
TRIBE_CONVEX.set("1", "0x07cd53380FE9B2a5E64099591b498c73F0EfaA66");
TRIBE_CONVEX.set("111", "0x07cd53380FE9B2a5E64099591b498c73F0EfaA66");
// TODO: Arbitrum

const REWARDS_DISTRIBUTOR_CVX = new Map();
REWARDS_DISTRIBUTOR_CVX.set("1", "0x18B9aE8499e560bF94Ef581420c38EC4CfF8559C");
REWARDS_DISTRIBUTOR_CVX.set("111", "0x18B9aE8499e560bF94Ef581420c38EC4CfF8559C");
// TODO: Arbitrum

const REWARDS_DISTRIBUTOR_CRV = new Map();
REWARDS_DISTRIBUTOR_CRV.set("1", "0xd533a949740bb3306d119cc777fa900ba034cd52");
REWARDS_DISTRIBUTOR_CRV.set("111", "0xd533a949740bb3306d119cc777fa900ba034cd52");
// TODO: Arbitrum

const FUSE_POOL_DIR = new Map();
FUSE_POOL_DIR.set("1", "0x835482FE0532f169024d5E9410199369aAD5C77E");
FUSE_POOL_DIR.set("111", "0x835482FE0532f169024d5E9410199369aAD5C77E");
// TODO: Arbitrum

const FUSE_COMPTROLLER_IMPL = new Map();
FUSE_COMPTROLLER_IMPL.set("1", "0xE16DB319d9dA7Ce40b666DD2E365a4b8B3C18217");
FUSE_COMPTROLLER_IMPL.set("111", "0xE16DB319d9dA7Ce40b666DD2E365a4b8B3C18217");
// TODO: Arbitrum

const FUSE_CERC20_IMPL = new Map();
FUSE_CERC20_IMPL.set("1", "0x67db14e73c2dce786b5bbbfa4d010deab4bbfcf9");
FUSE_CERC20_IMPL.set("111", "0x67db14e73c2dce786b5bbbfa4d010deab4bbfcf9");

const MASTER_ORACLE_IMPL = new Map();
MASTER_ORACLE_IMPL.set("1", "0xb3c8ee7309be658c186f986388c2377da436d8fb");
MASTER_ORACLE_IMPL.set("111", "0xb3c8ee7309be658c186f986388c2377da436d8fb");

const MASTER_ORACLE = new Map();
MASTER_ORACLE.set("1", "0x1887118E49e0F4A78Bd71B792a49dE03504A764D");
MASTER_ORACLE.set("111", "0x1887118E49e0F4A78Bd71B792a49dE03504A764D");

const COMPOUND_PRICE_FEED = new Map();
COMPOUND_PRICE_FEED.set("1", "0x6D2299C48a8dD07a872FDd0F8233924872Ad1071");
COMPOUND_PRICE_FEED.set("111", "0x6D2299C48a8dD07a872FDd0F8233924872Ad1071");

const INTEREST_RATE_MODEL = new Map();
// 0x640dce7c7c6349e254b20eccfa2bb902b354c317 = JumpRateModel_Compound_Stables
INTEREST_RATE_MODEL.set("1", "0x640dce7c7c6349e254b20eccfa2bb902b354c317");
INTEREST_RATE_MODEL.set("111", "0x640dce7c7c6349e254b20eccfa2bb902b354c317");

const BALANCER_VAULT = new Map();
BALANCER_VAULT.set("1", "0xBA12222222228d8Ba445958a75a0704d566BF2C8");
BALANCER_VAULT.set("111", "0xBA12222222228d8Ba445958a75a0704d566BF2C8");

const OZ_RELAYER = new Map();
OZ_RELAYER.set("1", "0xe09fe5acb74c1d98507f87494cf6adebd3b26b1e");
OZ_RELAYER.set("5", "0x19f3bf5d7f8a58945da80eaa4131df2958f7aa4a");
OZ_RELAYER.set("111", "0xe09fe5acb74c1d98507f87494cf6adebd3b26b1e");

exports.COMP_TOKEN = COMP_TOKEN;
exports.DAI_TOKEN = DAI_TOKEN;
exports.CDAI_TOKEN = CDAI_TOKEN;
exports.CUSDC_TOKEN = CUSDC_TOKEN;
exports.CUSDT_TOKEN = CUSDT_TOKEN;
exports.WETH_TOKEN = WETH_TOKEN;
exports.WSTETH_TOKEN = WSTETH_TOKEN;
exports.STETH_TOKEN = STETH_TOKEN;
exports.F18DAI_TOKEN = F18DAI_TOKEN;
exports.OLYMPUS_POOL_PARTY = OLYMPUS_POOL_PARTY;
exports.F156FRAX3CRV_TOKEN = F156FRAX3CRV_TOKEN;
exports.FRAX3CRV_TOKEN = FRAX3CRV_TOKEN;
exports.DIVIDER_CUP = DIVIDER_CUP;
exports.FUSE_POOL_DIR = FUSE_POOL_DIR;
exports.FUSE_COMPTROLLER_IMPL = FUSE_COMPTROLLER_IMPL;
exports.FUSE_CERC20_IMPL = FUSE_CERC20_IMPL;
exports.MASTER_ORACLE_IMPL = MASTER_ORACLE_IMPL;
exports.MASTER_ORACLE = MASTER_ORACLE;
exports.COMPOUND_PRICE_FEED = COMPOUND_PRICE_FEED;
exports.INTEREST_RATE_MODEL = INTEREST_RATE_MODEL;
exports.BALANCER_VAULT = BALANCER_VAULT;
exports.OZ_RELAYER = OZ_RELAYER;
exports.SENSE_MULTISIG = SENSE_MULTISIG;
exports.CONVEX_TOKEN = CONVEX_TOKEN;
exports.CRV_TOKEN = CRV_TOKEN;
exports.TRIBE_CONVEX = TRIBE_CONVEX;
exports.REWARDS_DISTRIBUTOR_CVX = REWARDS_DISTRIBUTOR_CVX;
exports.REWARDS_DISTRIBUTOR_CRV = REWARDS_DISTRIBUTOR_CRV;
exports.CHAINS = CHAINS;
// ------------------------------------
