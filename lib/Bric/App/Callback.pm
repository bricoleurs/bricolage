package Bric::App::Callback;

use base qw(MasonX::CallbackHandler);
__PACKAGE__->register_subclass(class_key => 'Callback');
use strict;

use Bric::App::Cache;
use Bric::Config qw(:ui);
use Bric::Util::Language;

use Bric::App::Callback::Action;
use Bric::App::Callback::AddMore;
use Bric::App::Callback::Alert;
use Bric::App::Callback::AlertType;
use Bric::App::Callback::Alias;
use Bric::App::Callback::AssetMeta;
use Bric::App::Callback::ContainerProf;
use Bric::App::Callback::Desk;
use Bric::App::Callback::Dest;
use Bric::App::Callback::Element;
use Bric::App::Callback::FileUpload;
use Bric::App::Callback::FormBuilder;
use Bric::App::Callback::Grp;
use Bric::App::Callback::Job;
use Bric::App::Callback::ListManager;
use Bric::App::Callback::Login;
use Bric::App::Callback::Nav;
use Bric::App::Callback::Perm;
use Bric::App::Callback::Profile;
use Bric::App::Callback::Publish;
use Bric::App::Callback::Search;
use Bric::App::Callback::SelectObject;
use Bric::App::Callback::SelectTime;
use Bric::App::Callback::Server;
use Bric::App::Callback::Site;
use Bric::App::Callback::SiteContext;
use Bric::App::Callback::Workflow;
use Bric::App::Callback::Workspace;


my $cache = Bric::App::Cache->new();
my $lang = Bric::Util::Language->get_handle(LANGUAGE);

sub lang { $lang }
sub cache { $cache }


1;
