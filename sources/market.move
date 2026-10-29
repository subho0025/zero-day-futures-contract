module zero_day_futures::market {
    use std::signer;

    const E_UNAUTHORIZED: u64 = 1;
    const E_MARKET_ALREADY_INITIALIZED: u64 = 2;
    const E_INVALID_PRICE: u64 = 3;
    const E_INVALID_DURATION: u64 = 4;
    const E_MARKET_NOT_INITIALIZED: u64 = 5;

    struct MarketState has key {
        admin_address: address,
        curr_price: u128,
        duration: u128,
    }

    public entry fun init_market(account: &signer, price: u128, duration: u128){
        let account_addr: address = signer::address_of(account);
        assert!(account_addr == @zero_day_futures,E_UNAUTHORIZED);

        assert!(!exists<MarketState>(@zero_day_futures), E_MARKET_ALREADY_INITIALIZED);

        assert!(price > 0, E_INVALID_PRICE);
        assert!(duration > 0, E_INVALID_DURATION);

        move_to(account, MarketState {
            admin_address: account_addr,
            curr_price: price,
            duration,
        });

    }

    public entry fun update_price(admin: &signer,new_price: u128) acquires MarketState {
        assert!(exists<MarketState>(@zero_day_futures),E_MARKET_NOT_INITIALIZED);

        let admin_addr : address = signer::address_of(admin);
        let market_state : &mut MarketState= borrow_global_mut<MarketState>(@zero_day_futures);

        assert!(admin_addr == market_state.admin_address,E_UNAUTHORIZED);

        assert!(new_price > 0, E_INVALID_PRICE);

        market_state.curr_price = new_price;
    }

    #[view]
    public fun get_price(): u128 acquires MarketState {
        assert!(exists<MarketState>(@zero_day_futures),E_MARKET_NOT_INITIALIZED);

        let market_state: &MarketState =borrow_global<MarketState>(@zero_day_futures);

        market_state.curr_price
    }

    #[view]
    public fun get_duration(): u128 acquires MarketState {
        assert!(exists<MarketState>(@zero_day_futures),E_MARKET_NOT_INITIALIZED);

        let market_state: &MarketState =borrow_global<MarketState>(@zero_day_futures);

        market_state.duration
    }

    #[view]
    public fun get_admin(): address acquires MarketState {
        assert!(exists<MarketState>(@zero_day_futures),E_MARKET_NOT_INITIALIZED);

        let market_state: &MarketState =borrow_global<MarketState>(@zero_day_futures);

        market_state.admin_address
    }

    #[view]
    public fun get_market_info(): (bool, u128, u128, address) acquires MarketState {
        if (!exists<MarketState>(@zero_day_futures)) {
            return (false, 0, 0, @0x0)
        };

        let m: &MarketState = borrow_global<MarketState>(@zero_day_futures);
        (true, m.curr_price, m.duration, m.admin_address)
    }

    #[view]
    public fun is_initialized(): bool {
        exists<MarketState>(@zero_day_futures)
    }
}