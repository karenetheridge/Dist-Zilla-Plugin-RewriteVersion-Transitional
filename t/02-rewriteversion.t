use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

local $TODO = 'not yet done!';

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
                        fallback_version_provider => 'not used',
                    },
                ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n\nour \$VERSION = '0.002';\n\n1;\n",
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
    '0.002',
    'version was properly extracted from .pm file',
);

my $contents = path($tzil->tempdir, qw(build lib Foo.pm))->slurp_utf8;
is(
    $contents,
    "package Foo;\n\nour \$VERSION = '0.002';\n\n1;\n",
    '.pm contents are left unchanged',
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
                            fallback_version_provider => 'not used',
                        },
                        'Dist::Zilla::Plugin::RewriteVersion' => {
                            skip_version_provider => bool(0),
                        },
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
