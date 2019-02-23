package Mojolicious::Plugin::Dirdown;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub register ($self, $app, $conf) {

    # Prepare content directory (may be undef, will be set later)
    $ENV{DIRDOWN_CONTENT} //= $conf->{dir};

    # Enable debug route
    $ENV{DIRDOWN_DEBUGROUTE} //= $conf->{debug};

    # Mount the dirdown app in the app using us as a plugin
    $app->plugin(Mount => {
        $conf->{prefix} // '/dirdown',
        $app->home->rel_file('script/dirdown'),
    });
}

1;
