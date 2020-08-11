/// RestrictedTokenFaucet.sol

// Copyright (C) 2019-2020 Maker Ecosystem Growth Holdings, INC.

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.6.7;

interface ERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transfer(address,uint256) external; // return bool?
}

contract RestrictedTokenFaucet {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "RestrictedTokenFaucet/account-not-authorized");
        _;
    }
    // --- Whitelist ---
    mapping (address => uint256) public whitelistedAccounts;
    function whitelist(address usr) public isAuthorized {
        whitelistedAccounts[usr] = 1;
        emit Whitelist(usr);
    }
    function blacklist(address usr) public isAuthorized {
        whitelistedAccounts[usr] = 0;
        emit Blacklist(usr);
    }

    mapping (address => uint256) public allocatedAmount;
    mapping (address => mapping (address => bool)) public claimed;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event Whitelist(address account);
    event Blacklist(address account);
    event RequestTokens(address sender, address token);
    event RequestTokens(address token, address[] addrs);
    event TransferAllTokens(address token);
    event SetAllocatedAmount(address token, uint256 allocatedAmount);
    event MarkAsUnclaimed(address usr, address token);

    constructor () public {
        authorizedAccounts[msg.sender] = 1;
        whitelistedAccounts[msg.sender] = 1;
        emit AddAuthorization(msg.sender);
        emit Whitelist(msg.sender);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "RestrictedTokenFaucet/mul-overflow");
    }

    function requestTokens(address token) external {
        require(whitelistedAccounts[address(0)] == 1 || whitelistedAccounts[msg.sender] == 1, "RestrictedTokenFaucet/no-whitelist");
        require(!claimed[msg.sender][token], "RestrictedTokenFaucet/already-used_faucet");
        require(ERC20Like(token).balanceOf(address(this)) >= allocatedAmount[token], "RestrictedTokenFaucet/not-enough-balance");
        claimed[msg.sender][token] = true;
        emit RequestTokens(msg.sender, token);
        ERC20Like(token).transfer(msg.sender, allocatedAmount[token]);
    }

    function requestTokens(address token, address[] calldata addrs) external {
        require(ERC20Like(token).balanceOf(address(this)) >= mul(allocatedAmount[token], addrs.length), "RestrictedTokenFaucet/not-enough-balance");

        emit RequestTokens(token, addrs);

        for (uint256 i = 0; i < addrs.length; i++) {
            require(whitelistedAccounts[address(0)] == 1 || whitelistedAccounts[addrs[i]] == 1, "RestrictedTokenFaucet/no-whitelist");
            require(!claimed[addrs[i]][address(token)], "RestrictedTokenFaucet/already-used-faucet");
            claimed[addrs[i]][address(token)] = true;
            ERC20Like(token).transfer(addrs[i], allocatedAmount[token]);
        }
    }

    function transferAllTokens(ERC20Like token) external isAuthorized {
        emit TransferAllTokens(address(token));
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function markAsUnclaimed(address usr, address token) external isAuthorized {
        claimed[usr][token] = false;
        emit MarkAsUnclaimed(usr, token);
    }

    function setAllocatedAmount(address token, uint256 allocatedAmount_) external isAuthorized {
        allocatedAmount[token] = allocatedAmount_;
        emit SetAllocatedAmount(token, allocatedAmount_);
    }
}
