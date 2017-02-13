pragma solidity ^0.4.0;

contract seat {
  
  uint public status; 
  // status can be 0 (unsold), 1 (sold), 2 (used), 3 (cancelled), 4 (unlocked)
  bytes32 public venue;
  bytes32 public event_name;
  bytes32 public seat_name;
  uint public price;
  uint public event_time;
  address public event_owner;
  address public artist;
  address public seat_owner;
  uint public sellable_from;
  uint public sellable_until;

  function seat(bytes32 _venue, bytes32 _event_name, bytes32 _seat_name, uint _price, uint _event_time, address _artist, uint _sellable_from, uint _sellable_until) {
    status =0;
    event_owner = msg.sender;
    venue = _venue;
    event_name = _event_name;
    seat_name = _seat_name;
    price = _price;
    event_time = _event_time;
    artist = _artist;
    sellable_from = _sellable_from;
    sellable_until = _sellable_until;
  }

  function buy_seat (address _seat_owner) payable {
    if (event_owner != msg.sender) throw;
    if (status !=0) throw;
    if (msg.value != price) throw;
    if (sellable_from > now) throw;
    if (sellable_until < now) throw;
    status = 1;
    seat_owner = _seat_owner;
  }

  function redeem_ticket () {
    if (event_owner != msg.sender) throw;
    if (status != 1) throw;
    status = 2;
    if (!artist.send(this.balance)) throw;

  }


  function mark_unlocked () {
    if (event_owner != msg.sender) throw;
    if (event_time > now) throw;
    if (!artist.send(this.balance)) throw;
   
  }

  function mark_cancelled() {
    if (event_owner != msg.sender) throw;
    if (status != 1) throw;
    if (!seat_owner.send(this.balance)) throw;
  }

}

contract gig {

  bytes32 public venue;
  bytes32 public event_name;
  uint public event_time;
  address public event_owner;
  address public artist;
  mapping (uint => seat) public seating_plan;
  uint public seat_count;

  function gig(bytes32 _venue, bytes32 _event_name, uint _event_time, address _artist) {
    venue = _venue;
    event_name = _event_name;
    event_time = _event_time;
    event_owner = msg.sender;
    artist = _artist;
    seat_count = 0;
  }

  function create_seat(bytes32 _seat_name, uint _price, uint _sellable_from, uint _sellable_until) {
    if (event_owner != msg.sender) throw;
    var s = new seat(venue, event_name, _seat_name, _price, event_time, artist, _sellable_from, _sellable_until);
    seating_plan[seat_count++] = s;
  }

  function buy_seat (address _seat_address) payable {
    seat existing_seat = seat(_seat_address);
    address myAddress = this;
    if (existing_seat.event_owner() != myAddress) throw;
    existing_seat.buy_seat.value(msg.value)(msg.sender);
  }

  function redemption_challenge (address _seat_to_redeem) constant returns (uint) {
    seat existing_seat = seat (_seat_to_redeem);
    if (existing_seat.seat_owner() != msg.sender) {
      return 0;
    }
    return 1;
  }

  function redeem_ticket(address _seat_to_redeem) {
    seat existing_seat = seat (_seat_to_redeem);
    if (existing_seat.seat_owner() != msg.sender) throw;
    existing_seat.redeem_ticket();
  }

}
