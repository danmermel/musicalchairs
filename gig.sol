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
  bool public redeemed_by_seat_owner;
  bool public redeemed_by_event_owner;

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
    redeemed_by_seat_owner = false;
    redeemed_by_event_owner = false;

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

  function redeem_ticket (address _redeemer) {
    if (event_owner != msg.sender) throw;    
    if (status != 1) throw;
    if (_redeemer == event_owner) {
      redeemed_by_event_owner = true;
    }
    if (_redeemer == seat_owner) {
      redeemed_by_seat_owner = true;
    }

    // kill the contract and send its value to the artist
    if (redeemed_by_seat_owner && redeemed_by_event_owner) {
      suicide(artist);
    }
  }


  function mark_unlocked () {
    if (event_owner != msg.sender) throw;
    if (event_time > now) throw;
    // kill the contract and send its value to the artist
    suicide(artist);
  }

  function mark_cancelled() {
    if (event_owner != msg.sender) throw;
    if (status != 1) throw;
    suicide(seat_owner);
  }

}

contract gig {

  bytes32 public venue;
  bytes32 public event_name;
  uint public event_time;
  address public event_owner;
  address public artist;
  mapping (address => uint) public seating_plan;
  mapping (uint => seat) public seating_list;
  uint public seat_count;
  uint public seats_sold;

  event Log_seat_created (address seat_address);
  event Log_seat_bought (address seat_bought);
  event Log_ticket_redeemed (address ticket_redeemed, address redeemer);


  function gig(bytes32 _venue, bytes32 _event_name, uint _event_time, address _artist) {
    venue = _venue;
    event_name = _event_name;
    event_time = _event_time;
    event_owner = msg.sender;
    artist = _artist;
    seat_count = 0;
    seats_sold = 0;
  }

  function create_seat(bytes32 _seat_name, uint _price, uint _sellable_from, uint _sellable_until) {
    if (event_owner != msg.sender) throw;
    var s = new seat(venue, event_name, _seat_name, _price, event_time, artist, _sellable_from, _sellable_until);
    // list of created seats in an array indexed by integer
    seating_list[seat_count] = s;
    // list of 1s indexed by seat addresses
    seating_plan[s] = 1;
    seat_count++;
    Log_seat_created(s);
  }

  function buy_seat (address _seat_address) payable {
    if (seating_plan[_seat_address] != 1) throw;
    seat existing_seat = seat(_seat_address);
    existing_seat.buy_seat.value(msg.value)(msg.sender);
    seats_sold++;
    Log_seat_bought(existing_seat);
  }

  function buy_seats (address _seat_address1, address _seat_address2, address _seat_address3, address _seat_address4) payable {

    if (_seat_address1 != address(0)) {
      if (seating_plan[_seat_address1] != 1) throw;
      seat existing_seat1 = seat(_seat_address1);
      var seat_cost1 = existing_seat1.price();
      existing_seat1.buy_seat.value(seat_cost1)(msg.sender);
      seats_sold++;
      Log_seat_bought(existing_seat1);
    }

    if (_seat_address2 != address(0)) {
      if (seating_plan[_seat_address2] != 1) throw;
      seat existing_seat2 = seat(_seat_address2);
      var seat_cost2 = existing_seat2.price();
      existing_seat2.buy_seat.value(seat_cost2)(msg.sender);
      seats_sold++;
      Log_seat_bought(existing_seat2);
    }

    if (_seat_address3 != address(0)) {
      if (seating_plan[_seat_address3] != 1) throw;
      seat existing_seat3 = seat(_seat_address3);
      var seat_cost3 = existing_seat3.price();
      existing_seat3.buy_seat.value(seat_cost3)(msg.sender);
      seats_sold++;
      Log_seat_bought(existing_seat3);
    }

    if (_seat_address4 != address(0)) {
      if (seating_plan[_seat_address4] != 1) throw;
      seat existing_seat4 = seat(_seat_address4);
      var seat_cost4 = existing_seat4.price();
      existing_seat4.buy_seat.value(seat_cost4)(msg.sender);
      seats_sold++;
      Log_seat_bought(existing_seat4);
    }

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
    if (existing_seat.seat_owner() != msg.sender && event_owner != msg.sender) throw;
    existing_seat.redeem_ticket(msg.sender);
    Log_ticket_redeemed(existing_seat, msg.sender);

  }

}
