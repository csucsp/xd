#!/usr/bin/perl -w
use scripts::Lib::Common;
use strict;

if( defined($ENV{'CurriculaParam'}))	{ $Common::command = $ENV{'CurriculaParam'};	}
if(defined($ARGV[0])) { $Common::command = shift or Util::halt("There is no command to process (i.e. AREA-INST)");	}

sub update_page_numbers()
{
        Util::precondition("read_pagerefs");
	my $size          = "big";
	my $dot_file      = Common::get_template("out-$size-graph-curricula-dot-file");
	my $dot_file_txt  = Util::read_file($dot_file);
	foreach my $codcur (keys %{$Common::config{pages_map}})
	{
		$dot_file_txt =~ s/--PAGE$codcur--/$Common::config{pages_map}{"sec:$codcur"}/g;
	}
	foreach my $outcome (keys %{$Common::config{outcomes_map}})
	{
		$dot_file_txt =~ s/\\outcome{$outcome}/$Common::config{outcomes_map}{$outcome}/g;
	}

# 	$dot_file =~ s/\\~n/ñ/g;
	Util::write_file($dot_file, $dot_file_txt);
}

sub replace_outcomes()
{
	my $file = Common::get_template("in-all-outcomes-by-course-poster");
	my $all_outcomes_txt = Util::read_file($file);
	while( $all_outcomes_txt =~ m/\\ref{out:Outcome(.*?)}/g )
	{
	      my $outcome = $1;
	      $all_outcomes_txt =~ s/\\ref{out:Outcome$outcome}/ $Common::config{outcomes_map}{$outcome}/g;
	}
	Util::write_file($file, $all_outcomes_txt);
	Util::print_message("replace_outcomes() OK!");
}

sub main()
{
	Common::set_initial_configuration($Common::command);
        Common::read_pagerefs();
	update_page_numbers();
	replace_outcomes();
}

main();