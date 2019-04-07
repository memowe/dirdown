package Mojolicious::Plugin::Dirdown;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

use Dirdown;
use Mojo::File 'path';

has 'debug';
has 'refresh';

sub register ($self, $app, $conf) {

    # Enclose environment variables that may have been defined with local
    my %env; $env{$_} = $ENV{'DIRDOWN_' . uc $_} for qw(
        prefix content directoryhome debugroute refresh templates
    );

    # Prepare dirdown helper
    $app->helper(dirdown => sub {
        my %args = ();
        my $dir  = $env{content} // $conf->{dir};
        my $home = $env{directoryhome} // $conf->{home};
        $args{dir}  = path($dir) if defined $dir;
        $args{home} = $home if defined $home;
        state $dirdown = Dirdown->new(%args);
    });

    # Plugin web app state
    $self->debug($env{debugroute} // $conf->{debug});
    $self->refresh($env{refresh} // $conf->{refresh} // 0);

    # Enable dirdown commands for the outer app
    push @{$app->commands->namespaces}, 'Dirdown::Command';

    # Custom templates
    my $tmpl_dir = $env{templates} // $conf->{templates};
    unshift @{$app->renderer->paths}, $tmpl_dir if defined $tmpl_dir;

    # Dirdown static files/templates
    my $res = path($INC{'Dirdown.pm'})->sibling('Dirdown')->child('resources');
    push @{$app->static->paths}, $res->child('public')->to_string;
    push @{$app->renderer->paths}, $res->child('templates')->to_string;

    # Relative URL helper
    $app->helper(rel_html_path => sub ($, $url, $base) {

        # No leading slashes
        $_ =~ s|^/+|| for $url, $base;

        # Remove shared directories
        while ($url =~ m|^([^/]+/)|) {
            my $d = $1;
            last unless $base =~ m|^$d|;
            s/^$d// for $url, $base;
        }

        # Go up and prepend '../'s
        my $depth    =()= $base =~ m|/|g;
        my $up          = '../' x $depth;
        my $rel_path    = $up . $url;

        # Special cases
        return './' if $rel_path eq '';
        return $rel_path if substr($rel_path, -1, 1) eq '/';
        return "$rel_path.html";
    });

    # Routes
    my $prefix = $env{prefix} // $conf->{prefix} // '/pages';
    my $r = $app->routes->any($prefix);
    $r->get($self->debug)->name('dirdown_debug') if defined $self->debug;
    $r->get('/*cpath')
        ->to(cb => sub ($c) {$self->_serve($c)})->name('dirdown_page');
    $r->get('/')
        ->to(cb => sub ($c) {$self->_serve($c)});
}

# Try to be a controller
sub _serve ($self, $c) {

    # Prepare path
    (my $path = $c->param('cpath') // '') =~ s/\.html//;

    # Try to find content
    $c->dirdown->refresh if $self->refresh;
    my $page = $c->dirdown->content_for($path);
    return $c->reply->not_found unless defined $page;

    # Collect data
    $c->stash(
        page_path   => $path,
        page        => $page,
        navi_tree   => $c->dirdown->navi_tree($path),
        navi_stack  => $c->dirdown->navi_stack($path),
    );

    # Serve a directory listing
    return $c->render(dir => $page, template => 'dirdown_listing')
        unless $page->isa('Dirdown::Page');

    # Serve a page
    $c->render(page => $page, template => (defined $self->debug) ?
        'dirdown_page_debug' : 'dirdown_page',
    );
}

1;
