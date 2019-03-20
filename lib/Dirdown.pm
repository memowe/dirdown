package Dirdown;
use Mojo::Base 'Mojolicious', -signatures;

use Dirdown::Content;
use Mojo::File 'path';

has 'debug';
has 'refresh';

sub startup ($self) {

    # Prepare
    $self->helper(dirdown => sub {
        my $dir = $ENV{DIRDOWN_CONTENT}
            // $self->home->rel_file('dirdown_content')->to_string;
        my $home = $ENV{DIRDOWN_DIRECTORYHOME};
        state $dirdown = Dirdown::Content->new(dir => path($dir));
        $dirdown->home($home) if defined $home;
    $dirdown});
    $self->debug($ENV{DIRDOWN_DEBUGROUTE});
    $self->refresh($ENV{DIRDOWN_REFRESH});

    # Custom templates
    my $tmpls = $ENV{DIRDOWN_TEMPLATES};
    unshift @{$self->renderer->paths}, $tmpls if defined $tmpls;

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
    $c->dirdown->refresh if $c->app->refresh;
    my $page = $c->dirdown->content_for($path);
    return $c->reply->not_found unless defined $page;

    # Collect data
    $c->stash(
        page        => $page,
        navi_tree   => $c->dirdown->navi_tree($path),
        navi_stack  => $c->dirdown->navi_stack($path),
    );

    # Serve
    $c->render(template => (defined $c->app->debug) ?
        'dirdown_page_debug' : 'dirdown_page'
    );
}

1;
