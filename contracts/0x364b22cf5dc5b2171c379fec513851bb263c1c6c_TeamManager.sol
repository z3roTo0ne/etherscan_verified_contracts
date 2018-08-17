pragma solidity ^0.4.24;
/* -Team Manager- v0.2.5
 *
 *         ┌──────────────────────────────────────────────────────────────────────┐
 *         │ Que up intensely spectacular intro music...  In walks, Team Just.    │
 *         │                         Everyone goes crazy.                         │
 *         │ This is a companion to MSFun.  It&#39;s a central database of Devs and   │
 *         │ Admin&#39;s that we can import to any dapp to allow them management      │
 *         │ permissions.                                                         │
 *         └──────────────────────────────────────────────────────────────────────┘
 *                                ┌────────────────────┐
 *                                │ Setup Instructions │
 *                                └────────────────────┘
 * (Step 1) import this contracts interface into your contract
 *
 *    import &quot;./TeamManagerInterface.sol&quot;;
 *
 * (Step 2) set up the interface to point to the TeamManager contract
 *
 *    TeamManagerInterface constant TeamManager = TeamManagerInterface(0x464904238b5CdBdCE12722A7E6014EC1C0B66928);
 *
 *    modifier onlyAdmins() {require(TeamManager.isAdmin(msg.sender) == true, &quot;onlyAdmins failed - msg.sender is not an admin&quot;); _;}
 *    modifier onlyDevs() {require(TeamManager.isDev(msg.sender) == true, &quot;onlyDevs failed - msg.sender is not a dev&quot;); _;}
 *                                ┌────────────────────┐
 *                                │ Usage Instructions │
 *                                └────────────────────┘
 * use onlyAdmins() and onlyDevs() modifiers as you normally would on any function
 * you wish to restrict to admins/devs registered with this contract.
 *
 * to get required signatures for admins or devs
 *       uint256 x = TeamManager.requiredSignatures();
 *       uint256 x = TeamManager.requiredDevSignatures();
 *
 * to get admin count or dev count
 *       uint256 x = TeamManager.adminCount();
 *       uint256 x = TeamManager.devCount();
 *
 * to get the name of an admin (in bytes32 format)
 *       bytes32 x = TeamManager.adminName(address);
 */

interface BankForwarderInterface {
    function deposit() external payable returns(bool);
    function status() external view returns(address, address, bool);
    function startMigration(address _newCorpBank) external returns(bool);
    function cancelMigration() external returns(bool);
    function finishMigration() external returns(bool);
    function setup(address _firstCorpBank) external;
}

contract TeamManager {
    BankForwarderInterface private TipJar = BankForwarderInterface(0x0);
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // SET UP MSFun (note, check signers by name is modified from MSFun sdk)
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    MSFun.Data private msData;
    function deleteAnyProposal(bytes32 _whatFunction) onlyDevs() public {MSFun.deleteProposal(msData, _whatFunction);}
    function checkData(bytes32 _whatFunction) onlyAdmins() public view returns(bytes32 message_data, uint256 signature_count) {return(MSFun.checkMsgData(msData, _whatFunction), MSFun.checkCount(msData, _whatFunction));}
    function checkSignersByName(bytes32 _whatFunction, uint256 _signerA, uint256 _signerB, uint256 _signerC) onlyAdmins() public view returns(bytes32, bytes32, bytes32) {return(this.adminName(MSFun.checkSigner(msData, _whatFunction, _signerA)), this.adminName(MSFun.checkSigner(msData, _whatFunction, _signerB)), this.adminName(MSFun.checkSigner(msData, _whatFunction, _signerC)));}

    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // DATA SETUP
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    struct Admin {
        bool isAdmin;
        bool isDev;
        bytes32 name;
    }
    mapping (address =&gt; Admin) admins_;

    uint256 adminCount_;
    uint256 devCount_;
    uint256 requiredSignatures_;
    uint256 requiredDevSignatures_;

    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // CONSTRUCTOR
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    constructor()
    public
    {
        address alice = 0x0A6065569370BF9Ee13c3A0da1cf6201B1870576;
        address bob   = 0x04369d3C731d1016Fae5fa516C964bdE64A2C92F;
        address chloe = 0x3aE32614A97b2a7A6e05626856Df82635877ED56;
        address david = 0xa7B254eedcbCe806CDbC94C20CDb639E1Ac75630;
        address eve   = 0x9490b19a5A0536b99069A629095A24B9129DF0b6;

        admins_[alice] = Admin(true, true, &quot;alice&quot;);
        admins_[bob]   = Admin(true, true, &quot;bob&quot;);
        admins_[chloe] = Admin(true, true, &quot;chloe&quot;);
        admins_[david] = Admin(true, true, &quot;david&quot;);
        admins_[eve]   = Admin(true, true, &quot;eve&quot;);

        adminCount_ = 5;
        devCount_ = 5;
        requiredSignatures_ = 1;
        requiredDevSignatures_ = 1;
    }
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // FALLBACK, SETUP, AND FORWARD
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // there should never be a balance in this contract.  but if someone
    // does stupidly send eth here for some reason.  we can forward it
    // to tipjar
    function ()
    public
    payable
    {
        TipJar.deposit.value(address(this).balance)();
    }

    function setup(address _addr)
    onlyDevs()
    public
    {
        require( address(TipJar) == address(0) );
        TipJar = BankForwarderInterface(_addr);
    }

    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // MODIFIERS
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    modifier onlyDevs()
    {
        require(admins_[msg.sender].isDev == true, &quot;onlyDevs failed - msg.sender is not a dev&quot;);
        _;
    }

    modifier onlyAdmins()
    {
        require(admins_[msg.sender].isAdmin == true, &quot;onlyAdmins failed - msg.sender is not an admin&quot;);
        _;
    }

    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // DEV ONLY FUNCTIONS
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    /**
    * @dev DEV - use this to add admins.  this is a dev only function.
    * @param _who - address of the admin you wish to add
    * @param _name - admins name
    * @param _isDev - is this admin also a dev?
    */
    function addAdmin(address _who, bytes32 _name, bool _isDev)
    public
    onlyDevs()
    {
        if (MSFun.multiSig(msData, requiredDevSignatures_, &quot;addAdmin&quot;) == true)
        {
            MSFun.deleteProposal(msData, &quot;addAdmin&quot;);

            // must check this so we dont mess up admin count by adding someone
            // who is already an admin
            if (admins_[_who].isAdmin == false)
            {

                // set admins flag to true in admin mapping
                admins_[_who].isAdmin = true;

                // adjust admin count and required signatures
                adminCount_ += 1;
                requiredSignatures_ += 1;
            }

            // are we setting them as a dev?
            // by putting this outside the above if statement, we can upgrade existing
            // admins to devs.
            if (_isDev == true)
            {
                // bestow the honored dev status
                admins_[_who].isDev = _isDev;

                // increase dev count and required dev signatures
                devCount_ += 1;
                requiredDevSignatures_ += 1;
            }
        }

        // by putting this outside the above multisig, we can allow easy name changes
        // without having to bother with multisig.  this will still create a proposal though
        // so use the deleteAnyProposal to delete it if you want to
        admins_[_who].name = _name;
    }

    /**
    * @dev DEV - use this to remove admins. this is a dev only function.
    * -requirements: never less than 1 admin
    *                never less than 1 dev
    *                never less admins than required signatures
    *                never less devs than required dev signatures
    * @param _who - address of the admin you wish to remove
    */
    function removeAdmin(address _who)
    public
    onlyDevs()
    {
        // we can put our requires outside the multisig, this will prevent
        // creating a proposal that would never pass checks anyway.
        require(adminCount_ &gt; 1, &quot;removeAdmin failed - cannot have less than 2 admins&quot;);
        require(adminCount_ &gt;= requiredSignatures_, &quot;removeAdmin failed - cannot have less admins than number of required signatures&quot;);
        if (admins_[_who].isDev == true)
        {
            require(devCount_ &gt; 1, &quot;removeAdmin failed - cannot have less than 2 devs&quot;);
            require(devCount_ &gt;= requiredDevSignatures_, &quot;removeAdmin failed - cannot have less devs than number of required dev signatures&quot;);
        }

        // checks passed
        if (MSFun.multiSig(msData, requiredDevSignatures_, &quot;removeAdmin&quot;) == true)
        {
            MSFun.deleteProposal(msData, &quot;removeAdmin&quot;);

            // must check this so we dont mess up admin count by removing someone
            // who wasnt an admin to start with
            if (admins_[_who].isAdmin == true) {

                //set admins flag to false in admin mapping
                admins_[_who].isAdmin = false;

                //adjust admin count and required signatures
                adminCount_ -= 1;
                if (requiredSignatures_ &gt; 1)
                {
                    requiredSignatures_ -= 1;
                }
            }

            // were they also a dev?
            if (admins_[_who].isDev == true) {

                //set dev flag to false
                admins_[_who].isDev = false;

                //adjust dev count and required dev signatures
                devCount_ -= 1;
                if (requiredDevSignatures_ &gt; 1)
                {
                    requiredDevSignatures_ -= 1;
                }
            }
        }
    }

    /**
    * @dev DEV - change the number of required signatures.  must be between
    * 1 and the number of admins.  this is a dev only function
    * @param _howMany - desired number of required signatures
    */
    function changeRequiredSignatures(uint256 _howMany)
    public
    onlyDevs()
    {
        // make sure its between 1 and number of admins
        require(_howMany &gt; 0 &amp;&amp; _howMany &lt;= adminCount_, &quot;changeRequiredSignatures failed - must be between 1 and number of admins&quot;);

        if (MSFun.multiSig(msData, requiredDevSignatures_, &quot;changeRequiredSignatures&quot;) == true)
        {
            MSFun.deleteProposal(msData, &quot;changeRequiredSignatures&quot;);

            // store new setting.
            requiredSignatures_ = _howMany;
        }
    }

    /**
    * @dev DEV - change the number of required dev signatures.  must be between
    * 1 and the number of devs.  this is a dev only function
    * @param _howMany - desired number of required dev signatures
    */
    function changeRequiredDevSignatures(uint256 _howMany)
    public
    onlyDevs()
    {
        // make sure its between 1 and number of admins
        require(_howMany &gt; 0 &amp;&amp; _howMany &lt;= devCount_, &quot;changeRequiredDevSignatures failed - must be between 1 and number of devs&quot;);

        if (MSFun.multiSig(msData, requiredDevSignatures_, &quot;changeRequiredDevSignatures&quot;) == true)
        {
            MSFun.deleteProposal(msData, &quot;changeRequiredDevSignatures&quot;);

            // store new setting.
            requiredDevSignatures_ = _howMany;
        }
    }

    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // EXTERNAL FUNCTIONS
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    function requiredSignatures() external view returns(uint256) {return(requiredSignatures_);}
    function requiredDevSignatures() external view returns(uint256) {return(requiredDevSignatures_);}
    function adminCount() external view returns(uint256) {return(adminCount_);}
    function devCount() external view returns(uint256) {return(devCount_);}
    function adminName(address _who) external view returns(bytes32) {return(admins_[_who].name);}
    function isAdmin(address _who) external view returns(bool) {return(admins_[_who].isAdmin);}
    function isDev(address _who) external view returns(bool) {return(admins_[_who].isDev);}
}

library MSFun {
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // DATA SETS
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // contact data setup
    struct Data
    {
        mapping (bytes32 =&gt; ProposalData) proposal_;
    }
    struct ProposalData
    {
        // a hash of msg.data
        bytes32 msgData;
        // number of signers
        uint256 count;
        // tracking of wither admins have signed
        mapping (address =&gt; bool) admin;
        // list of admins who have signed
        mapping (uint256 =&gt; address) log;
    }

    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // MULTI SIG FUNCTIONS
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    function multiSig(Data storage self, uint256 _requiredSignatures, bytes32 _whatFunction)
    internal
    returns(bool)
    {
        // our proposal key will be a hash of our function name + our contracts address
        // by adding our contracts address to this, we prevent anyone trying to circumvent
        // the proposal&#39;s security via external calls.
        bytes32 _whatProposal = whatProposal(_whatFunction);

        // this is just done to make the code more readable.  grabs the signature count
        uint256 _currentCount = self.proposal_[_whatProposal].count;

        // store the address of the person sending the function call.  we use msg.sender
        // here as a layer of security.  in case someone imports our contract and tries to
        // circumvent function arguments.  still though, our contract that imports this
        // library and calls multisig, needs to use onlyAdmin modifiers or anyone who
        // calls the function will be a signer.
        address _whichAdmin = msg.sender;

        // prepare our msg data.  by storing this we are able to verify that all admins
        // are approving the same argument input to be executed for the function.  we hash
        // it and store in bytes32 so its size is known and comparable
        bytes32 _msgData = keccak256(msg.data);

        // check to see if this is a new execution of this proposal or not
        if (_currentCount == 0)
        {
            // if it is, lets record the original signers data
            self.proposal_[_whatProposal].msgData = _msgData;

            // record original senders signature
            self.proposal_[_whatProposal].admin[_whichAdmin] = true;

            // update log (used to delete records later, and easy way to view signers)
            // also useful if the calling function wants to give something to a
            // specific signer.
            self.proposal_[_whatProposal].log[_currentCount] = _whichAdmin;

            // track number of signatures
            self.proposal_[_whatProposal].count += 1;

            // if we now have enough signatures to execute the function, lets
            // return a bool of true.  we put this here in case the required signatures
            // is set to 1.
            if (self.proposal_[_whatProposal].count == _requiredSignatures) {
                return(true);
            }
            // if its not the first execution, lets make sure the msgData matches
        } else if (self.proposal_[_whatProposal].msgData == _msgData) {
            // msgData is a match
            // make sure admin hasnt already signed
            if (self.proposal_[_whatProposal].admin[_whichAdmin] == false)
            {
                // record their signature
                self.proposal_[_whatProposal].admin[_whichAdmin] = true;

                // update log (used to delete records later, and easy way to view signers)
                self.proposal_[_whatProposal].log[_currentCount] = _whichAdmin;

                // track number of signatures
                self.proposal_[_whatProposal].count += 1;
            }

            // if we now have enough signatures to execute the function, lets
            // return a bool of true.
            // we put this here for a few reasons.  (1) in normal operation, if
            // that last recorded signature got us to our required signatures.  we
            // need to return bool of true.  (2) if we have a situation where the
            // required number of signatures was adjusted to at or lower than our current
            // signature count, by putting this here, an admin who has already signed,
            // can call the function again to make it return a true bool.  but only if
            // they submit the correct msg data
            if (self.proposal_[_whatProposal].count == _requiredSignatures) {
                return(true);
            }
        }
    }


    // deletes proposal signature data after successfully executing a multiSig function
    function deleteProposal(Data storage self, bytes32 _whatFunction)
    internal
    {
        //done for readability sake
        bytes32 _whatProposal = whatProposal(_whatFunction);
        address _whichAdmin;

        //delete the admins votes &amp; log.   i know for loops are terrible.  but we have to do this
        //for our data stored in mappings.  simply deleting the proposal itself wouldn&#39;t accomplish this.
        for (uint256 i=0; i &lt; self.proposal_[_whatProposal].count; i++) {
            _whichAdmin = self.proposal_[_whatProposal].log[i];
            delete self.proposal_[_whatProposal].admin[_whichAdmin];
            delete self.proposal_[_whatProposal].log[i];
        }
        //delete the rest of the data in the record
        delete self.proposal_[_whatProposal];
    }

    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // HELPER FUNCTIONS
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

    function whatProposal(bytes32 _whatFunction)
    private
    view
    returns(bytes32)
    {
        return(keccak256(abi.encodePacked(_whatFunction,this)));
    }

    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // VANITY FUNCTIONS
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // returns a hashed version of msg.data sent by original signer for any given function
    function checkMsgData (Data storage self, bytes32 _whatFunction)
    internal
    view
    returns (bytes32 msg_data)
    {
        bytes32 _whatProposal = whatProposal(_whatFunction);
        return (self.proposal_[_whatProposal].msgData);
    }

    // returns number of signers for any given function
    function checkCount (Data storage self, bytes32 _whatFunction)
    internal
    view
    returns (uint256 signature_count)
    {
        bytes32 _whatProposal = whatProposal(_whatFunction);
        return (self.proposal_[_whatProposal].count);
    }

    // returns address of an admin who signed for any given function
    function checkSigner (Data storage self, bytes32 _whatFunction, uint256 _signer)
    internal
    view
    returns (address signer)
    {
        require(_signer &gt; 0, &quot;MSFun checkSigner failed - 0 not allowed&quot;);
        bytes32 _whatProposal = whatProposal(_whatFunction);
        return (self.proposal_[_whatProposal].log[_signer - 1]);
    }
}