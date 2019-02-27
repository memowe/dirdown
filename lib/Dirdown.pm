package Dirdown;
use Mojo::Base 'Mojolicious', -signatures;

use Dirdown::Content;
use Mojo::File 'path';

has 'debug';

sub startup ($self) {

    # Prepare
    $self->helper(dirdown => sub {
        my $dir = $ENV{DIRDOWN_CONTENT}
            // $self->home->rel_file('dirdown_content')->to_string;
        state $dirdown = Dirdown::Content->new(
            dir     => path($dir),
            home    => $ENV{DIRDOWN_DIRECTORYHOME},
        );
    });
    $self->debug($ENV{DIRDOWN_DEBUGROUTE});

    # Routes
    my $r = $self->routes;
    $r->get($self->debug)->name('dirdown_debug') if defined $self->debug;
    $r->get('/*cpath')->to(cb => \&_serve)->name('dirdown_page');
    $r->get('/')->to(cb => \&_serve);
}

# Try to be a controller
sub _serve ($c) {

    # Prepare path
    (my $path = $c->param('cpath') // '') =~ s/\.html//;

    # Try to find content
    my $page = $c->dirdown->content_for($path);
    return $c->reply->not_found unless defined $page;

    # Serve
    $c->render(page => $page, template =>
        (defined $c->app->debug) ? 'dirdown_page_debug' : 'dirdown_page'
    );
}

1;
