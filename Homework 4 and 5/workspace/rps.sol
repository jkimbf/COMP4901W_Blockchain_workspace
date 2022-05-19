pragma solidity >=0.7.0 <0.9.0;

contract RPSGame {
    address Alice = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address Bob = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    mapping(address => bytes32) public hashed_choices;
    mapping(address => bool) public hash_submitted;
    mapping(address => string) public choices;
    mapping(address => bool) public has_revealed;
    mapping(address => uint256) public money_to_receive;
    mapping(address => bool) public money_claimed;
    uint gambling_money;
    uint deadline;
    bool finished;

    bytes32 R = keccak256(bytes("rock"));
    bytes32 P = keccak256(bytes("paper"));
    bytes32 S = keccak256(bytes("scissors"));

    function submitHashedChoice(bytes32 hashed_choice) public payable {
        require(msg.sender == Alice || msg.sender == Bob, "Only Alice and Bob can participate");
        require(msg.value == 1 ether, "Deposit amount must be 1 ETH");
        require(!hash_submitted[msg.sender], "You already submitted your choice");

        hash_submitted[msg.sender] = true;
        hashed_choices[msg.sender] = hashed_choice;
        gambling_money += msg.value;
        if (hash_submitted[Alice] && hash_submitted[Bob])
            deadline = block.number + 300; // 1 hour
    }

    function revealChoice(string memory choice, string memory nonce) public {
        require(msg.sender == Alice || msg.sender == Bob, "Only Alice and Bob can participate");
        require(hash_submitted[Alice] && hash_submitted[Bob], "One of the players did not submit the hased choices");
        require(block.number < deadline); // have to reveal in 1 hour
        require(!has_revealed[msg.sender]);

        bytes32 hashed_reveal = sha256(bytes.concat(bytes(choice), bytes(nonce)));
        require(hashed_choices[msg.sender] == hashed_reveal); // valid means hashed choice is equal to the prior one
        has_revealed[msg.sender] = true;
        choices[msg.sender] = choice;
    }

    function redeem() public {
        require(!finished);
        require(msg.sender == Alice || msg.sender == Bob, "Only Alice and Bob can participate");
        require((block.number >= deadline) || (has_revealed[Alice] && has_revealed[Bob]));

        bytes32 AliceChoice = keccak256(bytes(choices[Alice]));
        bytes32 BobChoice = keccak256(bytes(choices[Bob]));

        if ((!has_revealed[Alice] && has_revealed[Bob]) || // Bob winning // has_revealed only true when choice is properly revealed
            (AliceChoice == R && BobChoice == P) ||
            (AliceChoice == P && BobChoice == S) ||
            (AliceChoice == S && BobChoice == R))
            money_to_receive[Bob] = 2 ether;

        else if ((has_revealed[Alice] && !has_revealed[Bob]) || // Alice winning
                (AliceChoice == R && BobChoice == S) ||
                (AliceChoice == P && BobChoice == R) ||
                (AliceChoice == S && BobChoice == P))
            money_to_receive[Alice] = 2 ether;

        else { // Ties
            money_to_receive[Alice] = 1 ether;
            money_to_receive[Bob] = 1 ether;
        }
        finished = true;
    }

    function claimRewards() public {
        require(msg.sender == Alice || msg.sender == Bob, "Only Alice and Bob can participate");
        require(money_claimed[msg.sender] == false);
        money_claimed[msg.sender] = true;
        payable(msg.sender).transfer(money_to_receive[msg.sender]);
    }
}