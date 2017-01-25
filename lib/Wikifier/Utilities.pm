# Copyright (c) 2014, Mitchell Cooper
#
# Wikifier::Utilities provides several functions used throughout the Wikifier.
# It exports any of the functions as needed.
package Wikifier::Utilities;

use warnings;
use strict;
use 5.010;

use Scalar::Util qw(blessed);

sub import {
    my $package = caller;
    no strict 'refs';
    *{$package.'::'.$_} = *{__PACKAGE__.'::'.$_} foreach @_[1..$#_];
}

#################
### UTILITIES ###
#################

# Increase indention level by $times indents.
sub indent_str {
    my ($string, $times) = (shift, shift || 1);
    my $space = '    ' x $times;
    my $final_string = '';
    foreach my $line (split "\n", $string) {
        $final_string .= "$space$line\n";
    }
    return $final_string;
}

# 'Some Article' -> 'Some_Article.page'
sub page_name {
    my ($page_name, $ext) = @_;
    return $page_name->name if blessed $page_name;

    # replace non-alphanumerics with _ and lowercase.
    $page_name =~ s/[^\w\.]/_/g;
    $page_name = lc $page_name;

    # append .page if it isn't already there.
    if ($page_name !~ m/\.(page|conf|model)$/) {
        $ext //= '.page';
        $page_name .= $ext;
    }

    return $page_name;
}

# 'Some_Article.page' -> 'Some_Article'
sub page_name_ne {
    my $page_name = page_name(shift, '');
    $page_name =~ s/\.(page|conf|model)$//;
    return $page_name;
}

# two page names equal?
sub page_names_equal {
    my ($page_name_1, $page_name_2, $ext) = @_;
    return page_name($page_name_1, $ext) eq page_name($page_name_2, $ext);
}

# removes leading and trailing whitespace from a string.
sub trim {
    my $string = shift;
    $string =~ s/^\s*//g;     # remove leading whitespace.
    $string =~ s/\s*$//g;     # remove trailing whitespace.
    return $string;
}

### LOGGING

our $indent = 0;

sub indent () { $indent++ }
sub back   () { $indent-- }

# log.
sub L {
    my @lines = @_;
    foreach my $str (@lines) {
        if (ref $str eq 'CODE') {
            indent;
            $str->();
            back;
            next;
        }
        chomp $str;
        say(('    ' x $indent).$str);
    }
}

# log and then indent.
sub Lindent($) {
    L(shift);
    indent;
}

# go back and then log.
sub Lback($) {
    back;
    L(shift);
}

sub align {
    my ($action, $info) = @_;
    return sprintf '%-10s%s', $action, $info // '';
}

sub notice {
    my ($type, %opts) = @_;
    my $noti = { %opts, type => $type };
    foreach my $sess (values %Wikifier::Server::sessions) {
        # TODO: make it possible to subscribe to specific types of notifications
        push @{ $sess->{notifications} }, $noti;
    }
}

1
