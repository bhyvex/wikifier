#!/usr/bin/perl
# Copyright (c) 2014, Mitchell Cooper
#
# sections are containers for paragraphs, image boxes, etc., each with a title.
#
package Wikifier::Block::Section;

use warnings;
use strict;

use Scalar::Util 'blessed';

our %block_types = (
    section => {
        base  => 'container',
        parse => \&section_parse,
        html  => \&section_html,
        alias => 'sec'
    },
    clear => {
        html => \&clear_html
    }
);

# this counts how many sections there are.
# this is then compared in section_html to see if it's the last section.
# if it is and last_section_footer is enabled, the </div> is omitted
# in order to leave room for a footer.
sub section_parse {
    my ($block, $page) = @_;

    $page->{c_section_n} = -1 if not defined $page->{section_n};
    $page->{section_n}   = -1 if not defined $page->{section_n};

    $page->{section_n}++;

    print 'parse section '.$page->{section_n},"\n";
}

sub section_html {
    my ($block, $page) = (shift, @_);
    my $string = "<div class=\"wiki-section\">\n";
    $page->{c_section_n}++;
    print 'html section '.$page->{c_section_n},"\n";
    
    # determine if this is the intro section.
    my $is_intro = !$page->{c_section_n};
    my $class    = $is_intro ? 'wiki-section-page-title' : 'wiki-section-title';
    
    # determine the page title.
    my $title    = $block->{name};
       $title    = $page->get('page.title') if $is_intro && !length $title;
    
    # if we have a title, and this type of title is enabled.
    if (length $title and !($is_intro && $page->wiki_info('no_page_title'))) {
        $string .= "    <h1 class=\"wiki-section-page-title\">$title</h1>\n";
    }
   
    # append the indented HTML of each contained block.
    foreach my $item (@{$block->{content}}) {
        next unless blessed $item;
        $string .= Wikifier::Utilities::indent($item->html(@_))."\n";
    }
    
    # end the section.
    $string .= "    <div class=\"clear\"></div>\n";
    
    # disabled </div>.
    print "checking if disabled: C($$page{c_section_n} S($$page{section_n})\n";
    print "yes\n" and return $string if
        $page->wiki_info('enable.last_section_footer') &&
        $page->{c_section_n} == $page->{section_n};
    
    $string .= "</div>\n";
    
    return $string;
    
}

sub clear_html {
    return '<div class="clear"></div>';
}

__PACKAGE__
