pragma solidity >=0.7.0 <0.9.0;

contract RPSGame {
    address Alice = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address Bob = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    mapping(address => bytes32) public hashed_choices;
    mapping(address => bool) public hash_submitted;
    mapping(address => string) public choices;
    mapping(address => bool) public has_revealed;
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

        if ((!has_revealed[Alice] && has_revealed[Bob]) || // Bob winning // has_revealed only true when choice is properly revealed
            (keccak256(bytes(choices[Alice])) == R && keccak256(bytes(choices[Bob])) == P) ||
            (keccak256(bytes(choices[Alice])) == P && keccak256(bytes(choices[Bob])) == S) ||
            (keccak256(bytes(choices[Alice])) == S && keccak256(bytes(choices[Bob])) == R))
            payable(Bob).transfer(2 ether);

        else if ((has_revealed[Alice] && !has_revealed[Bob]) || // Alice winning
                (keccak256(bytes(choices[Alice])) == R && keccak256(bytes(choices[Bob])) == S) ||
                (keccak256(bytes(choices[Alice])) == P && keccak256(bytes(choices[Bob])) == R) ||
                (keccak256(bytes(choices[Alice])) == S && keccak256(bytes(choices[Bob])) == P))
            payable(Alice).transfer(2 ether);

        else { // Ties
            payable(Alice).transfer(1 ether);
            payable(Bob).transfer(1 ether);
        }
        finished = true;
    }
}