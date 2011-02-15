package BearMail::Backend;

=pod

=head1 NAME

BearMail::Backend - Bearmail core class


=head1 SYNOPSIS

    use BearMail::Backend;
    
    my $bb = BearMail::Backend->new();
    $bb->login('root');
    
    my @domains = $bb->get_domains(search => '*bear*', range => [0, 9]);
    my @account = $bb->get_account(search => '*@bearstech.com', range => [30, 39]);

    ...


=head1 DESCRIPTION

C<BearMail::Backend> is at the core of the Bearmail infrastructure. It connects
to whatever 'backend' implements your email services and let you query and 
configure it.

For instance C<BearMail::Backend::Files> can configure a Postfix+Dovecot setup
with only the help of the filesystem. It works and scales very well up to
a few thousands accounts, and is adminsys friendly (you can version control
everything, trivially analyze, backup and fix things, etc.)

For large scale and stable behaviour wrt. massive end users hitting the web
interface, you might prefer the C<BearMail::Backend::SQL> interface.

TODO: describe account, targets, autorization model.


=head1 METHODS

=head2 new

The constructor C<new> connects to an existing backend. It will first search
for a global configuration file (see C<BearMail::Config>) and use its
content to select a type of backend and optionnally configure it.

    my $bb = BearMail::Backend->new(
        config  => BearMail::Config->new->load('mymail.cfg'),
        backend => BearMail::Backend::Files->new
    );

Optionnal parameters are :

=item * config

C<BearMail::Backend> will create a C<BearMail::Config> object with no specific
parameters. If you want to provide a different configuration (eg. load the
configuration from a different file than the one hardwired in
C<BearMail::Config>), you may provide your own config object here.

You may also pass an undef value; in this case you will have to explictly
create other needed ressources for the backend.

=item * backend

Normally C<BearMail::Backend> will select and configure a backend using the
'backend' configuration parameter. If you have no configuration or want
to explicitly pass the backend, provide a C<BearMail::Backend> here.

=back

If the backend initialization failed for some reason, it will carp and
this constructor will return C<undef>.


=head1 SUPPORT

Bugs should be reported via the Trac tool at

L<http://forge.bearstech.com/trac/newticket>

=head1 AUTHORS

=head1 SEE ALSO

L<BearMail>

=head1 COPYRIGHT

Copyright (C) 2009,2010 Bearstech - http://bearstech.com/

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut


1;
