package Bric::Util::Burner::Template::DevTest;

use strict;
use warnings;
#use utf8; # Allow Test::File::Contents to do a binary comparison.
use base qw(Bric::Util::Burner::DevTest);
use File::Basename;
use Test::More;

sub test_burn : Test(131) {
    my $self = shift;
    return "HTML::Template not installed"
      unless eval { require HTML::Template };
    require Bric::Util::Burner::Template;

    return $self->subclass_burn_test(
        'Template',
        'tmpl',
        Bric::Biz::OutputChannel::BURNER_TEMPLATE,
    );
}

sub extra_templates {
    my ($self, $p) = @_;

    my $cat_tmpl_fn = 'sub_' . Bric::Util::Burner->cat_fn_for_ext('pl') . '.pl';
    my $file = Bric::Util::Trans::FS->cat_file(dirname(__FILE__), $cat_tmpl_fn);
    open my $fh, '<', $file or die "Cannot open '$file': $!\n";
    ok my $cat_tmpl = Bric::Biz::Asset::Template->new({
        output_channel => $p->{suboc}, # Put it in the contained OC.
        user__id       => $self->user_id,
        category_id    => $p->{subcat}->get_id,
        site_id        => 100,
        tplate_type    => Bric::Biz::Asset::Template::CATEGORY_TEMPLATE,
        file_type      => 'pl',
        data           => join('', <$fh>),
    }), "Create a subcategory script template";
    ok( $cat_tmpl->save, "Save subcategory script template" );
    $self->add_del_ids($cat_tmpl->get_id, 'template');
    close $fh;

    $file = Bric::Util::Trans::FS->cat_file(dirname(__FILE__), "pull_quote.pl");
    open $fh, '<', $file or die "Cannot open '$file': $!\n";
    ok my $pq_tmpl = Bric::Biz::Asset::Template->new({
        output_channel => $p->{suboc}, # Put it in the contained OC.
        user__id       => $self->user_id,
        category_id    => $p->{cat}->get_id, # Put it in a subcategory
        site_id        => 100,
        tplate_type    => Bric::Biz::Asset::Template::ELEMENT_TEMPLATE,
        element        => $p->{pull_quote},
        file_type      => 'pl',
        data           => join('', <$fh>),
    }), "Create a pull quote script template";
    ok( $pq_tmpl->save, "Save pull quote script template" );
    $self->add_del_ids($pq_tmpl->get_id, 'template');
    close $fh;

    return $cat_tmpl, $pq_tmpl;
}

sub story_output {
    # Whitespace rules in HTML::Template are god-awful.
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





<p>圳地在圭圬圯圩夙多夷夸妄奸妃好她如妁字存宇守宅安寺尖屹州帆并年</p>





<p>橿梶鰍潟割喝恰括活渇滑葛褐轄且鰹叶椛樺鞄株兜竃蒲釜鎌噛鴨栢茅萱</p>





<p>뼈뼉뼘뼙뼛뼜뼝뽀뽁뽄뽈뽐뽑뽕뾔뾰뿅뿌뿍뿐뿔뿜뿟뿡쀼쁑쁘쁜쁠쁨쁩삐</p>







<blockquote>
<p>So, first of all, let me assert my firm belief that the only thing we have to fear is fear itself -- nameless, unreasoning, unjustified terror which paralyzes needed efforts to convert retreat into advance.</p>
<p>--Franklin D. Roosevelt, 1933.03.04</p>
</blockquote>









<h4>My URI: /testing/sub/2005/03/22/test_burn/</h4>
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





<p>圳地在圭圬圯圩夙多夷夸妄奸妃好她如妁字存宇守宅安寺尖屹州帆并年</p>





<p>橿梶鰍潟割喝恰括活渇滑葛褐轄且鰹叶椛樺鞄株兜竃蒲釜鎌噛鴨栢茅萱</p>





<p>뼈뼉뼘뼙뼛뼜뼝뽀뽁뽄뽈뽐뽑뽕뾔뾰뿅뿌뿍뿐뿔뿜뿟뿡쀼쁑쁘쁜쁠쁨쁩삐</p>







<blockquote>
<p>So, first of all, let me assert my firm belief that the only thing we have to fear is fear itself -- nameless, unreasoning, unjustified terror which paralyzes needed efforts to convert retreat into advance.</p>
<p>--Franklin D. Roosevelt, 1933.03.04</p>
</blockquote>














<div class="page">
<p>Wee, page one paragraph</p>
<p>Another page one paragraph</p>

</div>



<h4>My URI: /testing/sub/2005/03/22/test_burn/</h4>
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





<p>圳地在圭圬圯圩夙多夷夸妄奸妃好她如妁字存宇守宅安寺尖屹州帆并年</p>





<p>橿梶鰍潟割喝恰括活渇滑葛褐轄且鰹叶椛樺鞄株兜竃蒲釜鎌噛鴨栢茅萱</p>





<p>뼈뼉뼘뼙뼛뼜뼝뽀뽁뽄뽈뽐뽑뽕뾔뾰뿅뿌뿍뿐뿔뿜뿟뿡쀼쁑쁘쁜쁠쁨쁩삐</p>







<blockquote>
<p>So, first of all, let me assert my firm belief that the only thing we have to fear is fear itself -- nameless, unreasoning, unjustified terror which paralyzes needed efforts to convert retreat into advance.</p>
<p>--Franklin D. Roosevelt, 1933.03.04</p>
</blockquote>














<div class="page">
<p>Wee, page two paragraph</p>
<p>Another page two paragraph</p>

</div>



<h4>My URI: /testing/sub/2005/03/22/test_burn/</h4>
<div>Licensed under the BSD license</div>
</body></html>

};
}

1;
