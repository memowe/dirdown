package Dirdown::Content;
use Mojo::Base -base, -signatures;

use Carp;
use Dirdown::Content::Node;
use Mojo::File;

# Content list
has dir         => sub {croak "No Dirdown directory 'dir' given!\n"};
has home        => 'index';
has navi_tree   => sub ($self) {$self->tree->navi_tree};
has tree        => sub ($self) {Dirdown::Content::Node->new(
    dir => $self->dir, path => $self->dir, home => $self->home
)};

sub full_tree ($self) {$self->tree->full_tree}

# Try to find a content page
sub content_for ($self, $path) {
    return $self->tree->content_for($path);
}

sub navi_tree_for ($self, $path) {

    # Shorthand: nothing...
    my $leaf = $self->content_for($path);
    return unless defined $leaf;

    # TODO
}

1;
