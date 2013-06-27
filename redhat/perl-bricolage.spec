Name:           perl-bricolage
Version:        2.0.1
Release:        6%{?dist}
Summary:        bricolage Perl module
License:        Distributable, see License
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/bricolage/
Source0:        http://www.cpan.org/modules/by-module/bricolage/bricolage-%{version}.tar.gz
Patch0:         use-apache2.patch
Patch1:         bric-db.patch
Patch2:         bric-single.patch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
AutoReqProv:    no
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  httpd, postgresql, postgresql-devel, expat, expat-devel
BuildRequires:  perl(DBD::Pg),  perl(Unix::Syslog),  perl(Devel::Symdump),  perl(DBI),  perl(Error),  perl(Cache::Cache)
BuildRequires:  perl(Cache::Mmap),  perl(Digest::SHA1),  perl(URI),  perl(HTML::Tagset),  perl(HTML::Parser),  perl(MIME::Tools)
BuildRequires:  perl(Mail::Address),  perl(XML::Writer),  perl(LWP),  perl(Image::Info),  perl(MLDBM),  perl(Params::Validate)
BuildRequires:  perl(Exception::Class),  perl(Class::Container),  perl(HTML::Mason),  perl(Apache::Session),  perl(Test::Simple)
BuildRequires:  perl(Test::MockModule),  perl(Test::File::Contents),  perl(Test::File),  perl(XML::Simple),  perl(IO::Stringy)
BuildRequires:  perl(SOAP::Lite),  perl(Text::LevenshteinXS),  perl(Test::Class),  perl(Params::CallbackRequest)
BuildRequires:  perl(MasonX::Interp::WithCallbacks),  perl(DateTime),  perl(DateTime::TimeZone),  perl(Term::ReadPassword)
BuildRequires:  perl(Data::UUID),  perl(List::MoreUtils),  perl(Text::Diff),  perl(Text::Diff::HTML),  perl(Text::WordDiff),
BuildRequires:  perl(URI::Escape),  perl(Clone),  perl(Imager),  perl(HTML::Template),  perl(HTML::Template::Expr),  perl(Template)
BuildRequires:  perl(Pod::Simple),  perl(Test::Pod),  perl(Net::FTPServer),  perl(Net::SSH2),  perl(HTTP::DAV),  perl(Crypt::SSLeay)
BuildRequires:  perl(Text::Aspell),  perl(XML::DOM),  perl(Apache2::Request),  perl(Apache2::SizeLimit), perl(Time::HiRes)


Requires:       httpd, postgresql, expat
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
Requires:  perl(DBD::Pg),  perl(Unix::Syslog),  perl(Devel::Symdump),  perl(DBI),  perl(Error),  perl(Cache::Cache)
Requires:  perl(Cache::Mmap),  perl(Digest::SHA1),  perl(URI),  perl(HTML::Tagset),  perl(HTML::Parser),  perl(MIME::Tools)
Requires:  perl(Mail::Address),  perl(XML::Writer),  perl(LWP),  perl(Image::Info),  perl(MLDBM),  perl(Params::Validate)
Requires:  perl(Exception::Class),  perl(Class::Container),  perl(HTML::Mason),  perl(Apache::Session),  perl(Test::Simple)
Requires:  perl(Test::MockModule),  perl(Test::File::Contents),  perl(Test::File),  perl(XML::Simple),  perl(IO::Stringy)
Requires:  perl(SOAP::Lite),  perl(Text::LevenshteinXS),  perl(Test::Class),  perl(Params::CallbackRequest)
Requires:  perl(MasonX::Interp::WithCallbacks),  perl(DateTime),  perl(DateTime::TimeZone),  perl(Term::ReadPassword)
Requires:  perl(Data::UUID),  perl(List::MoreUtils),  perl(Text::Diff),  perl(Text::Diff::HTML),  perl(Text::WordDiff),
Requires:  perl(URI::Escape),  perl(Clone),  perl(Imager),  perl(HTML::Template),  perl(HTML::Template::Expr),  perl(Template)
Requires:  perl(Pod::Simple),  perl(Test::Pod),  perl(Net::FTPServer),  perl(Net::SSH2),  perl(HTTP::DAV),  perl(Crypt::SSLeay)
Requires:  perl(Text::Aspell),  perl(XML::DOM),  perl(Apache2::Request),  perl(Apache2::SizeLimit), perl(Time::HiRes)



%description
Bricolage is a full-featured, enterprise-class content management system.
It offers a browser-based interface for ease-of use, a full-fledged
templating system with complete programming language support for
flexibility, and many other features. It operates in an Apache/mod_perl
environment, and uses the PostgreSQL RDBMS for its repository.

%prep
%setup -q -n bricolage-%{version}

%patch0 -p0 -b .useapache2
%patch1 -p0 -b .bricdb
%patch2 -p0 -b .bricsingle

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor INSTALL_VERBOSITY=QUIET
make INSTALL_VERBOSITY=QUIET

%install
rm -rf $RPM_BUILD_ROOT

make install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT INSTALL_VERBOSITY=QUIET

find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} \;
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

rm -f /usr/local/bricolage/lib/Bric/Util/DBD/Oracle.pm
rm -f /usr/local/bricolage/man/man3/Bric::Util::DBD::Oracle.3pm
rm -f /usr/local/bricolage/lib/Bric/Util/Burner/PHP.pm
rm -f /usr/local/bricolage/man/man3/Bric::Util::Burner::PHP.3pm
rm -f /usr/local/bricolage/lib/Bric/Util/DBD/mysql.pm
rm -f /usr/local/bricolage/man/man3/Bric::Util::DBD::mysql.3pm

%{_fixperms} $RPM_BUILD_ROOT/*

%check
# make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc Changes License README README.Debian README.FreeBSD README.MacOSX README.Mandrake README.Redhat README.Solaris README.Ubuntu
%doc %_mandir/*
/usr/local/bricolage/*
%{_bindir}/*
%(eval %{__perl} -MConfig -e 'print $Config{sitelib}')/*

%changelog
* Wed Jun 26 2013 Dean Hamstead <dean.hamstead@optusnet.com.au> 2.0.1-6
- Change from multi-install to single install mode
* Tue Jun 25 2013 Dean Hamstead <dean.hamstead@optusnet.com.au> 2.0.1-5
- Exclude some files
- AutoReqProv: no
* Mon Jun 24 2013 Dean Hamstead <dean.hamstead@optusnet.com.au> 2.0.1-4
- Getting closer to the right build arguments
* Mon Jun 24 2013 Dean Hamstead <dean.hamstead@optusnet.com.au> 2.0.1-3
- Trying to get the the requirements right and the build steps right
* Mon Jun 24 2013 Dean Hamstead <dean.hamstead@optusnet.com.au> 2.0.1-2
- Some minor patches to make the build requirements scripts work right
* Tue Jun 18 2013 Dean Hamstead <dean.hamstead@optusnet.com.au> 2.0.1-1
- Manually added Requires: httpd, postresql, expat
- Specfile autogenerated by cpanspec 1.78.
