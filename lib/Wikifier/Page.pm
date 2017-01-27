#
# Copyright (c) 2014, Mitchell Cooper
#
# Wikifier::Page provides an objective interface to a wiki page or article. It implements
# the very user-friendly programming interface of the Wikifier.
#
package Wikifier::Page;

use warnings;
use strict;
use Scalar::Util qw(blessed);
use File::Basename qw(basename);
use Cwd qw(abs_path);
use Wikifier::Utilities qw(page_name align L);

# default options.
our %wiki_defaults = (
    'name'                  => 'Wiki',
    'dir.wikifier'          => '.',
    'dir.image'             => 'images',
    'dir.page'              => 'pages',
    'dir.cache'             => 'cache',
    'dir.model'             => 'models',
    'dir.category'          => 'categories',
    'dir.m_category'        => 'model-categories',
    'root.image'            => '/images',   # relative to HTTP root.
    'root.category'         => '/topic',
    'root.page'             => '',          # AKA "/"
    'root.wiki'             => '',          # AKA "/"
    'image.size_method'     => 'javascript',
    'page.enable.titles'    => 1,
    'external.name'         => 'Wikipedia',
    'external.root'         => 'http://en.wikipedia.org/wiki',
    'image.rounding'        => 'normal',
    'image.calc'            => \&_default_calculator,
    'image.sizer'           => \&_default_sizer,
    'var'                   => {}
);

# create a new page.
sub new {
    my ($class, %opts) = @_;
    $opts{references} ||= [];
    $opts{content}    ||= [];
    $opts{variables}  ||= {};

    # no wikifier given, create a new one.
    $opts{wikifier} ||= Wikifier->new();
    my $wikifier = $opts{wikifier};

    # if file_path is provided, we can use it for the page name
    if (length $opts{file_path} && !length $opts{name}) {
        $opts{name} = basename($opts{file_path});
    }

    # create the page.
    my $page = bless \%opts, $class;
    $page->{name} = page_name($page->{name});

    # create the page's main block.
    $page->{main_block} = $wikifier->{main_block} = $wikifier->create_block(
        wdir   => $page->wiki_opt('dir.wikifier'),
        type   => 'main',
        parent => undef     # main block has no parent.
    );

    return $page;
}

# parses the file.
sub parse {
    my $page = shift;
    my $err;
    L align('Parse'), sub {
        $err = $page->wikifier->parse($page, $page->path);
    };
    L align('Error', $err) if $err;
    return $err;
}

# returns the generated page HTML.
sub html {
    my $page = shift;
    my $res;
    L('HTML', sub {
        $page->{wikifier}{main_block}->html($page);
    });
    L('Generate', sub {
        $res = $page->{wikifier}{main_block}{element}->generate;
    });
    return $res;
}

# returns the generated page CSS.
sub css {
    my $page = shift;
    return unless $page->{styles};
    my $string = '';
    foreach my $rule_set (@{ $page->{styles} }) {
        my $apply_to = $page->_css_apply_string(@{ $rule_set->{apply_to} });
        $string     .= "$apply_to {\n";
        foreach my $rule (keys %{ $rule_set->{rules} }) {
            my $value = $rule_set->{rules}{$rule};
            $string  .= "    $rule: $value;\n";
        }
        $string .= "}\n";
    }
    return $string;
}

sub _css_apply_string {
    my ($page, @sets) = @_;
    # @sets = an array of [
    #   ['section'],
    #   ['.someClass'],
    #   ['section', '.someClass'],
    #   ['section', '.someClass.someOther']
    # ] etc.
    return join ",\n", map {
        my $string = $page->_css_set_string(@$_);
        my $start  = substr $string, 0, 10;
        if (!$start || $start ne '.wiki-main') {
            my $id  = $page->{wikifier}{main_block}{element}{id};
            $string = ".wiki-$id $string";
        }
        $string
    } @sets;
}

sub _css_set_string {
    my ($page, @items) = @_;
    return join ' ', map { $page->_css_item_string(split //, $_) } @items;
}

sub _css_item_string {
    my ($page, @chars) = @_;
    my ($string, $in_class, $in_el_type) = '';
    foreach my $char (@chars) {

        # we're starting a class.
        if ($char eq '.') {
            $in_class++;
            $string .= '.wiki-class-';
            next;
        }

        # we're in neither a class nor an element type.
        # assume that this is the start of element type.
        if (!$in_class && !$in_el_type && $char ne '*') {
            $in_el_type = 1;
            $string .= '.wiki-';
        }

        $string .= $char;
    }
    return $string;
}

# set a variable.
sub set {
    my ($page, $var, $value) = @_;
    my ($hash, $name) = _get_hash($page->{variables}, $var);
    $hash->{$name} = $value;
}

# fetch a variable.
sub get {
    my ($page, $var)  = @_;

    # try page variables.
    my ($hash, $name) = _get_hash($page->{variables}, $var);
    return $hash->{$name} if defined $hash->{$name};

    # try global variables.
    ($hash, $name) = _get_hash($page->{wiki}{variables}, $var);
    return $hash->{$name};

}

sub get_href {
    my $val = &get;
    return {} if ref $val ne 'HASH';
    return $val;
}

sub get_aref {
    my $val = &get;
    return [] if ref $val ne 'ARRAY';
    return $val;
}

# internal use only.
sub _get_hash {
    my ($hash, $var) = @_;
    my $i    = 0;
    my @parts = split /\./, $var;
    foreach my $part (@parts) {
        last if $i == $#parts;
        $hash->{$part} = {} if ref $hash->{$part} ne 'HASH';
        $hash = $hash->{$part};
        $i++;
    }
    return ($hash, $parts[-1]);
}

# returns HTML for formatting.
sub parse_formatted_text {
    my ($page, $text, $no_html_entities) = @_;
    return $page->wikifier->parse_formatted_text($page, $text, $no_html_entities);
}

# returns a wiki option or the default.
sub wiki_opt {
    my ($page, $var, @args) = @_;
    return $page->{wiki}->opt($var) if blessed $page->{wiki};
    return _call_wiki_opt($wiki_defaults{$var});
}

sub _call_wiki_opt {
    my ($val, @args) = @_;
    if (ref $val eq 'CODE') {
        return $val->(@args);
    }
    return $val;
}

# default image dimension calculator. requires Image::Size.
sub _default_calculator {
    my %img = @_;
    my ($width, $height) = ($img{width}, $img{height});

    # maybe these were found for us already.
    my ($big_w, $big_h) = ($img{big_width}, $img{big_height});

    # gotta do it the hard way.
    # use Image::Size to determine the dimensions.
    # note: these are provided by GD in WiWiki.
    if (!$big_w || !$big_h) {
        require Image::Size;
        my $dir = $img{page}->wiki_opt('dir.image');
        ($big_w, $big_h) = Image::Size::imgsize("$dir/$img{file}");
    }

    # neither dimensions were given. use the full size.
    if (!$width && !$height) {
        return ($big_w, $big_h, 1);
    }

    # now we must find the scaling factor.
    my $scale_factor;
    my ($final_w, $final_h);

    # width was given; calculate height.
    if ($width) {
        $scale_factor = $big_w / $width;
        $final_w = $img{width};
        $final_h = $img{page}->image_round($big_h / $scale_factor);
    }

    # height was given; calculate width.
    elsif ($height) {
        $scale_factor = $big_h / $height;
        $final_w = $img{page}->image_round($big_w / $scale_factor);
        $final_h = $img{height};
    }

    return ($final_w, $final_h);
}

sub _default_sizer {
    my %img = @_;
    my $page = $img{page};

    # full-sized image.
    if (!$img{width} || !$img{height}) {
        return $page->wiki_opt('root.image').'/'.$img{file};
    }

    # scaled image.
    return $page->wiki_opt('root.image')."/$img{width}x$img{height}-$img{file}";
}

# round dimension according to setting.
sub image_round {
    my ($page, $size) = @_;
    my $round = $page->wiki_opt('image.rounding');
    return int($size + 0.5 ) if $round eq 'normal';
    return int($size + 0.99) if $round eq 'up';
    return int($size       ) if $round eq 'down';
    return $size; # fallback.
}

sub cache_path {
    my $page = shift;
    return abs_path($page->{cache_path})
        if length $page->{cache_path};
    return abs_path($page->wiki_opt('dir.cache').'/'.$page->name.'.cache');
}

sub path {
    my $page = shift;
    return abs_path($page->{file_path})
        if length $page->{file_path};
    return abs_path($page->wiki_opt('dir.page').'/'.$page->name);
}

sub created_time {
    my $page = shift;
    my $page_data = $page->get_href('page');
    $page_data = {} if ref $page_data ne 'HASH';
    return $page_data->{created} || $page->{created};
}

sub modified_time {
    my $page = shift;
    return (stat $page->path)[9];
}

sub name {
    return shift->{name};
}

sub title {
    my $page = shift;
    return length $page->{title} ? $page->{title} : $page->name;
}

sub wikifier { shift->{wikifier} }

1
