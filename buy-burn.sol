// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IUniswapV2Router02 {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}

interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IzData {
    function WETH() external pure returns (address);
    function PancakeRouterV2() external pure returns (address);
    function zContract() external pure returns (address);
    function USDT() external pure returns (address);
    function USDC() external pure returns (address);
    function DAI() external pure returns (address);
}

contract BuyAndBurn is Ownable {

    IzData zData = IzData(0x37B8764427130b5d89f324B444aebe1D12fDEc63);
    IUniswapV2Router02 private uniswapRouter = IUniswapV2Router02(zData.PancakeRouterV2());
    IBEP20 private token;
    IBEP20 private bnb = IBEP20(zData.WETH());
    address private deadWallet = 0x000000000000000000000000000000000000dEaD;

    constructor(address _token) {
        token = IBEP20(_token);
    }

    receive() external payable {
        address[] memory path = new address[](2);
        path[0] = address(bnb);
        path[1] = address(token);

        uint deadline = block.timestamp + 300;
        uint[] memory amounts = uniswapRouter.swapExactETHForTokens{value: msg.value}(0, path, address(this), deadline);
        uint amountToken = amounts[1];
        token.transfer(deadWallet, amountToken);
    }



    function withdrawToken() public onlyOwner {
        uint balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function withdrawBNB() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
