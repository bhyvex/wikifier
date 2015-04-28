#
# Copyright (c) 2014, Mitchell Cooper
#
# Version control methods for WiWiki.
#
package Wikifier::Wiki;

use warnings;
use strict;

sub write_page {
    my ($wiki, $page, $reason) = @_;

    # write the file
    open my $fh, '+>', $page->path or return;
    print {$fh} $page->{content};
    close $fh;
    
    # commit the change
    rev_commit(
        message => defined $reason ? "Updated $$page{name}: $reason" : "Created $$page{name}",
        affects => [ $page->path ]
    );
    
    # update the page
    $wiki->display_page($page);
    
    return 1;
}

####################################
### LOW-LEVEL REVISION FUNCTIONS ###
####################################

# commit a revision
sub rev_commit (@) {
    
}

# convert objects to file paths.
sub _filify {
    my @objects_and_files = @_;
    my @paths;
    foreach my $thing (@objects_and_files) {
        my $path = $thing;
        $path = _path($thing) if blessed $thing;
        push @paths, $path;
    }
    return @paths;
}

sub _path {
    my $thing = shift;
    return $thing->path;
}

1
