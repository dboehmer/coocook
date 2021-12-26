use Test2::V0;

## no critic (BuiltinFunctions::ProhibitStringyEval)
eval "use Test::Pod 1.14";
plan skip_all => 'Test::Pod 1.14 required' if $@;

all_pod_files_ok();
