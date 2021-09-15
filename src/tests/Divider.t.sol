pragma solidity ^0.8.6;

import "./test-helpers/divider/DividerTest.sol";
import "./test-helpers/TestToken.sol";
import "./test-helpers/TestFeed.sol";
import "../external/DateTime.sol";
import "../tokens/Claim.sol";
import "../tokens/BaseToken.sol";

contract Divide is DividerTest {
    using WadMath for uint256;
    using Errors for string;

    address[] accounts;
    uint256[] values;

    /* ========== initSeries() tests ========== */

    function testCantInitSeriesNotEnoughStakeBalance() public {
        uint256 balance = stableToken.balanceOf(address(alice));
        alice.doTransfer(address(bob), balance - INIT_STAKE / 2);
        uint256 maturity = getValidMaturity(2021, 10);
        try alice.doInitSeries(address(feed), maturity) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.AmountExceedsBalance);
        }
    }

    function testCantInitSeriesNotEnoughStakeAllowance() public {
        alice.doApproveStable(address(divider), 0);
        uint256 maturity = getValidMaturity(2021, 10);
        try alice.doInitSeries(address(feed), maturity) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.AllowanceNotEnough);
        }
    }

    function testCantInitSeriesFeedNotEnabled() public {
        uint256 maturity = getValidMaturity(2021, 10);
        gov.doSetFeed(address(feed), false);
        try alice.doInitSeries(address(feed), maturity) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.InvalidFeed);
        }
    }

    function testCantInitSeriesIfAlreadyExists() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        try alice.doInitSeries(address(feed), maturity) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.DuplicateSeries);
        }
    }

    function testCantInitSeriesActiveSeriesReached() public {
        uint256 SERIES_TO_INIT = 3;
        for (uint256 i = 1; i <= SERIES_TO_INIT; i++) {
            uint256 nextMonthDate = DateTime.addMonths(block.timestamp, i);
            nextMonthDate = getValidMaturity(DateTime.getYear(nextMonthDate), DateTime.getMonth(nextMonthDate));
            (address zero, address claim) = initSampleSeries(address(alice), nextMonthDate);
            assertTrue(address(zero) != address(0));
            assertTrue(address(claim) != address(0));
        }
        uint256 lastDate = DateTime.addMonths(block.timestamp, SERIES_TO_INIT + 1);
        lastDate = getValidMaturity(DateTime.getYear(lastDate), DateTime.getMonth(lastDate));
        try alice.doInitSeries(address(feed), lastDate) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.InvalidMaturity);
        }
    }

    function testCantInitSeriesWithMaturityBeforeTimestamp() public {
        uint256 maturity = DateTime.timestampFromDateTime(2021, 8, 1, 0, 0, 0);
        try alice.doInitSeries(address(feed), maturity) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.InvalidMaturity);
        }
    }

    function testCantInitSeriesLessThanMinMaturity() public {
        hevm.warp(1631923200);
        // 18-09-21 00:00 UTC
        uint256 maturity = DateTime.timestampFromDateTime(2021, 10, 1, 0, 0, 0);
        try alice.doInitSeries(address(feed), maturity) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.InvalidMaturity);
        }
    }

    function testCantInitSeriesMoreThanMaxMaturity() public {
        hevm.warp(1631664000);
        // 15-09-21 00:00 UTC
        uint256 maturity = DateTime.timestampFromDateTime(2022, 1, 1, 0, 0, 0);
        try alice.doInitSeries(address(feed), maturity) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.InvalidMaturity);
        }
    }

    function testInitSeries() public {
        uint256 maturity = getValidMaturity(2021, 10);
        (address zero, address claim) = initSampleSeries(address(alice), maturity);
        assertTrue(address(zero) != address(0));
        assertTrue(address(claim) != address(0));
        // TODO: check names
    }

    function testInitSeriesWithdrawStake() public {
        uint256 maturity = getValidMaturity(2021, 10);
        uint256 beforeBalance = stableToken.balanceOf(address(alice));
        (address zero, address claim) = initSampleSeries(address(alice), maturity);
        assertTrue(address(zero) != address(0));
        assertTrue(address(claim) != address(0));
        uint256 afterBalance = stableToken.balanceOf(address(alice));
        assertEq(afterBalance, beforeBalance - INIT_STAKE);
    }

    function testInitThreeSeries() public {
        uint256 SERIES_TO_INIT = 3;
        for (uint256 i = 1; i <= SERIES_TO_INIT; i++) {
            uint256 nextMonthDate = DateTime.addMonths(block.timestamp, i);
            nextMonthDate = getValidMaturity(DateTime.getYear(nextMonthDate), DateTime.getMonth(nextMonthDate));
            (address zero, address claim) = initSampleSeries(address(alice), nextMonthDate);
            assertTrue(address(zero) != address(0));
            assertTrue(address(claim) != address(0));
        }
    }

    function testInitSeriesOnMinMaturity() public {
        hevm.warp(1631664000);
        // 15-09-21 00:00 UTC
        uint256 maturity = DateTime.timestampFromDateTime(2021, 10, 1, 0, 0, 0);
        initSampleSeries(address(alice), maturity);
    }

    function testInitSeriesOnMaxMaturity() public {
        hevm.warp(1631664000);
        // 15-09-21 00:00 UTC
        uint256 maturity = DateTime.timestampFromDateTime(2021, 12, 1, 0, 0, 0);
        initSampleSeries(address(alice), maturity);
    }

    /* ========== settleSeries() tests ========== */

    function testCantSettleSeriesIfDisabledFeed() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        gov.doSetFeed(address(feed), false);
        try alice.doSettleSeries(address(feed), maturity) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.InvalidFeed);
        }
    }

    function testCantSettleSeriesAlreadySettled() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        hevm.warp(maturity);
        alice.doSettleSeries(address(feed), maturity);
        try alice.doSettleSeries(address(feed), maturity) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.AlreadySettled);
        }
    }

    function testCantSettleSeriesIfNotSponsorAndSponsorWindow() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        hevm.warp(maturity);
        try bob.doSettleSeries(address(feed), maturity) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.OutOfWindowBoundaries);
        }
    }

    function testCantSettleSeriesIfNotSponsorCutoffTime() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        hevm.warp(DateTime.addSeconds(maturity, SPONSOR_WINDOW + SETTLEMENT_WINDOW + 1 seconds));
        try bob.doSettleSeries(address(feed), maturity) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.OutOfWindowBoundaries);
        }
    }

    function testCantSettleSeriesIfSponsorAndCutoffTime() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        hevm.warp(DateTime.addSeconds(maturity, SPONSOR_WINDOW + SETTLEMENT_WINDOW + 1 seconds));
        try alice.doSettleSeries(address(feed), maturity) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.OutOfWindowBoundaries);
        }
    }

    function testCantSettleSeriesIfNotSponsorAndSponsorTime() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        hevm.warp(DateTime.addSeconds(maturity, SPONSOR_WINDOW - 1 minutes));
        try bob.doSettleSeries(address(feed), maturity) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.OutOfWindowBoundaries);
        }
    }

    function testSettleSeries() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        hevm.warp(maturity);
        alice.doSettleSeries(address(feed), maturity);
    }

    function testSettleSeriesIfSponsorAndSponsorWindow() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        hevm.warp(maturity);
        alice.doSettleSeries(address(feed), maturity);
    }

    function testSettleSeriesIfSponsorAndOnSponsorWindowMinLimit() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        hevm.warp(DateTime.subSeconds(maturity, SPONSOR_WINDOW));
        alice.doSettleSeries(address(feed), maturity);
    }

    function testSettleSeriesIfSponsorAndOnSponsorWindowMaxLimit() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        hevm.warp(DateTime.addSeconds(maturity, SPONSOR_WINDOW));
        alice.doSettleSeries(address(feed), maturity);
    }

    function testSettleSeriesIfSponsorAndSettlementWindow() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        hevm.warp(DateTime.addSeconds(maturity, SPONSOR_WINDOW + SETTLEMENT_WINDOW));
        alice.doSettleSeries(address(feed), maturity);
    }

    function testSettleSeriesIfNotSponsorAndSettlementWindow() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        hevm.warp(DateTime.addSeconds(maturity, SPONSOR_WINDOW + SETTLEMENT_WINDOW));
        bob.doSettleSeries(address(feed), maturity);
    }

    function testSettleSeriesStakeIsTransferredIfSponsor() public {
        uint256 maturity = getValidMaturity(2021, 10);
        uint256 beforeBalance = stableToken.balanceOf(address(alice));
        initSampleSeries(address(alice), maturity);
        hevm.warp(maturity);
        alice.doSettleSeries(address(feed), maturity);
        uint256 afterBalance = stableToken.balanceOf(address(alice));
        assertEq(beforeBalance, afterBalance);
    }

    function testSettleSeriesStakeIsTransferredIfNotSponsor() public {
        uint256 maturity = getValidMaturity(2021, 10);
        uint256 beforeBalance = stableToken.balanceOf(address(bob));
        initSampleSeries(address(alice), maturity);
        hevm.warp(DateTime.addSeconds(maturity, SPONSOR_WINDOW + 1 seconds));
        bob.doSettleSeries(address(feed), maturity);
        uint256 afterBalance = stableToken.balanceOf(address(bob));
        assertEq(afterBalance, beforeBalance + INIT_STAKE);
    }

    //    function testSettleSeriesFeesAreTransferredIfSponsor() public {
    //        revert("IMPLEMENT");
    //    }
    //
    //    function testSettleSeriesFeesAreTransferredIfNotSponsor() public {
    //        revert("IMPLEMENT");
    //    }

    /* ========== issue() tests ========== */

    function testCantIssueFeedDisabled() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        uint256 amount = 1e18;
        gov.doSetFeed(address(feed), false);
        try alice.doIssue(address(feed), maturity, amount) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.InvalidFeed);
        }
    }

    function testCantIssueSeriesNotExists() public {
        uint256 maturity = getValidMaturity(2021, 10);
        uint256 amount = 100e18;
        try alice.doIssue(address(feed), maturity, amount) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.NotExists);
        }
    }

    function testCantIssueNotEnoughBalance() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        uint256 amount = target.balanceOf(address(alice));
        try alice.doIssue(address(feed), maturity, amount + 1) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.AmountExceedsBalance);
        }
    }

    function testCantIssueNotEnoughAllowance() public {
        alice.doApproveTarget(address(divider), 0);
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        uint256 amount = target.balanceOf(address(alice));
        try alice.doIssue(address(feed), maturity, amount) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.AllowanceNotEnough);
        }
    }

    function testIssue() public {
        uint256 maturity = getValidMaturity(2021, 10);
        (address zero, address claim) = initSampleSeries(address(alice), maturity);
        uint256 amount = 100e18; // 100 target
        uint256 fee = (ISSUANCE_FEE * 100e18) / 100; // 1 target
        uint256 tBalanceBefore = target.balanceOf(address(alice));
        uint256 zBalanceBefore = BaseToken(zero).balanceOf(address(alice));
        uint256 cBalanceBefore = Claim(claim).balanceOf(address(alice));
        alice.doIssue(address(feed), maturity, amount);
        uint256 zBalanceAfter = BaseToken(zero).balanceOf(address(alice));
        uint256 cBalanceAfter = Claim(claim).balanceOf(address(alice));
        uint256 tBalanceAfter = target.balanceOf(address(alice));
        // Formula = newBalance.wmul(scale)
        uint256 lscale = 2e17;
        uint256 mintedAmount = (amount - fee).wmul(lscale);
        assertEq(zBalanceAfter, mintedAmount);
        assertEq(cBalanceAfter, mintedAmount);
        assertEq(tBalanceAfter, tBalanceBefore - amount);
    }

    //    function testIssueTwoTimes() public {
    //        revert("IMPLEMENT");
    //    }

    /* ========== combine() tests ========== */

    function testCantCombineFeedDisabled() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        uint256 amount = 1e18;
        gov.doSetFeed(address(feed), false);
        try alice.doCombine(address(feed), maturity, amount) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.InvalidFeed);
        }
    }

    function testCantCombineSeriesNotExists() public {
        uint256 maturity = getValidMaturity(2021, 10);
        uint256 amount = 100e18;
        try alice.doCombine(address(feed), maturity, amount) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.NotExists);
        }
    }

    //    function testCantCombineNotEnoughBalance() public {
    //        revert("IMPLEMENT");
    //    }
    //
    //    function testCantCombineNotEnoughAllowance() public {
    //        revert("IMPLEMENT");
    //    }

    function testCombine() public {
        uint256 maturity = getValidMaturity(2021, 10);
        (address zero, address claim) = initSampleSeries(address(alice), maturity);
        uint256 tBal = 100e18;
        alice.doIssue(address(feed), maturity, tBal);
        uint256 tBalanceBefore = target.balanceOf(address(alice));
        uint256 zBalanceBefore = BaseToken(zero).balanceOf(address(alice));
        uint256 cBalanceBefore = Claim(claim).balanceOf(address(alice));
        alice.doCombine(address(feed), maturity, zBalanceBefore);
        uint256 tBalanceAfter = target.balanceOf(address(alice));
        uint256 zBalanceAfter = BaseToken(zero).balanceOf(address(alice));
        uint256 cBalanceAfter = Claim(claim).balanceOf(address(alice));
        require(zBalanceAfter == 0);
        require(cBalanceAfter == 0);
        uint256 lscale = divider.lscales(address(feed), maturity, address(alice));
        assertEq(zBalanceBefore, (tBalanceAfter - tBalanceBefore).wmul(lscale)); // TODO: check if this is correct!!
        // Amount of Zeros before combining == underlying balance
        // uint256 collected = ??
        // assertEq(tBalanceAfter - tBalanceBefore, collected); // TODO: assert collected value
    }

    /* ========== redeemZero() tests ========== */
    function testCantRedeemZeroDisabledFeed() public {
        uint256 maturity = getValidMaturity(2021, 10);
        (address zero, ) = initSampleSeries(address(alice), maturity);
        gov.doSetFeed(address(feed), false);
        uint256 balance = BaseToken(zero).balanceOf(address(alice));
        try alice.doRedeemZero(address(feed), maturity, balance) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.InvalidFeed);
        }
    }

    function testCantRedeemZeroSeriesNotExists() public {
        uint256 maturity = getValidMaturity(2021, 10);
        uint256 balance = 1e18;
        try alice.doRedeemZero(address(feed), maturity, balance) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.NotExists);
        }
    }

    function testCantRedeemZeroBalanceIsZero() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        uint256 balance = 0;
        try alice.doRedeemZero(address(feed), maturity, balance) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.ZeroBalance);
        }
    }

    function testCantRedeemZeroSeriesNotSettled() public {
        uint256 maturity = getValidMaturity(2021, 10);
        (address zero, ) = initSampleSeries(address(alice), maturity);
        uint256 balance = BaseToken(zero).balanceOf(address(alice));
        try alice.doRedeemZero(address(feed), maturity, balance) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.ZeroBalance);
        }
    }

    function testCantRedeemZeroMoreThanBalance() public {
        uint256 maturity = getValidMaturity(2021, 10);
        (address zero, ) = initSampleSeries(address(alice), maturity);
        hevm.warp(maturity);
        alice.doSettleSeries(address(feed), maturity);
        uint256 balance = BaseToken(zero).balanceOf(address(alice)) + 1e18;
        try alice.doRedeemZero(address(feed), maturity, balance) {
            fail();
        } catch (bytes memory error) {
            // Does not return any error message
        }
    }

    function testRedeemZero() public {
        uint256 maturity = getValidMaturity(2021, 10);
        (address zero, ) = initSampleSeries(address(alice), maturity);
        uint256 tBal = 100e18;
        bob.doIssue(address(feed), maturity, tBal);
        hevm.warp(maturity);
        alice.doSettleSeries(address(feed), maturity);
        uint256 zBalanceBefore = BaseToken(zero).balanceOf(address(bob));
        uint256 tBalanceBefore = target.balanceOf(address(bob));
        uint256 balanceToRedeem = zBalanceBefore;
        bob.doRedeemZero(address(feed), maturity, balanceToRedeem);
        uint256 zBalanceAfter = BaseToken(zero).balanceOf(address(bob));
        uint256 tBalanceAfter = target.balanceOf(address(bob));

        // Formula: tBal = balance / mscale
        (, , , , , , uint256 mscale) = divider.series(address(feed), maturity);
        uint256 redeemed = balanceToRedeem.wdiv(mscale);
        assertEq(zBalanceBefore, redeemed.wmul(mscale)); // Amount of Zeros burned == underlying amount
        assertEq(zBalanceBefore, zBalanceAfter + balanceToRedeem);
    }

    //    function testCanRedeemZeroBeforeMaturityIfSettled() public {
    //        revert("IMPLEMENT");
    //    }

    /* ========== collect() tests ========== */

    function testCantCollectDisabledFeed() public {
        uint256 maturity = getValidMaturity(2021, 10);
        (, address claim) = initSampleSeries(address(alice), maturity);
        gov.doSetFeed(address(feed), false);
        try alice.doCollect(claim) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.InvalidFeed);
        }
    }

    function testCantCollectIfMaturityAndNotSettled() public {
        uint256 maturity = getValidMaturity(2021, 10);
        (, address claim) = initSampleSeries(address(alice), maturity);
        uint256 tBal = 100e18;
        bob.doIssue(address(feed), maturity, tBal);
        hevm.warp(maturity);
        try bob.doCollect(claim) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.CollectNotSettled);
        }
    }

    //    function testCantCollectIfNotClaimContract() public {
    //        revert("IMPLEMENT");
    //    }

    function testCollect() public {
        uint256 maturity = getValidMaturity(2021, 10);
        (, address claim) = initSampleSeries(address(alice), maturity);
        uint256 tBal = 100e18;
        bob.doIssue(address(feed), maturity, tBal);
        uint256 cBalanceBefore = Claim(claim).balanceOf(address(bob));
        uint256 tBalanceBefore = target.balanceOf(address(bob));
        bob.doCollect(claim);
        uint256 cBalanceAfter = Claim(claim).balanceOf(address(bob));
        uint256 tBalanceAfter = target.balanceOf(address(bob));

        // Formula: collected = tBal * ( ( cscale - lscale ) / ( cscale * lscale) )
        (, , , , , uint256 iscale, uint256 mscale) = divider.series(address(feed), maturity);
        uint256 cscale = 3e17;
        uint256 lscale = 2e17;
        uint256 collected = cBalanceBefore.wmul((cscale - lscale).wdiv(cscale.wmul(lscale)));
        assertEq(cBalanceBefore, cBalanceAfter);
        assertEq(tBalanceAfter, tBalanceBefore + collected); // TODO: double check!
    }

    function testCollectAtMaturityBurnClaimsAndDoesNotCallBurnTwice() public {
        uint256 maturity = getValidMaturity(2021, 10);
        (, address claim) = initSampleSeries(address(alice), maturity);
        uint256 tBal = 100e18;
        bob.doIssue(address(feed), maturity, tBal);
        uint256 cBalanceBefore = Claim(claim).balanceOf(address(bob));
        uint256 tBalanceBefore = target.balanceOf(address(bob));
        hevm.warp(maturity);
        alice.doSettleSeries(address(feed), maturity);
        bob.doCollect(claim);
        uint256 cBalanceAfter = Claim(claim).balanceOf(address(bob));
        uint256 tBalanceAfter = target.balanceOf(address(bob));

        // Formula: collected = tBal * ( ( cscale - lscale ) / ( cscale * lscale) )
        (, , , , , uint256 iscale, uint256 mscale) = divider.series(address(feed), maturity);
        uint256 cscale = 3e17;
        uint256 lscale = 2e17;
        uint256 collected = cBalanceBefore.wmul((cscale - lscale).wdiv(cscale.wmul(lscale)));
        assertEq(cBalanceAfter, 0);
        assertEq(tBalanceAfter, tBalanceBefore + collected); // TODO: double check!
    }

    function testCollectBeforeMaturityAfterEmergencyDoesNotReplaceBackfilled() public {
        uint256 maturity = getValidMaturity(2021, 10);
        (, address claim) = initSampleSeries(address(alice), maturity);
        uint256 tBal = 100e18;
        bob.doIssue(address(feed), maturity, tBal);
        gov.doSetFeed(address(feed), false); // emergency stop
        uint256 newScale = 20e17;
        gov.doBackfillScale(address(feed), maturity, newScale, values, accounts); // fix invalid scale value
        gov.doSetFeed(address(feed), true); // re-enable feed after emergency
        bob.doCollect(claim);
        (, , , , , uint256 iscale, uint256 mscale) = divider.series(address(feed), maturity);
        assertEq(mscale, newScale);
        // TODO: check .scale() is not called (like to add the lscale). We can't?
    }

    /* ========== backfillScale() tests ========== */
    function testCantBackfillScaleSeriesNotExists() public {
        uint256 maturity = getValidMaturity(2021, 10);
        uint256 amount = 1e18;
        try gov.doBackfillScale(address(feed), maturity, amount, values, accounts) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.NotExists);
        }
    }

    function testCantBackfillScaleBeforeCutoffAndFeedEnabled() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        uint256 amount = 1e18;
        try gov.doBackfillScale(address(feed), maturity, amount, values, accounts) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.OutOfWindowBoundaries);
        }
    }

    function testCantBackfillScaleSeriesNotGov() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        hevm.warp(DateTime.addSeconds(maturity, SPONSOR_WINDOW + SETTLEMENT_WINDOW + 1 seconds));
        uint256 amount = 1e18;
        try alice.doBackfillScale(address(feed), maturity, amount, values, accounts) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.NotAuthorised);
        }
    }

    function testCantBackfillScaleInvalidValue() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        hevm.warp(DateTime.addSeconds(maturity, SPONSOR_WINDOW + SETTLEMENT_WINDOW + 1 seconds));
        uint256 amount = 1e16;
        try gov.doBackfillScale(address(feed), maturity, amount, values, accounts) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.InvalidScaleValue);
        }
    }

    function testBackfillScale() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        hevm.warp(DateTime.addSeconds(maturity, SPONSOR_WINDOW + SETTLEMENT_WINDOW + 1 seconds));
        uint256 newScale = 1e18;
        values = [5e17, 4e17];
        accounts = [address(alice), address(bob)];
        gov.doBackfillScale(address(feed), maturity, newScale, values, accounts);
        (, , , , , , uint256 mscale) = divider.series(address(feed), maturity);
        assertEq(mscale, newScale);
        uint256 lscale = divider.lscales(address(feed), maturity, address(alice));
        assertEq(lscale, values[0]);
        lscale = divider.lscales(address(feed), maturity, address(bob));
        assertEq(lscale, values[1]);
    }

    function testBackfillScaleBeforeCutoffAndFeedDisabled() public {
        uint256 maturity = getValidMaturity(2021, 10);
        initSampleSeries(address(alice), maturity);
        hevm.warp(maturity);
        gov.doSetFeed(address(feed), false);
        uint256 newScale = 1e18;
        gov.doBackfillScale(address(feed), maturity, newScale, values, accounts);
        (, , , , , , uint256 mscale) = divider.series(address(feed), maturity);
        assertEq(mscale, newScale);
    }

    /* ========== misc tests ========== */

    function testFeedIsDisabledIfScaleValueLowerThanPrevious() public {
        uint256 maturity = getValidMaturity(2021, 10);
        (address zero, address claim) = initSampleSeries(address(alice), maturity);
        TestFeed(feed).setCounter(911);
        try TestFeed(feed).scale() {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.InvalidScaleValue);
        }
        uint256 amount = 100e18;
        try alice.doIssue(address(feed), maturity, amount) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, Errors.InvalidScaleValue);
        }
    }

    //    function testFeedIsDisabledIfScaleValueCallReverts() public {
    //        revert("IMPLEMENT");
    //    }

    //    function testFeedIsDisabledIfScaleValueHigherThanThanPreviousPlusDelta() public {
    //        revert("IMPLEMENT");
    //    }

    /* ========== test helpers ========== */

    function getValidMaturity(uint256 year, uint256 month) public view returns (uint256 maturity) {
        maturity = DateTime.timestampFromDateTime(year, month, 1, 0, 0, 0);
        require(maturity >= block.timestamp + 2 weeks, "Can not return valid maturity with given year an month");
    }

    function initSampleSeries(address sponsor, uint256 maturity) public returns (address zero, address claim) {
        (zero, claim) = User(sponsor).doInitSeries(address(feed), maturity);
    }

    function assertClose(uint256 actual, uint256 expected) public {
        uint256 variance = 10;
        assertTrue(actual >= (expected - variance));
        assertTrue(actual <= (expected - variance));
    }
}
