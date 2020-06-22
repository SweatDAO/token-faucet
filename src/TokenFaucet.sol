/// TokenFaucet.sol

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

contract TokenFaucet is Logging {
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
        require(authorizedAccounts[msg.sender] == 1, "TokenFaucet/account-not-authorized");
        _;
    }

    mapping (address => uint256) public allocatedAmount;
    mapping (address => mapping (address => bool)) public claimed;

    constructor () public {
        authorizedAccounts[msg.sender] = 1;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function requestTokens(address token) external {
        require(!claimed[msg.sender][address(token)], "TokenFaucet: already used faucet");
        require(ERC20Like(token).balanceOf(address(this)) >= allocatedAmount[token], "TokenFaucet: not enough balance");
        claimed[msg.sender][address(token)] = true;
        ERC20Like(token).transfer(msg.sender, allocatedAmount[token]);
    }

    function requestTokens(address token, address[] calldata addrs) external {
        require(ERC20Like(token).balanceOf(address(this)) >= mul(allocatedAmount[token], addrs.length), "TokenFaucet: not enough balance");

        for (uint256 i = 0; i < addrs.length; i++) {
            require(!claimed[addrs[i]][address(token)], "TokenFaucet: already used faucet");
            claimed[addrs[i]][address(token)] = true;
            ERC20Like(token).transfer(addrs[i], allocatedAmount[token]);
        }
    }

    function transferAllTokens(ERC20Like token) external isAuthorized {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function setAllocatedAmount(address token, uint256 allocatedAmount_) external isAuthorized emitLog {
        allocatedAmount[token] = allocatedAmount_;
    }
}
