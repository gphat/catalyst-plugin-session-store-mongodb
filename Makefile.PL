use inc::Module::Install;

name     'Catalyst-Plugin-Session-Store-MongoDB';
all_from 'lib/Catalyst/Plugin/Session/Store/MongoDB.pm';
author   q{Cory G Watson <gphat@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'MongoDB';
requires 'Try::Tiny' => '0.02';
requires 'Catalyst::Plugin::Session' => '0.27';

WriteAll;

