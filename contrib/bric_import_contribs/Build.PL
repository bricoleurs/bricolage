use Module::Build;

my $build = Module::Build->new
  ( module_name        => 'bric_import_contribs',
    license            => 'perl',
    create_makefile_pl => 'passthrough',
    script_files       => [ 'bin/bric_import_contribs' ],
    dist_version_from  => 'bin/bric_import_contribs',
    pm_files           => {},
    requires           => { Getopt::Long    => 0,
                            Pod::Usage      => 0,
                          },
  );
$build->create_build_script;
