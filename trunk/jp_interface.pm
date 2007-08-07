package jp_interface;
use warnings;
use strict;

#Ein Interface-Objekt ist ein (virtuelles) Interface.  

sub new {
	my ($class, $name) = @_;
	my $self = {
		_name => undef,
		_vlan => undef,
		_zone => undef,
		_group => undef,
		_ip => undef,
		_ip_manageable => undef,
		_route => undef,
		_sub_if => undef,
	};
	$self->{_name} = $name if defined($name);
	$self->{_ip} = [];
	$self->{_sub_if} = [];
	bless($self, $class);
}

sub getname {
	my $self = shift;
	return $self->{_name};
}

sub getgroup {
	my $self = shift;
	return $self->{_group};
}

#Fügt ein Interface zu diesem Interface hinzu, setzt implizit vorraus, dass es sich um eine Gruppe handelt
sub add_sub_if {
	my $self = shift;
	my $sub_if = shift;
	push ( @{$self->{_sub_if}}, $sub_if);
}

#Setzt verschiedene Werte für das Interface wie den VLAN-Tag
sub set {
	my $self = shift;
	my $param = shift;
	#VLAN-Tag und Zone:
	if ($param =~ /^tag ([0-9]+) zone $main::name/ ) {
		$self->{_tag} = $1;
		my $zone = $2;
		$zone =~ s/"//g;
		$self->{_zone} = $zone;
	#Nur Zone
	} elsif ($param =~ /^zone $main::name/){
		my $zone = $1;
		$zone =~ s/"//g;
		$self->{_zone} = $zone;
	#Gruppe
	} elsif ($param =~ /^group $main::name/){
		my $group = $1;
		$group =~ s/"//g;
		$self->{_group} = $group;
	# IP
	} elsif ($param =~ /ip manageable/) {
		$self->{_ip_manageable} = " ";
	} elsif ($param =~ /manage $main::name/) {
		$self->{_ip_manageable} .= "$1 ";
	} elsif ($param =~ /ip $main::name/) {
		my $ip = $1;
		$ip =~ s/"//g;
		push ( @{$self->{_ip}}, $ip);
	# Routing ?
	} elsif ($param =~ /^route$/) {
		$self->{_route} = "true";
	}

}


#Liefert die Breite des Interfaces in der Grafik
#Für ein Zeichen wird eine Breite von ca. 8 Pixeln angenommen.
sub getwidth {
        my $self = shift;
        my $width = 20;
        my $sublength = 0;
        my $groupname = $self->{_group} ? $self->{_group} : "";
        my $ipm = $self->{_ip_manageable} ? $self->{_ip_manageable} : "";
		my $length = length($self->{_name}) > length($groupname) ? length($self->{_name}) : length($groupname);
		$length = $length > length($ipm) ? $length : length($ipm);
        
        foreach my $ip (@{$self->{_ip}}) {
			$sublength = length($ip) > $sublength ? length($ip) : $sublength;
		}
        $length = $length > $sublength ? $length : $sublength;
        
        foreach my $if (@{$self->{_sub_if}}) {
			$sublength = length($if->getname()) > $sublength ? length($if->getname()) : $sublength;
		}
        
        $length = $length > $sublength ? $length : $sublength;
        
        $width += 8 * $length;
        return $width;
}

#Trägt das Interface in die SVG ein.
sub generate_svg {
        my ($self, $svg, $xpos, $ypos, $opt, $config) = @_;
        my $height = $self->getheight() -5;
        my $width = $self->getwidth();
        my $color = $$config{color_interface};
        
        my $svg_if = $svg->group(id=>"interface$self->{_name}");
        $svg_if->rect(x=>$xpos, y=>$ypos, width=>$width, height=>$height, fill=>"$color");
        
		my $yoffset = 15 + $ypos;
		$svg_if->text(x=>$xpos+2, y=>$yoffset, -cdata=>"$self->{_name}", font=>"Verdana");
	
		$yoffset += 16;

		if ($self->{_group}) {
			$svg_if->text(x=>$xpos+6, y=>$yoffset, -cdata=>"Group: $self->{_group}", "font-size"=>12, font=>"Verdana");
			$yoffset += 16;
		}
		
		if ($self->{_tag}) {
			$svg_if->text(x=>$xpos+6, y=>$yoffset, -cdata=>"VLAN-Tag: $self->{_tag}", "font-size"=>12, font=>"Verdana");
			$yoffset += 16;
		}
		
		foreach my $if (@{$self->{_sub_if}}) {
			my $if_name = $if->getname();
			$svg_if->text(x=>$xpos+6, y=>$yoffset, -cdata=>"SubIf: $if_name", "font-size"=>12, font=>"Verdana");
			$yoffset += 16;
		}
		
		foreach my $ip (@{$self->{_ip}}) {
			$svg_if->text(x=>$xpos+6, y=>$yoffset, -cdata=>"IP: $ip", "font-size"=>12, font=>"Verdana");
			$yoffset += 16;
		}
		
		if ($self->{_ip_manageable}) {
			$svg_if->text(x=>$xpos+6, y=>$yoffset, -cdata=>"Manage:$self->{_ip_manageable}", "font-size"=>12, font=>"Verdana");
			$yoffset += 16;
		}

}

#Dieser Text dient dazu, das Interface als Record in der dot-Ausgabe darzustellen:
sub get_dot_text{
	my $self = shift;
	my $opt = shift;
	my $text = "";
	$text .= "|VLAN-Tag: $self->{_tag}" if ($self->{_tag});
	foreach my $ip (@{$self->{_ip}}) {
		$text .= "|IP: $ip";
	}
	$text .= "|Manage: $self->{_ip_manageable}" if ($self->{_ip_manageable});
	foreach my $if (@{$self->{_sub_if}}) {
		$text .= "|IF: ".$if->getname();
	}
	return "$text";
}

sub getheight {
    my $self = shift;
    my $height = 25;
	$height += 16 if $self->{_group};
	$height += 16 if $self->{_ip_manageable};   
	$height += 16 if $self->{_tag}; 
	my $sub_count = @{$self->{_ip}};
	$sub_count += @{$self->{_sub_if}};
	$height += 16 * $sub_count;
	return $height;
}

sub unset {
	my $self = shift;
	my $param = shift;
	$self->{_ip_manageable} = "" if ($param =~ /^ip manageable/);
}

sub getzone {
	my $self =shift;
	return $self->{_zone};
}

sub print {
	my $self = shift;
	print "--------------------------------------------\n";
	print "Interface-Name: ".$self->{_name}."\n";
	print "VLAN: $self->{_tag}\n" if (defined $self->{_tag});
	print "Zone: $self->{_zone}\n" if (defined $self->{_zone});
	print "Group: $self->{_group}\n" if (defined $self->{_group});
	print "Manage: $self->{_ip_manageable}\n" if (defined $self->{_ip_manageable});
	map{print "IP: $_\n"}(@{$self->{_ip}});
	map{print "SubInterface: ".$_->getname()."\n"}(@{$self->{_sub_if}});
	print "Route: $self->{_route}\n" if (defined $self->{_route});
}


1;

=pod

=head1 NAME

B<jp_interface.pm> - Klasse, die ein Interface darstellt

=head1 SYNOPSIS

=over 8

=item B<jp_interface::new>I<($name)>

=item B<jp_interface::getname>I<()>

=item B<jp_interface::getgroup>I<()>

=item B<jp_interface::add_sub_if>I<($sub_if)>

=item B<jp_interface::set>I<($param)>

=item B<jp_interface::unset>I<($param)>

=item B<jp_interface::getwidth>I<()>

=item B<jp_interface::getheight>I<()>

=item B<jp_interface::generate_svg>I<($svg, $xpos, $ypos, $opt, $config)>

=item B<jp_interface::get_dot_text>I<($opt)>

=item B<jp_interface::getzone>I<()>

=item B<jp_interface::print>I<()>

=back

=head1 DESCRIPTION

Objekte der Klasse Interface stellen ein (virtuelles) Interface in dem System dar.

=head1 COMMANDS

=over 8

=item B<new>

Erzeugt das Objekt.

=item B<getname>

Gibt den Namen des Interfaces zurück

=item B<getgroup>

Gibt die Gruppe zurück, in der sich das Interface befindet.

=item B<add_sub_if>

Fügt ein bestehendes Interface zu einem Interface hinzu. 
Damit wird das übergeordnete Interface automatisch zu einer Interface-Gruppe

=item B<set/unset>

Setzt verschiedene Werte für das Interface oder löscht diese.

=item B<getwidh/getheight>

Liefert die Höhe/Breite des Interfaces in der SVG-Grafik. In der Höhe ist bereits ein Abstand von 5 Pixeln nach unten enthalten.

=item B<generate_svg>

Erzeugt die SVG-Ausgabe für das Interface. 

=item B<get_dot_text>

Erzeugt die DOT-Ausgabe für das Interface und liefert sie als String zurück.

=item B<getzone>

Liefert die Zone, in der sich das Interface befindet.

=item B<print>

Gibt die Informationen des Interfaces auf STDOUT aus.

=back

=head1 OPTIONS

=over 8

=item B<$name>  I<String>

Der Name des Interfaces

=item B<$sub_if> I<Referenz>

Referenz auf ein Interface

=item B<$param> I<String>

Befehl, um einen Wert des Interfaces zu setzen, Syntax wie im CLI nur ohne C<[un]set $name>

=item B<$svg> I<Referenz>

Refernz auf das SVG-Objekt, in dem das Interface gezeichnet werden soll.

=item B<$xpos> I<Integer>, B<$ypos> I<Integer>

Die Koordinaten der linken oberen Ecke des Interfaces in der gesamten Grafik.

=item B<$opt> I<Hash>

Die Optionen, die über die Kommandozeile übergeben wurden

=item B<$config> I<Hash>

Die Farben für die Ausgabe, können in der Konfigurationsdatei gesetzt werden, siehe L<jp_parser.conf>

=back

=head1 EXAMPLES
 
    Erzeugt ein Interface namens I<Beispielinterface>:
 
          $if = jp_interface->new('Beispielinterface');
 
    Und weist diesem den IP-Bereich 192.168.1.0/24 zu:

          $if->set('ip 192.168.1.0/24');

=head1 SEE ALSO

L<jp_parser(1)>

=head1 REQUIRES

Perl 5.8

F<jp_parser>

=head1 AUTHOR and COPYRIGHT

     
     Till Potinius
     <justamail@justmoments.de>

     Copyright (c) 2007 Till Potinius



=cut
