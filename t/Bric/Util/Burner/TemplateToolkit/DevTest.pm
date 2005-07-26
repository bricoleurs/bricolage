package Bric::Util::Burner::TemplateToolkit::DevTest;

use strict;
use warnings;
use base qw(Bric::Util::Burner::DevTest);
use Test::More;

sub test_burn : Test(108) {
    my $self = shift;
    return "Template Toolkit not installed" unless eval { require Template };
    return "Template Toolkit not version 2.14 or later"
      unless $Template::VERSION >= 2.14;
    require Bric::Util::Burner::TemplateToolkit;

    return $self->subclass_burn_test(
        'TemplateToolkit',
        'tt',
        Bric::Biz::AssetType::BURNER_TT,
    );
}

sub story_output {
    # I don't understand the whitespace rules in TT at all!
    return q{<html><head>
<title>This is a Test</title>
</head><body><h1>This is a Test</h1><h2>2005.03.22</h2>
<p>This is a paragraph</p><p>Second paragraph</p><h3>And then...</h3><p>Third paragraph</p><blockquote>
<p>Ask not what your country can do for you. Ask what you can do for your country.</p>
<p>--John F. Kennedy, 1961.01.20</p>
</blockquote><h4>My URI: /testing/sub/2005/03/22/test_burn</h4>
<div>Licensed under the BSD license</div></body></html>};
}

sub story_page1 {
    return q{<html><head>
<title>This is a Test</title>
</head><body><h1>This is a Test</h1><h2>2005.03.22</h2>
<p>This is a paragraph</p><p>Second paragraph</p><h3>And then...</h3><p>Third paragraph</p><blockquote>
<p>Ask not what your country can do for you. Ask what you can do for your country.</p>
<p>--John F. Kennedy, 1961.01.20</p>
</blockquote><div class="page"><p>Wee, page one paragraph</p><p>Another page one paragraph</p></div><h4>My URI: /testing/sub/2005/03/22/test_burn</h4>
<div>Licensed under the BSD license</div></body></html>};
}

sub story_page2 {
    return q{<html><head>
<title>This is a Test</title>
</head><body><h1>This is a Test</h1><h2>2005.03.22</h2>
<p>This is a paragraph</p><p>Second paragraph</p><h3>And then...</h3><p>Third paragraph</p><blockquote>
<p>Ask not what your country can do for you. Ask what you can do for your country.</p>
<p>--John F. Kennedy, 1961.01.20</p>
</blockquote><div class="page"><p>Wee, page two paragraph</p><p>Another page two paragraph</p></div><h4>My URI: /testing/sub/2005/03/22/test_burn</h4>
<div>Licensed under the BSD license</div></body></html>};
}

1;
