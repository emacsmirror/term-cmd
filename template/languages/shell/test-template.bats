# shellcheck shell=bats

bats_require_minimum_version 1.5.0

setup() {
    bats_load_library 'bats-support'
    bats_load_library 'bats-assert'
}

@test "example1" {
    run --separate-stderr true
    assert_success
    refute_output
    refute_stderr
}

# bats test_tags=slow
@test "example2" {
    run --separate-stderr true
    assert_success
    refute_output
    refute_stderr
}
