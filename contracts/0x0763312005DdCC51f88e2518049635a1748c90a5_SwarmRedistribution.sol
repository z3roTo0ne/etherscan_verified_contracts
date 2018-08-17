pragma solidity ^0.4.6;

contract Campaign {
    
    address public JohanNygren;
    bool campaignOpen;
    
    function Campaign() {
        JohanNygren = 0x948176CB42B65d835Ee4324914B104B66fB93B52;
        campaignOpen = true;
    }
    
    modifier onlyJohan {
      if(msg.sender != JohanNygren) throw;
      _;
    }

    modifier isOpen {
      if(campaignOpen != true) throw;
      _;
    }
    
    function closeCampaign() onlyJohan {
        campaignOpen = false;
    }
    
}

contract RES is Campaign { 

    /* Public variables of the token */
    string public name;
    string public symbol;
    uint8 public decimals;
    
    uint public totalSupply;
    
    /* This creates an array with all balances */
    mapping (address =&gt; uint256) public balanceOf;
    
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    

    /* Bought or sold */

    event Bought(address from, uint amount);
    event Sold(address from, uint amount);
    event BoughtViaJohan(address from, uint amount);

    /* Initializes contract with name, symbol and decimals */

    function RES() {
        name = &quot;RES&quot;;     
        symbol = &quot;RES&quot;;
        decimals = 18;
    }
    
    function buy() isOpen public payable {
      balanceOf[msg.sender] += msg.value;
      totalSupply += msg.value;
      Bought(msg.sender, msg.value);
    }  

    function sell(uint256 _value) public {
      if(balanceOf[msg.sender] &lt; _value) throw;
      balanceOf[msg.sender] -= _value;
    
      if (!msg.sender.send(_value)) throw;

      totalSupply -= _value;
      Sold(msg.sender, _value);

    }

}

contract SwarmRedistribution is Campaign, RES {
    
    struct dividendPathway {
      address from;
      uint amount;
      uint timeStamp;
    }

    mapping(address =&gt; dividendPathway[]) public dividendPathways;
    
    mapping(address =&gt; bool) public isHuman;
    
    mapping(address =&gt; uint256) public totalBasicIncome;

    uint taxRate;
    uint exchangeRate;
    
    address[] humans;
    mapping(address =&gt; bool) inHumans;
    
    event Swarm(address indexed leaf, address indexed node, uint256 share);

    function SwarmRedistribution() {
      
    /* Tax-rate in parts per thousand */
    taxRate = 20;
    
    /* Exchange-rate in parts per thousand */
    exchangeRate = 0;
    
    isHuman[JohanNygren] = true;
    
    }

    function buyViaJohan() isOpen public payable {
      balanceOf[msg.sender] += msg.value;
      totalSupply += msg.value;  

      /* Create the dividend pathway */
      dividendPathways[msg.sender].push(dividendPathway({
                                      from: JohanNygren, 
                                      amount:  msg.value,
                                      timeStamp: now
                                    }));

      BoughtViaJohan(msg.sender, msg.value);
    }


    /* Send coins */
    function transfer(address _to, uint256 _value) isOpen {
        /* reject transaction to self to prevent dividend pathway loops*/
        if(_to == msg.sender) throw;
        
        /* if the sender doenst have enough balance then stop */
        if (balanceOf[msg.sender] &lt; _value) throw;
        if (balanceOf[_to] + _value &lt; balanceOf[_to]) throw;
        
        /* Calculate tax */
        uint256 taxCollected = _value * taxRate / 1000;
        uint256 sentAmount;

        /* Create the dividend pathway */
        dividendPathways[_to].push(dividendPathway({
                                        from: msg.sender, 
                                        amount:  _value,
                                        timeStamp: now
                                      }));
                                      
        iterateThroughSwarm(_to, now, taxCollected);

        if(humans.length &gt; 0) {
            doSwarm(_to, taxCollected);
            sentAmount = _value;
        }
        else sentAmount = _value - taxCollected; /* Return tax */
        

        /* Add and subtract new balances */

        balanceOf[msg.sender] -= sentAmount;
        balanceOf[_to] += _value - taxCollected;

        /* Notifiy anyone listening that this transfer took place */
        Transfer(msg.sender, _to, sentAmount);
    }
    
    
    function iterateThroughSwarm(address _node, uint _timeStamp, uint _taxCollected) internal {
        for(uint i = 0; i &lt; dividendPathways[_node].length; i++) {
            
            uint timeStamp = dividendPathways[_node][i].timeStamp;
            if(timeStamp &lt;= _timeStamp) {
                
                address node = dividendPathways[_node][i].from;
                
              if(
                  isHuman[node] == true 
                  &amp;&amp; 
                  inHumans[node] == false
                ) 
                {
                    humans.push(node);
                    inHumans[node] = true;
                }

              if(dividendPathways[_node][i].amount - _taxCollected &gt; 0) {
                dividendPathways[_node][i].amount -= _taxCollected; 
              }
              else removeDividendPathway(_node, i);
                                
              iterateThroughSwarm(node, timeStamp, _taxCollected);
            }
        }
    }

    function doSwarm(address _leaf, uint256 _taxCollected) internal {
      
      uint256 share = _taxCollected / humans.length;
    
      for(uint i = 0; i &lt; humans.length; i++) {

        balanceOf[humans[i]] += share;
        totalBasicIncome[humans[i]] += share;
        
        inHumans[humans[i]] = false;
        
        /* Notifiy anyone listening that this swarm took place */
        Swarm(_leaf, humans[i], share);
      }
      delete humans;
    }
    
    function removeDividendPathway(address node, uint index) internal {
                delete dividendPathways[node][index];
                for (uint i = index; i &lt; dividendPathways[node].length - 1; i++) {
                        dividendPathways[node][i] = dividendPathways[node][i + 1];
                }
                dividendPathways[node].length--;
        }

}