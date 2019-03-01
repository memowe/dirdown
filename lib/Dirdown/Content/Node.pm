package Dirdown::Content::Node;
use Mojo::Base -base, -signatures;

use Carp;
use Mojo::Collection;
use Dirdown::Content::Page;

has dir         => sub {croak "No 'dir' given!\n"};
has path        => sub {croak "No 'path' given!\n"};
has home        => 'index';
has rel_path    => sub ($self) {$self->path->to_rel($self->dir)};
has path_parts  => sub ($self) {$self->rel_path->to_array};
has basename    => sub ($self) {$self->path_parts->[-1]};
has sort_val    => sub ($self) {($self->basename =~ /^(\d+)_/)[0] // 0};
has path_name   => \&_path_name;
has children    => \&_children;
has children_hr => \&_children_hr;

sub _path_name ($self) {
    ($self->basename =~ /^  # start
        (?: \d+ _ )?        # optional sort value
        (   .*?   )         # name we need (captured)
        (?: \.\w+ )?        # optional file extension
    $/x)[0];                # end of string
}

sub _children ($self) {
    opendir my $dh, $self->path or return Mojo::Collection->new;
    return Mojo::Collection->new(readdir $dh)
        ->grep(sub ($name) {$name !~ /^\.\.?$/})
        ->map(sub ($name) {
            my $path = $self->path->child($name);
            my %args = (path => $path, dir => $self->dir, home => $self->home);
            return (-f $path)
                ? Dirdown::Content::Page->new(%args)
                : Dirdown::Content::Node->new(%args);
        })->sort(sub {$a->sort_val <=> $b->sort_val});
}

sub _children_hr ($self) {
    return { map {$_->path_name => $_} @{$self->children->to_array} };
}

sub clone ($self) {
    return __PACKAGE__->new(
        dir => $self->dir, path => $self->path, home => $self->home);
}

sub equals ($self, $other) {
        $self->dir->to_string eq $other->dir->to_string
    and $self->path->to_string eq $other->path->to_string;
}

# Un-lazy content tree
sub full_tree ($self) {
    $self->_lc($self);
    return $self;
}
sub _lc ($self, $node) {
    $node->children_hr;
    $node->children->map(sub {$self->_lc($_)});
}

# Try to find a content page
sub content_for ($self, $path) {

    # Try to work with the next part of the path
    my ($next_part, $rest)  = ($path // '') =~ m|^([^/]*)(?:/(.*))?|;

    # Found something: give/delegate (pages give themselves)
    my $found = $self->children_hr->{$next_part};
    return $found->content_for($rest // '') if defined $found;

    # Nothing found and path is empty: try to find a directory home
    return $self->children_hr->{$self->home}
        if $next_part eq '' and exists $self->children_hr->{$self->home};

    # Nothing found
    return;
}

sub navi_tree ($self, $parts = '__FULL__') {
    my (@ps) = ($parts eq '__FULL__') ? 42 : @$parts;
    my $next = shift @ps;

    # Full tree: nothing active, all children, "cloned"
    my $tree = $self->clone->children->map(sub ($child) {
        my $d = {path => $child->path_name, node => $child};
        $d->{children} = $child->navi_tree(\@ps)
            unless $child->can('content');
    $d});
    return $tree if $parts eq '__FULL__';

    # Partial tree: activate
    return $tree->map(sub ($d) {
        if (defined $next and $d->{path} eq $next) {
            $d->{active}++;
        } else {
            delete $d->{children};
        }
    $d});
}

1;
