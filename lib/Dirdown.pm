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

    # Routes
    my $r = $self->routes;

    # Debug route?
    my $dbr = $ENV{DIRDOWN_DEBUGROUTE};
    $r->get($dbr)->to('C#debug')->name('dirdown_debug') if defined $dbr;

    # Content, needs to be the last route because it matches everything
    $r->get('/*cpath')->to('C#content')->name('dirdown_content');
    $r->get('/')->to('C#content');
}

package Dirdown::C;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub content ($c) {
    my $node = $c->dirdown->content_for($c->param('cpath') // '');
    return $c->reply->not_found unless defined $node;
}

sub debug ($c) {
    $c->render(inline => '<pre><%= dumper dirdown->tree %></pre>');
}

1;
