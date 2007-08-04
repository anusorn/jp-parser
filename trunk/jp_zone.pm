package jp_zone;
use strict;
use warnings;
use jp_vsys;
use jp_vrouter;

#In einer Zone können mehrere Interfaces zusammengefasst werden.

sub new {
	my ($class, $zone_name, $vsys) = @_;
	my $self = {
		_name => undef,
		_vrouter => undef,
		_id => undef,
		_tcp_rst => "true",
		_reassembly_for_alg => 0,
		_block => 0,
		_screen => undef,
		_addresses => undef,
		_xpos => undef,
		_yos => undef,
		_vsys => undef,
		_interfaces => undef,
		_shared => 0,
	};
	$self->{_name} = $zone_name if defined($zone_name);
	$self->{_vsys} = $vsys if defined($vsys);
	$self->{_shared} = 1 if $zone_name eq "Untrust";
	$self->{_screen} = {};
	$self->{_addresses} = {};
	$self->{_interfaces} = {};
	bless($self, $class);
}

sub is_shared {
	my $self = shift;
	return $self->{_shared};
}

sub getname {
	my $self = shift;
	return $self->{_name};
}

#Name für dot-Ausgabe, in der Form <Vsysname>if<name> 
sub getdotname {
	my $self = shift;
	return "\"".$self->{_vsys}->getname().'if'.$self->{_name}."\"";
}

#Name für dot-Ausgabe, in der Form <Vsysname>if<name>:0 als Ansatz für die Pfeile.
sub getdot_target_name {
	my $self = shift;
	return "\"".$self->{_vsys}->getname().'if'.$self->{_name}."\"".":f0";
}

#Gewichtung, Zonen sind weniger wichtig als VRouter
sub getdotweight {
	my $self = shift;
	return 1;
}

#Setzt verschiedene Werte für die Zone
sub set {
	my $self = shift;
	my ($command, $value, $vsys) = @_;
	if ($command =~ /^vrouter/) {
		$self->{_vrouter} = $vsys->getvrouterbyname($value);
	}
	$self->{_id} = $value if ($command =~ /^id/);
	$self->{_tcp_rst} = "true" if ($command =~ /^tcp-rst/ );
	$self->{_reassembly_for_alg} = "true" if ($command =~ /^reassembly-for-alg/);
	$self->{_shared} = "true" if ($command =~ /^shared/);
	$self->{_block} = "true" if ($command =~ /^block/);
	$$self{_screen}{$value} = "true" if ($command =~ /^screen/);
	$self->set_address($value) if ($command =~ /^address/);
	$self->set_group($value) if ($command =~ /^group/);
}

#Fügt Adress-Gruppen zu der Zone hinzu:	
sub set_group {
	my $self = shift;
	$_ = shift;
	/^$main::name(?: (.*))?/;
	my $group = $1;
	my $desc = $2;
	my %address = ('name' => "Gruppe: $group", 'ip' => "", 'mask' => "", 'desc' => $desc);
	$$self{_addresses}{$group} = \%address;
}

#Fügt Adressen zu der Zone hinzu:
sub set_address {
	my $self = shift;
	$_ = shift;
	/^$main::name $main::name $main::name(?: $main::name)?/;
	my $address_name = $1 ? $1 : "";
	my $ip = $2 ? $2 : "";
	my $mask = $3 ? $3 : "";
	my $desc = $4 ? $4 : "";
	$address_name =~ s/"//g;
	my %address = ( 'name' => $address_name, 'ip' => $ip, 'mask' => $mask, 'desc' => $desc );
	$$self{_addresses}{$address_name} = \%address;
}

sub unset {
	my $self = shift;
	my ($command, $value) = @_;
	$self->{_vrouter} = undef if ($command =~ /^vrouter/);
	$self->{_id} = undef if ($command =~ /^id/);
	$self->{_tcp_rst} = 0 if ($command =~ /^tcp-rst/ );
	$self->{_reassembly_for_alg} = 0 if ($command =~ /^reassembly-for-alg/);
	$self->{_block} = 0 if ($command =~ /^block/);
	$$self{_screen}{$value} = 0 if ($command =~ /^screen/);
}

#Liefert die Höhe der Zone in der Grafik
sub getheight {
	my $self = shift;
	my $opt = shift;
	my $laenge = keys(%{$self->{_interfaces}});
	#Höhe = 0, wenn keine leeren Zonen gezeichnet werden sollen
	return 0 if ($$opt{n} && $laenge == 0);
	my $height = 25;

	foreach my $if_name (keys(%{$self->{_interfaces}})) {
		$height += $$self{_interfaces}{$if_name}->getheight($opt);
	}
	return $height;
}

#Trägt die Zone in die SVG ein.
sub generate_svg {
	my ($self, $svg, $xpos, $ypos, $routes, $opt, $config) = @_;
	my $height = $self->getheight($opt) - 5;
	my $width = $self->getwidth($opt) ;
	
	my $color;
	
	if ($self->is_shared()) {
		$color = $$config{color_zone_sharable};
	} else {
		$color = $$config{color_zone};
	}
	
    #Abbruch, wenn Zone leer ist.
	return  if ($height < 5 );
	
	my $svg_zone = $svg->group(id=>"zone$self->{_vsys}$self->{_name}");
	$svg_zone->rect(x=>$xpos, y=>$ypos, width=>$width, height=>$height, fill=>"$color");
	$svg_zone->text(x=>2+$xpos, y=>14+$ypos, -cdata=>"$self->{_name}");

	$self->{_xpos} = $xpos;
	$self->{_ypos} = $ypos;
	
  	if (defined($self->{_vrouter})) {
        my @line = ($self, $$self{_vrouter});
		push  (@{$routes}, \@line);
	} elsif (defined($self->{_vsys}->getdefaultvr()))  {
		my @line = ($self, $self->{_vsys}->getdefaultvr());
		push  (@{$routes}, \@line);
	}

	my $xoffset = 10 + $xpos;
	my $yoffset = 20 + $ypos;
	
	foreach my $if_name (sort(keys(%{$self->{_interfaces}}))) {
		$$self{_interfaces}{$if_name}->generate_svg($svg_zone, $xoffset, $yoffset, $opt, $config);
		$yoffset += $$self{_interfaces}{$if_name}->getheight($opt);
	}

}


#Trägt die Zone in die DOT-Datei ein.
sub generate_dot {
	my ($self, $DOT, $routes, $opt, $config) = @_;
	my $height = $self->getheight($opt) - 5;
	
	my $color ;
	if ($self->is_shared()) {
		$color = $$config{color_zone_sharable};
	} else {
		$color = $$config{color_zone};
	}
	
	
    #Abbruch, wenn Zone leer ist.
	return  if ($height < 5 );
	
	my $label = "<f0> ".$self->getname()."|{";
	my $separator ="";
	foreach my $if_name (sort(keys(%{$self->{_interfaces}}))) {
		my $ip = $$self{_interfaces}{$if_name}->get_dot_text($opt);
		$label .= " ${separator}{$if_name$ip}";
		$separator = "| ";
	}
	$label .= " }";
	print $DOT $self->getdotname()." [shape=record, style=filled, label=\"{$label}\", fillcolor=$color];\n";
	
  	if (defined($self->{_vrouter})) {
        my @line = ($self, $$self{_vrouter});
		push  (@{$routes}, \@line);
	} elsif (defined($self->{_vsys}->getdefaultvr()))  {
		my @line = ($self, $self->{_vsys}->getdefaultvr());
		push  (@{$routes}, \@line);
	}

}

#Linke Koordinaten, für die Routen nach links.
sub getleftcoord {
	my $self = shift;
	return ($self->{_xpos}, $self->{_ypos} + ($self->getheight() / 2) );
}

#Untere Koordinaten, für die Routen nach unten.
sub getdowncoord {
	my $self = shift;
	return ($self->{_xpos} + ($self->getwidth() / 2), $self->{_ypos} );
}

#Koordinaten(unten links)
sub getcoord {
	my $self = shift;
	return ($self->{_xpos}, $self->{_ypos});
}

#Die Breite der Zone. Angenommen werden 8 Pixel pro Buchstabe.
sub getwidth {
	my $self = shift;
	my $opt = shift;
	my $width = 20;
	my $subwidth = 8 * length($self->{_name});
	my $laenge = %{$self->{_interfaces}};
	#Breite = 0, wenn Zone nicht gezeichnet werden soll.
	return 0 if ($opt->{noempyzones} && $laenge == 0); 
	
	foreach my $if_name (keys(%{$self->{_interfaces}})) {
		$subwidth = $$self{_interfaces}{$if_name}->getwidth($opt) if ($subwidth < $$self{_interfaces}{$if_name}->getwidth($opt));
	}
	$width += $subwidth;
	return $width;
}

#Fügt ein Interface zu der Zone hinzu.
sub add {
	my $self = shift;
	my $interface = shift;
	$$self{_interfaces}{$interface->getname()} = $interface; 
}

sub print {
	my $self = shift;
	my $vrouter = $self->{_vrouter}->getname() if (defined($self->{_vrouter})) ;
	print "--------------------------------------------\n";
	print "Zonen-Name: $self->{_name}\n";
	print "VSys: ",$self->{_vsys}->getname(),"\n" if (defined ($self->{_vsys}));	
	print "VRouter: $vrouter\n" if (defined ($vrouter));
	print "ID: $self->{_id}\n" if (defined($self->{_id}));
	print "TCP-rst: $self->{_tcp_rst}\n";
	print "Reassembly for Alg: $self->{_reassembly_for_alg}\n";
	print "Block: $self->{_block}\n";
	print "Shared: $self->{_shared}\n";
	my $laenge_screen = keys(%{$self->{_screen}});
	if ($laenge_screen > 0) {
		print "Screen: ";
		foreach my $name (sort(keys(%{$self->{_screen}}))) {
			print "$name " if ($$self{_screen}{$name});
		}
		print "\n";
	}
	my $laenge_addr = keys(%{$self->{_addresses}});
	if ($laenge_addr > 0) {
		print "Addresses: \n";
		foreach my $name (sort(keys(%{$self->{_addresses}}))) {
			print "      $$self{_addresses}{$name}{name} $$self{_addresses}{$name}{ip} $$self{_addresses}{$name}{mask} $$self{_addresses}{$name}{desc} \n";
		}
	}

}


1;

=pod

=head1 NAME

B<jp_zone.pm> - Klasse, die eine Zone darstellt

=head1 SYNOPSIS

=over 8

=item B<jp_zone::new>I<($name, $vsys)>

=item B<jp_zone::getname>I<()>

=item B<jp_zone::getdotname>I<()>

=item B<jp_zone::getdot_target_name>I<()>

=item B<jp_zone::getdotweight>I<()>

=item B<jp_zone::is_shared>I<()>

=item B<jp_zone::set>I<($command, $value, $vsys)>

=item B<jp_zone::unset>I<($command, $value)>

=item B<jp_zone::set_group>I<($param)>

=item B<jp_zone::set_address>I<($param)>

=item B<jp_zone::getwidth>I<()>

=item B<jp_zone::getheight>I<()>

=item B<jp_zone::generate_svg>I<($svg, $xpos, $ypos, $routes, $opt, $config)>

=item B<jp_zone::generate_dot>I<($DOT, $routes, $opt, $config)>

=item B<jp_zone::getleftcoord>I<()>

=item B<jp_zone::getdowncoord>I<()>

=item B<jp_zone::getcoord>I<()>

=item B<jp_zone::add>I<($interface)>

=item B<jp_zone::print>I<()>

=back

=head1 DESCRIPTION

Objekte der Klasse Zone stellen eine Sicherheitszone in dem System dar.

=head1 COMMANDS

=over 8

=item B<new>

Erzeugt die Zone.

=item B<getname>

Gibt den Namen der Zone zurück

=item B<getdotname>

Gibt den Namen der Zone zurück, wie er in der dot-Ausgabe als interner Begriff genutzt wird. Der Name ist eindeutig.

=item B<getdot_target_name>

Gibt den Namen der Zone zurück, wie er in der dot-Ausgabe als interner Begriff genutzt wird, 
mit einem Ansatzpunkt für die Routen. Der Name ist eindeutig.

=item B<getdotweight>

Durch die Gewichtung wird den Routen zwischen 2 Objekten eine Gewichtung verliehen, je nach Renderer wird versucht, diese kürzer zu halten.
VRouter haben eine höhere Gewichtung als Zonen, so dass diese näher beieinander gezeichnet werden.

=item B<is_shared>

True, wenn die Zone I<shared> ist.

=item B<set/unset/set_group/set_address>

Setzt verschiedene Werte für die Zone oder löscht diese.

=item B<getwidh/getheight>

Liefert die Höhe/Breite des Interfaces in der SVG-Grafik. In der Höhe ist bereits ein Abstand von 5 Pixeln nach unten enthalten.

=item B<generate_svg>

Erzeugt die SVG-Ausgabe für die Zone. 

=item B<generate_dot>

Erzeugt die DOT-Ausgabe für die Zone.

=item B<getleftcoord>

Liefert die Koordinaten, wo Routen enden, die von links zu der Zone gehen.

=item B<getdowncoord>

Liefert die Koordinaten, wo Routen enden, die von unten zu der Zone gehen.

=item B<getcoord>

Liefert die Koordinaten der Zone.

=item B<add>

Fügt ein Interface zu der Zone hinzu

=item B<print>

Gibt die Informationen der Zone auf STDOUT aus.

=back

=head1 OPTIONS

=over 8

=item B<$name>  I<String>

Der Name der Zone

=item B<$vsys> I<Referenz>

Das VSys, in dem sich die Zone befindet.

=item B<$command> I<String>

Befehl, um einen Wert der Zone zu setzen, Syntax wie im CLI nur ohne C<[un]set $name>

=item B<$value> I<String>

Wert, der zu $command in der Zone gesetzt wird.

=item B<$svg> I<Referenz>

Refernz auf das SVG-Objekt, in dem das Interface gezeichnet werden soll.

=item B<$xpos> I<Integer>, B<$ypos> I<Integer>

Die Koordinaten der linken oberen Ecke des Interfaces in der gesamten Grafik.

=item B<$routes> I<Array>

Eine Liste, in der alle Routen eingetragen werden.

=item B<$opt> I<Hash>

Die Optionen, die über die Kommandozeile übergeben wurden

=item B<$config> I<Hash>

Die Farben für die Ausgabe, können in der Konfigurationsdatei gesetzt werden, siehe L<jp_parser.conf(3)>

=item B<$DOT> I<Filehandle>

Ein Filehandle, in das die dot-Ausgabe geschrieben wird.

=item B<$interface> I<Referenz>

Ein Interface, dass der Zone hinzugefügt wird.

=back

=head1 EXAMPLES
 
Erzeugt eine Zone namens I<Beispielzone> im VSys I<$root>:
 
 $zone = jp_zone->new('Beispielzone', $root);
 
Und fügt dieser das Interface I<$if> hinzu:

 $zone->add($if);

=head1 SEE ALSO

L<jp_parser(1)>, L<jp_vsys.pm(3)>, L<jp_vrouter.pm(3)>

=head1 REQUIRES

Perl 5.8

F<jp_parser>, F<jp_vsys.pm>, F<jp_vrouter.pm>

=head1 AUTHOR and COPYRIGHT

     
     Till Potinius
     <justamail@justmoments.de>

     Copyright (c) 2007 Till Potinius


=cut