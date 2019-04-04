package Dirdown::Node;
use Mojo::Base -base, -signatures;

use Carp;
use Mojo::Collection;
use Dirdown::Page;

has _parent     => ();
has dir         => sub {croak "No 'dir' given!\n"};
has path        => sub {croak "No 'path' given!\n"};
has home        => 'index';
has rel_path    => sub ($self) {$self->path->to_rel($self->dir)};
has path_parts  => sub ($self) {$self->rel_path->to_array};
has basename    => sub ($self) {$self->path_parts->[-1]};
has sort_val    => sub ($self) {($self->basename =~ /^(\d+)_/)[0] // 0};
has path_name   => \&_path_name;
has name        => \&_name;
has children    => \&_children;
has children_hr => \&_children_hr;

sub _path_name ($self) {
    ($self->basename =~ /^  # start
        (?: \d+ _ )?        # optional sort value
        (   .*?   )         # name we need (captured)
        (?: \.\w+ )?        # optional file extension
    $/x)[0];                # end of string
}

sub _name ($self) {
}

sub _children ($self) {
    return Mojo::Collection->new unless -d $self->path;
    return $self->path->list({dir => 1})->map(sub ($path) {
        my %args = (_parent => $self,
            path => $path, dir => $self->dir, home => $self->home);
        return Dirdown::Page->new(%args) if -f $path;
        return Dirdown::Node->new(%args);
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

    # Nothing found, path is empty: return the node
    return $self if $next_part eq '';

    # Nothing found
    return;
}

sub navi_name ($self) {

    # Try to get it from our meta
    if ($self->can('meta')) {
        my $m = $self->meta;
        return $m->{navi_name}  if exists $m->{navi_name};
        return $m->{name}       if exists $m->{name};
    }

    # I'm the home page
    return $self->_parent->navi_name
        if $self->path_name eq $self->home and defined $self->_parent;

    # Try to get it from home page
    my $chome = $self->children_hr->{$self->home};
    if (defined $chome and $chome->can('meta')) {
        my $m = $chome->meta;
        return $m->{navi_name}  if exists $m->{navi_name};
        return $m->{name}       if exists $m->{name};
    }

    # Derive it from our path name
    (my $name = $self->path_name) =~ s/_/ /g;
    return $name;
}

sub navi_tree ($self, $prefix, $parts = '__FULL__') {
    my (@ps) = ($parts eq '__FULL__') ? 42 : @$parts;
    my $next = shift @ps;

    # Full tree: nothing active, all children, "cloned"
    my $tree = $self->clone->children->map(sub ($child) {
        my $cpath = $prefix . '/' . $child->path_name;
        my $d = {
            cpath   => $cpath,
            path    => $child->path_name,
            node    => $child,
            name    => $child->navi_name,
        };
        $d->{children} = $child->navi_tree($cpath, \@ps)
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

sub navi_stack ($self, $parts) {
    my @ps   = @$parts;
    my $next = shift @ps;

    # Transform children
    my $active;
    my $level = $self->clone->children->map(sub ($child) {
        my $d = {
            path => $child->path_name,
            node => $child,
            name => $child->navi_name,
        };
        if (defined $next and $child->path_name eq $next) {
            $d->{active} = 1;
            $active = $child unless $child->can('content');
        }
    $d})->to_array;

    return ($level, defined($active) ? $active->navi_stack(\@ps) : ());
}

1;
