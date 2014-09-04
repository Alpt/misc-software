#!/usr/bin/perl
#
# Un interfaccia a festival per Irssi, ottimizzata per l'italiano.
#
# Questo codice deriva da xchat_speak.pl:
# http://www.nogas.org/xchat_speak/
#
# Il nuovo codice e' stato scritto da AlpT (@freaknet.org)
#
# http://www.freaknet.org/alpt/src/xchestival/

########### CONFIGURE THIS BIT!
# Adjust this so it reflects the location of your festival executable
$festival='/usr/bin/festival --pipe';

$home=`echo ~`;   # la tua home
$home =~ s/\n//;  # toglia la newline finale
# Il file usato da xchestival per le sostituzioni
$xchestival_sub = "$home/.irssi/xchestival.sub"; 
$xchestival_sub_default="/usr/share/xchestival/xchestival.sub";

$lang="it";  #"en" if english

# Adjust this to your preferred Voice 
$VOICE = "voice_lp_mbrola"; 	# Voce della femmina italiana

#$VOICE = "voice_pc_mbrola"; 	# voce del maschio italiano
#$VOICE = "voice_lp_diphone"; 	# voce del robot femmina italiano
#$VOICE = "voice_pc_diphone"; 	# voce del robot maschio italiano
#$VOICE = "voice_rab_diphone"; # A muted British-esque voice
#$VOICE = "voice_kal_diphone"; # An American male voice
#$VOICE = "voice_ked_diphone"; # A less mechanical American male voice

# Smaller numbers = faster speech
$SPEED = ".99";

########## YOU CAN STOP CONFIGURING!

%IRSSI = (
    name        => 'speak',
    authors     => 'AlpT',
    contact     => 'alpt (@freaknet org)',
    description => 'Irrsi parla',
    license     => 'GPL',
    url         => 'http://www.freaknet.org/alpt/src/xchestival/',
);  

use Irssi;
use Irssi::Irc;
#use Irssi::UI;

sub evento {
  my ($server, $data) = @_;
  if($data !~ /PRIVMSG/ &&  $data !~ /TOPIC/ && $data !~ /JOIN/  &&
          $data !~ /NICK/ && $data !~ /INVITE/ && $data !~ /PART/ &&
          $data !~ /QUIT/ ) {
	  return; 
  }
  &speak($data);
}

$already_loaded=0;
$spaccaballe=1;
$do_queue_mutex=0;
$pidof_festival="";
$lastchan="";
$lastquery="";
$buf_lines = "10";  # Quante linee svuota ogni volta dal buffer del canale.
$says="dice";
$query_says="ti dice";
$line_highlight="";
$MY_NAME = "irssi_speak.pl";
$VERSION = "0.3.6";

%chan_queue = ();
%channels = ();
$lastthingsaid = "";
%lastwho = ();
%smilesub = ();
%wordsub = ();



Irssi::command_bind("muto", \&cmd_speechoff); 
Irssi::command_bind("voce", \&cmd_speechvoice); 
Irssi::command_bind("velocita",\&cmd_speechspeed); 
Irssi::command_bind("censure", \&cmd_censure);
Irssi::command_bind("parla", \&cmd_speechon); 
Irssi::command_bind("associazioni", \&load_sub);
Irssi::command_bind("associa", \&write_sub); 
Irssi::command_bind("seleziona", \&cmd_highlight); 
Irssi::command_bind("solotesto", cmd_solotesto);
Irssi::command_bind("parlatutto", cmd_parlatutto);
Irssi::command_bind("parlasoloin", cmq_parlasoloin); 
Irssi::signal_add("server incoming", "evento");

sub cmd_parlatutto {
	$spaccaballe=1;
	Irssi::print("   Comunico anche: topic, join, cambio nick, invite, part e quit\n");
}
sub cmd_solotesto {
	$spaccaballe=0;
	Irssi::print("   Non dico: topic, join, cambio nick, invite, part e quit\n");
}

sub update_chan_list {
	my $linein=$_[0], $c, $status;

	if(!$linein) { 
		$status="on"; 
	} else {
		$status=$linein;
	}
	
	@chan_list=Irssi::channels();
	foreach my $ch (@chan_list) {
		$c = $ch->{name};
		if($c =~ /^[#+]/) {
			$channels{$c}=$status; 
#			Irssi::print("$c == $channels{$c}");
		}
		
	}
}

sub cmq_parlasoloin {
	my $linein=$_[0];
	if(!$linein) { return 0; }
	&cmd_speechoff();
	&cmd_speechon($linein);
}

sub cmd_highlight {
	my $linein=$_[0];
	
	if(!$linein) {
		Irssi::print("La selezione delle frasi e' disabilitata");
		undef $line_highlight; 
		return; 
	}

	$line_highlight=$linein;
	Irssi::print("Ora leggero' solo le frasi che contengono: $line_highlight");
}

sub load_sub {
	my $linein=$_[0], $smi, $line;
	if(!$linein) { $linein = $xchestival_sub; }

	open(SUBFD, "< $linein")
	|| do {
			Irssi::print("*E* Error opening $linein : $!");
			Irssi::print("*E* trying with $xchestival_sub_default");
	        $linein = $xchestival_sub_default;
         	open(SUBFD, "< $linein")
			|| do {
                     Irssi::print("*E* Error opening $xchestival_sub_default : $!");
	                 return; 
				  };
	      };

	Irssi::print("Il file delle sostituzioni ora e': $linein");
	%smilesub = ();
	%wordsub = ();

	while(<SUBFD>) {
		s/[\r\n]//g;
		warning("whitespace follows the \\ at the end-of-line.\nIf you
			meant to have a line continuation, remove the trailing
			whitespace.")
		if /\\\s+$/;
		$line = "$_\n" unless /^#/;
		s/#.*//;                # remove comments
		s/^\s+//;               # remove leading white space
		s/\s+$//;               # remove trailing white space
		s/\s+/ /g;              # canonify
		next if /^$/;

		$line =~ s/[\r\n]//g;
		$smi=0;
		if($line =~ /^SMILE:/) { $line =~ s/SMILE://; $smi=1; }
		$line =~ s/^\s+//;
		
		($a, $b) = split(/\s*==\s*/, "$line", 2);

		if($smi) { 
			$smilesub{$a} = $b; 	
		} else {
			$wordsub{$a} = $b; 
		}
	}
	close SUBFD;
}

sub write_sub {
	my $sub=$_[0] ,$linein, $line;
	
	if(!$sub) { return; }
	$linein = $xchestival_sub;

	open(SUBFD, ">>$linein") || do { Irssi::print("*E* Error opening $linein : $!"); return; };
	
	print SUBFD "$sub\n";

	$line = $sub;
	if($line =~ /^SMILE:/) { $line =~ s/SMILE://; $smi=1; }
	$line =~ s/^\s+//;
	($a, $b) = split(/\s*==\s*/, "$line", 2);
	if($smi) {
		$smilesub{$a} = $b; 
		Irssi::print("smile $a == $b");
	} else {
		$wordsub{$a} = $b;
		Irssi::print("$a == $b");
	}
	close SUBFD;
}

sub smile_sub {
	my $linein=$_[0];
	my $sub;

	foreach my $word (split(' ',$linein)) {
		$sub=$smilesub{$word} unless $sub;
		if ($sub) {
			return $sub;
		}
		undef($sub);
	}
	return $sub;
}

sub spch_substitute {
	my $linein=$_[0];
	my ($sub,$lineout);
	foreach my $word (split(' ',$linein)) {
		#	$sub=$wordsub{$word};
		$sub=$wordsub{$word} unless $sub;
		if ($sub) {
			$lineout.=" $sub ";
		} else {
			$lineout.=" $word ";
		}
		undef($sub);
	}
	return($lineout);
}

sub cmd_censure {
	if(!$already_loaded) { return 0; }
	Irssi::print("Questa e' la lista dei canali dove NON posso parlare:");
	@key=keys(%channels);
	foreach my $ch (@key) {
		$channels{$ch} eq "off" && Irssi::print("   $ch\n");
	}
}

sub cmd_speechvoice {
	if(!$_[0]) { return 0; }
	$says="dice";
	$query_says="ti dice";
	$lang="it";
	if ( $_[0] eq "donna" )
	{
		$VOICE = "voice_lp_mbrola";
		$ghgh="Voce settata a femmina italiana.";
	}
	if( $_[0] eq "uomo" )
	{	
		$VOICE = "voice_pc_mbrola"; 
		$ghgh="Voce settata a masculo italiano.";
	}
	if( $_[0] eq "uomo_robot" )
	{		
		$VOICE = "voice_pc_diphone"; 
		$ghgh="Voce settata a robot maschio italiano";
	}
	if ( $_[0] eq "donna_robot" )
	{	$VOICE = "voice_lp_diphone"; 
		$ghgh="Voce settata a robot femmina italiana";
	}

	if ( $_[0] eq "inglese" )
	{		$VOICE = "voice_ked_diphone"; 
		$ghgh="Voice setted to brute yankee";
		$says="says";
		$query_says="says";
		$lang="en";
	}

	Irssi::print("*** Voice $VOICE");
	print SPEECH "($VOICE)\n";
	&speak("$ghgh");
}

sub cmd_speechspeed {
	if(!$_[0]) { return 0; }
	$SPEED=$_[0];
	if($SPEED > 3) {
		&parla("Non posso settare quella velocita', sarei troppo lenta!", "1");
		Irssi::print("Non posso settare quella velocita', sarei troppo lenta!", "1");
		return 0;
	}
	if($SPEED < 0.40) {
		&parla("Non posso settare quella velocita', sarei troppo veloce!", "1");
		Irssi::print("Non posso settare quella velocita', sarei troppo veloce!");
		return 0;
	}
	Irssi::print("*** Speed $SPEED");
	print SPEECH "(Parameter.set 'Duration_Stretch $SPEED)\n";
	&parla("Velocita' settata a: $SPEED", "1");
	%lastwho = ();
}		

sub cmd_speechon {
	my $linein=$_[0];


	if (!defined($speech_pipe)) {
		open(SPEECH,"|$festival 2>&1 >/dev/null") || do { &print("*E* Error opening pipe to $festival"); return; };
		$pidof_festival=`pidof -s festival`;
		$pidof_festival =~ s/\n//;
		$fhcp=select(SPEECH);
		$|=1;
		select($fhcp);
		$speech_pipe=1;
		Irssi::print("*** Speech activated!");
		if(!$already_loaded) {
			$already_loaded=1;
		}
		print SPEECH "($VOICE)\n";
		print SPEECH "(Parameter.set 'Duration_Stretch $SPEED)\n";
		
		if(!$linein) { 
			$channels{"1"}="on";
			&update_chan_list("on");
			@key=keys(%channels);
			foreach my $ch (@key) {	$channels{$ch}="on"; }

			%lastwho = ();
			print SPEECH "(SayText \"Ora  comincio a parlare\")\n";
			&load_sub($xchestival_sub);
			return(1); 
		}
	}

	if($linein) {
		$linein =~ s/ //g;
		$channels{$linein} = "on";
		Irssi::print("Ora parlero' nel canale $linein");
		$linein =~ s/#//;
		print SPEECH "(SayText \"Ora parlero' nel canale $linein\")\n";
		$lastwho{$linein} = "";
		return 0;
	} else {
		@key=keys(%channels);
		foreach my $ch (@key) {	$channels{$ch}="on";	}
		Irssi::print("Ora parlero' in tutti i canali");
		print SPEECH "(SayText \"Ora parlero' in tutti i canali\")\n";
		%lastwho = ();
	}
}

sub cmd_speechoff {
	my $linein=$_[0];

	if(defined($speech_pipe)) {
		if($linein) {
			$linein =~ s/ //g;
			$channels{$linein} = "off";
			@{ $chan_queue{$linein} } = undef;
			Irssi::print("Ora staro' muta nel canale $linein");
			$linein =~ s/#//;
			&parla("Ora staro' muta nel canale $linein", "1");
			$lastwho{$linein} = "";
			return 0;
		} else {
			&update_chan_list("off");
			@key=keys(%channels);
			foreach my $ch (@key) { 
				$channels{$ch}="off"; 
				@{ $chan_queue{$ch} } = undef;
			}
			Irssi::print("*** Ora mi disattivo");
			print SPEECH "(SayText \"Ora mi disattivo\")\n";
			%lastwho = ();
			undef($speech_pipe);
			if($pidof_festival) {
				kill 15, $pidof_festival;
				$pidof_festival="";
			}
			close(SPEECH);
		}

	}

	return(1);
}

sub do_chan_queue {
	if($do_queue_mutex) { return 0; }
	$do_queue_mutex=1;
	
	@key=keys(%chan_queue);
	foreach my $ch (@key) { 
		my $sayit="cacca", $i=0, $chh="";
		while($sayit && $i < $buf_lines) {
			$sayit=shift @{ $chan_queue{$ch} }; 
			if($channels{$ch} eq "off" || !$sayit) { last; }
			if($sayit && (($channels{$ch} eq "on") || $ch eq "1")) {
				if(!$i && ($lastchan ne $ch) && ($ch ne "1") &&
				($ch =~ /^[#+]/)) {
					($chh = $ch) =~ s/[^a-zA-Z]//g;
					print SPEECH "(SayText \"Nel canale $chh, \")\n"; 
				}
				#		Irssi::print( "ch: $ch, last: $lastchan, $sayit");

				print SPEECH "(SayText \"$sayit\")\n";
				$lastchan=$ch;
				$i++;
			}
		}
	}
	$do_queue_mutex=0;
}

sub parla {
	my $linein=$_[0];
	my $can=$_[1];

	if(!$can) { $can="1"; }
	push @{ $chan_queue{$can} }, $linein;

	&do_chan_queue();
}

sub togli_merda {
	my $linein=$_[0];

	# Togliamo tutta la MMERDA dalla stringa,
	# Questa REGEX DELLA MORTE MALE e' stata scritta da quel pazzo di sand,
	# lode a lui o/
#	$linein =~ s/(?:\s|\A)\S*?[^a-z\s]+\S*?(?<![\.,:;'`])(?:\s|\Z)/ /gi;
#	$linein =~ s/(?:\s|\A)\S*?[^a-z\s]+\S*?(?<![\.,:;'`?!])(?:\s|\Z)/ /gi;
#	$linein =~ s/(?:\s|\A)\S*?[^a-z\s']+\S*?(?<![\.,:;'`?!])(?:\s|\Z)/ /gi;
	$linein =~ s/(?:\s|\A)\S*?[^a-z0-9\s')("]+\S*?(?<![\.,:;'`?!])(?:\s|\Z)/ /gi;
	return $linein;
}

sub speak {
	defined($speech_pipe) || return;
	my $speakline;
	my $smile, $chan="1", $query=0, $qualcosa=0;
	$speakline=$_[0];
	$speakline = lc($speakline);
	

	if("$lastthingsaid" eq "$speakline") {	return 0; }
	$lastthingsaid = $speakline;


	#### Escludi i canali e le query azzittite #####
	if ($speakline=~/^:(.*)!.*privmsg[^:]*[#+]([a-z0-9_A-Z]*)/) {
		$chan = "#"."$2";
		if($channels{$chan} eq "off") { return 0; }
	} else {
		if ($speakline=~/^:(.*)!.*privmsg[^:]*[a-z0-9_A-Z]*/) {
			$chan=$1;
			$query=1;
			if($channels{$chan} eq "off") { return 0; }
		}
	}
	if ($speakline=~/^:(.*)!.*part[^:]*[#+]([a-z0-9_A-Z]*)/) {
		$chan = "#"."$2";
		if($channels{$chan} eq "off") { return 0; }
	}
	if ($speakline=~/^:(.*)!.*topic[^:]*[#+]([a-z0-9_A-Z]*)/) {
		$chan = "#"."$2";
		if($channels{$chan} eq "off") { return 0; }
	}
	if ($speakline=~/^:(.*)!.*join[^:]*:(.*)/) {
		$chan = "#"."$2";
		if($channels{$chan} eq "off") { return 0; }
	}

	$channels{$chan}="on";

	if(!$query) { $lastquery=""; }

	if ($speakline=~/^:(.*)!.*privmsg[^:]*:(.*)/) { 
		$uno=$1; 
		$smile=&smile_sub($2);
		$due = &togli_merda($2);

		if($speakline =~ /:.action /) {
			$speakline =~ s/.action//;
			if($speakline =~/^:(.*)!.*privmsg[^:]*:(.*)/) {
				$uno=$1; $due = $2;
				$uno =~ s/[^a-z]//g;
				$speakline ="$uno $due"; 
				$lastwho{$chan} = "";
				if($query) { $lastquery=""; }
			}
		} else {
			$uno =~ s/[^a-z]//g;
			if($query) { $speakline="$uno $query_says, $due"; 
			} else {$speakline="$uno $says, $due"; }
			if(!$query && $lastwho{$chan} eq "$uno") { $speakline="$due"; }
			if($query && $lastquery eq "$chan") { $speakline="$due"; }
			if($query) { $lastquery=$chan; }
			$lastwho{$chan} = $uno;
		}
		($t=$due)=~ s/ //g;
		if(!$due || !$t) { if($smile) { &parla("$uno $smile", "$chan"); } return 0; }
		$qualcosa=1;
	}

	if ($spaccaballe) {
	if ($speakline=~/^:(.*)!.*topic[^:]*:(.*)/) {
		$uno=$1;
		$smile=&smile_sub($2);
		$due = &togli_merda($2);
		$speakline="il nuovo topicc e': $due"; 
		$uno =~ s/[^a-z]//g;
		($t=$due)=~ s/ //g;
		if(!$due || !$t) { if($smile) { &parla("$uno $smile","$chan"); } return 0; }
		$lastwho{$chan} = "";
	}
	if ($speakline=~/^:(.*)!.*join[^:]*:(.*)/) { 
		$uno=$1; $due=$2;
		$uno =~ s/[^a-z]//g;
		$speakline="$uno ha gioinato"; 
		$lastwho{$chan} = "";
	}
	if ($speakline=~/^:(.*)!.*nick[^:]*:(.*)/) { 
		$uno=$1; $due = $2;
		$uno =~ s/[^a-z]//g;
		$due =~ s/[^a-z]//g;
		$speakline="$uno ha cambiato il nick in  $due"; 
		$lastwho{$chan} = "";
	}
	if ($speakline=~/^:(.*)!.*invite[^:]*:(.*)/) { 
		$uno=$1;
		$uno =~ s/[^a-z]//g;
		$due = &togli_merda($2);
		$chan = "1";
		$speakline="$uno ti ha invitato in  $due"; 
		$lastwho{$chan} = "";
	}
	if ($speakline=~/^:(.*)!.*part[^:]*:(.*)/) { 
		$uno=$1;
		$due = &togli_merda($2);
		$uno =~ s/[^a-z]//g;
		$speakline="$uno e' uscito e dice: $due"; 
		$lastwho{$chan} = "";
	}
	if ($speakline=~/^:(.*)!.*quit[^:]*:(.*)/) { 
		$uno=$1;
		$due = &togli_merda($2);
		$uno =~ s/[^a-z]//g;
		$speakline="$uno e' uscito e dice: $due"; 
		$lastwho{$chan} = "";
	}
		$qualcosa=1;
	}
	if(!$qualcosa) { return; }

	$speakline=&spch_substitute($speakline);

	$speakline =~ tr/a-z0-9,.<>?'@+=&%$£!\/: ]//cd;
	$speakline =~ s/\?+/\?/g; # Collapse '?'
	$speakline =~ s/\!+/\!/g; # Collapse '!'
	$speakline =~ s/ +/ /g; # Collapse spaces
	$speakline =~ s/\.{2,}/ /g; # Collapse multiple dots
	$speakline =~ s/\s*\?\s*$/\?/; # "phrase    ?" = "phrase?" 
	$speakline =~ s/\s*\!\s*$/\!/; # "phrase    !" = "frase!"
	$speakline =~ s/\s*\?/\?/; # "phrase    ?" = "phrase?" 
	$speakline =~ s/\s*\!/\!/; # "phrase    !" = "frase!"

	# " frase " = ,frase,;   ( frase  ) = ,frase,;
	$speakline =~ s/([a-zA-Z])\s*\)|\(\s*([a-zA-Z])/\1, \2/g;
	$speakline =~ s/\s*"\s*/, /g;
	$speakline =~ s/\s*,\s*,\s*/, /g;
	$speakline =~ s/^,\s*//g;
	$speakline =~ s/\s*,\s*$//g;

	#collapse long repetition
	foreach my $i (split(//, $speakline)) { 
		if($i) { $speakline=~ s/[$i]{8,}/$i$i$i$i$i$i$i/g; }
	}
	
	
	if($lang eq "it") { $speakline =~ s/y/i/g; } # 'y' = 'i'

#	Irssi::print("$speakline");
	
	if($line_highlight && $speakline !~ /$line_highlight/) { return 0; }
	
	&parla("$speakline", "$chan");
	if($smile) { &parla("$uno $smile", "$chan"); }

	return 0;
}

Irssi::command("/parla");
