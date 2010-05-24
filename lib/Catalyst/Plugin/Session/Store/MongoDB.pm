package Catalyst::Plugin::Session::Store::MongoDB;
use warnings;
use strict;

use base qw/
    Class::Data::Inheritable
    Catalyst::Plugin::Session::Store
/;
use MRO::Compat;
use MIME::Base64 qw(encode_base64 decode_base64);
use MongoDB::Connection;
use Storable qw/nfreeze thaw/;

our $VERSION = '0.01';

__PACKAGE__->mk_classdata('_session_mongodb_conn');
__PACKAGE__->mk_classdata('_session_mongodb_db');
__PACKAGE__->mk_classdata('_session_mongodb_coll');

sub get_session_data {
    my ($c, $key) = @_;

    if(!defined($c->_session_mongodb_conn)) {
        $c->_mongo_connect;
    }

    if($key =~ /^expires:(.*)/) {
        my $sid = $1;
        my $data = $c->_session_mongodb_coll->find_one({ _id => $sid });

        if(defined($data)) {
            # Handle auto-expiry, delete it if it's expired and return
            # undef.
            if(time > $data->{expires}) {
                $c->_session_mongodb_coll->remove({ _id => $sid });
                return undef;
            } else {
                # Nothing's wrong here, send it along.
                return $data->{expires};
            }
        }

    } elsif($key =~ /^session:(.*)/) {
        my $sid = $1;
        # Assuming it wasn't deleted above, we'll return it.
        my $data = $c->_session_mongodb_coll->find_one({ _id => $sid });
        return thaw(decode_base64($data->{session})) if defined($data);
    }

    return {};
}

sub store_session_data {
    my ($c, $key, $data) = @_;

    if(!defined($c->_session_mongodb_conn)) {
        $c->_mongo_connect;
    }

    if($key =~ /^expires:(.*)/) {
        my $sid = $1;
        $c->_session_mongodb_coll->update({ _id => $sid }, { '$set' => { expires => $data } }, { upsert => 1 });
    } elsif($key =~ /^session:(.*)/) {
        my $sid = $1;
        $c->_session_mongodb_coll->update({ _id => $sid }, { '$set' => { session => encode_base64(nfreeze($data)) } }, { upsert => 1 });
    }

    return;
}

sub delete_session_data {
    my ($c, $key) = @_;

    $c->_session_mongodb_coll->remove({ _id => $key });

    return;
}

sub delete_expired_sessions {
    my ($c) = @_;

    $c->_session_mongodb_coll->remove({ expires => { '$lt' => time }})
}

sub prepare {
    my $c = shift;

    if(!defined($c->_session_mongodb_conn)) {
        $c->_mongo_connect;
    }

    $c->maybe::next::method(@_);
}

sub _mongo_connect {
    my $c = shift;

    my $cfg = $c->_session_plugin_config;

    $c->_session_mongodb_conn(
        MongoDB::Connection->new(
            host    => $cfg->{mongodb_host} || '127.0.0.1',
            port    => $cfg->{mongodb_port} || 27017,
        )
    );
    my $dbname = $cfg->{mongodb_database} || 'catalyst_sessions';
    $c->_session_mongodb_db($c->_session_mongodb_conn->get_database($dbname));
    my $colname = $cfg->{mongodb_collection} || 'sessions';
    $c->_session_mongodb_coll($c->_session_mongodb_db->get_collection($colname));
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Session::Store::MongoDB - MongoDB Session store for Catalyst

=head1 SYNOPSIS

    use Catalyst qw/
        Session
        Session::Store::MongoDB
        Session::State::Foo
    /;
    
    MyApp->config->{Plugin::Session} = {
        expires => 3600,
        mongodb_server => '127.0.0.1:6379',
        mongodb_debug => 0 # or 1!
    };

    # ... in an action:
    $c->session->{foo} = 'bar'; # will be saved

=head1 DESCRIPTION

C<Catalyst::Plugin::Session::Store::MongoDB> is a session storage plugin for
Catalyst that uses MongoDB (L<http://www.mongodb.org>).

=head1 NOTES

=over 4

=item B<Expired Sessions>

This store automatically expires sessions when they expire.

=back

=head1 WARNING

This module is currently untested, outside of the unit tests it ships with.
It will eventually be used with a busy site, but is currently unproven.
Patches are welcome!

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cory G Watson

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
