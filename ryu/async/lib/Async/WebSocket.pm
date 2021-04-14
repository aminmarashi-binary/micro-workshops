# Courtesy of https://metacpan.org/author/TEAM
package Async::WebSocket;

use strict;
use warnings;
no indirect;

use parent qw(IO::Async::Notifier);

=head1 NAME

Async::WebSocket

=head1 DESCRIPTION

A WebSocket client

=cut

use IO::Async::SSL;
use URI;
use URI::wss;
use URI::QueryParam;

use Net::Async::WebSocket::Client 0.12;
use Protocol::WebSocket::Frame;

use IO::Socket::SSL qw(SSL_VERIFY_NONE);

use Log::Any qw($log);

use curry::weak;

=head1 METHODS - Accessors

=head2 scheme

The target scheme for the endpoint. Defaults to wss.

=cut

sub scheme { shift->{scheme} //= 'wss' }

=head2 host

Returns the endpoint name.

=cut

sub host { shift->{host} }

=head2 port

The target port for the endpoint. Defaults to HTTPS (443).

=cut

sub port { shift->{port} //= 443 }

=head2 api_version

Returns the API version, currently always C<v3>.

=cut

sub api_version { 'v3' }

=head2 app_id

Application ID, see L<https://developers.binary.com/applications/>.

=cut

sub app_id { shift->{app_id} }

=head2 lang

Language, default is C<en>.

=cut

sub lang { shift->{lang} //= 'EN' }

=head2 base_uri

Returns the L<URI> instance for the endpoint, not including query parameters
such as C<app_id> or language.

=cut

sub base_uri {
    my ($self) = @_;
    $self->{base_uri} //= do {
        my $u = URI->new($self->scheme . '://' . $self->host . '/websockets/' . $self->api_version);
        $u->port($self->port);
        $u;
    }
}

=head2 http_headers

The HTTP headers to set on the connection

=cut

sub http_headers { shift->{http_headers} //= [] }

=head2 uri

Returns the full L<URI> including C<app_id> and language.

=cut

sub uri {
    my ($self) = @_;
    $self->{uri} //= do {
        my $uri = $self->base_uri->clone;
        $uri->query_param(l      => uc($self->lang));
        $uri->query_param(app_id => $self->app_id) if $self->app_id;
        $uri;
    }
}

=head2 configure

Expects any combination of the following named parameters:

=over 4

=item * C<host> - the endpoint hostname

=item * C<on_frame> - the callback which expects to receive frame data

=back

=cut

sub configure {
    my ($self, %args) = @_;
    for my $k (qw(host port uri base_uri on_frame on_close_frame app_id scheme lang http_headers)) {
        $self->{$k} = delete $args{$k} if exists $args{$k};
    }
    $self->SUPER::configure(%args);
}

=head2 on_frame

Called whenever we have a new frame.

=cut

sub on_frame {
    my ($self, $ws, $framebuffer, $bytes) = @_;
    eval {
        if ($framebuffer->is_close) {
            my ($code, $reason) = unpack 'n1a*', $bytes;
            $reason = Encode::decode_utf8($reason);
            $log->tracef("<< Close frame: %d %s", $code, $reason);
            $self->{on_close_frame}($code, $reason);
        } elsif ($framebuffer->is_text) {
            $log->tracef("<< %s", Encode::decode_utf8($bytes));
            $self->{on_frame}($bytes);
        }
        1;
    } or do {
        $log->errorf("Error processing frame [%v02x]: %s", $bytes, $@);
    }
}

=head2 connected

Will resolve once the connection is established.

=cut

sub connected { $_[0]->{connected} //= $_[0]->loop->new_future }

=head2 send

Sends data to the endpoint. Expects bytes, returns a L<Future>.

=cut

sub send {
    my ($self, $msg) = @_;
    warn "invalid message - should not be a ref" if ref $msg;
    $log->tracef(">> %s", $msg);
    utf8::upgrade($msg);
    $self->ws->send_frame(
        type   => 'text',
        buffer => $msg,
        masked => 1,
    );
}

=head2 connect

Attempts to connect, returns a L<Future> which resolves when done.

=cut

sub connect {
    my ($self) = @_;
    my $client = $self->ws;
    # Now we set up the URI and make the initial connection
    my $uri = $self->uri;

    $log->debugf("Connecting to %s", "$uri");
    $self->{connection} = $client->connect(
        url => "$uri",
        (
            $uri->scheme eq 'wss'
            ? (
                SSL_hostname    => $uri->host,
                SSL_verify_mode => SSL_VERIFY_NONE,
                )
            : ()
        ),
        req => Protocol::WebSocket::Request->new(
            headers => $self->http_headers,
        ),
    )->then(
        sub {
            $log->debugf("Connected to %s", "$uri");
            $self->connected->done;
        })->on_fail(sub { $log->errorf("Failed to connect to %s - %s", $uri, shift) })->retain;
}

sub ws { shift->{ws} }

sub _add_to_loop {
    my ($self) = @_;

    $self->add_child(
        $self->{ws} = Net::Async::WebSocket::Client->new(
            on_raw_frame => $self->curry::weak::on_frame,
        ));
    # $self->{ws} is just a convenience accessor for the websocket child
    Scalar::Util::weaken($self->{ws});
    $self->connect;
}

sub _remove_from_loop {
    my ($self) = @_;
    $log->debug("Removing from loop");
    # Shut down gracefully
    my $client = $self->ws;
    $client->send_frame(type => $Protocol::WebSocket::Frame::TYPES{close})->then(sub { $client->close_now })->retain;
}

1;
