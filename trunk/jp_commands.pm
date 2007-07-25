package jp_commands;
use strict;
use warnings;

use jp_vsys;
use jp_vrouter;
use jp_zone;
use jp_interface;


# Setzt zu einem vorhandenen VSys bestimmte Parameter, wie verfügbarer Speicher etc.
# Hat keinerlei Auswirkung auf die Grafik.
sub vsys_profile {
	my ($values, $vsys) = @_;
	$vsys->set("resources $values");
}

#Führt Kommandos für VRouter aus und erzeugt neue VRouter.
sub vrouter {
	my ($vrouter_name, $command, $unset, $rootvsys, $currentvsys) = @_;
	my $vrouter_liste = $currentvsys->get_vrouter_list();
    my $vrouter;
	if (!defined($rootvsys->getvrouterbyname($vrouter_name))) {
		$vrouter = jp_vrouter->new($vrouter_name, $currentvsys);
	} else {
		$vrouter = $rootvsys->getvrouterbyname($vrouter_name);
	}

	if ( $unset ) {
	        $vrouter->unset($command);
        } else {
                $vrouter->set($command, $rootvsys);
        }
	$$vrouter_liste{$vrouter_name} = $vrouter;
}

#Erstellt und konfiguriert Zonen
sub zone {
	my ( $command, $unset, $rootvsys, $currentvsys) = @_;
	my $zone_list = $currentvsys->get_zone_list();
	my $zone;
	return if (!defined($command));
	$_ = $command;
	/^$main::name $main::name(?: $main::name)?/;
	my $zone_name = $1;
	$command = $2;
	my $value = $3 ? $3 : "undef";
	
	my @tmp = ($3, $1, $2);
	# Zonen-ID: Zuordnung ist verdreht:
	($zone_name, $command, $value) = @tmp if ($1 =~ /^id$/ );

	$zone_name =~ s/"//g;
	$value =~ s/"//g;

	if (!defined($$zone_list{$zone_name})) {
		$zone = jp_zone->new($zone_name, $currentvsys);
	} else {
		$zone = $$zone_list{$zone_name};
	}

	if ($unset) {
		$zone->unset($command, $value);
	} else {
		$zone->set($command, $value, $rootvsys);
	}

	$$zone_list{$zone_name} = $zone;
}


# Fügt in einer Zone bestimmte Address-Bereiche hinzu
sub address {
	my ( $zone_name, $command, $unset, $currentvsys) = @_;
	my $zone_list = $currentvsys->get_zone_list();
	my $zone;

	if (!defined($$zone_list{$zone_name})) {
		$zone = jp_zone->new($zone_name, $currentvsys);
	} else {
		$zone = $$zone_list{$zone_name};
	}

	if ($unset) {
		#Value wird fast immer leer sein. Vielleicht sogar immer.
		$zone->unset('address', $command);
	} else {
		$zone->set('address', $command);
	}

	$$zone_list{$zone_name} = $zone;
}

# Fügt Gruppen zu einer Zone hinzu
sub group {
	my ($zone_name, $group, $unset, $currentvsys) = @_;
	my $zone_list = $currentvsys->get_zone_list();
	my $zone;

	if (!defined($$zone_list{$zone_name})) {
		$zone = jp_zone->new($zone_name);
	} else {
		$zone = $$zone_list{$zone_name};
	}

	if ($unset) {
		$zone->unset('group', $group);
	} else {
		$zone->set('group', $group);
	}

	$$zone_list{$zone_name} = $zone;

}

# Erstellt ein neues Interface oder konfiguriert ein bestehendes
sub interface {
	my ($if_name, $param, $unset, $currentvsys) = @_;
	my $interface_list = $currentvsys->get_interface_list();
	
	my $if;

	if (!defined($$interface_list{$if_name})) {
		$if = jp_interface->new($if_name);
	} else {
		$if = $$interface_list{$if_name};
	}
	
	if ($unset) {
		$if->unset($param);
	} else {
		$if->set($param);
	}

	$$interface_list{$if_name} = $if;
}

# Ordnet einem VSys eine ID zu. 
sub vsys_id {
	my ($vsys, $vsys_id) = @_;
	$vsys->set("id $vsys_id");
}

#Setzt den default-Router eines VSys
sub vsys_default_vr {
	my ($vrouter_name, $currentvsys, $rootvsys) = @_;
	my $vrouter = $rootvsys->getvrouterbyname($vrouter_name);
	$currentvsys->set("vrouter", $vrouter);
}

1;


=pod

=head1 NAME

B<jp_commands.pm> - Wrapper zur Dateneingabe

=head1 SYNOPSIS

=over 8

=item B<jp_commands::vsys-profile>I<($command, $currentvsys)>

=item B<jp_commands::vrouter>I<($name, $command, $unset, $rootvsys, $currentvsys)>

=item B<jp_commands::zone>I<($command, $unset, $rootvsys, $currentvsys)>

=item B<jp_commands::address>I<($name, $command, $unset, $currentvsys)>

=item B<jp_commands::group>I<($name, $group, $unset, $currentvsys)>

=item B<jp_commands::interface>I<($name, $command, $unset, $currentvsys)>

=item B<jp_commands::vsys_id>I<($currentvsys, $vsys_id)>

=item B<jp_commands::vsys_default_vr>I<($name, $currentvsys, $rootvsys)>

=back

=head1 DESCRIPTION

B<jp_commands> stellt verschiedene Prozeduren bereit, die Daten in 
bestimmte Objekte eintragen bzw. diese bei Bedarf erstellen.

=head1 COMMANDS

=over 8

=item B<vsys-profile>

 Setzt zu einem vorhandenen VSys bestimmte Parameter, wie verfügbarer Speicher etc.
 Hat keinerlei Auswirkung auf die Grafik.

=item B<vrouter>

Führt Kommandos für VRouter aus und erzeugt neue VRouter.

=item B<zone>

Erstellt und konfiguriert Zonen

=item B<address>

Fügt in einer Zone bestimmte Address-Bereiche hinzu

=item B<group>

Fügt Gruppen zu einer Zone hinzu

=item B<interface>

Erstellt ein neues Interface oder konfiguriert ein bestehendes

=item B<vsys_id>

Ordnet einem VSys eine ID zu. 

=item B<vsys_default_vr>

Setzt den default-Router eines VSys

=back

=head1 OPTIONS

=over 8

=item B<$currentvsys> I<Referenz>

Referenz auf das VSys, in dem gearbeitet wird.

=item B<$rootvsys> I<Referenz>

Referenz auf das Root-VSys.

=item B<$command> I<String>

Der auszuführende Befehl, wie er in dem CLI genutzt wird(allerdings ohne C<set name>)

=item B<$name>  I<String>

Der Name des Objekts

=item B<$unset> I<Boolean>

true, wenn der Wert gelöscht wird(C<unset> im CLI)

=item B<$group> I<String>

Der Name der Gruppe

=item B<$vsys_id>  I<Integer>

Die ID des VSys als Zahl

=back

=head1 EXAMPLES
 
Erzeugt den VRouter I<$vrouter_name> in dem VSys I<$currentvsys>:
 
 	jp_commands::vrouter($vrouter_name, "create", 0, $rootvsys, $currentvsys);

=head1 SEE ALSO

L<jp_parser(1)>, L<jp_interface.pm(3)>, L<jp_zone.pm(3)>, L<jp_vsys.pm(3)>, L<jp_vrouter.pm(3)>

=head1 REQUIRES

Perl 5.8

F<jp_parser>, F<jp_vsys.pm>, F<jp_vrouter.pm>, F<jp_zone.pm>, F<jp_interface.pm>

=head1 AUTHOR and COPYRIGHT

     
     Till Potinius
     <justamail@justmoments.de>

     Copyright (c) 2007 Till Potinius

=cut
