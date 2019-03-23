package Dirdown::Command::dump;
use Mojo::Base 'Mojolicious::Command', -signatures;

use Mojo::File 'path';
use Mojo::UserAgent::Transactor;

has description => 'Generate static files from a dirdown app';
has usage       => "Usage: dirdown_app dump\n";

sub _paths ($self, $datas = $self->app->dirdown->navi_tree) {
    $datas->map(sub ($c_data) {
        return $c_data->{path} unless exists $c_data->{children};
        return $self->_paths($c_data->{children})
            ->map(sub {"$c_data->{path}/$_"});
    })->flatten;
}

sub run ($self) {

    # Static websites directory
    $self->create_rel_dir(my $target = path('dump'));

    # Request each page
    local $ENV{MOJO_LOG_LEVEL} = 'error';
    my $tr = Mojo::UserAgent::Transactor->new;
    $self->_paths->each(sub ($path, $) {
        my $url = $self->app->url_for('dirdown_page', cpath => $path);
        my $tx  = $tr->tx(get => $url);
        $self->app->handler($tx);
        $self->write_rel_file($target->child($path), $tx->res->body);
    });
}

1;
