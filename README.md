# NAME

App::TimeTracker - time tracking for impatient and lazy command line lovers

# VERSION

version 3.006

# SYNOPSIS

Backend for the `tracker` command. See [tracker](https://metacpan.org/pod/tracker) and/or `perldoc tracker` for details.

# INSTALLATION

[App::TimeTracker](https://metacpan.org/pod/App::TimeTracker) is a [Perl](http://perl.org) application, and thus requires
a recent Perl (>= 5.10). It also reuses a lot of code from
[CPAN](http://cpan.org).

## From CPAN

The easiest way to install the current stable version of [App::TimeTracker](https://metacpan.org/pod/App::TimeTracker) is
via [CPAN](http://cpan.org). There are several different CPAN clients
available:

### cpanminus

    ~$ cpanm App::TimeTracker
    --> Working on App::TimeTracker
    Fetching http://search.cpan.org/CPAN/authors/id/D/DO/DOMM/App-TimeTracker-2.009.tar.gz ... OK
    Configuring App-TimeTracker-2.009 ... OK
    Building and testing App-TimeTracker-2.009 ... OK
    Successfully installed App-TimeTracker-2.009
    1 distribution installed

If you don't have `cpanminus` installed yet, [install it right
now](http://search.cpan.org/dist/App-cpanminus/lib/App/cpanminus.pm#INSTALLATION):

    ~$ curl -L http://cpanmin.us | perl - --sudo App::cpanminus

### CPAN.pm

CPAN.pm is available on ancient Perls, and feels a bit ancient, too.

    cpan App::TimeTracker

## From a tarball

To install [App::TimeTracker](https://metacpan.org/pod/App::TimeTracker) from a tarball, do the usual CPAN module
install dance:

    ~/perl/App-TimeTracker$ perl Build.PL
    ~/perl/App-TimeTracker$ ./Build
    ~/perl/App-TimeTracker$ ./Build test
    ~/perl/App-TimeTracker$ ./Build install  # might require sudo

## From a git checkout

Clone the repository if you have not already done so, and enter the
`App-TimeTracker` directory:

    ~$ git clone git@github.com:domm/App-TimeTracker.git
    ~$ cd App-TimeTracker

`App-TimeTracker` uses [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) to build, test and install the code,
hence this must be installed first, e.g. with `cpanm`:

    ~/path/to/App-Tracker$ cpanm Dist::Zilla

Now install the distribution's dependencies, test and install in the usual
manner for `Dist::Zilla` projects:

    ~/path/to/App-Tracker$ dzil listdeps --missing | cpanm
    ~/path/to/App-Tracker$ dzil test
    ~/path/to/App-Tracker$ dzil install

# PLUGINS

Custom commands or adaptations to your workflow can be implemented via
an "interesting" set of [Moose](https://metacpan.org/pod/Moose)-powered plugins. You can configure
different sets of plugins for different jobs or projects.

**Tip:** Use `tracker plugins` to list all installed plugins. Read more
about each plugin in `App::TimeTracker::Command::PLUGIN-NAME`.

## Note about (missing) Plugins

Up to version 2.028 a lot of plugins where included in the main distribution
`App-TimeTracker`. To make installation easier and faster, all non-core
command plugins have been moved into distinct, standalone distributions.

The following plugins are affected:

- App::TimeTracker::Git (which also includes SyncViaGit)
- App::TimeTracker::RT
- App::TimeTracker::TellRemote (which was called Post2IRC earlier)
- App::TimeTracker::Overtime has been removed, while the idea is nice, the API and implementation are not good enough.
- App::TimeTracker::TextNotify has been removed.

# SOURCE CODE

## git

We use `git` for version control and maintain a public repository on
[github](http://github.com).

You can find the latest version of [App::TimeTracker](https://metacpan.org/pod/App::TimeTracker) here:

[https://github.com/domm/App-TimeTracker](https://github.com/domm/App-TimeTracker)

If you want to work on [App::TimeTracker](https://metacpan.org/pod/App::TimeTracker), add a feature, add a plugin or fix
a bug, please feel free to [fork](http://help.github.com/fork-a-repo/) the
repo and send us [pull requests](http://help.github.com/send-pull-requests/)
to merge your changes.

To report a bug, please **do not** use the `issues` feature from github;
use RT instead.

## CPAN

[App::TimeTracker](https://metacpan.org/pod/App::TimeTracker) is distributed via [CPAN](http://cpan.org/), the
Comprehensive Perl Archive Network. Here are a few different views of
CPAN, offering slightly different features:

- [https://metacpan.org/release/App-TimeTracker/](https://metacpan.org/release/App-TimeTracker/)
- [http://search.cpan.org/dist/App-TimeTracker/](http://search.cpan.org/dist/App-TimeTracker/)

# Viewing and reporting Bugs

We use [rt.cpan.org](http://rt.cpan.org) (thank you
[BestPractical](http://rt.bestpractical.com)) for bug reporting. Please do
not use the `issues` feature of github! We pay no attention to those...

Please use this URL to view and report bugs:

[https://rt.cpan.org/Public/Dist/Display.html?Name=App-TimeTracker](https://rt.cpan.org/Public/Dist/Display.html?Name=App-TimeTracker)

# CONTRIBUTORS

Maros Kollar, Klaus Ita, Yanick Champoux, Lukas Rampa, David Schmidt, Michael Kröll, Thomas Sibley, Nelo Onyiah, Jozef Kutej, Roland Lammel, Ruslan Zakirov, Kartik Thakore, Tokuhiro Matsuno, Paul Cochrane, David Provost, Mohammad S Anwar, Håkon Hægland

# AUTHOR

Thomas Klausner <domm@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2020 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
