#
# Copyright (c) 2014, Mitchell Cooper
#
# Version control methods for WiWiki.
#
package Wikifier::Wiki;

use warnings;
use strict;
use Git::Wrapper;

sub write_page {
    my ($wiki, $page, $reason) = @_;

    # write the file
    open my $fh, '>', $page->path or return;
    print {$fh} $page->{content};
    close $fh;
    
    # update the page
    $wiki->display_page($page);
    
    # commit the change
    return $wiki->rev_commit(
        message => defined $reason ? "Updated $$page{name}: $reason" : "Updated $$page{name}",
        add     => [ $page->path ]
    );
    
}

sub delete_page {
    my ($wiki, $page) = @_;
    
    # delete the file as well as the cache
    unlink $page->cache_path; # may or may not exist
    
    # commit the change
    $wiki->rev_commit(
        message => "Deleted $$page{name}",
        rm      => [ $page->path, $page->cache_path ]
    );
    
    return 1;
}

sub move_page {
    my ($wiki, $page, $new_name) = @_;
    $new_name = Wikifier::Page::_page_filename($new_name);
    my ($old_name, $old_path) = ($page->name, $page->path);
    $page->{name} = $new_name;

    # consider: what if the destination page exists?
    
    # delete the old cache file
    unlink $page->cache_path; # may or may not exist
    
#    # move the file as well as the cache
#    # consider: should we just let git mv move it?
#    rename $old_path, $page->path or do {
#        $page->{name} = $old_name;
#        return;
#    };
    
    # commit the change
    $wiki->rev_commit(
        message => "Moved $old_name -> $new_name",
        mv      => { $old_path => $page->path }
    );
    
    # update the page
    $wiki->display_page($page);
    
    return 1;
}

####################################
### LOW-LEVEL REVISION FUNCTIONS ###
####################################

# returns a scalar reference error on fail.
# returns 1 on success.
my @op_errors;
sub capture_logs(&$) {
    my $ret = _capture_logs(@_);
    push @op_errors, $$ret if ref $ret;
    return $ret;
}
sub _capture_logs(&$) {
    my ($code, $command) = @_;
    eval { $code->() };
    if ($@ && ref $@ eq 'Git::Wrapper::Exception') {
        my $message = $command.' exited with code '.$@->status.'. ';
        $message .= $@->error.$/.$@->output;
        Wikifier::l($message);
        return \$message;
    }
    elsif ($@) {
        Wikifier::l('Unspecified git error');
        return \ 'Unknown error';
    }
    return 1;
}

# return the results of the operations
# clear the list of operation results
#
# if all operations were successful,
# this returns an empty list
#
sub _rev_operation_finish {
    my @ops = @op_errors;
    @op_errors = ();
    return @ops;
}

# get info about the latest revision (commit)
# returns a hash reference containing the following:
#
# id
# author
# date
# message
#
sub rev_latest {
    my $wiki = shift;
    my $git  = $wiki->_prepare_git();
    my @logs = $git->log;
    my $last = shift @logs or return;
    return {
        id            => $last->id,
        author        => $last->author,
        date          => $last->date,
        message       => $last->message
    };
}

# create a git object for this wiki if there isn't one
sub _prepare_git {
    my $wiki = shift;
    if (!$wiki->{git}) {
        my $dir = $wiki->opt('dir.wiki');
        if (!length $dir) {
            Wikifier::l('Cannot commit; @dir.wiki not set');
            return;
        }
        $wiki->{git} = Git::Wrapper->new($dir);
    }
    return $wiki->{git};
}

# commit a revision
# returns a list of errors or an empty list on success
sub rev_commit (@) {
    my $wiki = shift;
    $wiki->_prepare_git();
    unshift @_, $wiki->{git};
    return eval { &_rev_commit };
}

sub _rev_commit {
    my ($git, %opts) = @_;
    my ($rm, $add, $mv) = @opts{'rm', 'add', 'mv'};
    
    # rm operation
    if ($rm && ref $rm eq 'ARRAY') {
        capture_logs { $git->rm(@$rm) } 'git rm';
    }
    
    # add operation
    if ($add && ref $add eq 'ARRAY') {
        capture_logs { $git->add(@$add) } 'git add';
    }
    
    # mv operation
    if ($mv && ref $mv eq 'HASH') {
        foreach (keys %$mv) {
            capture_logs { $git->mv($_, $mv->{$_}) } 'git mv';
        }
    }
    
    # commit operations
    Wikifier::l("git commit: $opts{message}");
    capture_logs { $git->commit({ message => $opts{message} // 'Unspecified' }) } 'git commit';
    
    # return errors
    return _rev_operation_finish();
    
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
