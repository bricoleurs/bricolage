package Bric::Util::Burner::Template::DevTest;

use strict;
use warnings;
use base qw(Bric::Util::Burner::DevTest);
use File::Basename;
use Test::More;

#sub test_burn : Test(80) {
sub test_burn : Test(119) {
    my $self = shift;
    return "HTML::Template not installed"
      unless eval { require HTML::Template };
    require Bric::Util::Burner::Template;

    return $self->subclass_burn_test(
        'Template',
        'tmpl',
        Bric::Biz::AssetType::BURNER_TEMPLATE,
    );
}

sub extra_templates {
    my ($self, $p) = @_;

    my $cat_tmpl_fn = Bric::Util::Burner->cat_fn_for_ext('pl') . '.pl';
    my $file = Bric::Util::Trans::FS->cat_file(dirname(__FILE__), $cat_tmpl_fn);
    open my $fh, '<', $file or die "Cannot open '$file': $!\n";
    ok my $cat_tmpl = Bric::Biz::Asset::Formatting->new({
        output_channel => $p->{suboc}, # Put it in the contained OC.
        user__id       => $self->user_id,
        category_id    => 1,
        site_id        => 100,
        tplate_type    => Bric::Biz::Asset::Formatting::CATEGORY_TEMPLATE,
        file_type      => 'pl',
        data           => join('', <$fh>),
    }), "Create a category script template";
    ok( $cat_tmpl->save, "Save category script template" );
    $self->add_del_ids($cat_tmpl->get_id, 'formatting');
    close $fh;

    $file = Bric::Util::Trans::FS->cat_file(dirname(__FILE__), "pull_quote.pl");
    open $fh, '<', $file or die "Cannot open '$file': $!\n";
    ok my $pq_tmpl = Bric::Biz::Asset::Formatting->new({
        output_channel => $p->{suboc}, # Put it in the contained OC.
        user__id       => $self->user_id,
        category_id    => $p->{cat}->get_id, # Put it in a subcategory
        site_id        => 100,
        tplate_type    => Bric::Biz::Asset::Formatting::ELEMENT_TEMPLATE,
        element        => $p->{pull_quote},
        file_type      => 'pl',
        data           => join('', <$fh>),
    }), "Create a pull quote script template";
    ok( $pq_tmpl->save, "Save pull quote script template" );
    $self->add_del_ids($pq_tmpl->get_id, 'formatting');
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





<p>Third paragraph</p>







<blockquote>
<p>Ask not what your country can do for you. Ask what you can do for your country.</p>
<p>--John F. Kennedy, 1961.01.20</p>
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





<p>Third paragraph</p>







<blockquote>
<p>Ask not what your country can do for you. Ask what you can do for your country.</p>
<p>--John F. Kennedy, 1961.01.20</p>
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





<p>Third paragraph</p>







<blockquote>
<p>Ask not what your country can do for you. Ask what you can do for your country.</p>
<p>--John F. Kennedy, 1961.01.20</p>
</blockquote>














<div class="page">
<p>Wee, page two paragraph</p>
<p>Another page two paragraph</p>

</div>


<h4>My URI: /testing/sub/2005/03/22/test_burn</h4>
<div>Licensed under the BSD license</div>
</body></html>

};
}

1;
