
#[test_only]
module zero_day_futures::zero_day_futures_tests {
    use aptos_framework::account;
    use aptos_framework::timestamp;

    use zero_day_futures::market;
    use zero_day_futures::trader;
    use zero_day_futures::trade;

    const ALICE: address = @0x1234;
    const BOB: address = @0x5678;
    const OTHER: address = @0x9999;

    const INITIAL_BALANCE: u128 = 10000000;

    // ---------------------------------------------------------
    // Test helpers
    // ---------------------------------------------------------

    fun setup_market(
        admin: &signer,
        price: u128,
        duration: u128,
    ) {
        market::init_market(admin, price, duration);
    }

    fun setup_market_and_trader(
        admin: &signer,
        user: &signer,
        price: u128,
        duration: u128,
    ) {
        market::init_market(admin, price, duration);
        trader::init_trader(user);
    }

    // Aptos timestamp::now_seconds() reads seconds from the
    // global timestamp. The test update function uses microseconds.
    fun start_clock(framework: &signer, start_seconds: u64) {
        timestamp::set_time_has_started_for_testing(framework);
        timestamp::update_global_time_for_test(
            start_seconds * 1000000
        );
    }

    fun move_clock_to(seconds: u64) {
        timestamp::update_global_time_for_test(seconds * 1000000);
    }

    // ---------------------------------------------------------
    // MARKET INITIALIZATION
    // ---------------------------------------------------------

    #[test(framework = @aptos_framework)]
    fun test_market_initializes_with_correct_values() {
        let admin =
            account::create_account_for_test(@zero_day_futures);

        setup_market(&admin, 100, 60);

        assert!(market::is_initialized(), 1);
        assert!(market::get_price() == 100, 2);
        assert!(market::get_duration() == 60, 3);
        assert!(
            market::get_admin() == @zero_day_futures,
            4
        );
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 1,
        location = zero_day_futures::market
    )]
    fun test_non_admin_cannot_initialize_market() {
        let other = account::create_account_for_test(OTHER);

        market::init_market(&other, 100, 60);
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 2,
        location = zero_day_futures::market
    )]
    fun test_market_cannot_initialize_twice() {
        let admin =
            account::create_account_for_test(@zero_day_futures);

        setup_market(&admin, 100, 60);
        market::init_market(&admin, 200, 120);
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 3,
        location = zero_day_futures::market
    )]
    fun test_zero_initial_price_is_rejected() {
        let admin =
            account::create_account_for_test(@zero_day_futures);

        market::init_market(&admin, 0, 60);
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 4,
        location = zero_day_futures::market
    )]
    fun test_zero_market_duration_is_rejected() {
        let admin =
            account::create_account_for_test(@zero_day_futures);

        market::init_market(&admin, 100, 0);
    }

    #[test(framework = @aptos_framework)]
    fun test_minimum_valid_price_and_duration() {
        let admin =
            account::create_account_for_test(@zero_day_futures);

        setup_market(&admin, 1, 1);

        assert!(market::get_price() == 1, 10);
        assert!(market::get_duration() == 1, 11);
    }

    // ---------------------------------------------------------
    // MARKET PRICE UPDATES
    // ---------------------------------------------------------

    #[test(framework = @aptos_framework)]
    fun test_admin_can_update_price() {
        let admin =
            account::create_account_for_test(@zero_day_futures);

        setup_market(&admin, 100, 60);

        market::update_price(&admin, 150);
        assert!(market::get_price() == 150, 20);

        market::update_price(&admin, 75);
        assert!(market::get_price() == 75, 21);
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 1,
        location = zero_day_futures::market
    )]
    fun test_non_admin_cannot_update_price() {
        let admin =
            account::create_account_for_test(@zero_day_futures);
        let other = account::create_account_for_test(OTHER);

        setup_market(&admin, 100, 60);

        market::update_price(&other, 200);
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 3,
        location = zero_day_futures::market
    )]
    fun test_admin_cannot_set_price_to_zero() {
        let admin =
            account::create_account_for_test(@zero_day_futures);

        setup_market(&admin, 100, 60);

        market::update_price(&admin, 0);
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 5,
        location = zero_day_futures::market
    )]
    fun test_cannot_update_price_before_market_initialization() {
        let admin =
            account::create_account_for_test(@zero_day_futures);

        market::update_price(&admin, 150);
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 5,
        location = zero_day_futures::market
    )]
    fun test_get_price_before_market_initialization_aborts() {
        market::get_price();
    }

    // ---------------------------------------------------------
    // TRADER INITIALIZATION AND BALANCE QUERIES
    // ---------------------------------------------------------

    #[test(framework = @aptos_framework)]
    fun test_trader_starts_with_expected_balance() {
        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market(&admin, 100, 60);
        trader::init_trader(&alice);

        assert!(trader::is_trader_initialized(ALICE), 30);
        assert!(
            trader::get_trader_balance(ALICE) == INITIAL_BALANCE,
            31
        );
        assert!(trader::get_locked_balance(ALICE) == 0, 32);
        assert!(trade::get_trade_count(ALICE) == 0, 33);
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 5,
        location = zero_day_futures::trader
    )]
    fun test_trader_cannot_initialize_before_market() {
        let alice = account::create_account_for_test(ALICE);

        trader::init_trader(&alice);
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 6,
        location = zero_day_futures::trader
    )]
    fun test_trader_cannot_initialize_twice() {
        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market(&admin, 100, 60);
        trader::init_trader(&alice);
        trader::init_trader(&alice);
    }

    #[test(framework = @aptos_framework)]
    fun test_unknown_address_is_not_initialized() {
        assert!(!trader::is_trader_initialized(ALICE), 40);
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 7,
        location = zero_day_futures::trader
    )]
    fun test_get_balance_for_unknown_trader_aborts() {
        trader::get_trader_balance(ALICE);
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 7,
        location = zero_day_futures::trader
    )]
    fun test_get_locked_balance_for_unknown_trader_aborts() {
        trader::get_locked_balance(ALICE);
    }

    // ---------------------------------------------------------
    // OPENING TRADES: VALIDATION
    // ---------------------------------------------------------

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 5,
        location = zero_day_futures::trade
    )]
    fun test_open_trade_before_market_initialization_aborts(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let alice = account::create_account_for_test(ALICE);

        trade::open_trade(&alice, true, 1000);
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 7,
        location = zero_day_futures::trade
    )]
    fun test_uninitialized_trader_cannot_open_trade(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market(&admin, 100, 60);

        trade::open_trade(&alice, true, 1000);
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 8,
        location = zero_day_futures::trade
    )]
    fun test_zero_stake_is_rejected(framework: signer) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 60);

        trade::open_trade(&alice, true, 0);
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 9,
        location = zero_day_futures::trade
    )]
    fun test_stake_above_available_balance_is_rejected(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 60);

        trade::open_trade(&alice, true, INITIAL_BALANCE + 1);
    }

    #[test(framework = @aptos_framework)]
    fun test_stake_equal_to_available_balance_is_allowed(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 60);

        trade::open_trade(&alice, true, INITIAL_BALANCE);

        assert!(trader::get_trader_balance(ALICE) == 0, 50);
        assert!(
            trader::get_locked_balance(ALICE) == INITIAL_BALANCE,
            51
        );
        assert!(trade::get_trade_count(ALICE) == 1, 52);
    }

    // ---------------------------------------------------------
    // OPENING TRADES: ACCOUNTING AND TRADE METADATA
    // ---------------------------------------------------------

    #[test(framework = @aptos_framework)]
    fun test_open_long_records_trade_and_locks_stake(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 60);

        trade::open_trade(&alice, true, 1000);

        assert!(
            trader::get_trader_balance(ALICE) == 9999000,
            60
        );
        assert!(trader::get_locked_balance(ALICE) == 1000, 61);

        assert!(trade::get_trade_count(ALICE) == 1, 62);
        assert!(trade::get_next_id(ALICE) == 2, 63);
        assert!(trade::get_trade_id(ALICE, 0) == 1, 64);

        assert!(trade::get_trade_direction(ALICE, 0), 65);
        assert!(trade::get_trade_stake(ALICE, 0) == 1000, 66);
        assert!(
            trade::get_trade_entry_price(ALICE, 0) == 100,
            67
        );
        assert!(!trade::get_trade_status(ALICE, 0), 68);
        assert!(
            trade::get_trade_settle_price(ALICE, 0) == 0,
            69
        );
        assert!(!trade::get_trade_settle_result(ALICE, 0), 70);
        assert!(trade::get_trade_pnl(ALICE, 0) == 0, 71);

        assert!(
            trade::get_trade_expiry(ALICE, 0)
                == trade::get_trade_open_time(ALICE, 0) + 60,
            72
        );
    }

    #[test(framework = @aptos_framework)]
    fun test_open_short_records_false_direction(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 60);

        trade::open_trade(&alice, false, 500);

        assert!(!trade::get_trade_direction(ALICE, 0), 80);
        assert!(trade::get_trade_stake(ALICE, 0) == 500, 81);
    }

    #[test(framework = @aptos_framework)]
    fun test_trade_price_is_snapshotted_at_open(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 60);

        trade::open_trade(&alice, true, 1000);
        market::update_price(&admin, 125);
        trade::open_trade(&alice, false, 1000);

        assert!(
            trade::get_trade_entry_price(ALICE, 0) == 100,
            90
        );
        assert!(
            trade::get_trade_entry_price(ALICE, 1) == 125,
            91
        );
        assert!(trade::get_trade_id(ALICE, 0) == 1, 92);
        assert!(trade::get_trade_id(ALICE, 1) == 2, 93);
    }

    #[test(framework = @aptos_framework)]
    fun test_multiple_trades_have_sequential_ids(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 60);

        trade::open_trade(&alice, true, 1000);
        trade::open_trade(&alice, false, 2000);
        trade::open_trade(&alice, true, 3000);

        assert!(trade::get_trade_count(ALICE) == 3, 100);
        assert!(trade::get_trade_id(ALICE, 0) == 1, 101);
        assert!(trade::get_trade_id(ALICE, 1) == 2, 102);
        assert!(trade::get_trade_id(ALICE, 2) == 3, 103);
        assert!(trade::get_next_id(ALICE) == 4, 104);

        assert!(
            trader::get_trader_balance(ALICE) == 9994000,
            105
        );
        assert!(trader::get_locked_balance(ALICE) == 6000, 106);
    }

    #[test(framework = @aptos_framework)]
    fun test_traders_have_separate_balances_and_trade_books(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);
        let bob = account::create_account_for_test(BOB);

        setup_market(&admin, 100, 60);
        trader::init_trader(&alice);
        trader::init_trader(&bob);

        trade::open_trade(&alice, true, 1000);
        trade::open_trade(&bob, false, 3000);

        assert!(
            trader::get_trader_balance(ALICE) == 9999000,
            110
        );
        assert!(
            trader::get_trader_balance(BOB) == 9997000,
            111
        );

        assert!(trader::get_locked_balance(ALICE) == 1000, 112);
        assert!(trader::get_locked_balance(BOB) == 3000, 113);

        assert!(trade::get_trade_count(ALICE) == 1, 114);
        assert!(trade::get_trade_count(BOB) == 1, 115);
        assert!(trade::get_trade_id(ALICE, 0) == 1, 116);
        assert!(trade::get_trade_id(BOB, 0) == 1, 117);
    }

    #[test(framework = @aptos_framework)]
    fun test_trade_count_is_zero_without_trade_record() {
        assert!(trade::get_trade_count(ALICE) == 0, 120);
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 11,
        location = zero_day_futures::trade
    )]
    fun test_get_next_id_without_trade_record_aborts() {
        trade::get_next_id(ALICE);
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 12,
        location = zero_day_futures::trade
    )]
    fun test_get_trade_at_invalid_index_aborts(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 60);
        trade::open_trade(&alice, true, 1000);

        // Only index zero exists.
        trade::get_trade_id(ALICE, 1);
    }

    // ---------------------------------------------------------
    // SETTLEMENT VALIDATION
    // ---------------------------------------------------------

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 11,
        location = zero_day_futures::trade
    )]
    fun test_cannot_settle_without_trade_record(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market(&admin, 100, 10);

        trade::settle_trade(&alice, 0);
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 12,
        location = zero_day_futures::trade
    )]
    fun test_cannot_settle_invalid_trade_index(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 10);
        trade::open_trade(&alice, true, 1000);

        move_clock_to(110);

        trade::settle_trade(&alice, 1);
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 14,
        location = zero_day_futures::trade
    )]
    fun test_cannot_settle_before_expiry(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 10);
        trade::open_trade(&alice, true, 1000);

        // Trade expires at second 110; current time is 100.
        trade::settle_trade(&alice, 0);
    }

    // ---------------------------------------------------------
    // SETTLEMENT: LONG PROFITS AND LOSSES
    // ---------------------------------------------------------

    #[test(framework = @aptos_framework)]
    fun test_profitable_long_trade(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 10);
        trade::open_trade(&alice, true, 1000);

        market::update_price(&admin, 120);
        move_clock_to(110);

        trade::settle_trade(&alice, 0);

        // P&L = (120 - 100) * 1000 / 100 = 200.
        assert!(trade::get_trade_status(ALICE, 0), 130);
        assert!(
            trade::get_trade_settle_price(ALICE, 0) == 120,
            131
        );
        assert!(trade::get_trade_settle_result(ALICE, 0), 132);
        assert!(trade::get_trade_pnl(ALICE, 0) == 200, 133);

        assert!(
            trader::get_trader_balance(ALICE) == 10000200,
            134
        );
        assert!(trader::get_locked_balance(ALICE) == 0, 135);
    }

    #[test(framework = @aptos_framework)]
    fun test_losing_long_trade(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 10);
        trade::open_trade(&alice, true, 1000);

        market::update_price(&admin, 80);
        move_clock_to(110);

        trade::settle_trade(&alice, 0);

        // P&L loss = (100 - 80) * 1000 / 100 = 200.
        assert!(trade::get_trade_status(ALICE, 0), 140);
        assert!(
            !trade::get_trade_settle_result(ALICE, 0),
            141
        );
        assert!(trade::get_trade_pnl(ALICE, 0) == 200, 142);

        assert!(
            trader::get_trader_balance(ALICE) == 9999800,
            143
        );
        assert!(trader::get_locked_balance(ALICE) == 0, 144);
    }

    // ---------------------------------------------------------
    // SETTLEMENT: SHORT PROFITS AND LOSSES
    // ---------------------------------------------------------

    #[test(framework = @aptos_framework)]
    fun test_profitable_short_trade(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 10);
        trade::open_trade(&alice, false, 1000);

        market::update_price(&admin, 80);
        move_clock_to(110);

        trade::settle_trade(&alice, 0);

        // Short profits when price falls.
        assert!(trade::get_trade_status(ALICE, 0), 150);
        assert!(trade::get_trade_settle_result(ALICE, 0), 151);
        assert!(trade::get_trade_pnl(ALICE, 0) == 200, 152);
        assert!(
            trader::get_trader_balance(ALICE) == 10000200,
            153
        );
        assert!(trader::get_locked_balance(ALICE) == 0, 154);
    }

    #[test(framework = @aptos_framework)]
    fun test_losing_short_trade(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 10);
        trade::open_trade(&alice, false, 1000);

        market::update_price(&admin, 120);
        move_clock_to(110);

        trade::settle_trade(&alice, 0);

        // Short loss = (120 - 100) * 1000 / 100 = 200.
        assert!(trade::get_trade_status(ALICE, 0), 160);
        assert!(
            !trade::get_trade_settle_result(ALICE, 0),
            161
        );
        assert!(trade::get_trade_pnl(ALICE, 0) == 200, 162);

        assert!(
            trader::get_trader_balance(ALICE) == 9999800,
            163
        );
        assert!(trader::get_locked_balance(ALICE) == 0, 164);
    }

    #[test(framework = @aptos_framework)]
    fun test_short_loss_is_capped_at_stake(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 10);
        trade::open_trade(&alice, false, 1000);

        // Uncapped loss would be 2,000; stake is only 1,000.
        market::update_price(&admin, 300);
        move_clock_to(110);

        trade::settle_trade(&alice, 0);

        assert!(trade::get_trade_status(ALICE, 0), 170);
        assert!(
            !trade::get_trade_settle_result(ALICE, 0),
            171
        );
        assert!(trade::get_trade_pnl(ALICE, 0) == 1000, 172);

        // The trader loses the stake but never goes negative.
        assert!(
            trader::get_trader_balance(ALICE) == 9999000,
            173
        );
        assert!(trader::get_locked_balance(ALICE) == 0, 174);
    }

    // ---------------------------------------------------------
    // BREAK-EVEN, EXPIRY AND REPEATED SETTLEMENT
    // ---------------------------------------------------------

    #[test(framework = @aptos_framework)]
    fun test_break_even_long_returns_stake(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 10);
        trade::open_trade(&alice, true, 1000);

        move_clock_to(110);
        trade::settle_trade(&alice, 0);

        assert!(trade::get_trade_status(ALICE, 0), 180);
        assert!(
            !trade::get_trade_settle_result(ALICE, 0),
            181
        );
        assert!(trade::get_trade_pnl(ALICE, 0) == 0, 182);
        assert!(
            trader::get_trader_balance(ALICE) == INITIAL_BALANCE,
            183
        );
        assert!(trader::get_locked_balance(ALICE) == 0, 184);
    }

    #[test(framework = @aptos_framework)]
    fun test_break_even_short_returns_stake(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 10);
        trade::open_trade(&alice, false, 1000);

        move_clock_to(110);
        trade::settle_trade(&alice, 0);

        assert!(trade::get_trade_status(ALICE, 0), 190);
        assert!(
            !trade::get_trade_settle_result(ALICE, 0),
            191
        );
        assert!(trade::get_trade_pnl(ALICE, 0) == 0, 192);
        assert!(
            trader::get_trader_balance(ALICE) == INITIAL_BALANCE,
            193
        );
        assert!(trader::get_locked_balance(ALICE) == 0, 194);
    }

    #[test(framework = @aptos_framework)]
    fun test_settlement_is_allowed_exactly_at_expiry(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 10);
        trade::open_trade(&alice, true, 1000);

        // Expiry is 110; the boundary is inclusive.
        move_clock_to(110);
        trade::settle_trade(&alice, 0);

        assert!(trade::get_trade_status(ALICE, 0), 200);
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(
        abort_code = 13,
        location = zero_day_futures::trade
    )]
    fun test_trade_cannot_be_settled_twice(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 10);
        trade::open_trade(&alice, true, 1000);

        move_clock_to(110);

        trade::settle_trade(&alice, 0);
        trade::settle_trade(&alice, 0);
    }

    #[test(framework = @aptos_framework)]
    fun test_settlement_uses_price_at_settlement_time(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 10);
        trade::open_trade(&alice, true, 1000);

        // Price changes after the trade opens and before it expires.
        market::update_price(&admin, 110);
        move_clock_to(110);
        market::update_price(&admin, 130);

        trade::settle_trade(&alice, 0);

        assert!(
            trade::get_trade_settle_price(ALICE, 0) == 130,
            210
        );
        assert!(trade::get_trade_pnl(ALICE, 0) == 300, 211);
        assert!(trade::get_trade_settle_result(ALICE, 0), 212);
    }

    // ---------------------------------------------------------
    // MULTIPLE OPEN TRADES AND BALANCE RELEASE
    // ---------------------------------------------------------

    #[test(framework = @aptos_framework)]
    fun test_settling_one_trade_does_not_settle_another(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 10);

        trade::open_trade(&alice, true, 1000);
        trade::open_trade(&alice, false, 2000);

        move_clock_to(110);
        market::update_price(&admin, 120);

        trade::settle_trade(&alice, 0);

        assert!(trade::get_trade_status(ALICE, 0), 220);
        assert!(!trade::get_trade_status(ALICE, 1), 221);

        assert!(trade::get_trade_count(ALICE) == 2, 222);
        assert!(trader::get_locked_balance(ALICE) == 2000, 223);
        assert!(
            trader::get_trader_balance(ALICE) == 9998200,
            224
        );
    }

    #[test(framework = @aptos_framework)]
    fun test_settling_all_trades_releases_all_locked_stake(
        framework: signer,
    ) {
        start_clock(&framework, 100);

        let admin =
            account::create_account_for_test(@zero_day_futures);
        let alice = account::create_account_for_test(ALICE);

        setup_market_and_trader(&admin, &alice, 100, 10);

        trade::open_trade(&alice, true, 1000);
        trade::open_trade(&alice, false, 2000);

        assert!(trader::get_locked_balance(ALICE) == 3000, 230);

        move_clock_to(110);
        market::update_price(&admin, 100);

        trade::settle_trade(&alice, 0);
        trade::settle_trade(&alice, 1);

        assert!(trade::get_trade_status(ALICE, 0), 231);
        assert!(trade::get_trade_status(ALICE, 1), 232);
        assert!(trader::get_locked_balance(ALICE) == 0, 233);
        assert!(
            trader::get_trader_balance(ALICE) == INITIAL_BALANCE,
            234
        );
    }
}
