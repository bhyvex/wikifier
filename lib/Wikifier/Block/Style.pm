#
# Copyright (c) 2014, Mitchell Cooper
#
package Wikifier::Block::Style;

use warnings;
use strict;

use Scalar::Util 'blessed';

our %block_types = (style => {
    base   => 'hash',
    parse  => \&style_parse,
    html   => \&style_html
});

sub style_parse {
    my ($block, $page) = (shift, @_);
    
    # parse the hash.
    $block->parse_base(@_);
    
    my %style = (
        apply_to => [],
        rules    => $block->{hash}
    );
    
    # if the block has a name, it applies to child class(es).
    if (length $block->{name}) {
        my @matchers = split ',', $block->{name};
        foreach my $matcher (@matchers) {
            $matcher =~ s/^\s*//g;
            $matcher =~ s/\s*$//g;
            
            # all children.
            if ($matcher eq '*') {
                $style{apply_to_all_children}++;
                next;
            }
            
            # this element.
            if ($matcher eq 'this') {
                $style{apply_to_main}++;
                next;
            }
            
            # element type or class, etc.
            # ex: p
            # ex: p.something
            # ex: .something.somethingelse
            push @{ $style{apply_to} }, [ split /\s/, $matcher ];
            
        }
    }
    
    # the block has no name. it applies to the parent element only.
    else {
        $style{apply_to_main}++;
    }
    
    $block->{style} = \%style;
}

sub style_html {
    my ($block, $page, $el) = (shift, @_);
    my %style   = %{ $block->{style} };
    my $main_el = $block->{parent}{element};
    my @apply;
    
    # if we're applying to main, add that.
    push @apply, [ $main_el->{id} ] if $style{apply_to_main};
    
    # add other things, if any.
    foreach my $item (@{ $style{apply_to} }) {
        unshift @$item, $main_el->{id};
        push @apply, $item;
    }
    
    $style{main_el}  = $main_el->{id};
    $style{apply_to} = \@apply;
    
    use Data::Dumper;
    print Dumper \%style;
    
    push @{ $page->{styles} ||= [] }, \%style;
}

__PACKAGE__