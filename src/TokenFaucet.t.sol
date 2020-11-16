pragma solidity ^0.6.7;

import "ds-test/test.sol";
import {DSToken} from "ds-token/token.sol";

import {TokenFaucet} from "./TokenFaucet.sol";

contract TokenFaucetTest is DSTest {
    TokenFaucet faucet;
    DSToken token;

    function setUp() public {
        faucet = new TokenFaucet();
        token = new DSToken("TEST", "TEST");
        token.mint(address(faucet), 1000000);
        faucet.setAllocatedAmount(address(token), 20);
    }

    function test_requestTokens() public {
        assertEq(token.balanceOf(address(this)), 0);
        faucet.requestTokens(address(token));
        assertEq(token.balanceOf(address(this)), 20);
    }

    function test_requestTokens_multiple() public {
        assertEq(token.balanceOf(address(123)), 0);
        assertEq(token.balanceOf(address(234)), 0);
        assertEq(token.balanceOf(address(567)), 0);
        assertEq(token.balanceOf(address(890)), 0);
        address[] memory addrs = new address[](4);
        addrs[0] = address(123);
        addrs[1] = address(234);
        addrs[2] = address(567);
        addrs[3] = address(890);
        faucet.requestTokens(address(token), addrs);
        assertEq(token.balanceOf(address(123)), 20);
        assertEq(token.balanceOf(address(234)), 20);
        assertEq(token.balanceOf(address(567)), 20);
        assertEq(token.balanceOf(address(890)), 20);
    }

    function testFail_request_tokens_multiple() public {
        faucet.requestTokens(address(token));
        address[] memory addrs = new address[](4);
        addrs[0] = address(this);
        addrs[1] = address(234);
        addrs[2] = address(567);
        addrs[3] = address(890);
        faucet.requestTokens(address(token), addrs);
    }

    function testFail_request_tokens_twice() public {
        faucet.requestTokens(address(token));
        faucet.requestTokens(address(token));
    }
}
