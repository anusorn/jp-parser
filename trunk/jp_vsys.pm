package jp_vsys;
use strict;
use warnings;
use jp_vrouter;

#Ein VSys kann andere VSys, VRouter und Zonen enthalten.

sub new {
	my ($class, $name) = @_;
	my $self = {
		_name => undef,
		_resources => undef,
		_vsys_children => undef,
		_vrouter => undef,
		_zonen => undef,
		_interfaces => undef,
		_id => undef,
		_defaultvr => undef,
		_isroot => "true",

	};
	$self->{_name} = $name if defined($name);
	$self->{_resources} = {};
	$self->{_vsys_children} = {};
	$self->{_vrouter} = {};
	$self->{_zonen} = {};
	$self->{_interfaces} = {};
	bless($self, $class);
}

sub getname {
	my $self = shift;
	return $self->{_name};
}

#Name für dot-Ausgabe, in der Form cluster<name> 
sub getdotname {
	my $self = shift;
	if ($self->isroot()) {
		return "\"".$self->{_name}."\"";
	} else {
		return "\"cluster".$self->{_name}."\"";
	}
}

sub getid {
	my $self = shift;
	return $self->{_id};
}

sub isroot {
	my $self = shift;
	return $self->{_isroot};
}

#Setzt verschiedene Werte für die Zone
sub set {
	my $self = shift;
	$_ = shift;
	my $vrouter = shift;
	$$self{_resources}{$1} = $2 if ( /^resources $main::name (.*)$/ );
	$self->{_id} = $1 if ( /^id ([0-9]+)/ );
	$self->{_defaultvr} = $vrouter if ( /^vrouter/);
	$self->{_isroot} = "true" if (/^root/);
}

sub unset {
	my $self = shift;
	$_ = shift;
	$self->{_isroot} = 0 if (/^root/);
}

sub get_vrouter_list {
	my $self = shift;
	return $self->{_vrouter};
}

sub get_zone_list {
	my $self = shift;
	return $self->{_zonen};
}

sub get_interface_list {
	my $self = shift;
	return $self->{_interfaces};
}

#Findet zu einem Namen das VSys
sub getvsysbyname {
	my $self = shift;
	my $name = shift;
	if ($self->{_name} eq $name) {
		return $self;
	} else {
		if (!defined($$self{_vsys_children}{$name})) {
			$$self{_vsys_children}{$name} = jp_vsys->new($name);
		}
		return $$self{_vsys_children}{$name};
	}

}

#Findet zu einer ID das VSys
sub getvsysbyid {
	my $self = shift;
	my $id = shift;
	foreach my $name (keys(%{$self->{_vsys_children}})) {
		return $$self{_vsys_children}{$name} if ( $id == $$self{_vsys_children}{$name}->getid());
	}
	return vsys->new("unknown id: $id");
}

#Sucht einen VRouter anhand seines Namens, liefert undef, falls keiner existiert.
sub getvrouterbyname {
	my $self = shift;
	my $name = shift;
	if (defined($$self{_vrouter}{$name})) {
		return $$self{_vrouter}{$name};
	} else {
		my $childvsys;
		foreach $childvsys (keys(%{$self->{_vsys_children}})) {
			return $$self{_vsys_children}{$childvsys}->getvrouterbyname($name) if ($$self{_vsys_children}{$childvsys}->getvrouterbyname($name));
		}
	}
	return undef;

}

sub getdefaultvr {
	my $self = shift;
	return $self->{_defaultvr};
}

#Liefert die Höhe des VSys in der Grafik
sub getheight {
	my $self = shift;
	my $opt = shift;

	# Irgendwo aus dem nichts kriegt das Root-VSys noch etwas mehr Höhe...
	my $height = $self->isroot() ? 30 : 30;
	my $vrouter_height = 0;

	foreach my $zone_name (keys(%{$self->{_zonen}})) {
		$height += $$self{_zonen}{$zone_name}->getheight($opt);
	}

	foreach my $vsys_name (keys(%{$self->{_vsys_children}})) {
		$height += $$self{_vsys_children}{$vsys_name}->getheight($opt);
	}
	
	foreach my $vr_name (keys(%{$self->{_vrouter}})) {
		$vrouter_height += $$self{_vrouter}{$vr_name}->getheight() if (!$$self{_vrouter}{$vr_name}->issharable() || $self->isroot());
	}

	$height += $vrouter_height;
	return 5 + $height;

}

#Liefert die Breite des VSys in der Grafik
sub getwidth {
	my $self = shift;
	my $opt = shift;
	my $width = 30;
	my $vrouter_width=0;
	
	foreach my $for_name (keys(%{$self->{_vrouter}})) {
		$width += 100 if (!$$self{_vrouter}{$for_name}->issharable() || $self->isroot());
		$vrouter_width = $$self{_vrouter}{$for_name}->getwidth() > $vrouter_width ? $$self{_vrouter}{$for_name}->getwidth() : $vrouter_width;
	}
	$vrouter_width+=10;
	my $zone_width = 20;
	
	foreach my $for_name (keys(%{$self->{_zonen}})) {
		$zone_width = $$self{_zonen}{$for_name}->getwidth($opt) if  ($zone_width < $$self{_zonen}{$for_name}->getwidth($opt));
	}
	
	foreach my $for_name (keys(%{$self->{_vsys_children}})) {
		$zone_width = $$self{_vsys_children}{$for_name}->getwidth($opt) if  ($zone_width < $$self{_vsys_children}{$for_name}->getwidth($opt));
	} 

	$width += $zone_width;

	return $width > $vrouter_width ? $width : $vrouter_width ;
}

#Der von den VRoutern erzeugte offset, um den Zonen und VSys nach rechts verschoben werden müssen.
sub getvrouteroffset {
	my $self = shift;
	my $offset = 20;
	foreach my $name (keys(%{$self->{_vrouter}})) {
		$offset += 100 if (!$$self{_vrouter}{$name}->issharable() || $self->isroot());
	}
	return $offset;
}

#Fügt die Interfaces den jeweiligen Zonen zu.
sub parseinterfaces {
	my $self = shift;
	
	my $if_name;
	foreach $if_name (keys(%{$self->{_interfaces}})) {
		if (defined($$self{_interfaces}{$if_name}->getzone())) {
			$$self{_zonen}{$$self{_interfaces}{$if_name}->getzone()}->add($$self{_interfaces}{$if_name});
		}
		if (defined($$self{_interfaces}{$if_name}->getgroup())) {
			$$self{_interfaces}{$$self{_interfaces}{$if_name}->getgroup()}->add_sub_if($$self{_interfaces}{$if_name});
		}
	}
	
	my $vsys_name;
	foreach $vsys_name (keys(%{$self->{_vsys_children}})) {
		$$self{_vsys_children}{$vsys_name}->parseinterfaces();
	}
}

#Trägt das VSys in die SVG ein.
sub generate_svg {
	my ($self,$svg, $xpos, $ypos, $routes, $opt, $config) = @_;
	my $height = $self->getheight($opt) -5;
	my $width = $self->getwidth($opt) ;
	my $color;
	if ($self->isroot()) {
		$color = "$$config{color_root}";
	} else {
		$color = "$$config{color_vsys}";
	}
	
	my $svg_vsys = $svg->group(id=>"vsys_$self->{_name}");
	$svg_vsys->rect(x=>"$xpos", y=>"$ypos", width=>"$width", height=>"$height",fill=>"$color");

	$svg_vsys->text(x=>$xpos+5, y=>$ypos+18, -cdata=>"VSys: $self->{_name}", font=>"Verdana");

	my $xoffset = 15 + $xpos;
	my $yoffset = 30 + $ypos;
	
	foreach my $vr_name (sort(keys(%{$self->{_vrouter}}))) {
		if (!$$self{_vrouter}{$vr_name}->issharable() || $self->isroot()) {
			$$self{_vrouter}{$vr_name}->generate_svg($svg_vsys, $xoffset, $yoffset, $routes, $opt, $config);
			$xoffset += 100;
			$yoffset += $$self{_vrouter}{$vr_name}->getheight();
		}
	}

	foreach my $vsys_name (sort(keys(%{$self->{_vsys_children}}))) {
			if (!$$self{_vsys_children}{$vsys_name}->isroot()) {
				$$self{_vsys_children}{$vsys_name}->generate_svg($svg_vsys, $xoffset, $yoffset, $routes, $opt, $config);
	        	$yoffset +=  $$self{_vsys_children}{$vsys_name}->getheight($opt);
			}
	}

	foreach my $zone_name (sort(keys(%{$self->{_zonen}}))) {
		$$self{_zonen}{$zone_name}->generate_svg($svg_vsys, $xoffset, $yoffset, $routes, $opt, $config);
		$yoffset += $$self{_zonen}{$zone_name}->getheight($opt);
	}
	
}

#Trägt das VSys in die DOT-Datei ein.
sub generate_dot {
	my ($self,$DOT, $routes, $opt, $config) = @_;
	my $color;
	if ($self->isroot()) {
		$color = "$$config{color_root}";
		print $DOT "graph ".$self->getdotname()." {\n";
	} else {
		$color = "$$config{color_vsys}";
		print $DOT "subgraph ".$self->getdotname()." {\n";
	}
	
	print $DOT "graph [bgcolor=$color];\n";
	print $DOT "graph [label=\"VSys: ".$self->getname()."\"];\n";
	foreach my $vr_name (sort(keys(%{$self->{_vrouter}}))) {
		if (!$$self{_vrouter}{$vr_name}->issharable() || $self->isroot()) {
			$$self{_vrouter}{$vr_name}->generate_dot($DOT, $routes, $opt, $config);
		}
	}

	foreach my $vsys_name (sort(keys(%{$self->{_vsys_children}}))) {
			if (!$$self{_vsys_children}{$vsys_name}->isroot()) {
				$$self{_vsys_children}{$vsys_name}->generate_dot($DOT, $routes, $opt, $config);
			}
	}

	foreach my $zone_name (sort(keys(%{$self->{_zonen}}))) {
		$$self{_zonen}{$zone_name}->generate_dot($DOT, $routes, $opt, $config);

	}
	
	print $DOT "}\n" if !$self->isroot();
	
}



sub print {
	my $self = shift;
	print "\n###############################################################\n\n";
	print "VSys-Name: ".$self->{_name}."\n";
	my $res_laenge = keys(%{$self->{_resources}});
	if ($res_laenge > 0) {
		print "Resources: \n";
		my $rs_name;
		foreach $rs_name (sort(keys(%{$self->{_resources}}))) {
			print "$rs_name: $$self{_resources}{$rs_name} \n";
		}
	}
	print "ID: $self->{_id} \n" if (defined($self->{_id}));
	my $defaultvr = "";
	$defaultvr = $self->{_defaultvr}->getname() if (defined($self->{_defaultvr}));
	print "Default-VR: $defaultvr \n";

	print "\n##########################################################\nVRouter-Liste:\n\n";
	
	my $for_name;
	foreach $for_name (sort(keys(%{$self->{_vrouter}}))) {
        	$$self{_vrouter}{$for_name}->print();
	};

	print "\n##########################################################\nZonen-Liste:\n\n";
	foreach $for_name (sort(keys(%{$self->{_zonen}}))) {
	        $$self{_zonen}{$for_name}->print();
	};


	print "\n##########################################################\nInterface-Liste:\n\n";
	foreach $for_name (sort(keys(%{$self->{_interfaces}}))) {
	        $$self{_interfaces}{$for_name}->print();
	};
	

	my $children_laenge = keys(%{$self->{_vsys_children}});
	if ($children_laenge > 0 ) {
		print "\n#########################################################################\n\nVSys-Children:\n\n";
		foreach $for_name (sort(keys(%{$self->{_vsys_children}}))) {
			$$self{_vsys_children}{$for_name}->print();
		}
	}

}


1;

=pod

=head1 NAME

B<jp_vsys.pm> - Klasse, die ein virtuelles System darstellt

=head1 SYNOPSIS

=over 8

=item B<jp_vsys::new>I<($name)>

=item B<jp_vsys::getname>I<()>

=item B<jp_vsys::getdotname>I<()>

=item B<jp_vsys::getid>I<()>

=item B<jp_vsys::isroot>I<()>

=item B<jp_vsys::set>I<($command, $vrouter)>

=item B<jp_vsys::unset>I<($command)>

=item B<jp_vsys::get_vrouter_list>I<()>

=item B<jp_vsys::get_zone_list>I<()>

=item B<jp_vsys::get_interface_list>I<()>

=item B<jp_vsys::getvsysbyname>I<($name)>

=item B<jp_vsys::getvsysbyid>I<($id)>

=item B<jp_vsys::getvrouterbyname>I<($name)>

=item B<jp_vsys::getdefaultvr>I<()>

=item B<jp_vsys::getwidth>I<()>

=item B<jp_vsys::getheight>I<()>

=item B<jp_vsys::getvrouteroffset>I<()>

=item B<jp_vsys::parseinterfaces>I<()>

=item B<jp_vsys::generate_svg>I<($svg, $xpos, $ypos, $routes, $opt, $config)>

=item B<jp_vsys::generate_dot>I<($DOT, $routes, $opt, $config)>

=item B<jp_vsys::print>I<()>

=back

=head1 DESCRIPTION

Objekte der Klasse VSys stellen ein virtuelles System dar.

=head1 COMMANDS

=over 8

=item B<new>

Erzeugt das VSys.

=item B<getname>

Gibt den Namen des VSys zurück

=item B<getdotname>

Gibt den Namen der Zone zurück, wie er in der dot-Ausgabe als interner Begriff genutzt wird. Der Name ist eindeutig.

=item B<getid>

Gibt die ID des VSys zurück

=item B<isroot>

True, wenn das VSys das Root-Vsys ist.

=item B<set/unset>

Setzt verschiedene Werte für das VSys oder löscht diese.

=item B<get_vrouter_list/get_zone_list/get_interface_list>

Liefert eine Liste der VRouter, der Zonen bzw. der Interfaces in diesem VSys.

=item B<getvsysbyname>

Liefert ein VSys anhand seines Namens zurück, durchsucht auch die Unter-VSys. 

=item B<getvsysbyid>

Liefert ein VSys anhand seiner ID zurück, durchsucht auch die Unter-VSys. 

=item B<getvrouterbyname>

Liefert einen virtuellen Router anhand seines Namens zurück, durchsucht auch die Unter-VSys. 

=item B<getdefaultvr>

Liefert den Default-VRouter des VSys. 

=item B<getvrouteroffset>

Liefert die Breite, um die die Zonen bzw. VSys nach rechts eingerückt werden müssen, damit Platz für die VRouter bleibt.

=item B<getwidh/getheight>

Liefert die Höhe/Breite des VSys in der SVG-Grafik. In der Höhe ist bereits ein Abstand von 5 Pixeln nach unten enthalten.

=item B<parseinterfaces>

Durchläuft alle Interfaces und ordnet diese ihrer jeweiligen Zone zu.

=item B<generate_svg>

Erzeugt die SVG-Ausgabe für das VSys. 

=item B<generate_dot>

Erzeugt die DOT-Ausgabe für die das VSys.

=item B<print>

Gibt die Informationen des VSys auf STDOUT aus.


=back

=head1 OPTIONS

=over 8

=item B<$name>  I<String>

Ein Name

=item B<$command> I<String>

Befehl, um einen Wert des VSys zu setzen, Syntax wie im CLI nur ohne C<[un]set $name>

=item B<$vrouter> I<Referenz>

Der default-Router des VSys.

=item B<$svg> I<Referenz>

Refernz auf das SVG-Objekt, in dem das Interface gezeichnet werden soll.

=item B<$xpos> I<Integer>, B<$ypos> I<Integer>

Die Koordinaten der linken oberen Ecke des VSys in der gesamten Grafik.

=item B<$routes> I<Array>

Eine Liste, in der alle Routen eingetragen werden.

=item B<$opt> I<Hash>

Die Optionen, die über die Kommandozeile übergeben wurden

=item B<$config> I<Hash>

Die Farben für die Ausgabe, können in der Konfigurationsdatei gesetzt werden, siehe L<jp_parser.conf>

=item B<$DOT> I<Filehandle>

Ein Filehandle, in das die dot-Ausgabe geschrieben wird.

=back

=head1 EXAMPLES
 
Erzeugt ein VSys namens I<BeispielVSys>:
 
 $vsys = jp_vsys->new('BeispielVSys');
 
Und sucht dieses VSys über das Root-VSys:

 $mein_vsys = $root->getvsysbyname('BeispielVSys');

=head1 SEE ALSO

L<jp_parser(1)>, L<jp_vrouter.pm(3)>

=head1 REQUIRES

Perl 5.8

F<jp_parser>, F<jp_vrouter.pm>

=head1 AUTHOR and COPYRIGHT

     
     Till Potinius
     <justamail@justmoments.de>

     Copyright (c) 2007 Till Potinius


=cut