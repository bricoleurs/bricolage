package Bric::App::Callback;

use strict;
use base qw(MasonX::CallbackHandler);
use constant CLASS_KEY => 'Callback';

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
use Bric::App::Callback::MediaProf;
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
use Bric::App::Callback::StoryProf;
use Bric::App::Callback::TmplProf;
use Bric::App::Callback::Workflow;
use Bric::App::Callback::Workspace;



1;
