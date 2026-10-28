module zero_day_futures::trader {
    use std::signer;
    use zero_day_futures::market;

    friend zero_day_futures::trade;

    const E_MARKET_NOT_INITIALIZED: u64 = 5;
    const E_TRADER_ALREADY_INITIALIZED: u64 = 6;
    const E_TRADER_NOT_INITIALIZED: u64 = 7;
    const E_INVALID_STAKE: u64 = 8;
    const E_INSUFFICIENT_BALANCE: u64 = 9;
    const E_INSUFFICIENT_LOCKED_BALANCE: u64 = 10;

    const INITIAL_BALANCE: u128 = 10000000;

    struct Trader has key {
        balance: u128,
        locked_balance: u128,
    }

    public entry fun init_trader(account: &signer){
        let account_addr: address = signer::address_of(account);

        assert!(market::is_initialized(), E_MARKET_NOT_INITIALIZED);

        assert!(!exists<Trader>(account_addr),E_TRADER_ALREADY_INITIALIZED);

        move_to(account, Trader {
            balance: INITIAL_BALANCE,
            locked_balance: 0,
        });

    }

    public(friend) fun lock_balance(addr: address,stake: u128,) acquires Trader {

        assert!(exists<Trader>(addr), E_TRADER_NOT_INITIALIZED);
        assert!(stake>0, E_INVALID_STAKE);

        let trader: &mut Trader = borrow_global_mut<Trader>(addr);

        assert!(stake <= trader.balance, E_INSUFFICIENT_BALANCE);

        trader.balance = trader.balance - stake;
        trader.locked_balance = trader.locked_balance + stake;
    }

    public(friend) fun settle_balance(addr: address, stake: u128, pnl_amount: u128, is_profit: bool,) acquires Trader {
        
        assert!(exists<Trader>(addr), E_TRADER_NOT_INITIALIZED);

        let trader: &mut Trader = borrow_global_mut<Trader>(addr);

        assert!(stake <= trader.locked_balance,E_INSUFFICIENT_LOCKED_BALANCE);

        trader.locked_balance = trader.locked_balance - stake;

        if(is_profit){
            trader.balance = trader.balance + stake + pnl_amount;
        }else{
            assert!(pnl_amount <= stake, E_INVALID_STAKE);
            trader.balance = trader.balance + stake - pnl_amount;
        };
    }

    #[view]
    public fun get_trader_balance(addr: address): u128 acquires Trader{

        assert!(exists<Trader>(addr), E_TRADER_NOT_INITIALIZED);

        let trader : &Trader = borrow_global<Trader>(addr);

        trader.balance
    }

    #[view]
    public fun get_locked_balance(addr: address): u128 acquires Trader{

        assert!(exists<Trader>(addr), E_TRADER_NOT_INITIALIZED);

        let trader : &Trader = borrow_global<Trader>(addr);

        trader.locked_balance
    }

    #[view]
    public fun is_trader_initialized(addr: address): bool {
        exists<Trader>(addr)
    }
}