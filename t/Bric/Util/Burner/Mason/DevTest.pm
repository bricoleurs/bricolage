package Bric::Util::Burner::Mason::DevTest;

use strict;
use warnings;
use base qw(Bric::Util::Burner::DevTest);
use Test::More;

sub test_burn : Test(112) {
    my $self = shift;
    return $self->subclass_burn_test(
        'Mason',
        'mc',
        Bric::Biz::AssetType::BURNER_MASON,
    );
}

sub story_output {
    return q{<html><head>
<title>This is a Test</title>
</head><body>
<h1>This is a Test</h1>
<h2>2005.03.22</h2>
<p>This is a paragraph</p>
<p>Second paragraph</p>
<h3>And then...</h3>
<p>Third paragraph</p>
<blockquote>
<p>Ask not what your country can do for you. Ask what you can do for your country.</p>
<p>--John F. Kennedy, 1961.01.20</p>
</blockquote>
<blockquote>
<p>So, first of all, let me assert my firm belief that the only thing we have to fear is fear itself -- nameless, unreasoning, unjustified terror which paralyzes needed efforts to convert retreat into advance.</p>
<p>--Franklin D. Roosevelt, 1933.03.04</p>
</blockquote>
<h4>My URI: /testing/sub/2005/03/22/test_burn</h4>
<div>Licensed under the BSD license</div>
</body></html>
}
}

sub story_page1 {
    return q{<html><head>
<title>This is a Test</title>
</head><body>
<h1>This is a Test</h1>
<h2>2005.03.22</h2>
<p>This is a paragraph</p>
<p>Second paragraph</p>
<h3>And then...</h3>
<p>Third paragraph</p>
<blockquote>
<p>Ask not what your country can do for you. Ask what you can do for your country.</p>
<p>--John F. Kennedy, 1961.01.20</p>
</blockquote>
<blockquote>
<p>So, first of all, let me assert my firm belief that the only thing we have to fear is fear itself -- nameless, unreasoning, unjustified terror which paralyzes needed efforts to convert retreat into advance.</p>
<p>--Franklin D. Roosevelt, 1933.03.04</p>
</blockquote>
<div class="page">
<p>Wee, page one paragraph</p>
<p>Another page one paragraph</p>
</div>
<h4>My URI: /testing/sub/2005/03/22/test_burn</h4>
<div>Licensed under the BSD license</div>
</body></html>
}
}

sub story_page2 {
    return q{<html><head>
<title>This is a Test</title>
</head><body>
<h1>This is a Test</h1>
<h2>2005.03.22</h2>
<p>This is a paragraph</p>
<p>Second paragraph</p>
<h3>And then...</h3>
<p>Third paragraph</p>
<blockquote>
<p>Ask not what your country can do for you. Ask what you can do for your country.</p>
<p>--John F. Kennedy, 1961.01.20</p>
</blockquote>
<blockquote>
<p>So, first of all, let me assert my firm belief that the only thing we have to fear is fear itself -- nameless, unreasoning, unjustified terror which paralyzes needed efforts to convert retreat into advance.</p>
<p>--Franklin D. Roosevelt, 1933.03.04</p>
</blockquote>
<div class="page">
<p>Wee, page two paragraph</p>
<p>Another page two paragraph</p>
</div>
<h4>My URI: /testing/sub/2005/03/22/test_burn</h4>
<div>Licensed under the BSD license</div>
</body></html>
}
}

1;
