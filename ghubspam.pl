# == WHAT
# Show the latest commit for a GitHub repository.
#
# == WHO
# Jan Moesen, 2012
#
# == INSTALL
# Save it in ~/.irssi/scripts/ and do /script load ghubspam.pl
# OR
# Save it in ~/.irssi/scripts/autorun and (re)start Irssi.

use strict;
use Irssi;
use JSON::XS;
use LWP::Simple;
use vars qw($VERSION %IRSSI);

$VERSION = '0.1';
%IRSSI = (
	authors     => 'Jan Moesen',
	name        => 'Ghubspam',
	description => 'Show the latest commit for a GitHub repository.',
	license     => 'GPL',
	url         => 'http://jan.moesen.nu/',
);

sub ghubspam_process_message {
	my ($server, $msg, $target) = @_;

	return unless $target =~ /^#(wijs|catena|lolwut)/;
	return unless $msg =~ m/https:\/\/github\.com\/([^\/]+)\/([^\/]+)(?:\/commit\/([^\/]+))?/;

	my $user = $1;
	my $repo = $2;
	my $treeish = $3;
	my $json_url = "https://api.github.com/repos/$user/$repo";
	my $json = get($json_url);
	return unless $json;
	my $summary = decode_json($json);
	my $message = "Repository: \"$summary->{name}: $summary->{description}\"";
	$server->command("msg $target $message");

	my $json_url = $treeish
		? "https://api.github.com/repos/$user/$repo/commits/$treeish"
		: "https://api.github.com/repos/$user/$repo/commits/HEAD";
	my $json = get($json_url);
	return unless $json;
	my $commit = decode_json($json);
	my $message_start = $treeish
		? "Commit " . substr($commit->{sha}, 0, 7)
		: "Latest commit";
	my $message = "$message_start: \"$commit->{commit}->{message}\" by $commit->{commit}->{author}->{name}";
	$server->command("msg $target $message");
}

Irssi::signal_add_last('message public', sub {
	my ($server, $msg, $nick, $mask, $target) = @_;
	Irssi::signal_continue($server, $msg, $nick, $mask, $target);
	ghubspam_process_message($server, $msg, $target);
});
Irssi::signal_add_last('message own_public', sub {
	my ($server, $msg, $target) = @_;
	Irssi::signal_continue($server, $msg, $target);
	ghubspam_process_message($server, $msg, $target);
});
