package Bric::Util::Burner::TemplateToolkit::DevTest;

use strict;
use warnings;
#use utf8; # Allow Test::File::Contents to do a binary comparison.
use base qw(Bric::Util::Burner::DevTest);
use Test::More;

sub test_burn : Test(124) {
    my $self = shift;
    return "Template Toolkit not installed" unless eval { require Template };
    return "Template Toolkit not version 2.14 or later"
      unless $Template::VERSION >= 2.14;
    require Bric::Util::Burner::TemplateToolkit;

    return $self->subclass_burn_test(
        'TemplateToolkit',
        'tt',
        Bric::Biz::OutputChannel::BURNER_TT,
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
<p>Third paragraph</p><blockquote>
<p>Ask not what your country can do for you. Ask what you can do for your country.</p>
<p>--John F. Kennedy, 1961.01.20</p>
</blockquote>

<p>圳地在圭圬圯圩夙多夷夸妄奸妃好她如妁字存宇守宅安寺尖屹州帆并年</p>
<p>橿梶鰍潟割喝恰括活渇滑葛褐轄且鰹叶椛樺鞄株兜竃蒲釜鎌噛鴨栢茅萱</p>
<p>뼈뼉뼘뼙뼛뼜뼝뽀뽁뽄뽈뽐뽑뽕뾔뾰뿅뿌뿍뿐뿔뿜뿟뿡쀼쁑쁘쁜쁠쁨쁩삐</p><blockquote>
<p>So, first of all, let me assert my firm belief that the only thing we have to fear is fear itself -- nameless, unreasoning, unjustified terror which paralyzes needed efforts to convert retreat into advance.</p>
<p>--Franklin D. Roosevelt, 1933.03.04</p>
</blockquote>
<h4>My URI: /testing/sub/2005/03/22/test_burn/</h4>
<h3>ANY: Bric::Util::DBI::ANY</h3>
<div>Licensed under the BSD license</div>
</body></html>
};
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
<p>Third paragraph</p><blockquote>
<p>Ask not what your country can do for you. Ask what you can do for your country.</p>
<p>--John F. Kennedy, 1961.01.20</p>
</blockquote>

<p>圳地在圭圬圯圩夙多夷夸妄奸妃好她如妁字存宇守宅安寺尖屹州帆并年</p>
<p>橿梶鰍潟割喝恰括活渇滑葛褐轄且鰹叶椛樺鞄株兜竃蒲釜鎌噛鴨栢茅萱</p>
<p>뼈뼉뼘뼙뼛뼜뼝뽀뽁뽄뽈뽐뽑뽕뾔뾰뿅뿌뿍뿐뿔뿜뿟뿡쀼쁑쁘쁜쁠쁨쁩삐</p><blockquote>
<p>So, first of all, let me assert my firm belief that the only thing we have to fear is fear itself -- nameless, unreasoning, unjustified terror which paralyzes needed efforts to convert retreat into advance.</p>
<p>--Franklin D. Roosevelt, 1933.03.04</p>
</blockquote>
<div class="page">
<p>Wee, page one paragraph</p>
<p>Another page one paragraph</p>
</div>
<h4>My URI: /testing/sub/2005/03/22/test_burn/</h4>
<h3>ANY: Bric::Util::DBI::ANY</h3>
<div>Licensed under the BSD license</div>
</body></html>
};
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
<p>Third paragraph</p><blockquote>
<p>Ask not what your country can do for you. Ask what you can do for your country.</p>
<p>--John F. Kennedy, 1961.01.20</p>
</blockquote>

<p>圳地在圭圬圯圩夙多夷夸妄奸妃好她如妁字存宇守宅安寺尖屹州帆并年</p>
<p>橿梶鰍潟割喝恰括活渇滑葛褐轄且鰹叶椛樺鞄株兜竃蒲釜鎌噛鴨栢茅萱</p>
<p>뼈뼉뼘뼙뼛뼜뼝뽀뽁뽄뽈뽐뽑뽕뾔뾰뿅뿌뿍뿐뿔뿜뿟뿡쀼쁑쁘쁜쁠쁨쁩삐</p><blockquote>
<p>So, first of all, let me assert my firm belief that the only thing we have to fear is fear itself -- nameless, unreasoning, unjustified terror which paralyzes needed efforts to convert retreat into advance.</p>
<p>--Franklin D. Roosevelt, 1933.03.04</p>
</blockquote>
<div class="page">
<p>Wee, page two paragraph</p>
<p>Another page two paragraph</p>
</div>
<h4>My URI: /testing/sub/2005/03/22/test_burn/</h4>
<h3>ANY: Bric::Util::DBI::ANY</h3>
<div>Licensed under the BSD license</div>
</body></html>
};
}

1;
