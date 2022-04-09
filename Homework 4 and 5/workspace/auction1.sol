pragma solidity >=0.7.0 <0.9.0;

contract Auction {
    uint deadline;
    mapping(address => bytes32) public hashed_bid_prices;
    mapping(address => bool) public bidded;
    mapping(address => bool) public revealed_bids;
    mapping(address => bool) public got_refunded;
    address winner;
    uint winningBid;

    constructor() {
        deadline = block.number + 7200;     // 24*60*60/12, assuming avg. time for one Ethereum block to be mined is 12 seconds
    }

    function bid(bytes32 hashed_bid) public payable {
        require(block.number < deadline);   // Approximated time bound
        require(msg.value == 50 ether);
        require(!bidded[msg.sender]);       // prevent bidding more than once, automatic one-time deposit payment
        
        bidded[msg.sender] = true;
        hashed_bid_prices[msg.sender] = hashed_bid;
    }

    function revealBid(uint org_bid, string memory nonce) public payable {
        require(block.number >= deadline);              // Can reveal the bid only after the deadline
        require(block.number < deadline + 3600);        // Can reveal for the next 12 hours
        require(bidded[msg.sender]);                    // Only people who bidded by the deadline can reveal their original bid
        require(!revealed_bids[msg.sender]);            // must have not revealed the bid yet
        require(msg.value == org_bid);                  // paying when revealing, unrevealed bids are ignored
        
        bytes32 temp_hashed_bid = sha256(bytes.concat(abi.encodePacked(org_bid), bytes(nonce)));
        require(hashed_bid_prices[msg.sender] == temp_hashed_bid);
        revealed_bids[msg.sender] = true;

        if (winner == address(0)) {
            winner = msg.sender;
            winningBid = org_bid;
        } else if (org_bid > winningBid) { 
            payable(winner).transfer(winningBid);
            winner = msg.sender;
            winningBid = org_bid;
        } else {
            payable(msg.sender).transfer(msg.value);
        }
    }

    function getRefund() public {
        require(block.number >= deadline + 3600);   // after the revealing period
        require(!got_refunded[msg.sender], "Your already got refunded");
        require(revealed_bids[msg.sender], "Can get refunded only when you correctly revealed your orginal bid");

        got_refunded[msg.sender] = true;            // preventing multiple refunds
        payable(msg.sender).transfer(50 ether);     // refund the deposit
    }
}