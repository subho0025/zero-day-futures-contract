#[test_only]
module zero_day_futures::zero_day_futures_tests {
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use std::signer;
    use zero_day_futures::zero_day_futures;

    fun setup_market(admin: &signer) {
        account::create_account_for_test(
            signer::address_of(admin)
        );

        zero_day_futures::init_market(admin, 10000, 60);
    }

    fun setup_market_and_trader(
        framework: &signer,
        admin: &signer,
        alice: &signer,
    ) {
        timestamp::set_time_has_started_for_testing(framework);

        setup_market(admin);

        account::create_account_for_test(
            signer::address_of(alice)
        );

        zero_day_futures::init_trader(alice);
    }

    // 1. Administrator can update the price.
    #[test(admin = @zero_day_futures)]
    fun admin_can_update_price(admin: signer) {
        setup_market(&admin);

        zero_day_futures::update_price(&admin, 10500);

        assert!(
            zero_day_futures::get_price() == 10500,
            100
        );
    }

    // 2. Non-administrator cannot update the price.
    #[test(admin = @zero_day_futures, bob = @0xB0B)]
    #[expected_failure(
        abort_code = 1,
        location = zero_day_futures::zero_day_futures
    )]
    fun non_admin_cannot_update_price(
        admin: signer,
        bob: signer,
    ) {
        setup_market(&admin);

        account::create_account_for_test(
            signer::address_of(&bob)
        );

        zero_day_futures::update_price(&bob, 10500);
    }

    // 3. Zero price update is rejected.
    #[test(admin = @zero_day_futures)]
    #[expected_failure(
        abort_code = 3,
        location = zero_day_futures::zero_day_futures
    )]
    fun zero_price_update_is_rejected(admin: signer) {
        setup_market(&admin);
        zero_day_futures::update_price(&admin, 0);
    }

    // 4. Update before initialization is rejected.
    #[test(admin = @zero_day_futures)]
    #[expected_failure(
        abort_code = 5,
        location = zero_day_futures::zero_day_futures
    )]
    fun update_before_market_initialization(admin: signer) {
        zero_day_futures::update_price(&admin, 10500);
    }

    // 5. Market cannot be initialized twice.
    #[test(admin = @zero_day_futures)]
    #[expected_failure(
        abort_code = 2,
        location = zero_day_futures::zero_day_futures
    )]
    fun market_cannot_be_initialized_twice(admin: signer) {
        setup_market(&admin);
        zero_day_futures::init_market(&admin, 11000, 60);
    }

    // 6. Zero initial price is rejected.
    #[test(admin = @zero_day_futures)]
    #[expected_failure(
        abort_code = 3,
        location = zero_day_futures::zero_day_futures
    )]
    fun zero_initial_price_is_rejected(admin: signer) {
        account::create_account_for_test(
            signer::address_of(&admin)
        );

        zero_day_futures::init_market(&admin, 0, 60);
    }

    // 7. Zero duration is rejected.
    #[test(admin = @zero_day_futures)]
    #[expected_failure(
        abort_code = 4,
        location = zero_day_futures::zero_day_futures
    )]
    fun zero_duration_is_rejected(admin: signer) {
        account::create_account_for_test(
            signer::address_of(&admin)
        );

        zero_day_futures::init_market(&admin, 10000, 0);
    }

    // 8. A trader cannot claim credits twice.
    #[test(admin = @zero_day_futures, alice = @0xA11CE)]
    #[expected_failure(
        abort_code = 6,
        location = zero_day_futures::zero_day_futures
    )]
    fun trader_cannot_claim_twice(
        admin: signer,
        alice: signer,
    ) {
        setup_market(&admin);

        account::create_account_for_test(
            signer::address_of(&alice)
        );

        zero_day_futures::init_trader(&alice);
        zero_day_futures::init_trader(&alice);
    }

    // 9. A trader cannot claim before market initialization.
    #[test(alice = @0xA11CE)]
    #[expected_failure(
        abort_code = 5,
        location = zero_day_futures::zero_day_futures
    )]
    fun trader_cannot_claim_before_market_exists(
        alice: signer,
    ) {
        account::create_account_for_test(
            signer::address_of(&alice)
        );

        zero_day_futures::init_trader(&alice);
    }

    // 10. Opening a trade records details and locks the stake.
    #[test(
        framework = @0x1,
        admin = @zero_day_futures,
        alice = @0xA11CE
    )]
    fun open_trade_records_and_locks_stake(
        framework: signer,
        admin: signer,
        alice: signer,
    ) {
        setup_market_and_trader(&framework, &admin, &alice);

        zero_day_futures::open_trade(&alice, true, 3000);

        let alice_addr = signer::address_of(&alice);

        assert!(
            zero_day_futures::get_trader_balance(alice_addr)
                == 9997000,
            101
        );

        assert!(
            zero_day_futures::get_locked_balance(alice_addr)
                == 3000,
            102
        );

        assert!(
            zero_day_futures::get_trade_count(alice_addr) == 1,
            103
        );

        assert!(
            zero_day_futures::get_next_id(alice_addr) == 2,
            104
        );

        assert!(
            zero_day_futures::get_trade_entry_price(
                alice_addr,
                0
            ) == 10000,
            105
        );

        assert!(
            zero_day_futures::get_trade_direction(
                alice_addr,
                0
            ),
            106
        );

        assert!(
            !zero_day_futures::get_trade_status(alice_addr, 0),
            107
        );

        let opened_at =
            zero_day_futures::get_trade_open_time(alice_addr, 0);

        let expires_at =
            zero_day_futures::get_trade_expiry(alice_addr, 0);

        assert!(expires_at == opened_at + 60, 108);
    }

    // 11. Each successful trade receives a new ID.
    #[test(
        framework = @0x1,
        admin = @zero_day_futures,
        alice = @0xA11CE
    )]
    fun trade_ids_increment(
        framework: signer,
        admin: signer,
        alice: signer,
    ) {
        setup_market_and_trader(&framework, &admin, &alice);

        zero_day_futures::open_trade(&alice, true, 1000);
        zero_day_futures::open_trade(&alice, false, 2000);

        let alice_addr = signer::address_of(&alice);

        assert!(
            zero_day_futures::get_trade_count(alice_addr) == 2,
            109
        );

        assert!(
            zero_day_futures::get_next_id(alice_addr) == 3,
            110
        );

        assert!(
            zero_day_futures::get_locked_balance(alice_addr)
                == 3000,
            111
        );
    }

    // 12. A zero stake is rejected.
    #[test(
        framework = @0x1,
        admin = @zero_day_futures,
        alice = @0xA11CE
    )]
    #[expected_failure(
        abort_code = 8,
        location = zero_day_futures::zero_day_futures
    )]
    fun zero_stake_is_rejected(
        framework: signer,
        admin: signer,
        alice: signer,
    ) {
        setup_market_and_trader(&framework, &admin, &alice);

        zero_day_futures::open_trade(&alice, true, 0);
    }

    // 13. A stake greater than the available balance is rejected.
    #[test(
        framework = @0x1,
        admin = @zero_day_futures,
        alice = @0xA11CE
    )]
    #[expected_failure(
        abort_code = 9,
        location = zero_day_futures::zero_day_futures
    )]
    fun insufficient_balance_is_rejected(
        framework: signer,
        admin: signer,
        alice: signer,
    ) {
        setup_market_and_trader(&framework, &admin, &alice);

        zero_day_futures::open_trade(&alice, true, 10000001);
    }

    // 14. A user without a Trader account cannot open a trade.
    #[test(
        framework = @0x1,
        admin = @zero_day_futures
    )]
    #[expected_failure(
        abort_code = 7,
        location = zero_day_futures::zero_day_futures
    )]
    fun trade_requires_trader_account(
        framework: signer,
        admin: signer,
    ) {
        timestamp::set_time_has_started_for_testing(&framework);

        setup_market(&admin);

        zero_day_futures::open_trade(&admin, true, 1000);
    }

    // 15. A trade cannot open before market initialization.
    #[test(alice = @0xA11CE)]
    #[expected_failure(
        abort_code = 5,
        location = zero_day_futures::zero_day_futures
    )]
    fun trade_requires_market(
        alice: signer,
    ) {
        account::create_account_for_test(
            signer::address_of(&alice)
        );

        zero_day_futures::open_trade(&alice, true, 1000);
    }
}