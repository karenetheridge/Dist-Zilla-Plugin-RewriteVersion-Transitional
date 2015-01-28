use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

delete $ENV{TRIAL};
delete $ENV{V};

{
    package inc::SimpleVersionProvider;
    use Moose;
    with 'Dist::Zilla::Role::VersionProvider';
    sub provide_version { '0.005' }
    $INC{'inc/SimpleVersionProvider.pm'} = __FILE__;
}

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => dist_ini(
                { # configs as in simple_ini, but no version assignment
                    name     => 'DZT-Sample',
                    abstract => 'Sample DZ Dist',
                    author   => 'E. Xavier Ample <example@example.org>',
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                },
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'RewriteVersion::Transitional' => {
                        fallback_version_provider => '=inc::SimpleVersionProvider',
                        some_other_arg => 'oh hai',
                    },
                ],
                [ FakeRelease => ],
                [ 'BumpVersionAfterRelease::Transitional' ],
            ),
            path(qw(source lib Foo.pm)) => <<FOO,
package Foo;
# ABSTRACT: oh hai

1;
FOO
            path(qw(source lib Foo Bar.pm)) => "package # hide from PAUSE\n   Foo::Bar;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->release },
    undef,
    'build and release proceeds normally',
);

is(
    $tzil->version,
    '0.005',
    'fallback version provider was employed to get the version',
);

is(
    path($tzil->tempdir, qw(build lib Foo Bar.pm))->slurp_utf8,
    "package # hide from PAUSE\n   Foo::Bar;\n1;\n",
    '$VERSION assignment was not added to the private module in the build dir',
);

is(
    path($tzil->tempdir, qw(source lib Foo Bar.pm))->slurp_utf8,
    "package # hide from PAUSE\n   Foo::Bar;\n1;\n",
    '$VERSION assignment was not added to the private module in the source dir',
);

cmp_deeply(
    $tzil->log_messages,
    superbagof(
        '[RewriteVersion::Transitional] inserting $VERSION assignment into lib/Foo.pm',
        '[BumpVersionAfterRelease::Transitional] inserting $VERSION assignment into ' . path($tzil->tempdir, qw(source lib Foo.pm)),

    ),
    'got appropriate log messages about inserting new $VERSION statement into Foo',
);

ok(
    (! grep {
        m{^\[(RewriteVersion|BumpVersionAfterRelease)::Transitional\] inserting \$VERSION assignment into .*Bar.pm$}
    } @{ $tzil->log_messages }),
    'did not log a message about inserting a $VERSION statement into private Foo::Bar',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
