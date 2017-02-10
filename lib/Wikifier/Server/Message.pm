# Copyright (c) 2017, Mitchell Cooper
package Wikifier::Server::Message;

use warnings;
use strict;
use 5.010;

# reply
sub reply {
    my ($msg, $reply_type, $href) = @_;
    my @args = ($reply_type => $href);
    push @args, $msg->{_reply_id} if defined $msg->{_reply_id};
    $msg->conn->send(@args);
}

sub error       { shift->conn->error(@_)  }
sub l           { shift->conn->l(@_)      }
sub conn        { shift->{conn}           }

1
