package Mojolicious::Plugin::Dirdown;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub register ($self, $app, $conf) {

    # Inject dirdown configuration
    $ENV{DIRDOWN_CONTENT}       //= $conf->{dir}; # Content directory
    $ENV{DIRDOWN_DIRECTORYHOME} //= $conf->{home}; # Home page name
    $ENV{DIRDOWN_TEMPLATES}     //= $conf->{templates}; # Custom template dir
    $ENV{DIRDOWN_DEBUGROUTE}    //= $conf->{debug}; # Debug route

    # Mount the dirdown app in the app using us as a plugin
    my $prefix  = $conf->{prefix} // '/pages';
    my $route   = $app->routes->route($prefix)->detour('Dirdown');
}

1;
