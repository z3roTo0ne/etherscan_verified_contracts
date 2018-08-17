pragma solidity ^0.4.16;

// SafeMath
contract SafeMath {
     function safeMul(uint a, uint b) internal returns (uint) {
          uint c = a * b;
          assert(a == 0 || c / a == b);
          return c;
     }

     function safeSub(uint a, uint b) internal returns (uint) {
          assert(b &lt;= a);
          return a - b;
     }

     function safeAdd(uint a, uint b) internal returns (uint) {
          uint c = a + b;
          assert(c&gt;=a &amp;&amp; c&gt;=b);
          return c;
     }
}

// Standard token interface (ERC 20)
// https://github.com/ethereum/EIPs/issues/20
// Token
contract Token is SafeMath {
     // Functions:
     /// @return total amount of tokens
     function totalSupply() constant returns (uint256 supply);

     /// @param _owner The address from which the balance will be retrieved
     /// @return The balance
     function balanceOf(address _owner) constant returns (uint256 balance);

     /// @notice send `_value` token to `_to` from `msg.sender`
     /// @param _to The address of the recipient
     /// @param _value The amount of token to be transferred
     function transfer(address _to, uint256 _value) returns(bool);
     
     /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     /// @param _from The address of the sender
     /// @param _to The address of the recipient
     /// @param _value The amount of token to be transferred
     /// @return Whether the transfer was successful or not
     function transferFrom(address _from, address _to, uint256 _value) returns(bool);

     /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
     /// @param _spender The address of the account able to transfer the tokens
     /// @param _value The amount of wei to be approved for transfer
     /// @return Whether the approval was successful or not
     function approve(address _spender, uint256 _value) returns (bool success);

     /// @param _owner The address of the account owning tokens
     /// @param _spender The address of the account able to transfer the tokens
     /// @return Amount of remaining tokens allowed to spent
     function allowance(address _owner, address _spender) constant returns (uint256 remaining);

     // Events:
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
//StdToken
contract StdToken is Token {
     // Fields:
     mapping(address =&gt; uint256) balances;
     mapping (address =&gt; mapping (address =&gt; uint256)) allowed;
     uint public supply = 0;

     // Functions:
     function transfer(address _to, uint256 _value) returns(bool) {
          require(balances[msg.sender] &gt;= _value);
          require(balances[_to] + _value &gt; balances[_to]);

          balances[msg.sender] = safeSub(balances[msg.sender],_value);
          balances[_to] = safeAdd(balances[_to],_value);

          Transfer(msg.sender, _to, _value);
          return true;
     }

     function transferFrom(address _from, address _to, uint256 _value) returns(bool){
          require(balances[_from] &gt;= _value);
          require(allowed[_from][msg.sender] &gt;= _value);
          require(balances[_to] + _value &gt; balances[_to]);

          balances[_to] = safeAdd(balances[_to],_value);
          balances[_from] = safeSub(balances[_from],_value);
          allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);

          Transfer(_from, _to, _value);
          return true;
     }

     function totalSupply() constant returns (uint256) {
          return supply;
     }

     function balanceOf(address _owner) constant returns (uint256) {
          return balances[_owner];
     }

     function approve(address _spender, uint256 _value) returns (bool) {
          // To change the approve amount you first have to reduce the addresses`
          //  allowance to zero by calling `approve(_spender, 0)` if it is not
          //  already 0 to mitigate the race condition described here:
          //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
          require((_value == 0) || (allowed[msg.sender][_spender] == 0));

          allowed[msg.sender][_spender] = _value;
          Approval(msg.sender, _spender, _value);

          return true;
     }

     function allowance(address _owner, address _spender) constant returns (uint256) {
          return allowed[_owner][_spender];
     }
}

contract NEOCASHToken is StdToken
{
/// Fields:
    string public constant name = &quot;NEO CASH&quot;;
    string public constant symbol = &quot;NEOC&quot;;
    uint public constant decimals = 18;

    uint public constant TOTAL_SUPPLY = 100000000 * (1 ether / 1 wei);
    // this includes DEVELOPERS_BONUS
    uint public constant DEVELOPERS_BONUS = 65000000 * (1 ether / 1 wei);
	
    uint public constant PRESALE_PRICE = 50;  // per 1 Ether
    uint public constant PRESALE_MAX_ETH = 100000;
    uint public constant PRESALE_TOKEN_SUPPLY_LIMIT = PRESALE_PRICE * PRESALE_MAX_ETH * (1 ether / 1 wei);


    uint public constant ICO_PRICE1 = 40;     // per 1 Ether
    uint public constant ICO_PRICE2 = 30;     // per 1 Ether
    uint public constant ICO_PRICE3 = 10;     // per 1 Ether

    // 680M2k2 - this includes presale tokens
    uint public constant TOTAL_SOLD_TOKEN_SUPPLY_LIMIT = 35000000* (1 ether / 1 wei);

    enum State{
       Init,
       Paused,

       PresaleRunning,
       PresaleFinished,

       ICORunning,
       ICOFinished
    }

    State public currentState = State.Init;
    bool public enableTransfers = true;

    address public teamTokenBonus = 0;

    // Gathered funds can be withdrawn only to escrow&#39;s address.
    address public escrow = 0;

    // Token manager has exclusive priveleges to call administrative
    // functions on this contract.
    address public tokenManager = 0;

    uint public presaleSoldTokens = 0;
    uint public icoSoldTokens = 0;
    uint public totalSoldTokens = 0;

/// Modifiers:
    modifier onlyTokenManager()
    {
        require(msg.sender==tokenManager); 
        _; 
    }
    
    modifier onlyTokenCrowner()
    {
        require(msg.sender==escrow); 
        _; 
    }

    modifier onlyInState(State state)
    {
        require(state==currentState); 
        _; 
    }

/// Events:
    event LogBuy(address indexed owner, uint value);
    event LogBurn(address indexed owner, uint value);

/// Functions:
    /// @dev Constructor
    /// @param _tokenManager Token manager address.
    function NEOCASHToken(address _tokenManager, address _escrow, address _teamTokenBonus) 
    {
        tokenManager = _tokenManager;
        teamTokenBonus = _teamTokenBonus;
        escrow = _escrow;

        // send team bonus immediately
        uint teamBonus = DEVELOPERS_BONUS;
        balances[_teamTokenBonus] += teamBonus;
        supply+= teamBonus;
        
        assert(PRESALE_TOKEN_SUPPLY_LIMIT==5000000 * (1 ether / 1 wei));
        assert(TOTAL_SOLD_TOKEN_SUPPLY_LIMIT==35000000 * (1 ether / 1 wei));
    }

    function buyTokens() public payable
    {
        require(currentState==State.PresaleRunning || currentState==State.ICORunning);

        if(currentState==State.PresaleRunning){
            return buyTokensPresale();
        }else{
            return buyTokensICO();
        }
    }

    function buyTokensPresale() public payable onlyInState(State.PresaleRunning)
    {
        // min - 1 ETH
        //require(msg.value &gt;= (1 ether / 1 wei));
        // min - 0.01 ETH
        require(msg.value &gt;= ((1 ether / 1 wei) / 100));
        uint newTokens = msg.value * PRESALE_PRICE;

        require(presaleSoldTokens + newTokens &lt;= PRESALE_TOKEN_SUPPLY_LIMIT);

        balances[msg.sender] += newTokens;
        supply+= newTokens;
        presaleSoldTokens+= newTokens;
        totalSoldTokens+= newTokens;

        LogBuy(msg.sender, newTokens);
    }

    function buyTokensICO() public payable onlyInState(State.ICORunning)
    {
        // min - 0.01 ETH
        require(msg.value &gt;= ((1 ether / 1 wei) / 100));
        uint newTokens = msg.value * getPrice();

        require(totalSoldTokens + newTokens &lt;= TOTAL_SOLD_TOKEN_SUPPLY_LIMIT);

        balances[msg.sender] += newTokens;
        supply+= newTokens;
        icoSoldTokens+= newTokens;
        totalSoldTokens+= newTokens;

        LogBuy(msg.sender, newTokens);
    }

    function getPrice()constant returns(uint)
    {
        if(currentState==State.ICORunning){
             if(icoSoldTokens&lt;(10000000 * (1 ether / 1 wei))){
                  return ICO_PRICE1;
             }
             
             if(icoSoldTokens&lt;(15000000 * (1 ether / 1 wei))){
                  return ICO_PRICE2;
             }

             return ICO_PRICE3;
        }else{
             return PRESALE_PRICE;
        }
    }

    function setState(State _nextState) public onlyTokenManager
    {
        //setState() method call shouldn&#39;t be entertained after ICOFinished
        require(currentState != State.ICOFinished);
        
        currentState = _nextState;
        // enable/disable transfers
        //enable transfers only after ICOFinished, disable otherwise
        //enableTransfers = (currentState==State.ICOFinished);
    }
    
    function DisableTransfer() public onlyTokenManager
    {
        enableTransfers = false;
    }
    
    
    function EnableTransfer() public onlyTokenManager
    {
        enableTransfers = true;
    }

    function withdrawEther() public onlyTokenManager
    {
        if(this.balance &gt; 0) 
        {
            require(escrow.send(this.balance));
        }
    }

/// Overrides:
    function transfer(address _to, uint256 _value) returns(bool){
        require(enableTransfers);
        return super.transfer(_to,_value);
    }

    function transferFrom(address _from, address _to, uint256 _value) returns(bool){
        require(enableTransfers);
        return super.transferFrom(_from,_to,_value);
    }

    function approve(address _spender, uint256 _value) returns (bool) {
        require(enableTransfers);
        return super.approve(_spender,_value);
    }

/// Setters/getters
    function ChangeTokenManager(address _mgr) public onlyTokenManager
    {
        tokenManager = _mgr;
    }
    
    function ChangeCrowner(address _mgr) public onlyTokenCrowner
    {
        escrow = _mgr;
    }

    // Default fallback function
    function() payable 
    {
        buyTokens();
    }
}