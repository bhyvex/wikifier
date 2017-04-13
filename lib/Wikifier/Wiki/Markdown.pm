# Copyright (c) 2017, Mitchell Cooper
package Wikifier::Wiki;

use warnings;
use strict;
use 5.010;

use Wikifier::Utilities qw(L Lindent back align);
use CommonMark qw(:node :event :list);
use Cwd qw(abs_path);

# all markdown files
sub all_markdowns {
    my $wiki = shift;
    my $dir = $wiki->opt('dir.md');
    return if !length $dir;
    return unique_files_in_dir($dir, 'md');
}

sub convert_markdown {
    my ($wiki, $md_name) = (shift, @_);
    Lindent "($md_name)";
    my $result = $wiki->_convert_markdown(@_);
    L align('Error', $result->{error}) if $result->{error};
    back;
    return $result;
}

sub _convert_markdown {
    my ($wiki, $md_name, %opts) = @_;
    my $md_path   = abs_path($wiki->opt('dir.md')."/$md_name");
    my $page_path = $wiki->path_for_page($md_name);
    
    # no such markdown file
    return display_error('Markdown file does not exist.')
        if !-f $md_path;
        
    # filename and path info
    my $result = {};
    $result->{file} = $md_name;         # with extension
    $result->{name} = (my $md_name_ne = $md_name) =~ s/\.md$//; # without
    $result->{path} = $page_path;       # absolute path
    
    # page content
    $result->{type} = 'markdown';
    $result->{mime} = 'text/plain'; # wikifier language
    
    # slurp the markdown file
    my $md_text = file_contents($md_path);
    
    # generate the wiki source
    my $source = $wiki->generate_from_markdown($md_text, %opts);
    $result->{content} = $source;
    
    # write to file
    open my $fh, '>', $page_path
        or return display_error('Unable to write page file.');
    print $fh $source;
    close $fh;
    
    return $result;
}

# NODE_NONE
# NODE_DOCUMENT
# NODE_BLOCK_QUOTE
# NODE_LIST
# NODE_ITEM
# NODE_CODE_BLOCK
# NODE_HTML
# NODE_PARAGRAPH
# NODE_HEADER
# NODE_HRULE
# NODE_TEXT
# NODE_SOFTBREAK
# NODE_LINEBREAK
# NODE_CODE
# NODE_INLINE_HTML
# NODE_EMPH
# NODE_STRONG
# NODE_LINK
# NODE_IMAGE
# NODE_CUSTOM_BLOCK
# NODE_CUSTOM_INLINE
# NODE_HTML_BLOCK
# NODE_HEADING
# NODE_THEMATIC_BREAK
# NODE_HTML_INLINE

sub generate_from_markdown {
    my ($wiki, $md_text, %opts) = @_;
    my $indent = 0;
    
    # parse the markdown file
    my $doc = CommonMark->parse(string => $md_text);
    
    # iterate through nodes
    my $iter = $doc->iterator;
    while (my ($ev_type, $node) = $iter->next) {
        my $node_type = $node->get_type;
        print "E $ev_type N $node_type\n";
    }
    
    return '';
}

1
