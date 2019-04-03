package Dirdown::Page;
use Mojo::Base 'Dirdown::Node', -signatures;

use Carp;
use Text::Markdown 'markdown';
use YAML::XS; sub yaml ($text) {Load($text) // {}}

has content     => \&_read;
has meta        => sub ($self) {yaml $self->content->{yaml}};
has html        => sub ($self) {markdown $self->content->{markdown}};
has name        => \&_extract_name;

sub _read ($self) {

    # Prepare raw content
    my $content     = {};
    $content->{raw} = $self->path->slurp; # don't encode

    # Try to split
    my ($first, $second) = split /^---+$/m => $content->{raw};
    $content->{yaml}     = defined($second) ? $first : '';
    $content->{markdown} = defined($second) ? $second : $first;

    # Done
    return $content;
}

sub _extract_name ($self) {

    # Name from Meta yaml information has priority
    return $self->meta->{name}      if exists $self->meta->{name};
    return $self->meta->{navi_name} if exists $self->meta->{navi_name};

    # Extract name from basename (foo_bar.md -> foo bar)
    my $name = $self->path_name;
    $name =~ s/_/ /g;
    $name =~ s/\.(md|markdown)$//;
    return $name;
}

sub clone ($self) {
    return __PACKAGE__->new(
        dir => $self->dir, path => $self->path, home => $self->home);
}

# Is this the page you're looking for?
sub content_for ($self, $path) {
    return $self if $path eq '';
    return;
}

1;
