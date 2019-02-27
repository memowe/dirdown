package Dirdown;
use Mojo::Base 'Mojolicious', -signatures;

use Dirdown::Content;
use Mojo::File 'path';

has 'debug';

sub startup ($self) {

    # Prepare Dirdown
    $self->helper(dirdown => sub {
        my $dir = $ENV{DIRDOWN_CONTENT}
            // $self->home->rel_file('dirdown_content')->to_string;
        state $dirdown = Dirdown::Content->new(
            dir     => path($dir),
            home    => $ENV{DIRDOWN_DIRECTORYHOME},
        );
    });

    # Routes
    my $r = $self->routes;

    # Debug route?
    $self->debug($ENV{DIRDOWN_DEBUGROUTE});
    $r->get($self->debug)->to('C#debug')->name('dirdown_debug')
        if defined $self->debug;

    # Content, needs to be the last route because it matches everything
    $r->get('/*cpath')->to('C#content')->name('dirdown_content');
    $r->get('/')->to('C#content');
}

package Dirdown::C;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub content ($c) {

    # Prepare path
    my $path = $c->param('cpath') // '';
    $path =~ s/\.html$//;

    # Try to serve content
    my $content = $c->dirdown->content_for($path);
    return $c->reply->not_found unless defined $content;
    $c->render(content => $content, template => 'content');
}

sub debug ($c) {
    $c->render(inline => '<pre><%= dumper dirdown->full_tree %></pre>');
}

1;
