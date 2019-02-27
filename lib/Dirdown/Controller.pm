package Dirdown::Controller;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub content ($c) {

    # Prepare path
    my $path = $c->param('cpath') // '';
    $path =~ s/\.html$//;

    # Try to serve content
    my $page = $c->dirdown->content_for($path);
    return $c->reply->not_found unless defined $page;
    $c->render(
        page        => $page,
        template    => (defined $c->app->debug) ?
            'dirdown_page_debug' : 'dirdown_page'
    );
}

sub debug ($c) {
    $c->render(inline => '<pre><%= dumper dirdown->full_tree %></pre>');
}

1;
