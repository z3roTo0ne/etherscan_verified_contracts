pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract CrisCoin {
    // Public variables of the token
    string public constant name = &quot;CrisCoin&quot;;
    string public constant symbol = &quot;CSX&quot;;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    address public owner;
    uint256 public constant RATE = 1000;
    
    uint256 initialSupply = 100000;

    mapping (address =&gt; uint256) public balanceOf;
    mapping (address =&gt; mapping (address =&gt; uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function CrisCoin() public 
    {
        owner = msg.sender;
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }
    
    function () public payable
    {
        createTokens();
    }
    
    function createTokens() public payable
    {
        require( msg.value &gt; 0 );
        
        require( msg.value * RATE &gt; msg.value );
        uint256 tokens = msg.value * RATE;
        
        require( balanceOf[msg.sender] + tokens &gt; balanceOf[msg.sender] );
        balanceOf[msg.sender] += tokens;
        
        require( totalSupply + tokens &gt; totalSupply );
        totalSupply += tokens;
        
        owner.transfer(msg.value);
    }

    function _transfer(address _from, address _to, uint _value) internal 
    {
        require(_to != 0x0);
        require(balanceOf[_from] &gt;= _value);
        require(balanceOf[_to] + _value &gt; balanceOf[_to]);
        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public 
    {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) 
    {
        require(_value &lt;= allowance[_from][msg.sender]);
        
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) 
    {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success)
    {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) 
        {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success)
    {
        require(balanceOf[msg.sender] &gt;= _value);
        
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) 
    {
        require(balanceOf[_from] &gt;= _value);
        require(_value &lt;= allowance[_from][msg.sender]);
        
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from, _value);
        
        return true;
    }
}