#
# Copyright (c) 2014, Mitchell Cooper
#
# The main block is the only block which does not have a parent. There is only one
# instance of this type of block. It is an implied block containing all first-level
# blocks.
#
package Wikifier::Block::Main;

use warnings;
use strict;

use Scalar::Util 'blessed';
use Digest::MD5  'md5_hex';

our %block_types = (
    main => {
        parse => \&main_parse,
        html  => \&main_html
    }
);

sub main_parse {
    my $block = shift;

    # filter out blank items.
    $block->remove_blank;

    # produce warnings for stray text.
    foreach ($block->content_text_pos) {
        my ($text, $pos) = @$_;
        $block->warning($pos, "Stray text '$text' will be ignored");
    }

    return 1;
}

sub main_html {
    my ($block, $page, $el) = @_;

    # generate a better ID.
    $el->{id} = 'main-'.time.substr(md5_hex($page->path), 0, 5);

    foreach my $item ($block->content_blocks) {
        $el->add($item->html($page));
    }
}

__PACKAGE__
