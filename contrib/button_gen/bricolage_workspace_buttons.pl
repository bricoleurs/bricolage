#!/usr/bin/perl

#
# Copyright (c) 2004, Florian Rossol (rossol@yola.in-berlin.de)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#  * Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  * Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
#  * Neither the authors name nor the names of the contributors may be
#    used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

use File::Path;
use Gimp ":auto"; 
use Gimp::Fu; 

sub bric_buttons { 
    #Gimp::set_trace(TRACE_ALL);
   
    my($text, $font, $bgcolor_i, $shadow_i, $bgcolor_ii, $shadow_ii, 
       $star_color, $fgcolor, $webbgcolor, $out_dir, $gif) = @_;
    
    chomp($text);

    # Die if output directory exists, so we won't override anything
    die "Output directory $out_dir exitst!\nPlease remove and start again\n" 
    if (-d $out_dir);
    mkpath($out_dir) or die "can't create output directory: $!\n";

    # Create a new image
    my $img = gimp_image_new(150, 20, RGB);

    foreach (1, 2) {

    my $name = "my_workspace_";
    if ($_ == 1) {
        $name .= "on";
    } elsif ($_ == 2) {
        $name .= "off";
    }
    if ($gif == 1) {
        $name .= ".gif";
    } else {
        $name .= ".png";
    }
    print "generating $name\n";
    
    # Create a new layer for the background and add it to the image
    my $background = gimp_layer_new($img, 150, 20, RGB, "Background", 100,
                    NORMAL_MODE);
    gimp_image_add_layer($img, $background, 1);

    # Fill the background layer
    gimp_palette_set_background($webbgcolor);
    gimp_edit_fill($background, BG_IMAGE_FILL);
    
    if ($_ == 1) {
            # select the shadow and fill it
        gimp_rect_select($img, 1, 1, 149, 19, 2, 0, 0);
        gimp_palette_set_background($shadow_i);
        gimp_edit_fill($background, BG_IMAGE_FILL);
        
        # select the background and fill it
        gimp_rect_select($img, 0, 0, 148, 18, 2, 0, 0);
        gimp_palette_set_background($bgcolor_i);
        gimp_edit_fill($background, BG_IMAGE_FILL);
    } elsif ($_ == 2) {
        gimp_palette_set_background($bgcolor_ii);
        gimp_edit_fill($background, BG_IMAGE_FILL);

        gimp_rect_select($img, 1, 18, 150, 20, 2, 0, 0);
        gimp_rect_select($img, 149, 1, 150, 20, 0, 0, 0);
        gimp_palette_set_background($shadow_ii);
        gimp_edit_fill($background, BG_IMAGE_FILL);

        # make the star
        gimp_free_select($img, 10, 
                 [10, 3, 12, 6, 16, 7, 13, 10, 14, 13, 10, 12, 6,
                      13, 7, 10, 4, 7, 8, 6],
                 2, 1, 0, 0);
        gimp_palette_set_background($star_color);
        gimp_edit_fill($background, BG_IMAGE_FILL);
        
    }
    # Choose color of text
    gimp_palette_set_foreground($fgcolor);
    
    # Create the text layer. Using -1 as the drawable creates a new layer. 
    $text_layer = gimp_text_fontname($img, -1, 20, 6, $text,
                     0, 1, 10, 0, $font);
    
    # merge visible layers
    my ($activelayer) = gimp_image_merge_visible_layers($img, 0);
    
    # save the image
    if ($gif == 1) {
        gimp_convert_indexed($img, 0, 0, 100, 0, 0, 0);
        file_gif_save(RUN_NONINTERACTIVE, $img, $activelayer,
              "$out_dir/$name", "$out_dir/$name", 
              0, 0, 0, 0);
        gimp_convert_rgb($img);
    } else {
        file_png_save(RUN_NONINTERACTIVE, $img, $activelayer,
              "$out_dir/$name", "$out_dir/$name", 
              0, 9, 0, 0, 0, 0, 0);
    }

    # remove the layer from $img
    gimp_image_remove_layer($img, $activelayer);

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
    "2004-02-05",                  # Date 
    "<Toolbox>/Xtns/Perl-Fu/Bricolage-Workspace-Buttons",    # menu path 
    "",                           # Image types 
    [ 
     [PF_STRING, "text", "Text", "MY WORKSPACE"],
     [PF_FONT, "font", "Schrift",    
    "-microsoft-verdana-bold-r-normal-*-10-*-*-*-*-*-*-*"],
     [PF_COLOR,    "backgroundcolor_i", "Background Color I", "#d7840f"],
     [PF_COLOR,    "shadow_i", "Shadow I", "#938654"],
      [PF_COLOR, "backgroundcolor_ii", "Background Color II", "#cccc99"],
     [PF_COLOR,    "shadow_ii", "Shadow II", "#999966"],
     [PF_COLOR,    "star_color", "Color of the star", "#cc9a03"],
     [PF_COLOR,    "textcolor", "Text Color", "#000000"],
     [PF_COLOR, "website_backgroundcolor", "Background Color of Website",
      "#FFFFFF"],
     [PF_FILE, "output_directory", "Output Directory"],
     [PF_TOGGLE, "gif_or_png", "Safe as GIF or PNG", 1],
    ], # Eingabe Parameter
    \&bric_buttons; 
   
exit main();


