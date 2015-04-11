use strict;
use warnings;
package # hide from PAUSE
    Dist::Zilla::Role::InsertVersion;
# vim: set ts=8 sts=4 sw=4 tw=78 et :

our $VERSION = '0.005';

use Moose::Role;
use namespace::autoclean;

=pod

=for Pod::Coverage insert_version

=cut

has _ourpkgversion => (
    is => 'ro', isa => 'Dist::Zilla::Plugin::OurPkgVersion',
    lazy => 1,
    default => sub {
        my $self = shift;
        Dist::Zilla::Plugin::OurPkgVersion->new(
            zilla => $self->zilla,
            plugin_name => 'OurPkgVersion, via RewriteVersion::Transitional',
        );
    },
    predicate => '_used_ourpkgversion',
);
has _pkgversion => (
    is => 'ro', isa => 'Dist::Zilla::Plugin::PkgVersion',
    lazy => 1,
    default => sub {
        my $self = shift;
        require Dist::Zilla::Plugin::PkgVersion;
        Dist::Zilla::Plugin::PkgVersion->VERSION('5.010');  # one line, no braces
        Dist::Zilla::Plugin::PkgVersion->new(
            zilla => $self->zilla,
            plugin_name => 'PkgVersion, via RewriteVersion::Transitional',
            die_on_existing_version => 1,
            die_on_line_insertion => 0,
        );
    },
    predicate => '_used_pkgversion',
);

sub insert_version
{
    my ($self, $file, $version) = @_;

    # $version is the bumped post-release version; fool the plugins into using
    # it rather than the version we released with
    my $release_version = $self->zilla->version;
    $self->zilla->version($version) if $release_version ne $version;

    MUNGE_FILE: {
        my $replaced;
        my $content = $file->content;
        if ($content =~ /\x{23} VERSION/ and eval { require Dist::Zilla::Plugin::OurPkgVersion; 1 })
        {
            my $orig_content = $content;
            $self->_ourpkgversion->munge_file($file);
            $content = $file->content;
            last MUNGE_FILE if $content eq $orig_content;

            my $trial = $self->zilla->is_trial;
            $replaced = $trial
                ? $content =~ s/ # TRIAL VERSION/ # TRIAL/mg
                : $content =~ s/ # VERSION$//mg;
        }
        else
        {
            my $orig_content = $content;
            $self->_pkgversion->munge_perl($file);
            $content = $file->content;
            last MUNGE_FILE if $content eq $orig_content;

            $replaced = $content =~ s/^\$\S+::(VERSION = '$version';)/our \$$1/mg;
        }

        $self->log(
            !$replaced
                ? [ q{failed to insert our $VERSION = '%s'; into %s}, $version, $file->name ]
                : $replaced == 1
                    ? [ 'inserted $VERSION statement into %s', $file->name ]
                    : [ 'inserted %d $VERSION statements into %s', $replaced, $file->name ]
        );

        $file->content($content);
    }

    # restore zilla version, in case other plugins still need it
    $self->zilla->version($release_version) if $release_version ne $version;

    return 1;
}

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{'Dist::Zilla::Plugin::OurPkgVersion'} = $self->_ourpkgversion->dump_config
        if $self->_used_ourpkgversion;
    $config->{'Dist::Zilla::Plugin::PkgVersion'} = $self->_pkgversion->dump_config
        if $self->_used_pkgversion;

    return $config;
};

1;
