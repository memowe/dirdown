package Dirdown::Content;
use Mojo::Base -base, -signatures;

use Carp;
use Dirdown::Content::Node;
use Mojo::Path;

# Content list
has dir     => sub {croak "No Dirdown directory 'dir' given!\n"};
has home    => 'index';
has tree    => sub ($self) {Dirdown::Content::Node->new(
    dir => $self->dir, path => $self->dir, home => $self->home
)};

sub full_tree ($self) {$self->tree->full_tree}

# Try to find a content page
sub content_for ($self, $path) {
    return $self->tree->content_for($path);
}

sub navi_tree ($self, $path = '__FULL__') {

    # Full tree?
    return $self->tree->navi_tree if $path eq '__FULL__';

    # Path exists?
    my $leaf = $self->content_for($path);
    return unless defined $leaf;

    # Home applicable?
    my $parts = Mojo::Path->new($path)->parts;
    push @$parts, $self->home
        if $leaf->path_name eq $self->home and $parts->[-1] ne $self->home;

    # Delegate
    return $self->tree->navi_tree($parts);
}

sub navi_stack ($self, $path = undef) {

    # Path exists?
    my $leaf = $self->content_for($path);
    return unless defined $leaf;

    # Home applicable?
    my $parts = Mojo::Path->new($path)->parts;
    push @$parts, $self->home
        if $leaf->path_name eq $self->home and $parts->[-1] ne $self->home;

    # Delegate
    return [$self->tree->navi_stack($parts)];
}

1;
