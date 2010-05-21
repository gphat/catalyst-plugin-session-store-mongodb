use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/lib";

use Test::More;

BEGIN {
    defined($ENV{SESSION_STORE_MONGODB_HOST})
        or plan skip_all => 'Must set SESSION_STORE_MONGODB_HOST and SESSION_STORE_MONGODB_PORT environment variables';
}

use Catalyst::Test "SessionStoreTest";

my $x = get("/store_scalar");
is(get('/get_scalar'), 456, 'Can store scalar value okay');
