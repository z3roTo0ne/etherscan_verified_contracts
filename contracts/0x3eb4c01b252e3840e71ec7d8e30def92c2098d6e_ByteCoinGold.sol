pragma solidity ^0.4.18;


contract owned {
    address public owner;
    address public candidate;

    function owned() payable internal {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address _owner) onlyOwner public {
        candidate = _owner;
    }

    function confirmOwner() public {
        require(candidate != address(0));
        require(candidate == msg.sender);
        owner = candidate;
        delete candidate;
    }
}


library SafeMath {
    function sub(uint256 a, uint256 b) pure internal returns (uint256) {
        assert(a &gt;= b);
        return a - b;
    }

    function add(uint256 a, uint256 b) pure internal returns (uint256) {
        uint256 c = a + b;
        assert(c &gt;= a &amp;&amp; c &gt;= b);
        return c;
    }
}


contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256 value);
    function allowance(address owner, address spender) public constant returns (uint256 _allowance);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ByteCoinGold is ERC20, owned {
    using SafeMath for uint256;
    string public name = &quot;ByteCoinGold&quot;;
    string public symbol = &quot;BCG&quot;;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address =&gt; uint256) private balances;
    mapping (address =&gt; mapping (address =&gt; uint256)) private allowed;

    function balanceOf(address _who) public constant returns (uint256) {
        return balances[_who];
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function ByteCoinGold() public {
        totalSupply = 4000000 * 1 ether;
        balances[msg.sender] = totalSupply;
        Transfer(0, msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] &gt;= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balances[_from] &gt;= _value &amp;&amp; allowed[_from][msg.sender] &gt;= _value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));
        require(balances[msg.sender] &gt;= _value);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function withdrawTokens(uint256 _value) public onlyOwner {
        require(balances[this] &gt;= _value);
        balances[this] = balances[this].sub(_value);
        balances[msg.sender] = balances[msg.sender].add(_value);
        Transfer(this, msg.sender, _value);
    }
}