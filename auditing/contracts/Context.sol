// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.1;

abstract contract Context {
    function _msgSender() internal view virtual returns ( address payable ) {
        return payable( msg.sender );
    }
}
