/*
Copyright (c) 2003-2010, CKSource - Frederico Knabben. All rights reserved.
For licensing, see LICENSE.html or http://ckeditor.com/license
*/

CKEDITOR.editorConfig = function( config )
{
// Define changes to default configuration here. For example:
    config.language = 'en';
    contentsLanguage = 'en';
    config.uiColor = '#cccc99'; //'#AADC6E';
    config.skin = 'office2003';
    config.extraPlugins = 'autogrow';
    config.enableTabKeyTools = true;

    config.format_tags = 'p;h2;h3;pre';
    // Load from a list of definitions.
    config.stylesSet = [
        { name : 'Emphasis', element : 'em' }, 
        { name : 'Strong Emphasis', element : 'strong' },
        { name : 'Small', element : 'small' },
        { name : 'Big', element : 'big' }
			];
    config.fontSize_sizes = '100% Medium/100%;Smaller/89%;Very Small/75%';

config.toolbar =
[
 ['Source'],//'-','Save','NewPage','Preview','-','Templates'],
 ['Cut','Copy','Paste','PasteText','PasteFromWord'],//'-','Print'],// 'SpellChecker', 'Scayt'],
 ['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
 // ['Form', 'Checkbox', 'Radio', 'TextField', 'Textarea', 'Select', 'Button', 'ImageButton', 'HiddenField'],
 '/',
 ['Bold','Italic','Underline','Strike','-','Subscript','Superscript'],
 ['NumberedList','BulletedList','-','Outdent','Indent','Blockquote','CreateDiv'],
 ['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],
 // ['BidiLtr', 'BidiRtl' ],
 ['Link','Unlink','Anchor'],
 ['Image','Flash','Table','HorizontalRule','Smiley','SpecialChar','PageBreak'],
 '/',
 ['Styles','Format'],//,'FontSize'],//'Font',
 ['TextColor','BGColor'],
 ['Maximize', 'ShowBlocks','-']//'About']
 ];
};
