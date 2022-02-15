// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

// Internal references
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { BaseAdapter } from "./BaseAdapter.sol";
import { Divider } from "../Divider.sol";

abstract contract BaseFactory {
    /* ========== CONSTANTS ========== */

    /// @notice Sets level to `31` by default, which keeps all Divider lifecycle methods public
    /// (`issue`, `combine`, `collect`, etc), but not the `onZeroRedeem` hook.
    uint256 public constant DEFAULT_LEVEL = 31;

    /* ========== PUBLIC IMMUTABLES ========== */

    /// @notice Sense core Divider address
    address public immutable divider;

    /// @notice Protocol's data contract address
    address public immutable protocol;

    /// @notice target -> adapter
    mapping(address => address) public adapters;

    /// @notice params for adapters deployed with this factory
    FactoryParams public factoryParams;

    /* ========== DATA STRUCTURES ========== */

    struct FactoryParams {
        address oracle; // oracle address
        uint256 ifee; // issuance fee
        address stake; // token to stake at issuance
        uint256 stakeSize; // amount to stake at issuance
        uint256 minm; // min maturity (seconds after block.timstamp)
        uint256 maxm; // max maturity (seconds after block.timstamp)
        uint16 mode; // 0 for monthly, 1 for weekly
        uint64 tilt; // tilt
    }

    constructor(
        address _divider,
        address _protocol,
        FactoryParams memory _factoryParams
    ) {
        divider = _divider;
        protocol = _protocol;
        factoryParams = _factoryParams;
    }

    /* ========== REQUIRED DEPLOY ========== */

    /// @notice Deploys both an adapter and a target wrapper for the given _target
    /// @param _target Address of the Target token
    function deployAdapter(address _target) external virtual returns (address adapter) {}

    /* ========== REQUIRED INTERNAL GUARD ========== */

    /// @notice Target validity check that must be overriden by child contracts
    function exists(address _target) external virtual returns (bool);

    /* ========== LOGS ========== */

    /// @notice Logs the deployment of the adapter
    event AdapterAdded(address addr, address indexed target);
}
