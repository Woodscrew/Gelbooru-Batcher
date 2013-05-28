#!/usr/bin/env perl

use LWP::Simple;
use Getopt::Long;
use File::Spec;
use File::Basename;
use XML::LibXML;

# Variables
my $api_url = 'http://gelbooru.com/index.php?page=dapi&s=post&q=index&pid=%s&tags=%s';
my $current_page = 0;
my $parser = XML::LibXML->new();

# Defaults
my $tags = '';
my $directory = '.';
my $help = 0;

# Parse opts
GetOptions(
	'tags=s' => \$tags,
	'dir=s' => \$directory,
	'help' => \$help
);

$directory = File::Spec->rel2abs($directory) ."/";


# Check input
if($help eq 1) {
	print <<EOF;
Usage: gelboorubatch [options]
Available options:
	--tags=\"<tags>\"
	--dir=\"<directory>\" (defaults to current)
EOF
	exit;
}

die "Missing tags, try --help for more information" if $tags eq '';

while(1) {
	my $response = get(sprintf($api_url, $current_page, $tags));
	my $xml = $parser->parse_string($response);
	my @posts = $xml->findnodes('/posts/post');
	
	last if scalar @posts eq 0; # Break on empty result

	for my $post (@posts) {
		my $file_url = $post->getAttribute('file_url');
		my $file_name = basename($file_url);

		print "$file_name \t";
		my $status = getstore($file_url, $directory . $file_name);

		if(is_success($status)) {
			print "[DONE]\n";
		} else {
			print "[FAILED]\n";
		}
	}

	$current_page++;
}