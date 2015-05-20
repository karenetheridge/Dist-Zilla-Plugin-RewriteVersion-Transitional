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
                    },
                ],
                [ FakeRelease => ],
                [ 'BumpVersionAfterRelease::Transitional' ],
            ),
            path(qw(source lib Foo.pm)) => <<'FOO'
package Foo;

package Bar;

1;
FOO
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
    'version was properly extracted from .pm file',
);

is(
    path($tzil->tempdir, qw(build lib Foo.pm))->slurp_utf8,
    <<'FOO',
package Foo;
our $VERSION = '0.005';
package Bar;
our $VERSION = '0.005';
1;
FOO
    '.pm contents in the build saw the version incremented, in both packages',
);

my $source_file = path($tzil->tempdir, qw(source lib Foo.pm));
is(
    $source_file->slurp_utf8,
    <<'FOO',
package Foo;
our $VERSION = '0.006';
package Bar;
our $VERSION = '0.006';
1;
FOO
    '.pm contents in source saw the version incremented, in both packages',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::RewriteVersion::Transitional',
                    config => superhashof({
                        'Dist::Zilla::Plugin::RewriteVersion::Transitional' => {
                            fallback_version_provider => '=inc::SimpleVersionProvider',
                            _fallback_version_provider_args => { },
                        },
                        # TODO, in [RewriteVersion]
                        #'Dist::Zilla::Plugin::RewriteVersion' => {
                        #    skip_version_provider => bool(0),
                        #},
                        '=inc::SimpleVersionProvider' => { },
                        'Dist::Zilla::Plugin::PkgVersion' => superhashof({}),
                    }),
                    name => 'RewriteVersion::Transitional',
                    version => Dist::Zilla::Plugin::RewriteVersion::Transitional->VERSION,
                },
                {
                    class => 'Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional',
                    config => superhashof({
                        'Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional' => {
                        },
                        # TODO, in [BumpVersionAfterRelease]
                        #'Dist::Zilla::Plugin::BumpVersionAfterRelease' => {
                        #    global => bool(0),
                        #    munge_makefile_pl => bool(0),
                        #},
                    }),
                    name => 'BumpVersionAfterRelease::Transitional',
                    version => Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional->VERSION,
                },
            ),
        }),
    }),
    'plugin metadata, including dumped configs',
) or diag 'got distmeta: ', explain $tzil->distmeta;

cmp_deeply(
    $tzil->log_messages,
    superbagof(
        '[RewriteVersion::Transitional] inserted 2 $VERSION statements into lib/Foo.pm',
        '[BumpVersionAfterRelease::Transitional] inserted 2 $VERSION statements into ' . $source_file,
    ),
    'got appropriate log messages about inserting new $VERSION statements',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
