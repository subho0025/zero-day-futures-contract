module zero_day_futures::zero_day_future {

    struct MarketState has key{
        admin_address : address,
        curr_price : u128,
        duration : u128
    }

    struct Trader has key{
        balance : u128,
        locked_balance : u128,
        trades : vector<Trade>
    }

    struct Trade has store{
        id : u64,
        next_id: u64,
        direction : bool,  //1 -> long , 0-> short
        stake: u128,
        entry_price: u128,
        open_time: u128,
        expire_time: u128,
        status: bool,
        settle_price: u128,
        settle_res: bool,
        pnl_amount: u128
    }

    
}
