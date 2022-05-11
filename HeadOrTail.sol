// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "VRFCoordinatorV2Interface.sol";
import "VRFConsumerBaseV2.sol";

contract HeadOrTail is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    mapping(uint256 => bool) public request_completed;
    mapping(uint256 => uint256) public amount_bet;
    mapping(uint256 => address) public bettor;
    mapping(uint256 => bool) public history;
    event Play(address _player, uint256 _amount, uint256 _requestId);
    event Result(
        address _player,
        uint256 _amount,
        uint256 _requestId,
        bool _win
    );

    // Rinkeby coordinator. For other networks,
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

    bytes32 keyHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    uint32 numWords = 1;

    uint256[] public s_randomWords;
    uint256 public rdm;
    uint256 public s_requestId;
    address s_owner;

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    function play() public payable returns (uint256 _requestId) {
        // Will revert if subscription is not set and funded.
        _requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requestId = _requestId;
        amount_bet[_requestId] = msg.value;
        bettor[_requestId] = msg.sender;
        emit Play(msg.sender, msg.value, _requestId);
    }

    function fulfillRandomWords(
        uint256 _requestId, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
        rdm = s_randomWords[0];
        bool win = (rdm % 2 == 0);

        if (win) {
            payable(bettor[_requestId]).transfer(
                (1900 * amount_bet[_requestId]) / 1000
            );
        }
        request_completed[_requestId] = true;
        history[_requestId] = win;
        emit Result(
            bettor[_requestId],
            amount_bet[_requestId],
            _requestId,
            win
        );
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }

    function balance() public view returns (uint256 _balance) {
        _balance = address(this).balance;
    }

    receive() external payable {}
}
