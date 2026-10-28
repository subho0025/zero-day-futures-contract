#[test_only]
module zero_day_futures::zero_day_futures_tests {
    use zero_day_futures::zero_day_futures;

    // 1. Administrator can update the price.
    #[test(admin = @zero_day_futures)]
    fun admin_can_update_price(admin: &signer) {
        zero_day_futures::init_market(admin, 10000, 60);
        zero_day_futures::update_price(admin, 10500);

        assert!(
            zero_day_futures::get_price() == 10500,
            100
        );
    }

    // 2. A non-admin cannot update the price.
    #[test(admin = @zero_day_futures, bob = @0xB0B)]
    #[expected_failure(
        abort_code = 1,
        location = zero_day_futures::zero_day_futures
    )]
    fun non_admin_cannot_update_price(
        admin: &signer,
        bob: &signer,
    ) {
        zero_day_futures::init_market(admin, 10000, 60);
        zero_day_futures::update_price(bob, 10500);
    }

    // 3. Zero price is invalid.
    #[test(admin = @zero_day_futures)]
    #[expected_failure(
        abort_code = 3,
        location = zero_day_futures::zero_day_futures
    )]
    fun zero_price_is_rejected(admin: &signer) {
        zero_day_futures::init_market(admin, 10000, 60);
        zero_day_futures::update_price(admin, 0);
    }

    // 4. Price updates require initialized market state.
    #[test(admin = @zero_day_futures)]
    #[expected_failure(
        abort_code = 5,
        location = zero_day_futures::zero_day_futures
    )]
    fun update_before_initialization_is_rejected(
        admin: &signer,
    ) {
        zero_day_futures::update_price(admin, 10500);
    }

    // 5. Market can only be initialized once.
    #[test(admin = @zero_day_futures)]
    #[expected_failure(
        abort_code = 2,
        location = zero_day_futures::zero_day_futures
    )]
    fun market_cannot_be_initialized_twice(
        admin: &signer,
    ) {
        zero_day_futures::init_market(admin, 10000, 60);
        zero_day_futures::init_market(admin, 10500, 60);
    }

    // 6. Zero initial price is invalid.
    #[test(admin = @zero_day_futures)]
    #[expected_failure(
        abort_code = 3,
        location = zero_day_futures::zero_day_futures
    )]
    fun zero_initial_price_is_rejected(admin: &signer) {
        zero_day_futures::init_market(admin, 0, 60);
    }

    // 7. Zero duration is invalid.
    #[test(admin = @zero_day_futures)]
    #[expected_failure(
        abort_code = 4,
        location = zero_day_futures::zero_day_futures
    )]
    fun zero_duration_is_rejected(admin: &signer) {
        zero_day_futures::init_market(admin, 10000, 0);
    }

    // 8. Trader cannot claim initial credits twice.
    #[test(admin = @zero_day_futures, alice = @0xA11CE)]
    #[expected_failure(
        abort_code = 6,
        location = zero_day_futures::zero_day_futures
    )]
    fun trader_cannot_claim_twice(
        admin: &signer,
        alice: &signer,
    ) {
        zero_day_futures::init_market(admin, 10000, 60);
        zero_day_futures::init_trader(alice);
        zero_day_futures::init_trader(alice);
    }

    // 9. Trader cannot claim before market initialization.
    #[test(alice = @0xA11CE)]
    #[expected_failure(
        abort_code = 5,
        location = zero_day_futures::zero_day_futures
    )]
    fun trader_cannot_claim_before_market_exists(
        alice: &signer,
    ) {
        zero_day_futures::init_trader(alice);
    }
}