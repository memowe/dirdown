package Dirdown;
use Mojo::Base -base, -signatures;

use Carp;
use Dirdown::Node;
use Mojo::Path;
use Mojo::Collection 'c';

# Content list
has dir     => sub {croak "No Dirdown directory 'dir' given!\n"};
has home    => 'index';
has tree    => \&_tree;

sub _tree ($self) { Dirdown::Node->new(
    dir => $self->dir, path => $self->dir, home => $self->home
)}

sub refresh ($self) {$self->tree($self->_tree)}

sub full_tree ($self) {$self->tree->full_tree}

# Try to find a content page
sub content_for ($self, $path) {
    return $self->tree->content_for($path);
}

sub navi_tree ($self, $path = '__FULL__') {

    # Full tree?
    return $self->tree->navi_tree('') if $path eq '__FULL__';

    # Path exists?
    my $leaf = $self->content_for($path);
    return unless defined $leaf;

    # Home applicable?
    my $parts = Mojo::Path->new($path)->parts;
    push @$parts, $self->home
        if $leaf->path_name eq $self->home
            and @$parts and $parts->[-1] ne $self->home;

    # Delegate
    return $self->tree->navi_tree('', $parts);
}

sub navi_stack ($self, $path = undef) {

    # Path exists?
    my $leaf = $self->content_for($path);
    return unless defined $leaf;
    my $parts = Mojo::Path->new($path)->parts;

    # Home applicable?
    push @$parts, $self->home
        if $leaf->path_name eq $self->home
            and @$parts and $parts->[-1] ne $self->home;

    # Go down level by level iteratively
    my $node    = $self->tree;
    my $npath   = '';
    my $levels  = c();
    while (1) {
        my $next = shift @$parts;

        # Collect children data
        my $active;
        push @$levels, $node->clone->children->map(sub ($child) {
            my $cpath = $npath . '/' . $child->path_name;
            my $d = {
                cpath   => $cpath,
                path    => $child->path_name,
                node    => $child,
                name    => $child->navi_name,
            };
            if (defined $next and $d->{path} eq $next) {
                $d->{active} = 1;
                $active = $d;
            }
        $d});

        # What's next?
        last unless defined $active;
        last if $active->{node}->can('content');
        $node   = $active->{node};
        $npath  = $active->{cpath};
    }

    # Done
    return $levels;
}

1;
