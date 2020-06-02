pragma solidity ^0.5.4;

import "ds-test/test.sol";
import {DSToken} from "ds-token/token.sol";

import {RestrictedTokenFaucet, ERC20Like} from "./RestrictedTokenFaucet.sol";

contract FaucetUser {
    DSToken token;
    RestrictedTokenFaucet faucet;

    constructor(DSToken token_, RestrictedTokenFaucet faucet_) public {
        token = token_;
        faucet = faucet_;
    }

    function doRequestTokens() public {
        faucet.requestTokens(address(token));
    }

    function doMarkAsUnclaimed(address usr) public {
        faucet.markAsUnclaimed(usr, address(token));
    }

    function doWhitelist(address usr) public {
        faucet.whitelist(usr);
    }

    function doBlacklist(address usr) public {
        faucet.blacklist(usr);
    }

    function doTransferAllTokens() public {
        faucet.transferAllTokens(ERC20Like(address(this)));
    }

    function doSetAllocatedAmount(address tok, uint allocatedAmount) public {
        faucet.setAllocatedAmount(tok, allocatedAmount);
    }
}

contract RestrictedTokenFaucetTest is DSTest {
    RestrictedTokenFaucet faucet;
    DSToken token;
    FaucetUser user1;
    FaucetUser user2;
    address self;

    function setUp() public {
        faucet = new RestrictedTokenFaucet();
        token = new DSToken("TEST");
        token.mint(address(faucet), 1000000);
        faucet.setAllocatedAmount(address(token), 20);
        user1 = new FaucetUser(token, faucet);
        user2 = new FaucetUser(token, faucet);
        self = address(this);
    }

    function testSetupPrecondition() public {
        assertEq(faucet.authorizedAccounts(self), 1);
        assertEq(faucet.whitelistedAccounts(self), 1);
        assertEq(faucet.whitelistedAccounts(address(user1)), 0);
        assertEq(faucet.whitelistedAccounts(address(user2)), 0);
    }

    function testFail_request_tokens_no_auth_list() public {
        FaucetUser(user2).doRequestTokens();
    }

    function test_request_tokens_auth_list() public {
        faucet.whitelist(address(user1));
        assertEq(faucet.whitelistedAccounts(address(user1)), 1);
        assertEq(token.balanceOf(address(user1)), 0);
        user1.doRequestTokens();
        assertEq(token.balanceOf(address(user1)), 20);
    }

    function test_requestTokens_auth_list_all() public {
        faucet.whitelist(address(0));
        assertEq(faucet.whitelistedAccounts(address(0)), 1);
        assertEq(faucet.whitelistedAccounts(address(user1)), 0);
        assertEq(token.balanceOf(address(user1)), 0);
        user1.doRequestTokens();
        assertEq(token.balanceOf(address(user1)), 20);
    }

    function testFail_hope_not_owner() public {
        user1.doWhitelist(address(123));
    }

    function testFail_nope_not_owner() public {
        user1.doBlacklist(address(this));
    }

    function test_requestTokens_multiple() public {
        address[] memory addrs = new address[](4);
        addrs[0] = address(123);
        faucet.whitelist(addrs[0]);
        addrs[1] = address(234);
        faucet.whitelist(addrs[1]);
        addrs[2] = address(567);
        faucet.whitelist(addrs[2]);
        addrs[3] = address(890);
        faucet.whitelist(addrs[3]);
        assertEq(token.balanceOf(address(123)), 0);
        assertEq(token.balanceOf(address(234)), 0);
        assertEq(token.balanceOf(address(567)), 0);
        assertEq(token.balanceOf(address(890)), 0);
        faucet.requestTokens(address(token), addrs);
        assertEq(token.balanceOf(address(123)), 20);
        assertEq(token.balanceOf(address(234)), 20);
        assertEq(token.balanceOf(address(567)), 20);
        assertEq(token.balanceOf(address(890)), 20);
    }

    function testFail_requestTokens_multiple() public {
        address[] memory addrs = new address[](2);
        addrs[0] = address(this); // already hope'ed
        addrs[2] = address(234); // not hope'ed
        faucet.requestTokens(address(token), addrs);
    }

    function testFail_requestTokens_twice() public {
        faucet.requestTokens(address(token));
        faucet.requestTokens(address(token));
    }

    function test_markAsUnclaimed() public {
        assertEq(token.balanceOf(address(this)), 0);

        faucet.requestTokens(address(token));
        assertEq(token.balanceOf(address(this)), 20);
        assertTrue(faucet.claimed(address(this), address(token)));

        faucet.markAsUnclaimed(address(this), address(token));
        assertTrue(!faucet.claimed(address(this), address(token)));

        faucet.requestTokens(address(token));
        assertEq(token.balanceOf(address(this)), 40);
    }

    function testFail_markAsUnclaimed_not_owner() public {
        faucet.requestTokens(address(token));
        assertTrue(faucet.claimed(address(this), address(token)));
        user1.doMarkAsUnclaimed(address(this));
    }

    function test_transferAllTokens() public {
        assertEq(token.balanceOf(address(this)), 0);
        faucet.transferAllTokens(ERC20Like(address(token)));
        assertEq(token.balanceOf(address(this)), 1000000);
    }

    function testFail_shut_not_owner() public {
        user1.doTransferAllTokens();
    }

    function test_set_allocated_amount() public {
        assertEq(faucet.allocatedAmount(address(token)), 20);
        faucet.setAllocatedAmount(address(token), 10);
        assertEq(faucet.allocatedAmount(address(token)), 10);
    }

    function testFail_set_allocated_amount_not_owner() public {
        user1.doSetAllocatedAmount(address(token), 10);
    }
}
