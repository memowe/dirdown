package Dirdown::Content;
use Mojo::Base -base, -signatures;

use Carp;
use Dirdown::Content::Node;
use Mojo::File;
use List::Util 'reduce';

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

1;
