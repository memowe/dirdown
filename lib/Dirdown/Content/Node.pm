package Dirdown::Content::Node;
use Mojo::Base -base, -signatures;

use Carp;
use Mojo::Collection;
use Dirdown::Content::Page;

has dir         => sub {croak "No 'dir' given!\n"};
has path        => sub {croak "No 'path' given!\n"};
has rel_path    => sub ($self) {$self->path->to_rel($self->dir)};
has path_parts  => sub ($self) {$self->rel_path->to_array};
has basename    => sub ($self) {$self->path_parts->[-1]};
has sort_val    => sub ($self) {($self->basename =~ /^(\d+)_/)[0]};
has path_name   => sub ($self) {($self->basename =~
    /^(?:\d+_)?(.*?)(?:\.\w+)?$/)[0]};
has children    => sub ($self) {$self->_children};
has children_hr => sub ($self) {+{
    map {$_->path_name => $_} @{$self->children->to_array}
}};

sub _children ($self) {
    opendir my $dh, $self->path or return Mojo::Collection->new;
    return Mojo::Collection->new(readdir $dh)
        ->grep(sub ($name) {$name !~ /^\.\.?$/})
        ->map(sub ($name) {
            my $path        = $self->path->child($name);
            my $child_obj   = (-f $path)
                ? Dirdown::Content::Page->new
                : Dirdown::Content::Node->new;
            return $child_obj->path($path)->dir($self->dir);
        });
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
    my ($next_part, $rest)  = $path =~ m|^([^/]+)(?:/(.*))?|;
    return unless my $found = $self->children_hr->{$next_part // ''};
    return $found->content_for($rest // '');
}

1;
