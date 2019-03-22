Dirdown
=======

Minimal file-system based CMS

[![Travis CI tests](https://travis-ci.org/memowe/dirdown.svg?branch=master)](https://travis-ci.org/memowe/dirdown)
[![Codecov test coverage](https://codecov.io/gh/memowe/dirdown/branch/master/graph/badge.svg)](https://codecov.io/gh/memowe/dirdown)
[![Coveralls test coverage](https://coveralls.io/repos/github/memowe/dirdown/badge.svg?branch=master)](https://coveralls.io/github/memowe/dirdown?branch=master)

## Generate a new dirdown web application

1. Invoke the generator
    ```bash
    $ mojo generate dirdown_app
    ```
2. Edit the markdown content in `dirdown_content`.
3. Start the server via
    ```bash
    $ morbo dirdown
    Server available at http://127.0.0.1:3000
    ```

## Use it as a plugin for your own Mojolicious web apps:

```perl
#!/usr/bin/env perl
use Mojolicious::Lite;

# Load the dirdown CMS under /content
plugin Dirdown => {
    prefix  => '/content',
    dir     => app->home->rel_file('dirdown_content'),
};

get '/' => {text => 'Hello world!'};

app->start;
```

Prerequisites
-------------

- **[Perl 5.20][perl]**

| Module                                    | Version   |
|-------------------------------------------|-----------|
| [Mojolicious][mojo]                       |  8.12     |
| [Text::Markdown][tmd]                     |  1.000031 |
| [YAML::XS][yml]                           |  0.76     |
| *[Test::Exception][teex] (Tests only)*    | *0.43*    |

[perl]: https://www.perl.org/get.html
[mojo]: https://metacpan.org/pod/Mojolicious
[tmd]: https://metacpan.org/pod/Text::Markdown
[yml]: https://metacpan.org/pod/YAML::XS
[teex]: https://metacpan.org/pod/Test::Exception

License and copyright
---------------------

Copyright (c) 2019 [Mirko Westermeier][mirko] ([\@memowe][mgh], [mirko@westermeier.de][mmail])

Released under the MIT (X11) license. See [LICENSE.txt][mit] for details.

[mirko]: http://mirko.westermeier.de
[mgh]: https://github.com/memowe
[mmail]: mailto:mirko@westermeier.de
[mit]: LICENSE.txt
