package Dirdown::Content::Page;
use Mojo::Base 'Dirdown::Content::Node', -signatures;

use Carp;
use Text::Markdown 'markdown';
use YAML::XS; sub yaml ($text) {Load $text}

has content     => sub ($self) {$self->_read};
has meta        => sub ($self) {yaml $self->content->{yaml}};
has html        => sub ($self) {markdown $self->content->{markdown}};
has name        => sub ($self) {$self->_extract_name};

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

sub _extract_name ($self) {

    # Name from Meta yaml information has priority
    return $self->meta->{name}
        if defined $self->meta and defined $self->meta->{name};

    # Extract name from basename (foo_bar.md -> foo bar)
    my $name = $self->path_name;
    $name =~ s/_/ /g;
    $name =~ s/\.(md|markdown)$//;
    return $name;
}

# Is this the page you're looking for?
sub content_for ($self, $path) {
    return $self if $path eq '';
    return;
}

1;
