package Log::Dispatch::TiarraSocket;

use warnings;
use strict;

use Text::Xslate;
use IO::Socket::UNIX;

use Params::Validate qw/validate SCALAR BOOLEAN/; 

use Log::Dispatch::Output;
use base qw/Log::Dispatch::Output/;

Params::Validate::validation_options(allow_extra => 1);

=head1 NAME

Log::Dispatch::TiarraSocket - The great new Log::Dispatch::TiarraSocket!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Log::Dispatch;
    my $foo = Log::Dispatch->new(
		outputs => [
			[ 'TiarraSocket', socket_name => 'hoge', channel => '#fuga@piyo', use_notice => 0 ],
		],
	);
	$foo->alert("Hogeeee!");

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 new

constructor used by Log::Dispatch;

=cut

sub new {
	my $proto = shift;
	my $class = ref $proto || $proto;

	my %param = validate(@_, +{
		charset => +{
			type    => SCALAR,
			default => 'UTF-8',
		},
		socket_name => +{
			type => SCALAR,
		},
		channel => +{
			type => SCALAR,
		},
		sender => +{
			type    => SCALAR,
			default => "Log::Dispatch::TiarraSocket $VERSION",
		},
		use_notice => +{
			type    => BOOLEAN,
			default => 1,
		},
		send_interval => +{
			type    => SCALAR,
			default => 1.0,
		},
	});

	my $self = bless {}, $class;
	$self->_basic_init(%param);

	# option param setting
	for (qw/charset socket_name channel sender use_notice send_interval/) {
		$self->{"tiarra_${_}"} = $param{$_};
	}

	my %virtual_template_path = (
		'message.tx' => <<"MESSAGE",
NOTIFY System::SendMessage <:= \$protocol :>\r
Sender: <:= \$sender :>\r
Notice: <:= \$notice :>\r
Channel: <:= \$channel :>\r
Charset: <:= \$charset :>\r
Text: [<:= \$level :>] <:= \$text :>\r
\r
MESSAGE
	);
	$self->{xslate} = Text::Xslate->new(path => \%virtual_template_path);

	return $self;
}

=head2 log_message

log_message used by Log::Dispatch

=cut

sub log_message {
	my($self, %param) = @_;

	my $socket = IO::Socket::UNIX->new(
		Type => SOCK_STREAM,
		Peer => '/tmp/tiarra-control/' . $self->{tiarra_socket_name},
	) or die "Cannot open UNIX socket open";

	my $stash = +{
		protocol => "TIARRACONTROL/1.0",
		sender   => $self->{tiarra_sender},
		notice   => $self->{tiarra_use_notice},
		channel  => $self->{tiarra_channel},
		charset  => $self->{tiarra_charset},
		text     => $param{message},
		level    => $param{level},
	};

	my $message = $self->{xslate}->render('message.tx', $stash);
	$socket->print($message);
	
	$socket->close();
}

=head1 AUTHOR

bobpp, C<< <bobpp at bobpp.jp> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-log-dispatch-tiarrasocket at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Dispatch-TiarraSocket>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Dispatch::TiarraSocket


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Dispatch-TiarraSocket>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Dispatch-TiarraSocket>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Dispatch-TiarraSocket>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Dispatch-TiarraSocket/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 bobpp.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Log::Dispatch::TiarraSocket
