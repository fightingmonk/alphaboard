#!/usr/bin/perl

use Net::WebSocket::Server;

$QUEUE_FILENAME = '/tmp/lightboard-queue';

open(FH, ">", $QUEUE_FILENAME);
close(FH);

Net::WebSocket::Server->new(
	listen => 8089,
	on_connect => sub {
		my ($serv, $conn) = @_;
	$addr = $conn->ip();
		$conn->on(
		ready => sub {
		my ($conn) = @_;
		$conn->send_utf8("HALO");
		},
			utf8 => sub {
				my ($conn, $msg) = @_;
				$conn->send_utf8($msg);
			},
		);
	},
	tick_period => 1,
	on_tick => sub {
		my ($serv) = @_;
	
		open(FH, "<", $QUEUE_FILENAME);
		$message = <FH>;
		close(FH);

		if ($message ne "") {
			truncate $QUEUE_FILENAME, 0;
			$_->send_utf8($message) for $serv->connections;
		}
	},
)->start;
