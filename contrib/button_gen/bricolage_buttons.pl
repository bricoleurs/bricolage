#!/usr/bin/perl

#
# bric_workflow_buttons.pl
# (c) 2004 Florian Rossol (rossol@yola.in-berlin.de)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
#
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

use File::Path;
use Gimp ":auto";
use Gimp::Fu; 

my $form;

  
sub bric_buttons { 
    #Gimp::set_trace(TRACE_ALL);
   
    my($font, $bgcolorred, $bgcolorlgreen, $bgcolordgreen, $bgcolororange, 
       $bgcolorblack, $fgcolor, $webbgcolor, $input_file, $out_dir, $gif) = @_;
    
    open(RH, $input_file) or die "can't read $input_file: $!\n";
    my $first_line = <RH>;
    chomp ($first_line);
    my @languages = split(';', $first_line);
    shift(@languages);

    # Die if output directory exists, so we won't override anything
    die "Output directory $out_dir exitst!\nPlease remove and start again\n" 
	if (-d $out_dir);
    mkpath($out_dir) or die "can't create output directory: $!\n";
    foreach (@languages) {
	mkpath("$out_dir/$_") or die "can't create output directory: $!\n";
    }

    # Create a new image of an arbitrary size
    my $img = gimp_image_new(100, 100, RGB);
    $img->undo_disable();

    # counter
    my $i;
  
    foreach (<RH>) {
	chomp;
	
	# ignore lines of blanks
	next if (/^\ *$/);
	if (/^\#/) {
	    s/^\#\ *//;
	    s/\ *$//;
	    $form = $_;
	    next;
	}
	
	my @texts = split(';');
	my $name = shift(@texts);
	$i = 0;

	foreach (@languages) {
	    print "generating $_/$name";
	    if ($gif == 1) {
		print ".gif\n";
	    } else {
		print ".png\n";
	    }

	    # Create a new layer for the background of arbitrary size, and
	    # add it to the image
	    my $background = gimp_layer_new($img, 100, 100,
					    RGB, "Background", 100,
					    NORMAL_MODE);
	    gimp_image_add_layer($background, 1);
	    
	    # Choose color of text
	    gimp_palette_set_foreground($fgcolor);
	    
	    # Create the text layer. Using -1 as the drawable creates a 
	    # new layer. Defaults to en_us.
	    my $text_layer;
	    my $text;
	    if ($texts[$i]) {
		$text = $texts[$i];
	    } else {
		$text = $texts[0];
	    }

	    if ($form eq "arrow left") {
		$text_layer = gimp_text_fontname($img, -1, 24, 5, $text,
					     0, 1, 10, 0, $font);
	    } elsif ($form eq "round") {
		my $text_width = (gimp_text_get_extents_fontname($text, 10, 0, $font))[0];
		# correct width 
		$text_width = $text_width - 7;
		my $lborder = lborder($text_width, 15);
		$text_layer = gimp_text_fontname($img, -1, $lborder, 3, $text,
					     0, 1, 10, 0, $font);
	    } else {
		$text_layer = gimp_text_fontname($img, -1, 12, 5, $text,
					     0, 1, 10, 0, $font);
	    }
	    
	    # get the width and resize the image
	    my $width = $text_layer->width;
	    if ($form eq "arrow left" or $form eq "arrow right") {
		gimp_image_resize($img, $width + 36, 20, 0, 0);
		gimp_layer_resize($background, $width + 36, 20, 0, 0);
	    } elsif ($form eq "round") {
		gimp_image_resize($img, 15, 15, 0, 0);
		gimp_layer_resize($background, 15, 15, 0, 0);
	    } elsif ($form eq "standard") {
		gimp_image_resize($img, $width + 24, 20, 0, 0);
		gimp_layer_resize($background, $width + 24, 20, 0, 0);
	    } else {
		die "Form $form not defined!\n";
	    }
	    
	    # Fill the background layer now when it has the right size.
	    gimp_palette_set_background($webbgcolor);
	    gimp_edit_fill($background, BG_IMAGE_FILL);
	    
	    # Select the area to fill with bgcolor
	    # left
	    if ($form eq "standard" or $form eq "arrow right") {
		gimp_ellipse_select($img, 0, 0, 16, 20, 2, 1, 0, 0);
	    } elsif ($form eq "arrow left") {
		gimp_free_select($img, 3, 
		     [8, 20, 0, 10, 8, 0],
		     0, 1, 0, 0);
	    }
	    # middle
	    if ($form eq "arrow left" or $form eq "arrow right") {
		gimp_rect_select($img, 8, 0, $width + 20, 20, 0, 0, 0);
	    } else {
		gimp_rect_select($img, 8, 0, $width + 8, 20, 0, 0, 0);
	    }
	    # right
	    if ($form eq "standard") {
		gimp_ellipse_select($img, $width + 8, 0, 16, 20, 0, 1, 0, 0);
	    } elsif  ($form eq "arrow left") {
		gimp_ellipse_select($img, $width + 20, 0, 16, 20, 0, 1, 0, 0);
	    } elsif ($form eq "arrow right") {
		gimp_free_select($img, 3, 
		     [$width + 28, 0, $width + 36, 10, $width + 28, 20],
		     0, 1, 0, 0);
	    }
	    # round buttons:
	    if ($form eq "round") {
		gimp_ellipse_select($img, 0, 0, 15, 15, 2, 1, 0, 0);
	    }
	    
	    if ($name =~ /red$/) {
		gimp_palette_set_background($bgcolorred);
	    } elsif ($name =~ /lgreen$/) {
		gimp_palette_set_background($bgcolorlgreen);
	    } elsif ($name =~ /dgreen$/) {
		gimp_palette_set_background($bgcolordgreen);
	    } elsif ($name =~ /orange$/) {
		gimp_palette_set_background($bgcolororange);
	    } elsif ($name =~ /black$/) {
		gimp_palette_set_background($bgcolorblack);
	    } else {
		die "unknown color: $name\n";
	    }
	    gimp_edit_fill($background, BG_IMAGE_FILL);

	    # make the arrows
	    if ($form eq "arrow left") {
		gimp_free_select($img, 9, 
		     [5, 10, 11, 4, 12, 4, 12, 7, 18, 7, 18, 13, 12, 13, 
		        12, 16, 11, 16],
		     2, 1, 0, 0);
		gimp_palette_set_background($fgcolor);
		gimp_edit_fill($background, BG_IMAGE_FILL);
	    } elsif ($form eq "arrow right") {
		gimp_free_select($img, 9, 
		     [$width + 31, 10, $width + 26, 16, $width + 25, 16,
		      $width + 25, 13, $width + 18, 13, $width + 18, 7,
		      $width + 25, 7, $width + 25, 4, $width + 26, 4],
		     2, 1, 0, 0);
		gimp_palette_set_background($fgcolor);
		gimp_edit_fill($background, BG_IMAGE_FILL);
	    }
	    
	    # merge visible layers
	    my ($activelayer) = gimp_image_merge_visible_layers($img, 0);
	    
	    # save the image
	    if ($gif == 1) {
		file_gif_save(RUN_NONINTERACTIVE, $img, $activelayer,
			  "$out_dir/$_/$name.gif", "$out_dir/$_/$name.gif", 
			  0, 0, 0, 0);
	    } else {
		file_png_save(RUN_NONINTERACTIVE, $img, $activelayer,
			  "$out_dir/$_/$name.png", "$out_dir/$_/$name.png", 
			  0, 9, 0, 0, 0, 0, 0);
	    }
	    
	    # remove the layer from $img
	    gimp_image_remove_layer($img, $activelayer);

	    $i++;
	}
    }
    return();
}
	

#############################################################################
register 
#############################################################################
    "bricolage_buttons",        # fill in name 
    "Create the buttons for bricolage",	# a small description 
    "Create the buttons for bricolage in all languages", # a help text 
    "Florian Rossol",           # Your name 
    "Florian Rossol (c)",       # Your copyright 
    "2004-01-18",              	# Date 
    "<Toolbox>/Xtns/Perl-Fu/Bricolage-Buttons",	# menu path 
    "",                       	# Image types 
    [ 
     [PF_FONT,	"font",		"Schrift",	
	"-microsoft-verdana-bold-r-normal-*-10-*-*-*-*-*-*-*"],
     [PF_COLOR,	"backgroundcolor_red", "Background Color \"red\"", "#993300"],
     [PF_COLOR,	"backgroundcolor_lgreen", "Background Color \"lgreen\"", "#999933"],
     [PF_COLOR,	"backgroundcolor_dgreen", "Background Color \"dgreen\"", "#646430"],
     [PF_COLOR,	"backgroundcolor_orange", "Background Color \"orange\"", "#cc9900"],
     [PF_COLOR,	"backgroundcolor_black", "Background Color \"black\"", "#000000"],
     [PF_COLOR,	"textcolor", 	"Text Color",	"#FFFFFF"],
     [PF_COLOR,	"website_backgroundcolor", 	"Background Color of Website",	"#FFFFFF"],
     [PF_FILE, "input_filename", "File containing the text for the buttons"],
     [PF_FILE, "output_directory", "Output Directory"],
     [PF_TOGGLE, "gif_or_png", "Safe as GIF or PNG", 1],
    ], # Eingabe Parameter
    \&bric_buttons; 
   
exit main();

###############################################################################
sub lborder {
###############################################################################
    my ($text, $button) = @_;
    return sprintf('%u', ($button - $text) / 2);
}

