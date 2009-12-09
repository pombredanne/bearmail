package BearMail::Backend::Files;

my $mailmap = "/etc/bearmail/mailmap";
my $debug = 0;

my %records;
my %by_domain;
my @domains;
my %files;
my %allowed = (
  'addr_normal pw_md5 local'           => 'regular_account',
  'addr_normal pw_none aliases'        => 'alias',
  'addr_normal pw_none pipe'           => 'pipe',
  'addr_catchall pw_none aliases'      => 'catchall',
  'addr_catchall pw_none domain_alias' => 'domain_alias',
);

# Read a simple "mailmap" configuration file, where:
#  - empty lines are ignored
#  - lines beginning with a '#' are ignored
#  - all other lines are counted as a 'record'.
#
# A record is ':'-delimited field list, with currently in this order:
#  - a (source) email 'adresss' (*@domain.com for catch-all)
#  - a MD5-hashed 'password' (128bits hexa)
#  - a 'target' (local delivery, aliases, domain alias, program)
#
sub read_mailmap {
  return if %records; # Parse mailmap only once

  open(MAILMAP, "<$mailmap") or die "$mailmap: $!";

  while(<MAILMAP>) {
    chomp;
    next if /^$/ or /^#/;  # Ignore empty lines and comments

    my @fields = split /:/;
    die "got ".scalar(@fields)." fields, expected 3" if @fields != 3;

    my %rec;
    my @types;
    foreach ('address', 'password', 'target') {
      my $field = shift @fields;
      push @types, check_field($_, $field);
      $rec{$_} = $field;
    }
    my $type = $allowed{"@types"};
    die "unsupported configuration (@types)" if !defined $type;

    # Users are key'ed by lowercase address (must be unique)
    $records{lc $rec{'address'}} = \%rec;
  }

  close MAILMAP;

  sort_mailmap();
}

# Field constraints. See https://scratch.bearstech.com/trac/ticket/34
#
sub check_field {
  my ($key, $val) = @_;

  if ($key eq 'address') {
    my $addr = $val;
    $addr =~ s/^\*@/x@/;  # Allow catch-all
    die "malformed address: $val" if not check_address($addr);
    die "non-unique address: $val" if defined $records{lc $val};

    return $val =~ m/^\*@/ ? 'addr_catchall' : 'addr_normal';
  }
  elsif ($key eq 'password') {
    return 'pw_none' if $val eq '';  # Non-login account
    die "malformed password hash: $val" if not $val =~ /^[0-9a-f]{32}$/;

    return 'pw_md5';
  }
  elsif ($key eq 'target') {
    return 'local' if $val eq 'local';  # Regular local IMAP account
    return 'pipe'  if $val =~ /^\|/;    # Pipe to a program (path unchecked)
    my $type = ($val =~ s/^\*@/x@/) ?   # Allow domain aliases (a single *@-like address)
      'domain_alias' : 'aliases';
    my @aliases = split(/,/, $val);
    die "can ony alias one domain at once" if @aliases > 1 && $type eq 'domain_alias';

    foreach (@aliases) {
      die "malformed address: $_" if not check_address($_);
    }
    return $type;
  }
}

# Email address basic check. It's a (small) RFC822 subset.
#
sub check_address {
  my $address = shift;
  return $address =~ /^[A-Za-z0-9\-\._]+@[A-Za-z0-9\-\.]+$/;
}

# Conf generators will have a prettier output if they sord records
# by domains, then by local part. Fill in @domains also.
#
sub sort_mailmap {
  foreach(keys %records) {
    /^([^@]+)@([^@]+)$/;
    my ($local, $domain) = ($1, $2);

    $by_domain{$domain} = [] if !defined $by_domain{$domain};
    $records{$_}->{'address_local'} = $local;
    push @{$by_domain{$domain}}, $records{$_};
  }

  foreach (keys %by_domain) {
    @{$by_domain{$_}} = sort { $a->{'address'} cmp $b->{'address'} } @{$by_domain{$_}};
  }
  @domains = sort keys %by_domain;
}

# Postfix conf files, expected settings in main.cf:
#   virtual_mailbox_domains   = hash:/etc/postfix/virtual_domains
#   virtual_mailbox_mailboxes = hash:/etc/postfix/virtual_mailboxes
#   virtual_alias_maps        = hash:/etc/postfix/virtual_aliases
#   alias_maps                = hash:/etc/aliases,
#                               hash:/etc/postfix/virtual_pipes
sub prepare_postfix_conf {
  my $virtual_domains   = join("\n", map { "$_ dummy" } @domains);
  my $virtual_mailboxes = '';
  my $virtual_aliases   = '';
  my $virtual_pipes     = '';

  foreach my $d (@domains) {
    my $comment = $virtual_mailboxes eq '' ? "" : "\n";
    $comment .= "# $d\n#\n";
    $virtual_mailboxes .= $comment;
    $virtual_aliases   .= $comment;

    foreach (@{$by_domain{$d}}) {
      my $address = $_->{'address'};
      my $target  = $_->{'target'};
      $address =~ s/^\*//;    # Fix catch-all syntax
      $target  =~ s/\*@/@/g;  # Fix domain aliasing syntax

      if ($target eq 'local') {
        $virtual_mailboxes .= "$address $d/$_->{'address_local'}/Maildir/\n";
        $virtual_aliases   .= "$address $address\n";
      }
      elsif ($target =~ /^\|/) {
        my $alias = "$_->{'address_local'}-$d-pipe";
        $virtual_aliases .= "$address $alias\n";
        $virtual_pipes   .= "$alias $target\n";
      }
      else {
        $virtual_aliases .= "$address $target\n";
      }
    }
  }

  $files{'/etc/postfix/virtual_domains'}   = $virtual_domains;
  $files{'/etc/postfix/virtual_mailboxes'} = $virtual_mailboxes;
  $files{'/etc/postfix/virtual_aliases'}   = $virtual_aliases;
  $files{'/etc/postfix/virtual_pipes'}     = $virtual_pipes;
}

# Dovecot auth files, expected settings in dovecot.cf:
#   passdb passwd-file {
#     args = /etc/dovecot/passwd
#   }
#   userdb passwd-file {
#     args = /etc/dovecot/passwd
#   }
#
sub prepare_dovecot_conf {
  my $passwd = '';

  foreach my $d (@domains) {

    foreach (@{$by_domain{$d}}) {
      my $password = $_->{'password'};
      next if $password eq '';

      my $address  = $_->{'address'};
      my $local    = $_->{'address_local'};
      $passwd .= "$address:{PLAIN-MD5}$password:500:500::/var/spool/imap/$d/${local}::\n";
    }
  }
  $files{"/etc/dovecot/passwd"} = $passwd;
}

sub write_conf {
  my $header = "# Generated by $program $version.\n# Please edit $mailmap instead of this file.\n\n";

  foreach (sort keys %files) {
    if (!$debug) {
      open(CONF, ">$_") or die "$_: $!";
      select CONF;
    } else {
      print "--\n-- $_\n--\n";
    }

    print $header.$files{$_}."\n";

    if (!$debug) {
      close(CONF);
      `postmap $_` if m:/etc/postfix/:;
    }
  }
  select STDOUT;
}


sub new() {
  my ($class, %args) = @_;

  bless \%args, $class;
}

sub get_domains() {
  my ($self) = @_;

  read_mailmap();
  my @hashed;
  push(@hashed, { name => $_ }) foreach @domains;
  return @hashed;
}

sub get_users() {
  my ($self, $domain) = @_;

  read_mailmap();
  return @{$by_domain{$domain}};
}

sub get_user() {
  my ($self, $user) = @_;

  read_mailmap();
  return $records{lc $user};
}

sub set_domain() {
}
sub set_address() {
}

sub add_domain() {
}
sub add_address() {
}

sub del_domain() {
}
sub del_address() {
}

1;
