use 5.006;
use strict;
use warnings;
use Module::Build;

$ENV{'PERL_MB_OPT'} = '--install-base=/usr'; # I could not make this work via the parameters below :/
$ENV{'DEB_BUILD_OPTIONS'}='nocheck';

use lib '../tm2_base/lib';
use lib '../templescript/lib';

my $debian = Module::Build->subclass(
    class => "Module::Build::Debian",
    code => <<'SUBCLASS' );

sub DEBVERSION {
    return 2;
}

sub ACTION_debian {
    my $self = shift;

    $self->depends_on("dist");
    $self->depends_on("distdir");

    my $version = $self->dist_version;
    my $debversion = $self->DEBVERSION;
    $self->do_system(qq{ dh-make-perl make --email=rho\@devc.at --desc='APC UPS reporting' --packagename=app-apc-reporter --version=$version-$debversion App-APC-Reporter-$version } );
    $self->do_system(qq{ cp debian_template/* App-APC-Reporter-$version/debian/ } );
    $self->do_system(qq{ ( cd App-APC-Reporter-$version/ ; debuild --no-lintian -us -uc -b ) } );
}

sub ACTION_inject {
    my $self = shift;

    $self->depends_on("debian");

    my $version = $self->dist_version;
    my $debversion = $self->DEBVERSION;
    $self->do_system(qq{ scp app-apc-reporter_${version}-${debversion}_all.deb packages.devc.at:packages/ } );
    foreach (qw(stretch) ) { # squeeze wheezy jessie
        $self->do_system(qq{ ssh packages.devc.at -Y -t reprepro --ask-passphrase -b /var/www/packages/data/dists/ includedeb $_ packages/app-ap-reporter_${version}-${debversion}_all.deb })
;
    }
}
SUBCLASS

my $builder = $debian->new(
    module_name         => 'App::APC::Reporter',
    license             => 'perl',
    dist_author         => q{Robert Barta <rho@devc.at>},
    dist_version_from   => 'lib/App/APC/Reporter.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More' => '0',
    },
    requires => {
	'Config::Simple' => 0,
	'LWP' => 0,
	'JSON' => 0,
    },
    add_to_cleanup     => [ 'App-APC-Reporter-*' ],
    install_base       => '/usr',
    install_path       => {
	'var'        => '/var/lib/app-apc-reporter',
	'bin'        => '/usr/bin',
	'etc'        => '/etc/',
	'etc-cron.d' => '/etc/cron.d/',
    },
    conf_files => {
        'etc/apc-ups-reporter.conf' => 'etc/apc-ups-reporter.conf',
        'etc/crontab'               => 'etc-cron.d/app-apc-reporter',
    },
    bin_files => {
        'bin/apc-ups-reporter' => 'bin/apc-ups-reporter',
    },
);

$builder->add_build_element('conf');
$builder->create_build_script();
