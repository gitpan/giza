#!/usr/bin/perl

use Crypt::CBCeasy;
my $key = 'asd897yas';
my $encrypted = Blowfish::encipher($key, 'this');

print unpack("H*", $encrypted), "\n";
print Blowfish::decipher($key, $encrypted), "\n";

