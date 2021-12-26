use Test2::V0;

## no critic (BuiltinFunctions::ProhibitStringyEval)

eval "use Test::Pod::Coverage 1.04";
plan skip_all => 'Test::Pod::Coverage 1.04 required' if $@;

eval "use Pod::Coverage 0.20";
plan skip_all => 'Pod::Coverage 0.20 required' if $@;

todo "we really need to work on POD coverage" => sub {
    all_pod_coverage_ok();
};
