pragma solidity ^0.4.18;
pragma solidity ^0.4.18;

contract EtherealFoundationOwned {
	address private Owner;
    
	function IsOwner(address addr) view public returns(bool)
	{
	    return Owner == addr;
	}
	
	function TransferOwner(address newOwner) public onlyOwner
	{
	    Owner = newOwner;
	}
	
	function EtherealFoundationOwned() public
	{
	    Owner = msg.sender;
	}
	
	function Terminate() public onlyOwner
	{
	    selfdestruct(Owner);
	}
	
	modifier onlyOwner(){
        require(msg.sender == Owner);
        _;
    }
}

contract EtherealCharity  is EtherealFoundationOwned{
    string public constant CONTRACT_NAME = &quot;EtherealCharity&quot;;
    string public constant CONTRACT_VERSION = &quot;A&quot;;
    string public constant CAUSE = &quot;EtherealCharity Creation&quot;;
    string public constant URL = &quot;none&quot;;
    string public constant QUOTE = &quot;&#39;A man who procrastinates in his choosing will inevitably have his choice made for him by circumstance.&#39; -Hunter S. Thompson&quot;;
    
    
    event RecievedDonation(address indexed from, uint256 value, string note);
    function Donate(string note)  public payable{
        RecievedDonation(msg.sender, msg.value, note);
    }
    
    //this is the fallback
    event RecievedAnonDonation(address indexed from, uint256 value);
	function () payable public {
		RecievedAnonDonation(msg.sender, msg.value);		
	}
	
	event TransferedEth(address indexed to, uint256 value);
	function TransferEth(address to, uint256 value) public onlyOwner{
	    require(this.balance &gt;= value);
	    
        if(value &gt;0)
		{
			to.transfer(value);
			TransferedEth(to, value);
		}   
	}
}