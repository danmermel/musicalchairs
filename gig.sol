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
  address public gig_address;

  function seat(bytes32 _venue, bytes32 _event_name, bytes32 _seat_name, uint _price, uint _event_time, address _artist, uint _sellable_from, uint _sellable_until, address _event_owner) {
    status =0;
    event_owner = _event_owner;
    gig_address = msg.sender;
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
    if (gig_address != msg.sender) throw;
    if (status !=0) throw;
    if (msg.value != price) throw;
    if (sellable_from > now) throw;
    if (sellable_until < now) throw;
    status = 1;
    seat_owner = _seat_owner;
  }

  function redeem_seat (bytes32 _msg, uint8 _v, bytes32 _r, bytes32 _s) constant returns (bool) {
    // if (gig_address != msg.sender) throw;    
    if (status != 1) throw;
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    bytes32 prefixedHash = sha3(prefix, _msg);
    if (ecrecover(prefixedHash, _v, _r, _s) == seat_owner) {
    // kill the contract and send its value to the artist
      suicide(artist);
      return true;
    }
    return false;
  }

  function kill() {
    suicide(artist);
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
  event Log_seat_bought (address seat_address);
  event Log_seat_redeemed (address seat_address, address redeemer);


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
    var s = new seat(venue, event_name, _seat_name, _price, event_time, artist, _sellable_from, _sellable_until, event_owner);
    // list of created seats in an array indexed by integer
    seating_list[seat_count] = s;
    // list of 1s indexed by seat addresses
    seating_plan[s] = 1;
    seat_count++;
    Log_seat_created(s);
  }

  function buy_seat (address _seat_address, address _seat_owner) payable {
    if (seating_plan[_seat_address] != 1) throw;
    seat existing_seat = seat(_seat_address);
    if (_seat_owner == 0) {
      _seat_owner = msg.sender;
    }
    existing_seat.buy_seat.value(msg.value)(_seat_owner);
    seats_sold++;
    Log_seat_bought(existing_seat);
  }

  function buy_seats (address _seat_address1, address _seat_owner1, address _seat_address2, address _seat_owner2, address _seat_address3, address _seat_owner3) payable {

    if (_seat_address1 != address(0)) {
      if (seating_plan[_seat_address1] != 1) throw;
      seat existing_seat1 = seat(_seat_address1);
      var seat_cost1 = existing_seat1.price();
      if (_seat_owner1 == 0) {
        _seat_owner1 = msg.sender;
      }
      existing_seat1.buy_seat.value(seat_cost1)(_seat_owner1);
      seats_sold++;
      Log_seat_bought(existing_seat1);
    }

    if (_seat_address2 != address(0)) {
      if (seating_plan[_seat_address2] != 1) throw;
      seat existing_seat2 = seat(_seat_address2);
      var seat_cost2 = existing_seat2.price();
      if (_seat_owner2 == 0) {
        _seat_owner2 = msg.sender;
      }
      existing_seat2.buy_seat.value(seat_cost2)(_seat_owner2);
      seats_sold++;
      Log_seat_bought(existing_seat2);
    }

    if (_seat_address3 != address(0)) {
      if (seating_plan[_seat_address3] != 1) throw;
      seat existing_seat3 = seat(_seat_address3);
      var seat_cost3 = existing_seat3.price();
      if (_seat_owner3 == 0) {
        _seat_owner3 = msg.sender;
      }
      existing_seat3.buy_seat.value(seat_cost3)(_seat_owner3);
      seats_sold++;
      Log_seat_bought(existing_seat3);
    }

  }


  function redeem_seat(address _seat_to_redeem, bytes32 _msg, uint8 _v, bytes32 _r, bytes32 _s ) constant returns (bool) {
   
    seat existing_seat = seat (_seat_to_redeem);

    // if (gig_address != msg.sender) throw;
    //if (status != 1) throw;
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    bytes32 prefixedHash = sha3(prefix, _msg);
    if (ecrecover(prefixedHash, _v, _r, _s) == existing_seat.seat_owner()) {
    // kill the contract and send its value to the artist
      existing_seat.kill();
      Log_seat_redeemed(existing_seat, msg.sender);
    //suicide(artist);
      return true;
    }
    return false;


//    if (existing_seat.event_owner() != msg.sender) throw;
//    if (existing_seat.redeem_seat(_msg, _v, _r, _s) ) {
//      Log_seat_redeemed(existing_seat, msg.sender);
//   }
  }

}
