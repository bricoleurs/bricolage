use Module::Build;

my $build = Module::Build->new(
    module_name        => 'republish_by_uri',
    license            => 'perl',
    create_makefile_pl => 'passthrough',
    script_files       => [ 'bin/republish_by_uri' ],
    dist_version_from  => 'bin/republish_by_uri',
    pm_files           => {},
    requires           => {
        Getopt::Long    => 0,
        Pod::Usage      => 0,
    },
  );
$build->create_build_script;
