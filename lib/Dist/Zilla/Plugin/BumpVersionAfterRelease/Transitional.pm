use strict;
use warnings;
package Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional;
# ABSTRACT: ease the transition to [BumpVersionAfterRelease] in your distribution
# KEYWORDS: plugin version rewrite munge module
# vim: set ts=8 sw=4 tw=78 et :

use Moose;
extends 'Dist::Zilla::Plugin::BumpVersionAfterRelease';

use namespace::autoclean;

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        # TODO
    };

    return $config;
};

__PACKAGE__->meta->make_immutable;
__END__

=pod

=head1 SYNOPSIS

In your F<dist.ini>:

    [BumpVersionAfterRelease::Transitional]

=head1 DESCRIPTION

=for stopwords BumpVersionAfterRelease OurPkgVersion PkgVersion

This is a L<Dist::Zilla> plugin that subclasses
L<[BumpVersionAfterRelease]|Dist::Zilla::Plugin::BumpVersionAfterRelease>, to allow plugin
bundles to transition from L<[PkgVersion]|Dist::Zilla::Plugin::PkgVersion> or
L<[OurPkgVersion]|Dist::Zilla::Plugin::OurPkgVersion> to
L<[RewriteVersion]|Dist::Zilla::Plugin::RewriteVersion>
and L<[BumpVersionAfterRelease]|Dist::Zilla::Plugin::BumpVersionAfterRelease>
without having to manually edit the F<dist.ini> or any F<.pm> files.

After releasing your distribution,
L<[BumpVersionAfterRelease]|Dist::Zilla::Plugin::BumpVersionAfterRelease> is
invoked to update the C<$VERSION> assignment in the module(s) in the
repository to the next version. If no such expression exists in the module,
one is added.

=head1 CONFIGURATION OPTIONS

Configuration is the same as in
L<[BumpVersionAfterRelease]|Dist::Zilla::Plugin::BumpVersionAfterRelease>.

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-RewriteVersion-Transitional>
(or L<bug-Dist-Zilla-Plugin-RewriteVersion-Transitional@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-RewriteVersion-Transitional@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=for :list
* L<Dist::Zilla::Plugin::RewriteVersion::Transitional>
* L<Dist::Zilla::Plugin::PkgVersion>
* L<Dist::Zilla::Plugin::RewriteVersion>
* L<Dist::Zilla::Plugin::BumpVersionAfterRelease>

=cut
