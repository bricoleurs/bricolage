package Bric::App::Callback::FileUpload;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'file_upload');
use strict;
use Bric::App::Session;

1;
