pragma solidity ^0.4.0;

contract seat {
  
  uint public status; 
  // status can be 0 (unsold), 1 (sold), 2 (used), 3 (cancelled), 4 (unlocked)
  bytes32 public venue;
  bytes32 public event_name;
  bytes32 public seat;
  uint public price;
  uint public event_time;
  address public event_owner;
  address public artist;
  address public seat_owner;
  uint public sellable_from;
  uint public sellable_until;
  uint redemption_code;

  function seat(bytes32 _venue, bytes32 _event_name, bytes32 _seat, uint _price, uint _event_time, address _artist, uint _sellable_from, uint _sellable_until) {
    status =0;
    event_owner = msg.sender;
    venue = _venue;
    event_name = _event_name;
    seat = _seat;
    price = _price;
    event_time = _event_time;
    artist = _artist;
    sellable_from = _sellable_from;
    sellable_until = _sellable_until;
    redemption_code =0;
  }

  function buy_seat () payable {
    if (status !=0) throw;
    if (msg.value != price) throw;
    if (sellable_from > now) throw;
    if (sellable_until < now) throw;
    status = 1;
    seat_owner = msg.sender;
    redemption_code =42;
  }

  function mark_used (uint _redemption_code) {
    if (event_owner != msg.sender) throw;
    if (status != 1) throw;
    if (_redemption_code != redemption_code) throw;
    status = 2;
    if (!artist.send(this.balance)) throw;

  }

  function mark_unlocked () {
    if (msg.sender != artist) throw;
    if (event_time > now) throw;
    if (!artist.send(this.balance)) throw;
   
  }

  function mark_cancelled() {
    if (msg.sender != artist ) throw;
    if (status != 1) throw;
    if (!seat_owner.send(this.balance)) throw;
  }

  function get_redemption_code() constant returns(uint) {
     if (msg.sender != seat_owner) throw;
     if (status != 1) throw;
     return redemption_code;
     
  }
}


