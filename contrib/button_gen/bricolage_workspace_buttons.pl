#!/usr/bin/perl

#
# bric_workspace_buttons.pl
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

sub bric_buttons { 
    #Gimp::set_trace(TRACE_ALL);
   
    my($text, $font, $bgcolor, $shadow, $fgcolor, $webbgcolor, 
       $out_dir, $gif) = @_;
    
    chomp($text);

    # Die if output directory exists, so we won't override anything
    die "Output directory $out_dir exitst!\nPlease remove and start again\n" 
	if (-d $out_dir);
    mkpath($out_dir) or die "can't create output directory: $!\n";

    # Create a new image
    my $img = gimp_image_new(150, 20, RGB);

    print "generating my_workspace_on.";
    if ($gif == 1) {
	print ".gif\n";
    } else {
	print ".png\n";
    }
    
    # Create a new layer for the background and add it to the image
    my $background = gimp_layer_new($img, 150, 20, RGB, "Background", 100,
					    NORMAL_MODE);
    gimp_image_add_layer($img, $background, 1);
	    
    # Fill the background layer
    gimp_palette_set_background($webbgcolor);
    gimp_edit_fill($background, BG_IMAGE_FILL);
    
    # select the shadow and fill it
    gimp_rect_select($img, 1, 1, 149, 19, 2, 0, 0);
    gimp_palette_set_background($shadow);
    gimp_edit_fill($background, BG_IMAGE_FILL);

    # select the background and fill it
    gimp_rect_select($img, 0, 0, 148, 18, 2, 0, 0);
    gimp_palette_set_background($bgcolor);
    gimp_edit_fill($background, BG_IMAGE_FILL);

    # Choose color of text
    gimp_palette_set_foreground($fgcolor);
	    
    # Create the text layer. Using -1 as the drawable creates a new layer. 
    $text_layer = gimp_text_fontname($img, -1, 20, 6, $text,
					 0, 1, 10, 0, $font);
    
    # merge visible layers
    my ($activelayer) = gimp_image_merge_visible_layers($img, 0);
    
    # save the image
    if ($gif == 1) {
	file_gif_save(RUN_NONINTERACTIVE, $img, $activelayer,
		      "$out_dir/$_/$name.gif", "$out_dir/$_/$name.gif", 
		      0, 0, 0, 0);
    } else {
	file_png_save(RUN_NONINTERACTIVE, $img, $activelayer,
		      "$out_dir/my_workspace_on.png", "$out_dir/my_workspace_on.png", 
		      0, 9, 0, 0, 0, 0, 0);
    }
    
    return;
}
	

#############################################################################
register 
#############################################################################
    "bricolage_workspace_button",        # fill in name 
    "Create the workspace button for bricolage", # a small description 
    "Create the workspace button for bricolage", # a help text 
    "Florian Rossol",           # Your name 
    "Florian Rossol (c)",       # Your copyright 
    "2004-02-05",              	# Date 
    "<Toolbox>/Xtns/Perl-Fu/Bricolage-Workspace-Buttons",	# menu path 
    "",                       	# Image types 
    [ 
     [PF_STRING, "text", "Text", "MY WORKSPACE"],
     [PF_FONT, "font", "Schrift",	
	"-microsoft-verdana-bold-r-normal-*-10-*-*-*-*-*-*-*"],
     [PF_COLOR,	"backgroundcolor", "Background Color", "#d7840f"],
     [PF_COLOR,	"shadow", "Shadow", "#938654"],
     [PF_COLOR,	"textcolor", "Text Color", "#000000"],
     [PF_COLOR, "website_backgroundcolor", "Background Color of Website",
      "#FFFFFF"],
     [PF_FILE, "output_directory", "Output Directory"],
     [PF_TOGGLE, "gif_or_png", "Safe as GIF or PNG", 1],
    ], # Eingabe Parameter
    \&bric_buttons; 
   
exit main();


