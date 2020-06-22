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

import "./Logging.sol";

interface ERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transfer(address,uint256) external; // return bool?
}

contract RestrictedTokenFaucet is Logging {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external emitLog isAuthorized { authorizedAccounts[account] = 1; }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external emitLog isAuthorized { authorizedAccounts[account] = 0; }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "RestrictedTokenFaucet/account-not-authorized");
        _;
    }
    // --- Whitelist ---
    mapping (address => uint256) public whitelistedAccounts;
    function whitelist(address usr) public isAuthorized emitLog { whitelistedAccounts[usr] = 1; }
    function blacklist(address usr) public isAuthorized emitLog { whitelistedAccounts[usr] = 0; }

    mapping (address => uint256) public allocatedAmount;
    mapping (address => mapping (address => bool)) public claimed;

    constructor () public {
        authorizedAccounts[msg.sender] = 1;
        whitelistedAccounts[msg.sender] = 1;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "RestrictedTokenFaucet/mul-overflow");
    }

    function requestTokens(address token) external {
        require(whitelistedAccounts[address(0)] == 1 || whitelistedAccounts[msg.sender] == 1, "RestrictedTokenFaucet/no-whitelist");
        require(!claimed[msg.sender][token], "RestrictedTokenFaucet/already-used_faucet");
        require(ERC20Like(token).balanceOf(address(this)) >= allocatedAmount[token], "RestrictedTokenFaucet/not-enough-balance");
        claimed[msg.sender][token] = true;
        ERC20Like(token).transfer(msg.sender, allocatedAmount[token]);
    }

    function requestTokens(address token, address[] calldata addrs) external {
        require(ERC20Like(token).balanceOf(address(this)) >= mul(allocatedAmount[token], addrs.length), "RestrictedTokenFaucet/not-enough-balance");

        for (uint256 i = 0; i < addrs.length; i++) {
            require(whitelistedAccounts[address(0)] == 1 || whitelistedAccounts[addrs[i]] == 1, "RestrictedTokenFaucet/no-whitelist");
            require(!claimed[addrs[i]][address(token)], "RestrictedTokenFaucet/already-used-faucet");
            claimed[addrs[i]][address(token)] = true;
            ERC20Like(token).transfer(addrs[i], allocatedAmount[token]);
        }
    }

    function transferAllTokens(ERC20Like token) external isAuthorized {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function markAsUnclaimed(address usr, address token) external isAuthorized emitLog {
        claimed[usr][token] = false;
    }

    function setAllocatedAmount(address token, uint256 allocatedAmount_) external isAuthorized emitLog {
        allocatedAmount[token] = allocatedAmount_;
    }
}
