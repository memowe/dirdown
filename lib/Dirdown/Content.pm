package Dirdown::Content;
use Mojo::Base -base, -signatures;

use Carp;
use Mojo::File;
use List::Util 'reduce';

# Content list
has dir     => sub {croak "No Dirdown directory 'dir' given!\n"};
has paths   => sub ($self) {Mojo::File->new($self->dir)->list_tree};
has pages   => sub ($self) {$self->paths->map(sub ($file) {
    Page->new(dir => $self->dir, path => $file);
})};

# Content tree
has tree => sub ($self) {

    # Root directory
    my $tree = {};

    # Go with path parts deep into tree and append the file again
    for my $page (@{$self->pages}) {
        my @parts       = @{$page->path_parts};
        my $leaf        = pop @parts;
        my $node        = reduce {$a->{$b} //= {}} $tree, @parts;
        $node->{$leaf}  = $page;
    }

    # Done
    return $tree;
};

package Page;
use Mojo::Base -base, -signatures;

use Carp;
use Text::Markdown 'markdown';
use YAML; sub yaml ($text) {Load $text}

has dir         => sub {croak "No 'dir' given!\n"};
has path        => sub {croak "No 'path' given!\n"};
has rel_path    => sub ($self) {$self->path->to_rel($self->dir)};
has path_parts  => sub ($self) {$self->rel_path->to_array};
has basename    => sub ($self) {$self->path_parts->[-1]};
has content     => sub ($self) {$self->_read};
has meta        => sub ($self) {yaml $self->content->{yaml}};
has html        => sub ($self) {markdown $self->content->{markdown}};

sub _read ($self) {

    # Prepare raw content
    my $content     = {};
    $content->{raw} = $self->path->slurp;

    # Try to split 
    my ($first, $second) = split /^---+$/m => $content->{raw};
    $content->{yaml}     = defined($second) ? $first : '';
    $content->{markdown} = defined($second) ? $second : $first;

    # Done
    return $content;
}

1;
