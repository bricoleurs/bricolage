#!/usr/bin/perl

#
# bric_workflow_buttons.pl
# (c) 2004 Florian Rossol (rossol@yola.in-berlin.de)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the license under which Bricolage is distributed.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Bricolage License for more details.
#

use File::Path;
use Gimp ":auto"; 
use Gimp::Fu; 

sub bric_buttons { 
    #Gimp::set_trace(TRACE_ALL);
   
    my($text, $font, $bgcolor_i, $bgcolor_ii, $fgcolor, $webbgcolor, 
       $out_dir, $gif) = @_;
    
    chomp($text);

    # Die if output directory exists, so we won't override anything
    die "Output directory $out_dir exitst!\nPlease remove and start again\n" 
	if (-d $out_dir);
    mkpath($out_dir) or die "can't create output directory: $!\n";

    # Create a new image
    my $img = gimp_image_new(150, 22, RGB);
    
    my $i;

    foreach ($bgcolor_i, $bgcolor_ii) {
	my $name = "workflow_";
	if ($i == 1) {
	    $name .= "workflow.";
	} else {
	    $name .= "admin.";
	}
	if ($gif == 1) {
	    $name .= "gif";
	} else {
	    $name .= "png";
	}

	print "generating $name\n";
	
	# Create a new layer for the background and add it to the image
	my $background = gimp_layer_new($img, 150, 22, RGB, "Background", 100,
					NORMAL_MODE);
	gimp_image_add_layer($img, $background, 1);
	
	# Fill the background layer
	gimp_palette_set_background($webbgcolor);
	gimp_edit_fill($background, BG_IMAGE_FILL);
	
	# select the background and fill it
	gimp_rect_select($img, 0, 8, 150, 22, 2, 0, 0);
	gimp_rect_select($img, 8, 0, 134, 8, 0, 0, 0);
	gimp_ellipse_select($img, 0, 0, 18, 18, 0, 1, 0, 0);
	gimp_ellipse_select($img, 132, 0, 18, 18, 0, 1, 0, 0);
	gimp_palette_set_background($_);
	gimp_edit_fill($background, BG_IMAGE_FILL);
	
	# Choose color of text
	gimp_palette_set_foreground($fgcolor);
	
	# Create the text layer. Using -1 as the drawable creates a new layer. 
	my $text_width = (gimp_text_get_extents_fontname($text, 12, 0, $font))[0];
	# correct width 
	$text_width = $text_width - 7;
	my $lborder = lborder($text_width, 150);
	$text_layer = gimp_text_fontname($img, -1, $lborder, 7, $text,
					 0, 1, 12, 0, $font);
	
	# merge visible layers
	my ($activelayer) = gimp_image_merge_visible_layers($img, 0);
	
	# save the image
	if ($gif == 1) {
	    file_gif_save(RUN_NONINTERACTIVE, $img, $activelayer,
			  "$out_dir/$name", "$out_dir/$name", 
			  0, 0, 0, 0);
	} else {
	    file_png_save(RUN_NONINTERACTIVE, $img, $activelayer,
			  "$out_dir/$name",
			  "$out_dir/$name", 
			  0, 9, 0, 0, 0, 0, 0);
	}
	
        # remove the layer from $img
	gimp_image_remove_layer($img, $activelayer);
	
	$i = 1;

    }
    return;
}
	

#############################################################################
register 
#############################################################################
    "bricolage_workflow_buttons", # fill in name 
    "Create the workflow buttons for bricolage",	# a small description 
    "Create the workflow buttons for bricolage", # a help text 
    "Florian Rossol",           # Your name 
    "Florian Rossol (c)",       # Your copyright 
    "2004-02-05",              	# Date 
    "<Toolbox>/Xtns/Perl-Fu/Bricolage-Workflow-Buttons", # menu path 
    "",                       	# Image types 
    [ 
     [PF_STRING, "text", "Text", "WORKFLOW"],
     [PF_FONT,	"font",		"Schrift",	
      "-microsoft-verdana-bold-r-normal-*-10-*-*-*-*-*-*-*"],
     [PF_COLOR,	"backgroundcolor_i", "Background Color I", "#999966"],
     [PF_COLOR,	"backgroundcolor_ii", "Background Color II", "#669999"],
     [PF_COLOR,	"textcolor", 	"Text Color",	"#FFFFFF"],
     [PF_COLOR,	"website_backgroundcolor", "Background Color of Website", 
      "#FFFFFF"],
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

