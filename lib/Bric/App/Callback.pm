package Bric::App::Callback;

use strict;
use base qw(MasonX::CallbackHandler);
use constant CLASS_KEY => 'Callback';

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
use Bric::App::Callback::Profile;   # XXX: think this will go away
use Bric::App::Callback::Publish;
use Bric::App::Callback::Search;
use Bric::App::Callback::SelectObject;
use Bric::App::Callback::SelectTime;
use Bric::App::Callback::Server;
use Bric::App::Callback::Site;
use Bric::App::Callback::SiteContext;
use Bric::App::Callback::Workflow;
use Bric::App::Callback::Workspace;

use Bric::App::Callback::Profile::Action.pm;
use Bric::App::Callback::Profile::AlertType.pm;
use Bric::App::Callback::Profile::Category.pm;
use Bric::App::Callback::Profile::Contrib.pm;
use Bric::App::Callback::Profile::Desk.pm;
use Bric::App::Callback::Profile::Dest.pm;
use Bric::App::Callback::Profile::ElementData.pm;
use Bric::App::Callback::Profile::ElementType.pm;
use Bric::App::Callback::Profile::FormBuilder.pm;
use Bric::App::Callback::Profile::Grp.pm;
use Bric::App::Callback::Profile::Job.pm;
use Bric::App::Callback::Profile::Media.pm;
use Bric::App::Callback::Profile::MediaType.pm;
use Bric::App::Callback::Profile::OutputChannel.pm;
use Bric::App::Callback::Profile::Pref.pm;
use Bric::App::Callback::Profile::Server.pm;
use Bric::App::Callback::Profile::Site.pm;
use Bric::App::Callback::Profile::Source.pm;
use Bric::App::Callback::Profile::Story.pm;
use Bric::App::Callback::Profile::Template.pm;
use Bric::App::Callback::Profile::User.pm;
use Bric::App::Callback::Profile::Workflow.pm;


my $cache = Bric::App::Cache->new();
my $lang = Bric::Util::Language->get_handle(LANGUAGE);

sub lang { $lang }
sub cache { $cache }


1;
