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
    $r->get($self->debug)->to('Controller#debug')->name('dirdown_debug')
        if defined $self->debug;

    # Content, needs to be the last route because it matches everything
    $r->get('/*cpath')->to('Controller#content')->name('dirdown_page');
    $r->get('/')->to('Controller#content');
}

1;
