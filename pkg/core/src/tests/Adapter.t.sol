// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

import { ERC20 } from "@rari-capital/solmate/src/tokens/ERC20.sol";
import { FixedMath } from "../external/FixedMath.sol";

import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";

import { BaseAdapter } from "../adapters/BaseAdapter.sol";
import { Divider } from "../Divider.sol";

import { MockAdapter } from "./test-helpers/mocks/MockAdapter.sol";
import { MockToken } from "./test-helpers/mocks/MockToken.sol";
import { MockTarget } from "./test-helpers/mocks/MockTarget.sol";
import { TestHelper } from "./test-helpers/TestHelper.sol";

contract FakeAdapter is BaseAdapter {
    constructor(address _divider, BaseAdapter.AdapterParams memory _adapterParams)
        BaseAdapter(_divider, _adapterParams)
    {}

    function scale() external virtual override returns (uint256 _value) {
        return 100e18;
    }

    function scaleStored() external view virtual override returns (uint256) {
        return 100e18;
    }

    function wrapUnderlying(uint256 amount) external override returns (uint256) {
        return 0;
    }

    function unwrapTarget(uint256 amount) external override returns (uint256) {
        return 0;
    }

    function getUnderlyingPrice() external view override returns (uint256) {
        return 1e18;
    }

    function doSetAdapter(Divider d, address _adapter) public {
        d.setAdapter(_adapter, true);
    }
}

contract Adapters is TestHelper {
    using FixedMath for uint256;

    function testAdapterHasParams() public {
        MockToken underlying = new MockToken("Dai", "DAI", 18);
        MockTarget target = new MockTarget(address(underlying), "Compound Dai", "cDAI", 18);

        BaseAdapter.AdapterParams memory adapterParams = BaseAdapter.AdapterParams({
            target: address(target),
            underlying: target.underlying(),
            oracle: ORACLE,
            stake: address(stake),
            stakeSize: STAKE_SIZE,
            minm: MIN_MATURITY,
            maxm: MAX_MATURITY,
            mode: MODE,
            ifee: ISSUANCE_FEE,
            tilt: 0,
            level: DEFAULT_LEVEL
        });

        MockAdapter adapter = new MockAdapter(address(divider), adapterParams, rewardTokens);

        assertEq(adapter.rewardTokens(0), address(reward));
        assertEq(adapter.name(), "Compound Dai Adapter");
        assertEq(adapter.symbol(), "cDAI-adapter");
        assertEq(adapter.target(), address(target));
        assertEq(adapter.underlying(), address(underlying));
        assertEq(adapter.divider(), address(divider));
        assertEq(adapter.ifee(), ISSUANCE_FEE);
        assertEq(adapter.stake(), address(stake));
        assertEq(adapter.stakeSize(), STAKE_SIZE);
        assertEq(adapter.minm(), MIN_MATURITY);
        assertEq(adapter.maxm(), MAX_MATURITY);
        assertEq(adapter.oracle(), ORACLE);
        assertEq(adapter.mode(), MODE);
    }

    function testScale() public {
        assertEq(adapter.scale(), adapter.INITIAL_VALUE());
    }

    function testScaleMultipleTimes() public {
        assertEq(adapter.scale(), adapter.INITIAL_VALUE());
        assertEq(adapter.scale(), adapter.INITIAL_VALUE());
        assertEq(adapter.scale(), adapter.INITIAL_VALUE());
    }

    function testCantAddCustomAdapterToDivider() public {
        BaseAdapter.AdapterParams memory adapterParams = BaseAdapter.AdapterParams({
            target: address(target),
            underlying: target.underlying(),
            oracle: ORACLE,
            stake: address(stake),
            stakeSize: STAKE_SIZE,
            minm: MIN_MATURITY,
            maxm: MAX_MATURITY,
            mode: MODE,
            ifee: ISSUANCE_FEE,
            tilt: 0,
            level: DEFAULT_LEVEL
        });
        FakeAdapter fakeAdapter = new FakeAdapter(address(divider), adapterParams);

        try fakeAdapter.doSetAdapter(divider, address(fakeAdapter)) {
            fail();
        } catch Error(string memory err) {
            assertEq(err, "UNTRUSTED");
        }
    }

    // distribution tests
    function testDistribution() public {
        uint256 maturity = getValidMaturity(2021, 10);
        sponsorSampleSeries(address(alice), maturity);
        adapter.setScale(1e18);

        alice.doIssue(address(adapter), maturity, 60 * 1e18);
        bob.doIssue(address(adapter), maturity, 40 * 1e18);

        reward.mint(address(adapter), 50 * 1e18);

        alice.doIssue(address(adapter), maturity, 0 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(alice)), 30 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(bob)), 0 * 1e18);

        bob.doIssue(address(adapter), maturity, 0 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(alice)), 30 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(bob)), 20 * 1e18);

        alice.doIssue(address(adapter), maturity, 0 * 1e18);
        bob.doIssue(address(adapter), maturity, 0 * 1e18);

        assertClose(ERC20(reward).balanceOf(address(alice)), 30 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(bob)), 20 * 1e18);
    }

    function testDistributionSimple() public {
        uint256 maturity = getValidMaturity(2021, 10);
        (, address yt) = sponsorSampleSeries(address(alice), maturity);
        adapter.setScale(1e18);

        alice.doIssue(address(adapter), maturity, 100 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(alice)), 0 * 1e18);

        reward.mint(address(adapter), 10 * 1e18);

        alice.doIssue(address(adapter), maturity, 0 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(alice)), 10 * 1e18);

        alice.doIssue(address(adapter), maturity, 100 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(alice)), 10 * 1e18);

        alice.doCombine(address(adapter), maturity, ERC20(yt).balanceOf(address(alice)));
        assertClose(ERC20(reward).balanceOf(address(alice)), 10 * 1e18);

        alice.doIssue(address(adapter), maturity, 50 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(alice)), 10 * 1e18);

        reward.mint(address(adapter), 10 * 1e18);

        alice.doIssue(address(adapter), maturity, 10 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(alice)), 20 * 1e18);
    }

    function testDistributionProportionally() public {
        uint256 maturity = getValidMaturity(2021, 10);
        (, address yt) = sponsorSampleSeries(address(alice), maturity);
        adapter.setScale(1e18);

        alice.doIssue(address(adapter), maturity, 60 * 1e18);
        bob.doIssue(address(adapter), maturity, 40 * 1e18);

        reward.mint(address(adapter), 50 * 1e18);

        alice.doIssue(address(adapter), maturity, 0 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(alice)), 30 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(bob)), 0);

        bob.doIssue(address(adapter), maturity, 0 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(alice)), 30 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(bob)), 20 * 1e18);

        alice.doIssue(address(adapter), maturity, 0 * 1e18);
        bob.doIssue(address(adapter), maturity, 0 * 1e18);

        assertClose(ERC20(reward).balanceOf(address(alice)), 30 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(bob)), 20 * 1e18);

        reward.mint(address(adapter), 50e18);

        alice.doIssue(address(adapter), maturity, 20 * 1e18);
        bob.doIssue(address(adapter), maturity, 0 * 1e18);

        assertClose(ERC20(reward).balanceOf(address(alice)), 60 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(bob)), 40 * 1e18);

        reward.mint(address(adapter), 30 * 1e18);

        alice.doIssue(address(adapter), maturity, 0 * 1e18);
        bob.doIssue(address(adapter), maturity, 0 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(alice)), 80 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(bob)), 50 * 1e18);

        alice.doCombine(address(adapter), maturity, ERC20(yt).balanceOf(address(alice)));
    }

    function testDistributionSimpleCollect() public {
        uint256 maturity = getValidMaturity(2021, 10);
        (, address yt) = sponsorSampleSeries(address(alice), maturity);
        adapter.setScale(1e18);

        alice.doIssue(address(adapter), maturity, 60 * 1e18);
        bob.doIssue(address(adapter), maturity, 40 * 1e18);

        assertEq(reward.balanceOf(address(bob)), 0);

        reward.mint(address(adapter), 60 * 1e18);

        bob.doCollect(yt);
        assertClose(reward.balanceOf(address(bob)), 24 * 1e18);
    }

    function testDistributionCollectAndTransferMultiStep() public {
        uint256 maturity = getValidMaturity(2021, 10);
        (, address yt) = sponsorSampleSeries(address(alice), maturity);
        adapter.setScale(1e18);

        alice.doIssue(address(adapter), maturity, 60 * 1e18);
        // bob issues 40, now the pool is 40% bob and 60% alice
        bob.doIssue(address(adapter), maturity, 40 * 1e18);

        assertEq(reward.balanceOf(address(bob)), 0);

        // 60 reward tokens are aridropped before jim issues
        // 24 should go to bob and 36 to alice
        reward.mint(address(adapter), 60 * 1e18);
        hevm.warp(block.timestamp + 1 days);

        // jim issues 40, now the pool is 20% bob, 30% alice, and 50% jim
        jim.doIssue(address(adapter), maturity, 100 * 1e18);

        hevm.warp(block.timestamp + 1 days);
        // 100 more reward tokens are airdropped after jim has issued
        // 20 should go to bob, 30 to alice, and 50 to jim
        reward.mint(address(adapter), 100 * 1e18);

        // bob transfers all of his Yield to jim
        // now the pool is 70% jim and 30% alice
        bob.doTransfer(yt, address(jim), ERC20(yt).balanceOf(address(bob)));
        // bob collected on transfer, so he should now
        // have his 24 rewards from the first drop, and 20 from the second
        assertClose(reward.balanceOf(address(bob)), 44 * 1e18);

        // jim should have those 50 from the second airdrop (collected automatically when bob transferred to him)
        assertClose(reward.balanceOf(address(jim)), 50 * 1e18);

        // similarly, once alice collects, she should have her 36 fom the first airdrop and 30 from the second
        alice.doCollect(yt);
        assertClose(reward.balanceOf(address(alice)), 66 * 1e18);

        // now if another airdop happens, jim should get shares proportional to his new yt balance
        hevm.warp(block.timestamp + 1 days);
        // 100 more reward tokens are airdropped after bob has transferred to jim
        // 30 should go to alice and 70 to jim
        reward.mint(address(adapter), 100 * 1e18);
        jim.doCollect(yt);
        assertClose(reward.balanceOf(address(jim)), 120 * 1e18);
        alice.doCollect(yt);
        assertClose(reward.balanceOf(address(alice)), 96 * 1e18);
    }

    // test multiple rewards

    // TODO:
    // - tests with reward tokens different to 18 decimals
    // - testCantSetRewardTokens
    // - test distribution mlutiple rewards when reward is added in the middle
    // - test distribution mlutiple rewards when reward token removed

    function testSetRewardsTokens() public {
        MockToken reward2 = new MockToken("Reward Token 2", "RT2", 18);
        rewardTokens.push(address(reward2));

        hevm.startPrank(address(factory)); // only factory can call `setRewardTokens` as it was deployed via factory
        adapter.setRewardTokens(rewardTokens);

        assertEq(rewardTokens.length, 2);
        assertEq(rewardTokens.length, 5555);
        assertEq(rewardTokens[0], address(reward));
        assertEq(rewardTokens[1], address(reward2));
    }

    function testCantSetRewardsTokens() public {
        MockToken reward2 = new MockToken("Reward Token 2", "RT2", 18);
        rewardTokens.push(address(reward2));
        try adapter.setRewardTokens(rewardTokens) {
            fail();
        } catch Error(string memory err) {
            assertEq(err, "UNTRUSTED");
        }
    }

    function testDistributionMultipleRewards() public {
        // add new reward token
        MockToken reward2 = new MockToken("Reward Token 2", "RT2", 18);
        rewardTokens.push(address(reward2));

        hevm.startPrank(address(factory));
        adapter.setRewardTokens(rewardTokens);

        uint256 maturity = getValidMaturity(2021, 10);
        sponsorSampleSeries(address(alice), maturity);
        adapter.setScale(1e18);

        alice.doIssue(address(adapter), maturity, 60 * 1e18);
        bob.doIssue(address(adapter), maturity, 40 * 1e18);

        reward.mint(address(adapter), 50 * 1e18);
        reward2.mint(address(adapter), 100 * 1e18);

        alice.doIssue(address(adapter), maturity, 0 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(alice)), 30 * 1e18);
        assertClose(ERC20(reward2).balanceOf(address(alice)), 60 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(bob)), 0 * 1e18);
        assertClose(ERC20(reward2).balanceOf(address(bob)), 0 * 1e18);

        bob.doIssue(address(adapter), maturity, 0 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(alice)), 30 * 1e18);
        assertClose(ERC20(reward2).balanceOf(address(alice)), 60 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(bob)), 20 * 1e18);
        assertClose(ERC20(reward2).balanceOf(address(bob)), 40 * 1e18);

        alice.doIssue(address(adapter), maturity, 0 * 1e18);
        bob.doIssue(address(adapter), maturity, 0 * 1e18);

        assertClose(ERC20(reward).balanceOf(address(alice)), 30 * 1e18);
        assertClose(ERC20(reward2).balanceOf(address(alice)), 60 * 1e18);
        assertClose(ERC20(reward).balanceOf(address(bob)), 20 * 1e18);
        assertClose(ERC20(reward2).balanceOf(address(bob)), 40 * 1e18);
    }

    // wrap/unwrap tests
    function testWrapUnderlying() public {
        uint256 uBal = 100 * (10**underlying.decimals());
        uint256 tBal = 100 * (10**target.decimals());
        underlying.mint(address(alice), uBal);
        adapter.setScale(1e18);
        adapter.scale();

        alice.doApprove(address(underlying), address(adapter));
        uint256 tBalReceived = alice.doAdapterWrapUnderlying(address(adapter), uBal);
        assertEq(tBal, tBalReceived);
    }

    function testUnwrapTarget() public {
        uint256 tBal = 100 * (10**target.decimals());
        uint256 uBal = 100 * (10**underlying.decimals());
        target.mint(address(alice), tBal);
        adapter.setScale(1e18);
        adapter.scale();

        alice.doApprove(address(target), address(adapter));
        uint256 uBalReceived = alice.doAdapterUnwrapTarget(address(adapter), tBal);
        assertEq(uBal, uBalReceived);
    }
}
