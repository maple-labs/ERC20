// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IERC20 } from "./interfaces/IERC20.sol";

/**
 * @title Modern and gas efficient ERC-20 implementation.
 * @dev   Acknowledgements to Solmate, OpenZeppelin, and DSS for inspiring this code.
 */
contract ERC20 is IERC20 {

    /**************/
    /*** ERC-20 ***/
    /**************/

    string public override name;
    string public override symbol;

    uint8 public immutable override decimals;

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    /****************/
    /*** ERC-2612 ***/
    /****************/

    // PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 amount,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH      = 0xfc77c2b9d30fe91687fd39abb7d16fcdfe1472d065740051ab8b13e4bf4a617f;
    uint256 public constant S_VALUE_INCLUSIVE_UPPER_BOUND = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;

    mapping (address => uint256) public override nonces;

    /**
     * @param name_     The name of the token.
     * @param symbol_   The symbol of the token.
     * @param decimals_ The decimal precision used by the token.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name     = name_;
        symbol   = symbol_;
        decimals = decimals_;
    }

    /**************************/
    /*** External Functions ***/
    /**************************/

    function approve(address spender_, uint256 amount_) external override returns (bool success_) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    function decreaseAllowance(address spender_, uint256 subtractedAmount_) external override returns (bool success_) {
        _approve(msg.sender, spender_, allowance[msg.sender][spender_] - subtractedAmount_);
        return true;
    }

    function increaseAllowance(address spender_, uint256 addedAmount_) external override returns (bool success_) {
        _approve(msg.sender, spender_, allowance[msg.sender][spender_] + addedAmount_);
        return true;
    }

    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(deadline >= block.timestamp, "ERC20:P:EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline))
            )
        );

        // Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}.
        require(uint256(s) <= S_VALUE_INCLUSIVE_UPPER_BOUND && (v == 27 || v == 28), "ERC20:P:MALLEABLE");

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == owner && owner != address(0), "ERC20:P:INVALID_SIGNATURE");
        _approve(owner, spender, amount);
    }

    function transfer(address recipient_, uint256 amount_) external override returns (bool success_) {
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    function transferFrom(address owner_, address recipient_, uint256 amount_) external override returns (bool success_) {
        _approve(owner_, msg.sender, allowance[owner_][msg.sender] - amount_);
        _transfer(owner_, recipient_, amount_);
        return true;
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    function DOMAIN_SEPARATOR() public view override returns (bytes32 domainSeparator_) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function _approve(address owner_, address spender_, uint256 amount_) internal {
        emit Approval(owner_, spender_, allowance[owner_][spender_] = amount_);
    }

    function _burn(address owner_, uint256 amount_) internal {
        balanceOf[owner_] -= amount_;
        totalSupply       -= amount_;

        emit Transfer(owner_, address(0), amount_);
    }

    function _mint(address recipient_, uint256 amount_) internal {
        totalSupply           += amount_;
        balanceOf[recipient_] += amount_;

        emit Transfer(address(0), recipient_, amount_);
    }

    function _transfer(address owner_, address recipient_, uint256 amount_) internal {
        balanceOf[owner_]     -= amount_;
        balanceOf[recipient_] += amount_;

        emit Transfer(owner_, recipient_, amount_);
    }

}
