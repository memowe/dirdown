package Dirdown;
use Mojo::Base 'Mojolicious', -signatures;

use Dirdown::Content;

sub startup ($self) {

    # Prepare Dirdown
    $self->helper(dirdown => sub {
        state $dirdown = Dirdown::Content->new(
            dir => $ENV{DIRDOWN_CONTENT}
                // $self->home->rel_file('dirdown_content')
        )
    });

    # Routes (*cpath doesn't match empty string)
    my $r = $self->routes;
    $r->get('/*cpath')->to('C#content')->name('dirdown_content');
    $r->get('/')->to('C#content');

    $self->log->debug($self->dumper($self->dirdown->tree)); # TODO weg
}

package Dirdown::C;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub content ($c) {
    my $node = $c->dirdown->content_for($c->param('cpath') // '');
    return $c->reply->not_found unless defined $node;
}

1;
