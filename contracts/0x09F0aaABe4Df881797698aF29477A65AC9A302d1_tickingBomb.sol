contract tickingBomb {

    struct team {
        string name;
        uint lastUpdate;
        address[] members;
        uint nbrMembers;
    }

    uint public constant DELAY =  60 * 60 * 12; // 12 Hours
    uint public constant INVEST_AMOUNT = 500 finney; // 0.5 ETH
    uint constant FEE = 3;

    team public red;
    team public blue;

    mapping(address =&gt; uint) public balances;
    address creator;

    string[] public historyWinner;
    uint[] public historyRed;
    uint[] public historyBlue;
    uint public gameNbr;

    function tickingBomb() {
        newRound();
        creator = msg.sender;
        gameNbr = 0;
    }

    function helpRed() {
        uint i;
        uint amount = msg.value;

        // Check if Exploded, if so save the previous game
        // And create a new round
        checkIfExploded();

        // Update the TimeStamp
        red.lastUpdate = block.timestamp;

        // Split the incoming money every INVEST_AMOUNT
        while (amount &gt;= INVEST_AMOUNT) {
            red.members.push(msg.sender);
            red.nbrMembers++;
            amount -= INVEST_AMOUNT;
        }

        // If there is still some money in the balance, sent it back
        if (amount &gt; 0) {
            msg.sender.send(amount);
        }
    }

    function helpBlue() {
        uint i;
        uint amount = msg.value;

        // Check if Exploded, if so save the previous game
        // And create a new game
        checkIfExploded();

        // Update the TimeStamp
        blue.lastUpdate = block.timestamp;

        // Split the incoming money every 100 finneys
        while (amount &gt;= INVEST_AMOUNT) {
            blue.members.push(msg.sender);
            blue.nbrMembers++;
            amount -= INVEST_AMOUNT;
        }

        // If there is still some money in the balance, sent it back
        if (amount &gt; 0) {
            msg.sender.send(amount);
        }
    }

    function checkIfExploded() {
        if (checkTime()) {
            newRound();
        }
    }

    function checkTime() private returns(bool exploded) {
        uint i;
        uint lostAmount = 0;
        uint gainPerMember = 0;
        uint feeCollected = 0;

        // If Red and Blue have exploded at the same time, return the amounted invested
        if (red.lastUpdate == blue.lastUpdate &amp;&amp; red.lastUpdate + DELAY &lt; block.timestamp) {
            for (i = 0; i &lt; red.members.length; i++) {
                balances[red.members[i]] += INVEST_AMOUNT;
            }
            for (i = 0; i &lt; blue.members.length; i++) {
                balances[blue.members[i]] += INVEST_AMOUNT;
            }

            historyWinner.push(&#39;Tie between Red and Blue&#39;);
            historyRed.push(red.nbrMembers);
            historyBlue.push(blue.nbrMembers);
            gameNbr++;
            return true;
        }

        // Take the older timestamp
        if (red.lastUpdate &lt; blue.lastUpdate) {
            // Check if the Red bomb exploded
            if (red.lastUpdate + DELAY &lt; block.timestamp) {
                // Calculate the lost amount by the red team
                // Number of Red member * Invested amount per user  *
                feeCollected += (red.nbrMembers * INVEST_AMOUNT * FEE / 100);
                balances[creator] += feeCollected;
                lostAmount = (red.nbrMembers * INVEST_AMOUNT) - feeCollected;

                gainPerMember = lostAmount / blue.nbrMembers;
                for (i = 0; i &lt; blue.members.length; i++) {
                    balances[blue.members[i]] += (INVEST_AMOUNT + gainPerMember);
                }

                historyWinner.push(&#39;Red&#39;);
                historyRed.push(red.nbrMembers);
                historyBlue.push(blue.nbrMembers);
                gameNbr++;
                return true;
            }
            return false;
        } else {
            // Check if the Blue bomb exploded
            if (blue.lastUpdate + DELAY &lt; block.timestamp) {
                // Calculate the lost amount by the red team
                // Number of Red member * Invested amount per user  *
                feeCollected += (blue.nbrMembers * INVEST_AMOUNT * FEE / 100);
                balances[creator] += feeCollected;
                lostAmount = (blue.nbrMembers * INVEST_AMOUNT) - feeCollected;
                gainPerMember = lostAmount / red.nbrMembers;
                for (i = 0; i &lt; red.members.length; i++) {
                    balances[red.members[i]] += (INVEST_AMOUNT + gainPerMember);
                }

                historyWinner.push(&#39;Blue&#39;);
                historyRed.push(red.nbrMembers);
                historyBlue.push(blue.nbrMembers);
                gameNbr++;
                return true;
            }
            return false;
        }
    }

    function newRound() private {
        red.name = &quot;Red team&quot;;
        blue.name = &quot;Blue team&quot;;
        red.lastUpdate = block.timestamp;
        blue.lastUpdate = block.timestamp;
        red.nbrMembers = 0;
        blue.nbrMembers = 0;
        red.members = new address[](0);
        blue.members = new address[](0);
    }

    function() {
        // Help the oldest timestamp (going to explode first)
        if (red.lastUpdate &lt; blue.lastUpdate) {
            helpRed();
        } else {
            helpBlue();
        }
    }

    function collectBalance() {
        msg.sender.send(balances[msg.sender]);
        balances[msg.sender] = 0;
    }

    // Allow the creator to send their balances to the players
    function sendBalance(address player) {
        if (msg.sender == creator) {
            player.send(balances[player]);
        }
    }

    function newOwner(address newOwner) {
        if (msg.sender == creator) {
            creator = newOwner;
        }
    }

}