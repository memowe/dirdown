package Mojolicious::Command::Author::generate::dirdown_app;
use Mojo::Base 'Mojolicious::Command', -signatures;

use Mojo::File 'path';

has description => 'Generate Dirdown directory structure';
has usage       => "Usage: mojo generate dirdown_app\n";

sub run ($self) {

    # Prepare resources directory
    require Dirdown; my $dd_lib = path($INC{'Dirdown.pm'})->dirname;
    my $res = $dd_lib->child('Dirdown', 'resources');

    # Copy everything
    $res->list_tree->each(sub ($file, $) {
        my $target = path('.')->child($file->to_rel($res));
        $self->create_rel_dir($target->dirname);
        $file->copy_to($target);
    });
}

1;
