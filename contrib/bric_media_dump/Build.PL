use Module::Build;

my $build = Module::Build->new
  ( module_name        => 'bric_media_dump',
    license            => 'perl',
    create_makefile_pl => 'passthrough',
    script_files       => [ 'bin/bric_media_dump' ],
    dist_version_from  => 'bin/bric_media_dump',
    pm_files           => {},
    requires           => { Getopt::Long    => 0,
                            Pod::Usage      => 0,
                            SOAP::Lite      => 0,
                            File::Spec      => 0,
                            HTTP::Cookies   => 0,
                            File::Path      => 0,
                            MIME::Base64    => 0,
                            XML::Simple     => 0,
                          },
  );
$build->create_build_script;
