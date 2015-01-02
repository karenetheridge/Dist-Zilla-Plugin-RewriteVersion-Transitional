use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

use Test::Requires 'Dist::Zilla::Plugin::OurPkgVersion';

my $captured_args;
{
    package inc::SimpleVersionProvider;
    use Moose;
    with 'Dist::Zilla::Role::VersionProvider';
    sub provide_version { '0.005' }
    sub BUILD { $captured_args = $_[1] }
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
            ),
            path(qw(source lib Foo.pm)) => <<FOO,
package Foo;
# ABSTRACT: oh hai
    # VERSION

1;
FOO
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

is(
    $tzil->version,
    '0.005',
    'fallback version provider was employed to get the version',
);

cmp_deeply(
    $captured_args,
    {
        zilla => shallow($tzil),
        plugin_name => 'fallback version provider, via [RewriteVersion::Transitional]',
        some_other_arg => 'oh hai',
    },
    'extra plugin arguments were passed along to the fallback version provider',
);


my $contents = path($tzil->tempdir, qw(build lib Foo.pm))->slurp_utf8;
is(
    $contents,
    "package Foo;\n# ABSTRACT: oh hai\n    our \$VERSION = '0.005';\n\n1;\n",
    '$VERSION assignment was added to the module, where [OurPkgVersion] would normally insert it',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::RewriteVersion::Transitional',
                    config => {
                        'Dist::Zilla::Plugin::RewriteVersion::Transitional' => {
                            fallback_version_provider => '=inc::SimpleVersionProvider',
                            _fallback_version_provider_args => { some_other_arg => 'oh hai' },
                        },
                        # TODO, in [RewriteVersion]
                        #'Dist::Zilla::Plugin::RewriteVersion' => {
                        #    skip_version_provider => bool(0),
                        #},
                    },
                    name => 'RewriteVersion::Transitional',
                    version => ignore,
                },
            ),
        }),
    }),
    'plugin metadata, including dumped configs',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
