use strict;
use warnings;
package # hide from PAUSE
    Dist::Zilla::Role::InsertVersion;
# vim: set ts=8 sw=4 tw=78 et :

use Moose::Role;
use namespace::autoclean;

=pod

=for Pod::Coverage insert_version

=cut

sub insert_version
{
    my ($self, $file, $version) = @_;

    # $version is the bumped post-release version; fool the plugins into using
    # it rather than the version we released with
    my $release_version = $self->zilla->version;
    $self->zilla->version($version) if $release_version ne $version;

    my $content;
    if ($file->content =~ /# VERSION/)
    {
        require Dist::Zilla::Plugin::OurPkgVersion;
        my $ourpkgversion = Dist::Zilla::Plugin::OurPkgVersion->new(
            zilla => $self->zilla,
            plugin_name => 'fallback version munger, via [RewriteVersion::Transitional]',
        );

        $ourpkgversion->munge_file($file);
        $content = $file->content;
        my $trial = $self->zilla->is_trial;
        $content =~ s/ # TRIAL VERSION/ # TRIAL/mg if $trial;
        $content =~ s/ # VERSION$//mg if not $trial;
    }
    else
    {
        require Dist::Zilla::Plugin::PkgVersion;
        my $pkgversion = Dist::Zilla::Plugin::PkgVersion->new(
            zilla => $self->zilla,
            plugin_name => 'fallback version munger, via [RewriteVersion::Transitional]',
            die_on_existing_version => 1,
            die_on_line_insertion => 0,
        );

        $pkgversion->munge_perl($file);
        $content = $file->content;
        $content =~ s/^\$\S+::(VERSION = '$version';)/our \$$1/mg;
    }

    $self->log_debug([ 'adding $VERSION assignment to %s', $file->name ]);
    $file->content($content);

    # restore zilla version, in case other plugins still need it
    $self->zilla->version($release_version) if $release_version ne $version;

    return 1;
}

1;
