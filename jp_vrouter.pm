package jp_vrouter;
use strict;
use warnings;



sub new {
	my ($class, $name, $vsys) = @_;
	my $self = {
		_name => undef,
		_sharable => 0,
		_auto_route_export => 0,
		_id => undef,
		_route => undef,
		_xpos => undef,
		_ypos => undef,
		_vsys =>undef,
	};
	$self->{_name} = $name if defined($name);
	$self->{_sharable} = 1 if $name eq "untrust-vr";
	$self->{_vsys} = $vsys if defined($vsys);
	$self->{_route} = {};
	bless($self, $class);
}

sub getname {
	my $self = shift;
	return $self->{_name};
}

#Name für dot-Ausgabe, in der Form <vsysname>vr<name> 
sub getdotname {
	my $self = shift;
	return "\"".$self->{_vsys}->getname().'vr'.$self->{_name}."\"";
}

#Name für dot-Ausgabe, in der Form <vsysname>vr<name>, Router haben kein Ziel.
#Ist aber nötig, da beim Zeichnen der Routen nicht geprüft wird, ob es sich um einen Router oder eine Zone handelt.
sub getdot_target_name {
	my $self = shift;
	return "\"".$self->{_vsys}->getname().'vr'.$self->{_name}."\"";
}

#Die Kanten zwischen den Ecken erhalten ein Gewicht (Eckengewicht * Eckengewicht), daher 
#werden Kanten zwischen Routern kürzer.
sub getdotweight {
	my $self = shift;
	return 3;
}

#Setzt einige Werte für den Router:
sub set {
	my $self = shift;
	$_ = shift;
	my $rootvsys = shift;
	$self->{_sharable} = "1" if /^sharable/;
	$self->{_auto_route_export} = "true" if /^auto-route-export/;
	$self->{_id} = $1 if /^id ([0-9]+)/;
	if ( /^route $main::name vrouter $main::name (.*)/ ) {
		my $net = $1;
		my $target = $2;
		$net =~ s/"//g;
		$target =~ s/"//g;
		$self->{_route}{$net} = $rootvsys->getvrouterbyname($target);
	}
}

sub unset {
	my $self = shift;
	$_ = shift;
	$self->{_sharable} = "0" if /^sharable$/;
	$self->{_auto_route_export} = "0" if /^auto-route-export/;
}

sub issharable {
	my $self = shift;
	return $self->{_sharable};
}

sub getwidth {
        my $self = shift;
        my $width = 91;
		my $length = 0;
		
		my $net;
		foreach $net (sort(keys(%{$self->{_route}}))) {
			$length = length("$net -> ".$$self{_route}{$net}->getname()) > $length ? length("$net -> ".$$self{_route}{$net}->getname()) : $length;
		}

        $width += 7 * $length;
        return $width;
}

#Trägt den Router in die SVG ein.
sub generate_svg {
	my ($self, $svg, $xpos, $ypos, $routes, $opt, $config) = @_;
	my $color;
	if ($self->issharable()) {
		$color = $$config{color_vrouter_sharable};
	} else {
		$color = $$config{color_vrouter};
	}
	
	$self->{_xpos} = $xpos;
	$self->{_ypos} = $ypos;
	
	my $color_route = $$config{color_route};
	my $height = $self->getheight();
	my $width = $self->getwidth();
	
	my $svg_vrouter = $svg->group(id=>"vr_$self->{_name}");
	$svg_vrouter->ellipse(cx=>$xpos+46,cy=>$ypos+23,rx=>45,ry=>22,fill=>"$color");
	$svg_vrouter->text(x=>$xpos+20,y=>$ypos+28, -cdata=>"$self->{_name}","font-size"=>12, font=>"Verdana");
    
    my $routecount = (keys(%{$self->{_route}}));
    if ($routecount > 0) {
    	my $subwidth = $self->getsubwidth() -5 ;
    	my $subheight = 5 +  $self->getsubheight() - 5;
    	my $yoffset = 18;
    	my $text;
    	my $net;
   
   		my $svg_routing = $svg_vrouter->group(id=>"Routing_$self->{_name}");
   		$svg_routing->rect(x=>80+$xpos, y=>4+$ypos, width=>$subwidth, height=>$subheight, fill=>"$color_route", "stroke"=>"black");
        foreach $net (sort(keys(%{$self->{_route}}))) {
        	$text = "$net -> ".$$self{_route}{$net}->getname();
        	$svg_routing->text(x=>$xpos+85,y=>$ypos+$yoffset, -cdata=>"$text","font-size"=>12, font=>"Verdana");
			$yoffset += 15;
        }
    }
	foreach my $route (keys(%{$self->{_route}})) {
		my @line = ($self , $$self{_route}{$route});
		push  (@{$routes}, \@line);
	}

}


#Trägt den Router in die DOT-Datei ein.
sub generate_dot {
	my ($self, $DOT, $routes, $opt, $config) = @_;
	my $color;
	if ($self->issharable()) {
		$color = $$config{color_vrouter_sharable};
	} else {
		$color = $$config{color_vrouter};
	}
	
	print $DOT $self->getdotname()." [shape=octagon, style=filled, label=\"".$self->getname()."\", color=$color];\n";
	
 
	foreach my $route (keys(%{$self->{_route}})) {
		my @line = ($self , $$self{_route}{$route});
		push  (@{$routes}, \@line);
	}

}


#Untere Koordinaten, für die Routen nach unten.
sub getdowncoord {
	my $self = shift;
	return ($self->{_xpos} + 45, $self->{_ypos} + 44);
}

#Linke Koordinaten, für die Routen nach links.
sub getleftcoord {
	my $self = shift;
	return ($self->{_xpos} +1, $self->{_ypos} + 23);
}

#Koordinaten(unten links)
sub getcoord {
	my $self = shift;
	return ($self->{_xpos}, $self->{_ypos});
}

#Gesamthöhe
sub getheight {
	my $self = shift;
	my $height = (keys(%{$self->{_route}}));
	$height = $height * 15 + 15;
	return $height > 60 ? $height : 60;
	
}

#Höhe der Routen
sub getsubheight {
	my $self = shift;
	my $height = (keys(%{$self->{_route}}));
	$height = $height * 15 + 5;
	return $height;
}

#Breite der Routen
sub getsubwidth {
        my $self = shift;
        my $width = 5;
		my $length = 0;
		my $net;
		foreach $net (sort(keys(%{$self->{_route}}))) {
			$length = length("$net -> ".$$self{_route}{$net}->getname()) > $length ? length("$net -> ".$$self{_route}{$net}->getname()) : $length;
		}
        $width += 7 * $length;
        return $width;
}

sub print {
	my $self = shift;
	print "--------------------------------------------\n";
	print "VRouter-Name: $self->{_name}\n";
	print "Sharable: $self->{_sharable}\n";
	print "Auto-Route-Export: $self->{_auto_route_export}\n";
	print "ID: $self->{_id}\n" if (defined($self->{_id}));
	
	my $net;
	foreach $net (sort(keys(%{$self->{_route}}))) {
		print "Route: $net -> ",$$self{_route}{$net}->getname(),"\n";
	}

}


1;

=pod

=head1 NAME

B<jp_vrouter.pm> - Klasse, die einen virtuellen Router darstellt

=head1 SYNOPSIS

=over 8

=item B<jp_vrouter::new>I<($name, $vsys)>

=item B<jp_vrouter::getname>I<()>

=item B<jp_vrouter::getdotname>I<()>

=item B<jp_vrouter::getdot_target_name>I<()>

=item B<jp_vrouter::getdotweight>I<()>

=item B<jp_vrouter::issharable>I<()>

=item B<jp_vrouter::set>I<($command, $rootvsys)>

=item B<jp_vrouter::unset>I<($command)>

=item B<jp_vrouter::getwidth>I<()>

=item B<jp_vrouter::getheight>I<()>

=item B<jp_vrouter::getsubwidth>I<()>

=item B<jp_vrouter::getsubheight>I<()>

=item B<jp_vrouter::generate_svg>I<($svg, $xpos, $ypos, $routes, $opt, $config)>

=item B<jp_vrouter::generate_dot>I<($DOT, $routes, $opt, $config)>

=item B<jp_vrouter::getleftcoord>I<()>

=item B<jp_vrouter::getdowncoord>I<()>

=item B<jp_vrouter::getcoord>I<()>

=item B<jp_vrouter::print>I<()>

=back

=head1 DESCRIPTION

Objekte der Klasse B<jp_vrouter.pm> stellen einen virtuellen Router in dem System dar.

=head1 COMMANDS

=over 8

=item B<new>

Erzeugt den Router.

=item B<getname>

Gibt den Namen des Routers zurück

=item B<getdotname>

Gibt den Namen des Routers zurück, wie er in der dot-Ausgabe als interner Begriff genutzt wird. Der Name ist eindeutig.

=item B<getdot_target_name>

Gibt den Namen des Routers zurück, wie er in der dot-Ausgabe als interner Begriff genutzt wird, 
mit einem Ansatzpunkt für die Routen. Der Name ist eindeutig.

=item B<getdotweight>

Durch die Gewichtung wird den Routen zwischen 2 Objekten eine Gewichtung verliehen, je nach Renderer wird versucht, diese kürzer zu halten.
VRouter haben eine höhere Gewichtung als Zonen, so dass diese näher beieinander gezeichnet werden.

=item B<issharable>

True, wenn der Router I<shared> ist.

=item B<set/unset>

Setzt verschiedene Werte für den Router oder löscht diese.

=item B<getwidh/getheight>

Liefert die Höhe/Breite des Routers in der SVG-Grafik. In der Höhe ist bereits ein Abstand von 5 Pixeln nach unten enthalten.

=item B<getsubwidh/getsubheight>

Liefert die Höhe/Breite des Kastens mit den Routen in der SVG-Grafik.

=item B<generate_svg>

Erzeugt die SVG-Ausgabe für den Router. 

=item B<generate_dot>

Erzeugt die DOT-Ausgabe für den Router.

=item B<getleftcoord>

Liefert die Koordinaten, wo Routen enden, die von links zu dem Router gehen.

=item B<getdowncoord>

Liefert die Koordinaten, wo Routen enden, die von unten zu dem Router gehen.

=item B<getcoord>

Liefert die Koordinaten des Routers.

=item B<print>

Gibt die Informationen des Routers auf STDOUT aus.

=back

=head1 OPTIONS

=over 8

=item B<$name>  I<String>

Der Name des Routers.

=item B<$vsys> I<Referenz>

Das VSys, in dem sich der Router befindet.

=item B<$command> I<String>

Befehl, um einen Wert des Routers zu setzen, Syntax wie im CLI nur ohne C<[un]set $name>

=item B<$svg> I<Referenz>

Refernz auf das SVG-Objekt, in dem der Router gezeichnet werden soll.

=item B<$xpos> I<Integer>, B<$ypos> I<Integer>

Die Koordinaten der linken oberen Ecke dedes Routers in der gesamten Grafik.

=item B<$routes> I<Array>

Eine Liste, in der alle Routen eingetragen werden.

=item B<$opt> I<Hash>

Die Optionen, die über die Kommandozeile übergeben wurden

=item B<$config> I<Hash>

Die Farben für die Ausgabe, können in der Konfigurationsdatei gesetzt werden, siehe L<jp_parser.conf>(5)

=item B<$DOT> I<Filehandle>

Ein Filehandle, in das die dot-Ausgabe geschrieben wird.

=back

=head1 EXAMPLES
 
Zeichnet den Router in der Grafik I<$svg> an der Stelle 200,300:
 
 $vrouter->generate_svg($svg, 200, 300, $routes, $opt, $config);

=head1 SEE ALSO

L<jp_parser(1)>, L<jp_parser.conf(5)>

=head1 REQUIRES

Perl 5.8

F<jp_parser>

=head1 AUTHOR and COPYRIGHT

     
     Till Potinius
     <justamail@justmoments.de>

     Copyright (c) 2007 Till Potinius

=cut