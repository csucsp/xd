package Common;
use Carp::Assert;
use scripts::Lib::Util;
use strict;

our $command     = "";
our $institution = "";
our $filter      = "";
our $area	 = "";
our $version	 = "";
our $discipline  = "";

our $institutions_info_root	= "";
our $inst_list_file 		= "";
our %list_of_areas		= ();
our %list_of_courses_per_area   = ();
our %config 			= ();
our %dictionary			= ();
our %path_map			= ();
our %data			= ();
our %inst_list			= ();
our %map_hours_unit_by_course   = ();
our %acc_hours_by_course	= ();
our %acc_hours_by_unit		= ();

our $prefix_area 		= "";
our $only_macros_file		= "";
our $compileall_file    	= "";

# our @macro_files 		= ();
our %course_info          	= ();
our %courses_by_semester 	= ();
our %counts              	= ();
our %antialias_info 	 	= ();
our %list_of_courses_per_axe	= ();

my %Numbers2Text 		= (0 => "OH",   1 => "ONE", 2 => "TWO", 3 => "THREE", 4 => "FOUR", 
				   5 => "FIVE", 6 => "SIX", 7 => "SEVEN", 8 => "EIGHT", 9 => "NINE"
				  );
our %template_files = (	"Syllabus" 		=> "in-syllabus-template-file",
			"DeliveryControl" 	=> "in-syllabus-delivery-control-file",
		      );

# flush stdout with every print -- gives better feedback during
# long computations
$| = 1;

# ok
sub replace_accents($)
{
	my ($text) = (@_);
	$text =~ s/\\'A/Á/g;		$text =~ s/\\'a/á/g;		$text =~ s/\\'{a}/á/g;
	$text =~ s/\\'E/É/g;		$text =~ s/\\'e/é/g;		$text =~ s/\\'{e}/é/g;
	$text =~ s/\\'I/Í/g;		$text =~ s/\\'i/í/g;		$text =~ s/\\'{i}/í/g;
	$text =~ s/\\'O/Ó/g;		$text =~ s/\\'o/ó/g;		$text =~ s/\\'{o}/ó/g;
	$text =~ s/\\'U/Ú/g;		$text =~ s/\\'u/ú/g;		$text =~ s/\\'{u}/ú/g;
	$text =~ s/\\~N/Ñ/g;		$text =~ s/\\~n/ñ/g;		$text =~ s/\\~{n}/ñ/g;
	return $text;
}

# ok
sub no_accents($)
{
	my ($text) = (@_);
	$text =~ s/Á/A/g;		$text =~ s/á/a/g;
	$text =~ s/É/E/g;		$text =~ s/é/e/g;
	$text =~ s/Í/I/g;		$text =~ s/í/i/g;
	$text =~ s/Ó/O/g;		$text =~ s/ó/o/g;
	$text =~ s/Ú/U/g;		$text =~ s/ú/u/g;
	$text =~ s/Ñ/N/g;		$text =~ s/ñ/n/g;
	return $text;
}

sub filter_non_valid_chars($)
{
        my ($text) = (@_);
        $text = no_accents($text);
        $text =~ s/ //g;
        return $text;
}

# ok
sub get_alias($)
{
	my ($codcour) = (@_);	
	return $course_info{$codcour}{alias};
}

# ok
sub get_label($)
{
	my ($codcour) = (@_);
	if(defined($antialias_info{$codcour})) #ok
	{	$codcour = $antialias_info{$codcour};		}
	$codcour = get_alias($codcour); # ok
	return $codcour; #ok
}

# ok
sub get_area($)
{
	my ($codcour) = (@_);
# 	print "x$codcour, alias=$course_info{$codcour}{alias}\n";
	$codcour = $course_info{$codcour}{alias};
	if($codcour =~ m/(..).*/)
	{	return $1;	}
	return "";
}

sub get_pdf_icon_link($)
{
        my ($codcour) = (@_);
        my $link  = "<a href=\"syllabi/$codcour.pdf\">";
        $link    .= "<img alt=\"$Common::config{dictionary}{SyllabusOf} $codcour\" src=\"./figs/pdf.jpeg\" ";
        $link    .=  "style=\"border: 0px solid ; width: 16px; height: 16px;\"></a>";
        return $link;
}

sub get_small_icon($$)
{
        my ($icon, $alt) = (@_);
	my $pdflink .= "\\latexhtml{}{%\n";
	$pdflink    .= "\t\\begin{htmlonly}\n";
	$pdflink    .= "\t\t\\begin{rawhtml}\n";
	$pdflink    .=  "\t\t\t<img alt=\"$alt\" src=\"./figs/$icon\" style=\"border: 0px solid ; width: 16px; height: 16px;\">\n";
	$pdflink    .=  "\t\t\\end{rawhtml}\n";
	$pdflink    .=  "\t\\end{htmlonly}\n";
	$pdflink    .= "}";
        return $pdflink;
}

sub replace_special_chars($)
{
	my ($text) = (@_);
	$text =~ s/\\/\\\\/g;
	$text =~ s/\./\\./g;
	$text =~ s/\(/\\(/g;	$text =~ s/\)/\\)/g;
	$text =~ s/\[/\\[/g;	$text =~ s/\]/\\]/g;
	$text =~ s/\+/\\\+/g;
	$text =~ s/\$/\\\$/g;
	$text =~ s/\^/\\\^/g;
	#$text =~ s/\-/\\\-/g;
	$text =~ s/\?/\\\?/g;
	$text =~ s/\*/\\\*/g;
        $text =~ s/\|/\\\|/g;
	return $text;
}

sub InsertSeparator($)
{
    my ($input) = (@_);
    my $output  = "|";
    my $count = 0;
    while($input =~ m/([c|l|r|X|p])/g)
    {
        my $c    = $1;
        if($c eq "p")
        {       if($input =~ m/({.*?})/g)
                {   $output .= "$c$1|";       }
        }
        else
        {   $output .= "$c|";       }
        #Util::print_message("$input->$output");
        $count++;
        #exit if($count == 20);
    }
    return $output;
}

sub read_pages()
{
        my $filename    = Common::get_template("file_for_page_numbers");
        my %pages_map   = ();

	if(-e $filename)
        {
	    my $file_txt    = Util::read_file($filename);
	    while($file_txt =~ m/\\newlabel{(.*?)}{{(.*?)}{(.*?)}/g)
	    {
		    my ($label, $ref, $page) = ($1, $2, $3);
		    $pages_map{$label} = $page;
		  # Util::print_message("pages_map{$course} = $page");
	    }
	}
        return %pages_map;
}

sub read_outcomes_labels()
{
        my $filename     = Common::get_template("file_for_page_numbers");
        my %outcomes_map = ();

	if(-e $filename)
        {
	    my $file_txt     = Util::read_file($filename);
	    while($file_txt =~ m/\\newlabel{out:Outcome(.*?)}{{(.*?)}/g)
	    {
		    my ($outcome, $letter) = ($1, $2);
		    $outcomes_map{$outcome} = $letter;
		    if( $letter =~ m/\\.n/)
		    {       $outcomes_map{$outcome} = "ñ";          }
	    }
	}
        return %outcomes_map;
}

sub read_pagerefs()
{
    %{$config{pages_map}}     = Common::read_pages();
    %{$config{outcomes_map}}  = Common::read_outcomes_labels();
    Util::check_point("read_pagerefs");
}

# ok
sub sem_label($)
{
	my ($sem) = (@_);
# 	print "$sem\n";
	my $rpta  = "\"$sem$config{dictionary}{ordinal_postfix}{$sem} $config{dictionary}{Sem} ";
	$rpta .= "($config{credits_this_semester}{$sem} $config{dictionary}{cr})\"";
	return  $rpta;
}

sub set_version($)
{
	my ($version) = (@_);
	$config{graph_version} = $version;
	if($config{graph_version} == 1)
	{
	      $config{sep} = "|";
	      $config{hline} = "\\hline";
	}
	elsif($config{graph_version} == 2)
	{
	      $config{sep} = "";
	      $config{hline} = "";
	}
	else
	{	Util::halt("Version \"$version\" is not supported ...");	}
}

sub set_global_variables()
{
	$config{bibstyle}   = "apalike";
	$config{InScriptsDir}	= "$config{in}/scripts";

	system("mkdir -p $config{OutputDir}");

	$config{OutputTexDir} 	= "$config{OutputDir}/tex";
	system("mkdir -p $config{OutputTexDir}/syllabi");

	$config{OutputHtmlDir} 	   = "$config{OutputDir}/html";
        $config{OutputHtmlFigsDir} = "$config{OutputDir}/html/figs";
        #system("mkdir -p $config{OutputHtmlDir}");
        system("mkdir -p $config{OutputHtmlDir}/figs");

	$config{OutputPrereqDir} 	= "$config{OutputTexDir}/prereq";
	system("mkdir -p $config{OutputPrereqDir}");

	$config{OutputBinDir} 		= "$config{OutputDir}/bin";
	system("mkdir -p $config{OutputHtmlDir}");

	$config{OutputHtmlDir}	       		= "$config{OutputDir}/html"; 			
	system("mkdir -p $config{OutputHtmlDir}");

	$config{OutputSqlDir}        		= "$config{OutputDir}/gen-sql"; 		
	system("mkdir -p $config{OutputSqlDir}");

	$config{OutputMain4FigDir}   	= "$config{OutputDir}/tex/main4figs";
	system("mkdir -p $config{OutputMain4FigDir}");

	$config{OutputFigDir}         = "$config{OutputDir}/fig";
	system("mkdir -p $config{OutputFigDir}");

	$config{OutputAdvancesDir}   		= "$config{OutputDir}/advances";
	system("mkdir -p $config{OutputAdvancesDir}");

	$config{OutputPrereqDir}      	= "$config{OutputDir}/pre-prerequisites";    
	system("mkdir -p $config{OutputPrereqDir}");
	
	$config{OutputScriptsDir}	= "$config{OutputDir}/scripts";
	system("mkdir -p $config{OutputScriptsDir}");
	
	$config{InLangDir}	 	= "$config{in}/lang.$config{language_without_accents}";
	#$config{in_html_dir}      	= $config{InLangDir}."/templates";

	system("mkdir -p $config{out}/pdfs");

	Util::check_point("set_global_variables");
}

# OK
sub set_initial_paths()
{
	Util::precondition("set_global_variables");
	assert(defined($config{language_without_accents}) and defined($config{discipline}));

	$path_map{"curricula-main"}			= "curricula-main.tex";
	$path_map{"unified-main-file"}			= "unified-curricula-main.tex";
        $path_map{"file_for_page_numbers"}              = "curricula-main.aux";

	$path_map{"country"}				= $config{country};
	$path_map{"country_without_accents"}		= $config{country_without_accents};
	$path_map{"language"}				= $config{language};
	$path_map{"language_without_accents"}		= $config{language_without_accents};

################################################################################################################
# InputsDirs
	$path_map{InDir}				= $config{in};
	$path_map{InLangDir}				= $config{InLangDir};
 	$path_map{InTexDir}				= $path_map{InLangDir}."/$config{area}.tex";
	$path_map{InStyDir}				= $path_map{InLangDir}."/$config{area}.sty";
	$path_map{InStyAllDir}				= $path_map{InDir}."/All.sty";
	$path_map{InSyllabiContainerDir}		= $path_map{InLangDir}."/Syllabi";
        $path_map{InFigDir}                             = $path_map{InLangDir}."/figs";
	$path_map{InOthersDir}				= $path_map{InLangDir}."/$config{area}.others";
	$path_map{InHtmlDir}				= $path_map{InLangDir}."/All.html";
	$path_map{InTexAllDir}				= $path_map{InLangDir}."/All.tex";
	$path_map{InDisciplineDir}			= $path_map{InLangDir}."/$config{discipline}.tex";
	$path_map{InScriptsDir}				= "./scripts";
	$path_map{InCountryDir}				= $config{in}."/country.$path_map{country_without_accents}";
	$path_map{InInstDir}				= $path_map{InCountryDir}."/$config{area}-$config{institution}";
	$path_map{InLogosDir}				= $path_map{InCountryDir}."/logos";
	$path_map{InTemplatesDot}			= $path_map{InCountryDir}."/dot";

#############################################################################################################################
# OutputsDirs
	$path_map{OutDir}				= $config{out};
        $path_map{OutputDir}				= $config{OutputDir};
	$path_map{OutputTexDir}				= $config{OutputTexDir};
	$path_map{OutputBinDir}				= $config{OutputBinDir};
        $path_map{OutputLogDir}                         = $config{out}."/log";
	$path_map{OutputHtmlDir}			= $config{OutputHtmlDir};
        $path_map{OutputHtmlFigsDir}                    = $config{OutputHtmlFigsDir};
	$path_map{OutputHtmlSyllabiDir}			= $config{OutputHtmlDir}."/syllabi";
        $path_map{OutputFigDir}                     	= $config{OutputFigDir};
	$path_map{OutputScriptsDir}			= $config{OutputScriptsDir};
	$path_map{OutputPrereqDir}                  	= $config{OutputTexDir}."/prereq";
        $path_map{OutputMain4FigDir}			= $config{OutputMain4FigDir};
	$path_map{OutputTexSyllabiDir}			= $config{OutputTexDir}."/syllabi";

################################################################################################################################33
# Input and Output files
	# Tex files
	$path_map{"out-current-institution-file"}	= $path_map{OutputDir}."/tex/current-institution.tex";
	$path_map{"list-of-courses"}		   	= $path_map{InTexDir}."/$area$config{CurriculaVersion}-dependencies.tex";

	$path_map{"in-acronyms-base-file"}		= $path_map{InDisciplineDir}."/$config{discipline}-acronyms.tex";
	$path_map{"out-acronym-file"}			= $path_map{OutputTexDir}."/acronyms.tex";
        $path_map{"out-ncredits-file"}                  = $path_map{OutputTexDir}."/ncredits.tex";
        $path_map{"out-nsemesters-file"}                = $path_map{OutputTexDir}."/nsemesters.tex";

	$path_map{"in-outcomes-macros-file"}		= $path_map{InTexDir}."/outcomes-macros.tex";
	$path_map{"in-bok-macros-file"}			= $path_map{InStyDir}."/bok-macros.sty";
	$path_map{"in-LU-file"}				= $path_map{InTexDir}."/LU.tex";

	$path_map{"out-bok-index-file"}			= $path_map{OutputTexDir}."/BodyOfKnowledge-Index.tex";
	$path_map{"out-bok-body-file"}			= $path_map{OutputTexDir}."/BodyOfKnowledge-Body.tex";
	$path_map{"in-macros-order-file"}		= $path_map{InOthersDir}."/macros-order.txt";

	$path_map{"in-main-to-gen-fig"}			= $path_map{InTexAllDir}."/main-to-gen-fig.tex";

	$path_map{"out-description-foreach-area-file"}	= $path_map{OutputTexDir}."/areas-description.tex";
	$path_map{"out-tables-foreach-semester-file"}	= $path_map{OutputTexDir}."/tables-by-semester.tex";
	$path_map{"out-distribution-area-by-semester-file"}= $path_map{OutputTexDir}."/distribution-area-by-semester.tex";

	$path_map{"out-pie-credits-file"}		= $path_map{OutputTexDir}."/pie-credits.tex";
	$path_map{"out-pie-hours-file"}			= $path_map{OutputTexDir}."/pie-hours.tex";
	$path_map{"out-pie-by-levels-file"}		= $path_map{OutputTexDir}."/pie-by-levels.tex";

	$path_map{"out-list-of-courses-per-area-file"}	= $path_map{OutputTexDir}."/list-of-courses-per-area.tex";
	$path_map{"out-comparing-with-standards-file"}	= $path_map{OutputTexDir}."/comparing-with-standards.tex";
	$path_map{"in-all-outcomes-by-course-poster"}	= $path_map{OutputTexDir}."/all-outcomes-by-course-poster.tex";
        $path_map{"out-list-of-syllabi-include-file"}   = $path_map{OutputTexDir}."/list-of-syllabi.tex";
	$path_map{"out-laboratories-by-course-file"}	= $path_map{OutputTexDir}."/laboratories-by-course.tex";

	$path_map{"in-Book-of-syllabi-file"}		= $path_map{InTexAllDir}."/BookOfSyllabi.tex";
	$path_map{"in-Book-of-syllabi-face-file"}	= $path_map{InTexAllDir}."/Book-Face.tex";
	$path_map{"in-Book-of-syllabi-delivery-control-file"}		= $path_map{InTexAllDir}."/BookOfDeliveryControl.tex";
	$path_map{"in-Book-of-syllabi-delivery-control-face-file"}	= $path_map{InTexAllDir}."/Book-Face.tex";
	$path_map{"in-Book-of-descriptions-main-file"}	= $path_map{InTexAllDir}."/BookOfDescriptions.tex";
	$path_map{"in-Book-of-descriptions-face-file"}	= $path_map{InTexAllDir}."/Book-Face.tex";
	$path_map{"in-Book-of-bibliography-file"}	= $path_map{InTexAllDir}."/BookOfBibliography.tex";
	$path_map{"in-Book-of-bibliography-face-file"}	= $path_map{InTexAllDir}."/Book-Face.tex";
	$path_map{"in-Book-of-units-by-course-main-file"}= $path_map{InTexAllDir}."/BookOfUnitsByCourse.tex";
	$path_map{"in-Book-of-units-by-course-face-file"}= $path_map{InTexAllDir}."/Book-Face.tex";

        $path_map{"in-pdf-icon-file"}                   = $path_map{InFigDir}."/pdf.jpeg";
	$path_map{"out-pdf-syllabi-includelist-file"}	= $path_map{OutputTexDir}."/pdf-syllabi-includelist.tex";
	$path_map{"out-pdf-syllabi-delivery-control-includelist-file"}	= $path_map{OutputTexDir}."/pdf-syllabi-delivery-control-includelist.tex";
	$path_map{"out-short-descriptions-file"}	= $path_map{OutputTexDir}."/short-descriptions.tex";
	$path_map{"out-list-of-unit-by-course-file"}	= $path_map{OutputTexDir}."/list-of-units-by-course.tex";
	$path_map{"out-bibliography-list-file"}		= $path_map{OutputTexDir}."/bibliography-list.tex";

	$path_map{"in-description-foreach-area-file"}   = $path_map{InTexDir}."/description-foreach-area.tex";
	$path_map{"in-equivalence-file"}		= $path_map{InInstDir}."/table-of-equivalence.txt";
	$path_map{"out-equivalence-old-new-file"}	= $path_map{OutputTexDir}."/equivalence-old-new.tex";
	$path_map{"out-equivalence-new-old-file"}	= $path_map{OutputTexDir}."/equivalence-new-old.tex";

	$path_map{"in-syllabus-template-file"}		= $path_map{InInstDir}."/syllabus-template.tex";
	$path_map{"in-syllabus-delivery-control-file"}	= $path_map{InInstDir}."/syllabus-delivery-control.tex";
	$path_map{"in-additional-institution-info-file"}= $path_map{InInstDir}."/$area-$institution-extra-info.txt";
	$path_map{"in-distribution-file"}		= $path_map{InInstDir}."/distributions/distribution-$config{Semester}.txt";
	$path_map{"out-only-macros-file"}		= $path_map{OutputTexDir}."/macros-only.tex";

	$path_map{"faculty-file"}			= $path_map{InDir}."/country.$config{country_without_accents}/faculty.txt";
	$path_map{"in-replacements-file"}		= $path_map{InStyDir}."/replacements.txt";

	# Batch files
	$path_map{"out-compileall-file"}		= "compileall";
	$path_map{"in-compile1institucion-base-file"}	= $path_map{InDir}."/base-scripts/compile1institucion.sh-base";
	$path_map{"out-compile1institucion-file"}  	= $path_map{OutputScriptsDir}."/compile1institucion.sh";
	$path_map{"in-gen-html-1institution-base-file"}	= $path_map{InDir}."/base-scripts/gen-html-1institution.sh-base";
	$path_map{"out-gen-html-1institution-file"} 	= $path_map{OutputScriptsDir}."/gen-html-1institution.sh";
	$path_map{"in-gen-eps-files-base-file"}		= $path_map{InDir}."/base-scripts/gen-eps-files.sh-base";
	$path_map{"out-gen-eps-files-file"} 		= $path_map{OutputScriptsDir}."/gen-eps-files.sh";

	$path_map{"out-batch-to-gen-figs-file"}         = $path_map{OutputScriptsDir}."/gen-fig-files.sh";
	$path_map{"out-gen-syllabi.sh-file"}		= $path_map{OutputScriptsDir}."/gen-syllabi.sh";

	# Dot files
	$path_map{"in-small-graph-item.dot"}		= $path_map{InTemplatesDot}."/small-graph-item$config{graph_version}.dot";
	$path_map{"in-big-graph-item.dot"}		= $path_map{InTemplatesDot}."/big-graph-item$config{graph_version}.dot";
	$path_map{"out-small-graph-curricula-dot-file"}	= $config{OutputTexDir}."/small-graph-curricula.dot";
	$path_map{"out-big-graph-curricula-dot-file"}	= $config{OutputTexDir}."/big-graph-curricula.dot";
 
	# Poster files
	$path_map{"in-poster-file"}			= $path_map{InDisciplineDir}."/$config{discipline}-poster.tex";
	$path_map{"out-poster-file"}			= $path_map{OutputTexDir}."/$config{discipline}-poster.tex";
        $path_map{"in-a0poster-sty-file"}               = $path_map{InStyAllDir}."/a0poster.sty";
        $path_map{"in-poster-macros-sty-file"}          = $path_map{InStyAllDir}."/poster-macros.sty";
        $path_map{"in-small-graph-curricula-file"}      = $path_map{InTexAllDir}."/small-graph-curricula.tex";

	# Html
	$path_map{"in-web-course-template.html-file"} 	= $path_map{InHtmlDir}."/web-course-template.html";
        $path_map{"in-analytics.js-file"}               = $path_map{InDir}."/analytics.js";

	# Config files
 	$path_map{"all-config"}				= $path_map{InDir}."/config/all.config"; 
 	$path_map{"colors"}				= $path_map{InDir}."/config/colors.config";
 	$path_map{"discipline-config"}		   	= $path_map{InLangDir}."/$config{discipline}.config/$config{discipline}.config";
 	$path_map{"in-area-all-config-file"}		= $path_map{InLangDir}."/$config{area}.config/$config{area}-All.config";
 	$path_map{"in-area-config-file"}		= $path_map{InLangDir}."/$config{area}.config/$config{area}.config";
 	$path_map{"in-country-info-file"}		= $path_map{InDir}."/country.$config{country_without_accents}/country-info.tex";
        $path_map{"in-country-environments-to-insert-file"}
                              = $path_map{InDir}."/country.$config{country_without_accents}/country-environments-to-insert.tex";
 	$path_map{"dictionary"}				= $path_map{InDir}."/lang.$config{language_without_accents}/dictionary.txt";
	$path_map{SpiderChartInfoDir}			= $path_map{InDisciplineDir}."/SpiderChartInfo";

	Util::check_point("set_initial_paths");
}

sub getInstDir($$$)
{
      my ($_area, $_inst, $_country) = (@_);
      $_country = filter_non_valid_chars($_country);
      get_template("InDir")."/country.$_country/$_area-$_inst";
}

sub get_file_name($)
{
	my ($tpl) = (@_);
	return get_template($tpl);
}

# ok
sub read_discipline_config()
{
	my %discipline_cfg	= read_config_file("discipline-config");
	my ($key, $value);
	while ( ($key, $value)  = each(%discipline_cfg) ) 
	{	
# 		print "country-info: key=$key, value=$value\n";
		$config{$key} = $value; 	
	}

	@{$config{SyllabiDirs}} = ();
	foreach my $dir (split(",", $config{SyllabusListOfDirs}))
	{
		push(@{$config{SyllabiDirs}}, $dir);
	}

	%{$config{sub_areas_priority}} = ();
	my $count = 0;
	foreach my $axe (split(",", $config{SpiderChartAxes}))
	{
		$config{sub_areas_priority}{$axe} = $count++;
	}
	$config{NumberOfAxes} = $count;
}

# ok
sub get_syllabus_dir($)
{
	my ($codcour) = (@_);
	my $syllabus_base_dir = get_template("InSyllabiContainerDir");
	foreach my $dir (@{$config{SyllabiDirs}})
	{
		my $file = "$syllabus_base_dir/$dir/$codcour";
		if(-e $file.".tex" or -e $file.".bib")
		{	return "$syllabus_base_dir/$dir";	}
	}
	Util::halt("I can not find syllabus/bib file for $codcour");
}

# ok
sub get_syllabus_full_path($$)
{
	my ($codcour, $semester) = (@_);
	my $syllabus_base_dir = get_template("InSyllabiContainerDir");
	foreach my $dir (@{$config{SyllabiDirs}})
	{
		my $file = "$syllabus_base_dir/$dir/$codcour";
# 		Util::print_message("file=$file");
		if(-e $file.".tex")
		{	return $file.".tex";	}
		if(-e $file.".bib")
		{	return $file.".bib";	}
	}
	Util::halt("I could not find course $codcour proposed at $config{dictionary}{Sem} #$semester ... VERIFY file: \"$syllabus_base_dir/$codcour\"");
}

# ok
sub get_template($)
{
	my ($acro) = (@_);
	if(defined($path_map{$acro}))
	{	return $path_map{$acro};	}
	Util::halt("get_template: Template not recognized ($acro), Did you define it?");
}

# ok
sub read_config_file($)
{
	my ($tpl) 		= (@_);
 	my $filename 		= get_template($tpl);
	my %map 		= ();
 	Util::print_message("Reading config file: \"$filename\"");
	my $txt = Util::read_file($filename);

	while($txt =~ m/<HASH name=(.*?)>((?:.|\n)*?)<\/HASH>/)
	{
		my ($name, $body) = ($1, $2);
		my $body_tmp = replace_special_chars($body);
		$txt =~ s/<HASH name=$name>$body_tmp<\/HASH>//g;
		while($body =~ m/\s*(\w*)\s*=>\s*(.*?)\s*\n/g)
		{
			$map{$name}{$1} = $2;
# 			if($2 eq "Segundo")
# 			{	Util::print_message("map{$name}{$1} = $2; file = $filename");
# 				exit;
# 			}
# 			Util::print_message("map{$name}{$1} = $2; ");
		}
# 		Util::halt("hash $name ...");
	}
# 	foreach my $line (split("\n", $txt))

	while($txt =~ m/\s*(\w*?)\s*=\s*(.*)\s*/g)
	{	$map{$1} = $2;	
 		if($1 eq "ComparisonWithStandardCaption") 
		{ 	#print "map{$1}=\"$2\"; ($tpl) \n";
			#exit;
		}
	}
        return %map;
}

# ok
sub read_config($)
{
	my ($tpl) = (@_);
	my %map = read_config_file($tpl);
	my ($key, $value);
	while ( ($key, $value) = each(%map)) 
	{
		$config{$key} = $value;
# 		Util::print_message("$config{$key} = $value");
	}
}

# ok
sub read_macros($)
{
    my ($file_name) = (@_);
    my $bok_txt 	  = clean_file(Util::read_file($file_name));
    
    my $count = 0;
    while($bok_txt =~ m/\\newcommand{\\(.*?)}((\s|\n)*?){/g)
    {
	my ($cmd)  = ($1);
	my $cPar   = 1;
	my $body   = "";
	while($cPar > 0)
	{
		$bok_txt =~ m/((.|\s))/g;
		$cPar++ if($1 eq "{");
		$cPar-- if($1 eq "}");
		$body      .= $1 if($cPar > 0);
	}
	$Common::config{macros}{$cmd} = $body;
# 	if( $cmd eq "SPONEAllTopics")
# 	{	Util::print_message("*****\n$body\n*****");	exit;	}
	$count++;
    }
    Util::print_message("read_macros ($file_name) $count macros processed ... OK!");
}

sub read_replacements()
{
	my $replacements_file = Common::get_template("in-replacements-file");
	%{$config{replacements}} = ();
	if( not -e $replacements_file )
	{
	      Util::print_message("I did not find replacements ($replacements_file) just ignoring this process ... ");
	      return;
	}
        my $txt = Util::read_file($replacements_file);
	foreach my $line (split("\n", $txt))
	{
		if($line =~ m/\s*(.*)\s*=>\s*(.*)\s*/g )
		{
		      $config{replacements}{$1} = $2;
		}
	}
}

sub replace_old_macros($)
{
      my ($syllabus_in) = (@_);
      my $count = 0;
      foreach my $key (sort {length($b) <=> length($a)} keys %{$config{replacements}})
      {
	    $count += $syllabus_in =~ s/\\$key/\\$config{replacements}{$key}/g;
      }
      return ($syllabus_in, $count);
}

# ok
sub process_config_vars()
{
#  	print "config{macros_file} = \"$config{macros_file}\"\n";
        my $InStyDir = get_template("InStyDir");
	my $InLangDir = get_template("InLangDir");
	foreach my $file (split(",", $config{macros_file}))
	{
		$file =~ s/<STY-AREA>/$InStyDir/g;
		$file =~ s/<LANG-AREA>/$InLangDir/g;
	}

# 	AreaPriority=CS,IS,SE,HW,IT,MC,OG,CB,CF,CM,CQ,HU,ET,ID
	my $acro_count = 0;
	foreach my $acro_area (split(",",$config{AreaPriority}))
	{
		$config{area_priority}{$acro_area} = ++$acro_count;
	}

	%{$config{colors}{colors_per_level}}   = %{$config{temp_colors}{colors_per_level}};
	undef(%{$config{temp_colors}{colors_per_level}});
	foreach my $area (keys %{$config{temp_colors}})
	{
		# Util::print_message("$config{temp_colors}{$area}");
		if(ref($config{temp_colors}{$area}) eq "HASH")
		{
			Util::print_message("***** Ignoring config{temp_colors}{$area}");
		}
		else
		{
# 			Util::print_message("config{temp_colors}{$area}");
			if($config{temp_colors}{$area} =~ m/(.*),(.*)/g)
			{
				$config{colors}{$area}{textcolor} = $1;
				$config{colors}{$area}{bgcolor}   = $2;
			}
		}
	}
	$config{colors}{change_highlight_background} = "honeydew3";
	$config{colors}{change_highlight_text}       = "black";
}

# ok
sub read_institutions_list()
{
	my $inst_list_file 	= get_template("institutions-list");
	open(IN, "<$inst_list_file") or Util::halt("read_inst_list: $inst_list_file does not open");
	my @lines = <IN>;
	close(IN);
	my $count = 0;
	foreach my $line (@lines)
	{
		#                   CS-SPC     : Peru	   : Computing : SPC       : final
		if($line =~ m/\s*(.*?)-(.*?)\s*:\s*(.*?)\s*:\s*(.*?)\s*:\s*(.*?)\s*:\s*(.*?)\s*$/)
		{
			my $_area   = $1;
			my $country = $3;
			if( $_area eq $config{area})
			{
				$inst_list{$2}{area}       = $1;
				$inst_list{$2}{country}    = $country;
				$inst_list{$2}{discipline} = $4;
				$inst_list{$2}{filter}     = $5;
				$inst_list{$2}{version}    = $6;
				$count++;
				#print "Area = $1, Inst = $2, Filter = $3, version = $4\n";
			}
			else
			{
				if(not defined($inst_list{$2}))
				{
					$inst_list{$2}{area}       = "";
					$inst_list{$2}{country}    = "";
					$inst_list{$2}{discipline} = "";
					$inst_list{$2}{filter}     = "";
					$inst_list{$2}{version}    = "";
					$count++;
					#print "No definido: $line";
				}
			}
			$country = filter_non_valid_chars($country);
			$config{list_of_countries}{$country} = "";
			$list_of_areas{$_area} = "";
		}
		else
		{
			#print "No match \"$line\"\n";
		}
	}
	Util::print_message("read_inst_list ($count)");
	Util::check_point("read_institutions_list");
}

# ok
sub read_institution_info()
{
	my $file = get_template("this-institutions-info-file");
	my $txt  = Util::read_file($file);
# 	print "^^^^^^^^^^^^^^^^^^^^^^^^^\n$txt\n^^^^^^^^^^^^^^^^^^^^^^^^^^\n";
	# Read the Semester
	if($txt =~ m/\\newcommand{\\Semester}{(.*?)\\.*?}/)
	{	$config{Semester} = $1;			}
	else
	{	Util::print_error("Error (read_institution_info): there is no Semester configured in \"$file\"\n");	}

	# Read the dictionary
	if($txt =~ m/\\newcommand{\\dictionary}{(.*?)\\.*?}/)
	{	$config{language_without_accents} 	= no_accents($1);
		$config{language} 			= $1;
	}
	else
	{	Util::print_error("read_institution_info: there is not \\dictionary configured in \"$file\"\n");	}

	# Read the country
	if($txt =~ m/\\newcommand{\\country}{(.*?)\\.*?}/)
	{
                $config{country}                        = $1;
                $config{country_without_accents} 	= filter_non_valid_chars($config{country});
 		#Util::print_message("country=$config{country}, country_without_accents=$config{country_without_accents}\n"); exit;
	}
	else
	{	Util::print_error("Error (read_institution_info): there is not \\country configured in \"$file\"\n");	}

	# Read the GraphVersion
	if($txt =~ m/\\newcommand{\\GraphVersion}{(.*?)\\.*?}/)
	{	set_version($1);		}
	else
	{	Util::print_warning("(read_institution_info): there is not \\GraphVersion configured in \"$file\" ... assuming 1 ...\n");	
		set_version(1);
	}
	
	# Read the CurriculaVersion
	if($txt =~ m/\\newcommand{\\\CurriculaVersion}{(.*?)\\.*?}/)
	{	$config{CurriculaVersion} = $1;		}
	else
	{	Util::print_warning("(read_institution_info): there is not \\GraphVersion configured in \"$file\" ... assuming 1 ...\n");	
		$config{CurriculaVersion} = 1;
	}

	# Read the outcomes list
	if($txt =~ m/\\newcommand{\\OutcomesList}{(.*?)}/)
	{	$config{outcomes_list} = $1;		}
	else
	{	Util::print_error("(read_institution_info): there is not \\OutcomesList configured in \"$file\" ...\n");	
	}

        # Read the outcomes list
        if($txt =~ m/\\newcommand{\\logowidth}{(\d*)(.*?)}/)
        {       $config{logowidth}       = $1;
                $config{logowidth_units} = $2;
                #Util::print_message("config{logowidth}=$config{logowidth}, config{logowidth_units}=$config{logowidth_units}"); exit;
        }
        else
        {       Util::print_error("(read_institution_info): there is not \\logowidth configured in \"$file\" ...\n");
        }

	# Read the HTMLFootnote
	if($txt =~ m/\\newcommand{\\HTMLFootnote}{(.*?)}/)
	{	$config{HTMLFootnote} = $1;		}
	else
	{	Util::print_error("(read_institution_info): there is not \\HTMLFootnote configured in \"$file\" ...\n");	
	}

        # Read the HTMLFootnote
        if($txt =~ m/\\newcommand{\\Copyrights}{(.*?)}/)
        {       $config{Copyrights} = $1;             }
        else
        {       Util::print_error("(read_institution_info): there is not \\Copyrights configured in \"$file\" ...\n");
        }
	Util::check_point("read_institution_info");
}

# ok
sub parse_input_command($)
{
	my ($command) = (@_);
	if($command =~ m/(.*)-(.*)/)
	{
		($area, $institution) 	= ($1, $2);
		#print "Institution = $institution\n";
		#print "Area        = $area\n";
                ($config{area}, $config{institution}) = ($area, $institution);
	}
	else
	{	Util::halt("There is no command to process (i.e AREA-INST)");
	}
}

sub process_filters()
{
	$inst_list{$institution}{filter} =~ s/ //g;
	my $priority = 100;
	foreach my $inst (split(",", $inst_list{$institution}{filter}))
	{
		$config{valid_institutions}{$inst}	= $priority;
		$config{filter_priority}{$inst}		= $priority;
		$priority--;
	}
}

sub verify_dependencies()
{
    my @files_to_verify = (get_template("InTexDir")."/abstract-$config{language_without_accents}.tex"    );
    foreach my $flag (keys %template_files)
    {
	my $file = get_template($template_files{$flag});
	if(-e $file)
	{	$config{flags}{$flag} = 1;	}
	else
	{	$config{flags}{$flag} = 0;	}
    }
}

# First Parameter is something such as CS-SPC
# ok 
sub set_initial_configuration($)  
{
	my ($command) = (@_);
	($config{in}, $config{out})	= ("./in", "./out");
        system("mkdir -p $config{out}/tex");

	# Parse the command
	parse_input_command($command);
	$path_map{"institutions-list"}	= "$config{in}/institutions-list.txt";
	read_institutions_list();

	$config{InInstDir} = "$config{in}/country.$inst_list{$config{institution}}{country}/$config{area}-$config{institution}";
	$path_map{"this-institutions-info-file"}		 = "$config{InInstDir}/institution-info.tex";
	$config{OutputDir}	    = "$config{out}/$inst_list{$config{institution}}{country}/$config{area}-$config{institution}";

	# Read the config for this institution (lang, country, etc)
	read_institution_info();

	# Set global variables, first phase
	set_global_variables();        #1st Phase

	# Parse filters for this institution
	process_filters();
	$config{discipline}	  = $inst_list{$institution}{discipline};

	# set_initial_paths (useful for get_template)
	set_initial_paths();

	# Verify dependencies
	verify_dependencies();

	# Read configuration for this discipline
	read_discipline_config();

	read_config("all-config");
	$path_map{"crossed-reference-file"}		= $config{main_file}.".aux";
	read_config("in-area-all-config-file"); # i.e. CS-All.config
 	read_config("in-area-config-file");     # i.e. CS.config
	#Util::print_message("CS=$config{dictionary}{AreaDescription}{CS}"); exit;
	%{$config{temp_colors}} = read_config_file("colors");

	# Read dictionary for this language
	%{$config{dictionary}} = read_config_file("dictionary");

	# Read specific config for its country
	my %countryvars = read_config_file("in-country-info-file");
	while ( my ($key, $value) = each(%countryvars) ) 
	{	
		# print "country-info: key=$key, value=$value\n";
		$config{dictionary}{$key} = $value; 	
	}
	$config{"country-environments-to-insert"} = "";
	my $file_to_insert = Common::get_template("in-country-environments-to-insert-file");
	if(-e $file_to_insert)
        {	$config{"country-environments-to-insert"} = Util::read_file($file_to_insert);	}

        #Util::print_message($config{"country-environments-to-insert"}); exit;
 	process_config_vars();
	read_crossed_references();

	my $InStyDir = get_template("InStyDir");
	my $InLangDir = get_template("InLangDir");
	foreach my $file (split(",", $config{macros_file}))
	{
		$file =~ s/<STY-AREA>/$InStyDir/g;
		$file =~ s/<LANG-AREA>/$InLangDir/g;
		#read_macros(Common::get_template("in-bok-macros-file"));
		read_macros($file);
	}
        read_bok_order();
	read_macros(Common::get_template("in-outcomes-macros-file"));
        read_macros(Common::get_template("out-current-institution-file")) if(-e Common::get_template("out-current-institution-file"));

	read_replacements();

	$config{macros}{siglas}        = $institution;
	$config{macros}{spcbibstyle}   = $config{bibstyle};
# Util::print_message("****4\n$Common::config{macros}{DSDescription}\n4****");	exit;

	$config{recommended_prereq} = 1;
	$config{corequisites}       = 1;
	$config{verbose}            = 1;
	$config{except_file}{"config-hdr-foot.tex"}     = "";
	$config{except_file}{"current-institution.tex"} = "";
	$config{except_file}{"outcomes-macros.tex"}     = "";
	$config{except_file}{"custom-colors.tex"}       = "";

	#$config{change_file}{"topics-by-course.tex"}    = "topics-by-course-web.tex";
# 	@{$config{bib_files}}	                        = [];

	$config{subsection_label}	= "subsection";
	$config{bold_label}		= "textbf";

        $config{main_to_gen_fig}        = Util::read_file(get_template("in-main-to-gen-fig"));
        Util::check_point("set_initial_configuration");
}

sub read_crossed_references()
{
      my $crf = Common::get_template("crossed-reference-file");
      return if(not -e $crf);
      my $txt = Util::read_file($crf);
      # \newlabel{out:Outcomed}{{d}{5}}
      while($txt =~ m/\\newlabel{(.*?)}{{(.*?)}{(.*?)}}/g)
      {
	    $config{references}{$1}{content}	= $2;
	    $config{references}{$1}{page}	= $3;
	    #Util::print_message("$1 value is $2");
      }
}

# ok
sub gen_only_macros()
{
	my $output_txt = "";
	
	$output_txt .= "% 1st by countries ...\n";
	foreach my $country (keys %{$config{list_of_countries}})
	{
                $output_txt .= "\\newcommand{\\Only$country}[1]{";
                if($country eq $config{country_without_accents})
                {       $output_txt .= "\#1";   }
                $output_txt .= "\\xspace}\n";
                $output_txt .= "\\newcommand{\\Not$country}[1]{";
                if(not $country eq $config{country_without_accents})
                {       $output_txt .= "\#1";   }
                $output_txt .= "\\xspace}\n\n";
        }

        $output_txt .= "% 2st by areas ...\n";
	foreach my $onearea (keys %list_of_areas)
        {
                $output_txt .= "\\newcommand{\\Only$onearea}[1]{";
                if($onearea eq $area)
                {       $output_txt .= "\#1";   }
                $output_txt .= "\\xspace}\n";

                $output_txt .= "\\newcommand{\\Not$onearea}[1]{";
                if(not $onearea eq $area)
                {       $output_txt .= "\#1";   }
                $output_txt .= "\\xspace}\n\n";
        }
        
	$output_txt .= "% And now by institutions ...\n";
	foreach my $inst (keys %inst_list)
        {
                $output_txt .= "\\newcommand{\\Only$inst}[1]{";
                if($inst eq $institution)
                {       $output_txt .= "\#1";   }
                $output_txt .= "\\xspace}\n";
                $output_txt .= "\\newcommand{\\Not$inst}[1]{";
                if(not $inst eq $institution)
                {       $output_txt .= "\#1";   }
                $output_txt .= "\\xspace}\n\n";
        }
	my $only_macros_file = get_template("out-only-macros-file");
	Util::write_file($only_macros_file, $output_txt);
	Util::print_message("gen_only_macros ($only_macros_file) OK!");
}

sub gen_faculty_sql()
{
	my $output_sql = "";
	my ($user_count, $professor_count) = (10, 10);
	foreach my $email (keys %{$config{faculty}})
	{
		my ($username, $firstname, $lastname) = ("", "", "");
		if($email =~ /(.*)@.*/g)
		{	$username = $1;		}
		if($config{faculty}{$email}{name} =~ m/(.*?)\s(.*)\r/)
		{
			($firstname, $lastname) = ($1, $2);
		}
		$user_count++;
		$output_sql .= "INSERT INTO auth_user(id, username, first_name, last_name, email, password, ";
		$output_sql .= "is_staff, is_active, is_superuser)\n";
		$output_sql .= "\tVALUES($user_count, '$username', '$firstname', '$lastname', '$email', PASSWORD, 0, 0, 0);\n\n";
		
		my $shortcv = "";
		if( $config{faculty}{$email}{shortcv} =~ /(\\begin{itemize}(?:.|\n)*?\\end{itemize})/g )
		{	$shortcv = $1;	}
		my $title = "";
		if( $config{faculty}{$email}{title} =~ /(.*)\r/g )
		{	$title = $1;	}
		$professor_count++;
		$output_sql .= "INSERT INTO curricula_professor(id, user_id, shortBio, prefix_id)\n";
		$output_sql .= "\tVALUES($professor_count, $user_count, ";
		$output_sql .= "'$shortcv', '$title');\n\n";
		
	}
	Util::write_file("$config{OutputSqlDir}/docentes.sql", $output_sql);
}

# ok
sub read_faculty()
{
	my $faculty_file = get_template("faculty-file");
	%{$config{faculty}} = ();
	return if(not -e $faculty_file);
	my $input = Util::read_file($faculty_file);

	while($input =~ m/--BEGIN-PROFESSOR--<(.*?)>\s*\n((?:.|\n)*?)--END-PROFESSOR--?/g)
	{
		my $email = $1;
		my $body  = $2;
# 		print "<<$email>>\n\n";
		($config{faculty}{$email}{title}, $config{faculty}{$email}{name}, $config{faculty}{$email}{shortcv}) = ("", "", "");
		if( $body =~ m/TITLE=(.*?)\n((?:.|\n)*)/)
		{	($config{faculty}{$email}{title}, $body)   = ($1, $2); 
			#print "$email title->$config{faculty}{$email}{title} ...\n";
		}
		
		if( $body =~ m/(.*?)\n((?:.|\n)*?)/g)
		{	$config{faculty}{$email}{name}    = $1;	
			$config{faculty}{$email}{shortcv} = $config{faculty}{$email}{title};
			$config{faculty}{$email}{shortcv}.= $body;		
		}
# 		print "<<$email>>2\n\n";
#  		if($email =~ m/criloal23/)
# 		{
# 			Util::print_message("<<$email>>3 title   -> $config{faculty}{$email}{title}");
# 			Util::print_message("$email name    -> $config{faculty}{$email}{name}");
# 			Util::print_message("$email shortcv -> $config{faculty}{$email}{shortcv}");
# 			exit;
# 		}
	}
	Util::check_point("read_faculty");
}
 
# ok
sub read_distribution()
{
	Util::precondition("set_initial_paths");
	my $distribution_file = get_template("in-distribution-file");
	Util::uncheck_point("read_distribution");
	if(not open(IN, "<$distribution_file") )
	{
	    Util::print_warning("read_distribution: I can not open \"$distribution_file\"");
	    return;
	}
	my $count   = 0;
	my $line_number = 0;
	my $codcour = "";
	my $alias   = "";
        my %ignored_email = ();
	while(<IN>)
	{
		$line_number++;
		my $line = $_;
		$line =~ s/\r//g;
		if($line =~ m/\s*(.*)\s*->\s*(.*)\s*/)
		{
			$codcour   = $1; $codcour =~ s/ //g; 
			my $emails = $2; $emails  =~ s/ //g;
			$emails  =~ s/\r//g;
			if(defined($antialias_info{$codcour}))
			{	$codcour = $antialias_info{$codcour}	}
			if( not defined($course_info{$codcour}) )
			{
			      Util::print_error("codcour \"$codcour\" assigned in \"$distribution_file\" does not exist (line: $line_number)... ");
			}
			$alias = get_alias($codcour);
			if( $alias eq "" )
			{
			      Util::print_error("$alias is empty ! codcour=$codcour, $course_info{$codcour}{name}=$course_info{$codcour}{alias}");
			}
# 			
			if(not defined($config{distribution}{$alias}))
			{
				
				$config{distribution}{$alias} = [];
				#Util::print_message("Initializing $codcour($alias) ---");
			}
			#print "\$config{distribution}{$codcour} ... = ";
			foreach my $oneemail (split(",",$emails) )
			{	
 				if( defined($config{faculty}{$oneemail}) )
				{    push(@{$config{distribution}{$alias}}, $oneemail);
                                     #Util::print_message("Course $codcour:\"$oneemail\" ... OK!");
                                }
				else
				{
				      Util::print_warning("No professor information for email:\"$oneemail\" ($codcour) ... just commenting it"); exit;
                                      $ignored_email{$alias} = "" if(not defined($ignored_email{$alias}));
                                      $ignored_email{$alias} .= ",$oneemail";

				}
				#print "$oneemail ";
			}
                        
			#print "\$config{distribution}{$codcour} .= ";
			#foreach my $email (@{$config{distribution}{$codcour}})
			#{	
			#	print "$email ** ";
			#}
			#print "\n";
		}
		$count++;
	}
	close IN;
	#system("rm $distribution_file");

	my $output_txt = "";
	for(my $semester=1; $semester <= $config{n_semesters} ; $semester++)
	{
		my $this_sem_text  = "";
		my $this_sem_count = 0;
		my $ncourses       = 0;
# 		foreach $codcour (@{$courses_by_semester{$semester}})
		foreach my $codcour (sort {$config{area_priority}{$course_info{$a}{prefix}} <=> $config{area_priority}{$course_info{$b}{prefix}}}  @{$courses_by_semester{$semester}})
		{
			if(defined($antialias_info{$codcour}))
			{	$codcour = $antialias_info{$codcour}	}
			$alias = get_alias($codcour);
			if( not defined($config{distribution}{$alias}) )
			{
				Util::print_warning("I do not find professor for course $codcour ($alias) ($semester sem) $course_info{$codcour}{course_name} ...");
			}
			else
			{	my $sep = "";
				$this_sem_text .= "% $codcour($alias). $course_info{$codcour}{course_name} ($config{dictionary}{$course_info{$codcour}{course_type}})\n";
				$this_sem_text .= "$codcour->";
				foreach my $email (@{$config{distribution}{$alias}})
				{
					$this_sem_text .= "$sep$email";
					Util::print_message("$email,");
					$sep = ",";
				}
				$this_sem_text .= "\n";

                                if( defined($ignored_email{$alias}) )
                                {
                                      $this_sem_text .= "%IGNORED $codcour->$ignored_email{$alias}\n";
                                }
			}
			$ncourses++;
		}
		if( $ncourses > 0 )
		{
			$output_txt .= "\n% Semester #$semester .\n";
			$output_txt .= "$this_sem_text\n";
		}
	}
	Util::write_file("$distribution_file", $output_txt);	
	Util::print_message("read_distribution($distribution_file) OK!");
	Util::check_point("read_distribution");
exit;
}

# ok
sub read_aditional_info_for_silabos()
{
	my $file = get_template("in-additional-institution-info-file");
	open(IN, "<$file") or return;
	my $codcour = "";
	while(<IN>)
	{
		if(m/\s*(.*)\s*=\s*(.*)/)
		{
			my $label = $1;
			my $body  = $2;
			if( $label eq "COURSE" )
			{	$codcour = $body;	}
			else
			{	
				$course_info{$codcour}{extra_tags}{$label} = $body;
				#print "Aditional $codcour > $label=\"$body\"\n";
			}
		}
	}
	close IN;
}

# ok
sub replace_accents_in_file($)
{
	my ($filename) = (@_);
	my $fulltxt = Util::read_file($filename);
	$fulltxt = replace_accents($fulltxt);
	Util::write_file($filename, $fulltxt);
}

sub save_outcomes_involved($$)
{
	my ($codcour, $fulltxt) = (@_);
	if($fulltxt =~ m/\\begin{outcomes}\s*((?:.|\n)*?)\\end{outcomes}/)
	{
	    my $body = $1;
	    foreach my $line (split("\n", $body))
	    {
		if($line =~ m/\\ExpandOutcome{(.*?)}{(.*?)}/)
		{
		    $course_info{$codcour}{outcomes}{$1} = $2;	
		}
	    }
	}
}

# ok
sub preprocess_syllabus($)
{
	Util::precondition("parse_courses");
	my ($filename) = (@_);
# 	print "filename = $filename\n";
	my $codcour = "";
	if($filename =~ m/.*\/(.*)\.tex/)
	{	$codcour = $1;		}	
	my @contents;
	my $line = "";

	my $fulltxt = Util::read_file($filename);
	$fulltxt = replace_accents($fulltxt);
	while($fulltxt =~ m/\n\n\n/)
	{	$fulltxt =~ s/\n\n\n/\n\n/g;	}
	
	my $alias       = get_alias($codcour);
# 	Util::print_message("Verifying accents in: $codcour, $course_info{$codcour}{course_name}");
	my $course_name = $course_info{$codcour}{course_name};
	my $course_type = $Common::config{dictionary}{$course_info{$codcour}{course_type}};
	my $header      = "\n\\course{$alias. $course_name}{$course_type}{$codcour}";
	
	my $newhead 	= "\\begin{syllabus}\n$header\n\n\\begin{justification}";
	$fulltxt 		=~ s/\\begin{syllabus}\s*((?:.|\n)*?)\\begin{justification}/$newhead/g;
	save_outcomes_involved($codcour, $fulltxt);

	system("rm $filename");
	@contents = split("\n", $fulltxt);
	my ($count,$inunit)  = (0, 0);
	my $output_txt = "";
	foreach $line (@contents)
	{	
		$line =~ s/\\\s/\\/g; 
		$output_txt .= "$line\n";
		$count++;
	}
        my $country_environments_to_insert = $Common::config{"country-environments-to-insert"};
        $country_environments_to_insert =~ s/<AREA>/$Common::course_info{$codcour}{prefix}/g;
        #$country_environments_to_insert = "hola raton abc";

        my $newtext = "\\end{unit}\n\n$country_environments_to_insert\n\n\\begin{coursebibliography}";
        $output_txt =~ s/((?:.|\n)*)\\end{unit}\s*((?:.|\n)*?)\\begin{coursebibliography}/$1\\end{unit}\\begin{coursebibliography}/g;
        $output_txt =~ s/\\end{unit}\\begin{coursebibliography}/$newtext/g;

	Util::write_file($filename, $output_txt);
        #Util::print_message($filename); exit;
}

# ok
sub replace_special_characters_in_syllabi()
{
	my $base_syllabi = get_template("InSyllabiContainerDir");
	foreach my $localdir (@{$config{SyllabiDirs}})
	{
		my $dir = "$base_syllabi/$localdir";	
		opendir DIR, $dir;
		my @filelist = readdir DIR;
		closedir DIR;
		foreach my $texfile (@filelist)
		{
			if($texfile=~ m/(.*)\.tex$/)
			{
				my $codcour = $1;
				if(defined($course_info{$codcour}))
				{
 					preprocess_syllabus("$dir/$texfile");
# 					generate_prerequisitos($texfile);
				}	
			}
			elsif($texfile=~ m/(.*)\.bib$/)
			{
				replace_accents_in_file("$dir/$texfile");
			}
		}
	}
}


sub replace_acronyms($)
{
	my ($label) = (@_);
	foreach my $acro (keys %{$config{dictionary}{Acronyms}})
	{
		$label =~ s/$config{dictionary}{Acronyms}{$acro}/$acro/g;	
	}
	return $label;
}

# ok
sub wrap_label($)
{
	my ($label) = (@_);
	$label = replace_acronyms($label);
	$label =~ s/  / /g;
	my @words 		= split(" ", $label);
	my $output 		= "";
	my $acu_length 	= 0;
	my $nwords     	= 0;
	my $sep 		= "";
	my $nlines 		= 1;
	foreach my $word (@words)
	{
		if($acu_length+length($word)+1 > $config{label_size} and $nwords >0)
		{
			$output    .= "\\n";
			$acu_length = 0;
			$nwords 	= 0;
			$nlines++;
			$sep 		= "";
		}
		$nwords++;
		$output     .= "$sep$word";
		$acu_length += length($word)+length($sep);
		$sep 		 = " ";
	}
	return ($output,$nlines);
}

# 
# sub change_number_by_text($)
# {
# 	my ($txt) = (@_);
# 	while($txt =~ m/(\d)/)
# 	{
# 		my $digit = $1;
# 		$txt =~ s/$digit/$numbersmap{$digit}/g;
# 	}
# 	$txt =~ s/\./x/g;
# 	return $txt;
# } 
 
sub replace_tags($$$%)
{
 	my ($txt, $before, $after, %map) = (@_);
 	while($txt =~ m/$before(.*?)$after/g)
	{
		my $tag=$1;
# 		print "tag=$tag\n";
		if(defined($map{$tag}))
		{	$txt =~ s/$before$tag$after/$map{$tag}/g;
# 			Util::print_warning("$before$tag$after => $map{$tag}");
		}
		else
		{
			#Util::print_warning("(replace_tags) There is no translation for tag \"$before$tag$after\"");
		}
	}
	return $txt;
}

# ok
sub count_number_of_tags($)
{
	my ($course_line) = (@_);
	my $count = 0;
	while($course_line =~ m/<(.*?)>/g)
	{
		$count++;
	}
	return $count;
}

# ok
sub find_credit_column($)
{
	my ($course_line) = (@_);
	my $count = 1;
	while($course_line =~ m/<<(.*?)>>/g)
	{
		my $tag = $1;
# 		Util::print_message("tag=$tag");
		if($tag eq "CREDITS")
		{ 	
# 			Util::print_message("count=$count"); exit;
			return $count;
		}
		$count++;
	}
	return 1;
}

# ok 
sub read_bok_order()
{
	my $file = get_template("in-macros-order-file");
	my $txt  = Util::read_file($file);

	my $count = 0;
	foreach my $line (split("\n", $txt))
	{
		if($line =~ m/(([a-z]|[A-Z])*)/)
		{	
			$config{topics_priority}{$1} = $count++;		
 		}
	}
	Util::print_message("read_bok_order: $count topics read ...");
}

# my $sql_topic  = "<prefix>INSERT INTO curricula_knowledgetopic(id, \"name\", unit_id, \"topicParent_id\")\n";
#    $sql_topic .= "<prefix>\t\tVALUES (<ctopic>, \'<body>\', <cunit>, <parent>);\n";
# 
# sub gen_bok_normal_topic($$$$$)
# {
# 	my ($ctopic, $body, $cunit, $prefix, $parent) = (@_);
# 	while($body =~ m/  /)
# 	{	$body =~ s/  / /g;	}
# 	my $secret = "xyz1y2b3ytr";
# 	$body .= $secret;
# 
# # 	print "0:\"$body\"\n"	if($body =~ m/pigeonhole/);
# 	if($body =~ m/(.*) $secret/) #delete spaces at the end
# 	{	$body = "$1$secret";	}
# # 	print "s:\"$body\"\n"	if($body =~ m/pigeonhole/);
# 
# 	if($body =~ m/(.*)\.$secret/) #delete the point
# 	{	$body = "$1";		}
# # 	print "p:\"$body\"\n"	if($body =~ m/pigeonhole/);
# 
# 	$body =~ s/$secret//g;
# # 	print "f:\"$body\"\n"	if($body =~ m/pigeonhole/);
# 
# 	$ctopic++;
# 	my $this_sql = $sql_topic;
# 	$this_sql =~ s/<prefix>/$prefix/g;
# 	$this_sql =~ s/<ctopic>/$ctopic/g;
# 	$this_sql =~ s/<body>/$body/g;
# 	$this_sql =~ s/<cunit>/$cunit/g;
# 	$this_sql =~ s/<parent>/$parent/g;
# 	return ($this_sql, $ctopic);
# }
# 
# sub gen_bok_subtopic($$$$$)
# {
# 	my ($ctopic, $body, $cunit, $prefix, $parent) = (@_);
# 	my $this_sql = "";
# 	my $sub_body = "";
# 	
# 	my @lines = split("\n", $body);
# 	foreach my $line (@lines)
# 	{
# 		if( $line =~ m/\\item\s+(.*?)\.\s*%/)
# 		{	
# 			my $sql_tmp = ""; 
# 			($sql_tmp, $ctopic) = gen_bok_normal_topic($ctopic, $1, $cunit, "$prefix   ", $parent);
# 			$this_sql              .= $sql_tmp;
# 		}
# 	}
# 	return ($this_sql, $ctopic);
# }
# 
# sub gen_bok_topic($$$$)
# {
# 	my ($ctopic, $body, $cunit, $prefix) = (@_);
# 	my ($sql, $this_sql) = ("", "");
# 	my $sub_body = "";
# 	if($body =~ m/\s*((?:.|\n)*?)\s*\\begin{inparaenum}\[.*?\]\s*((?:.|\n)*?)\s*\\end{inparaenum}/)
# 	{
# 		$body     = $1;
# 		$sub_body = $2;
# 
# # 		print "\"$body\"\n";
# # 		print "\"$sub_body\"";  exit;
# 		($this_sql, $ctopic) = gen_bok_normal_topic($ctopic, $body, $cunit, $prefix, "null");
# 		$sql .= $this_sql;
# 		($this_sql, $ctopic) = gen_bok_subtopic($ctopic, $sub_body, $cunit, "$prefix   ", $ctopic);
# 		$sql .= $this_sql;
# 	}
# 	else
# 	{
# 		($this_sql, $ctopic) = gen_bok_normal_topic($ctopic, $body, $cunit, $prefix, "null");
# 		$sql .= $this_sql;
# 	}
# 	return ($sql, $ctopic);
# }
# 
# sub generate_bok_sql($$)
# {
# 	my ($filename, $outfile) = (@_);
# 	my $txt_file = Util::read_file($filename);
# # 	print $txt_file;exit;
# 	my $sql = "";
# 
# 	# Config
# 	my $bok_id = 1; #CS=1
# 	my ($carea, $cunit, $ctopic) = (0, 0, 0);
# 	# End config
# 	# Generate areas
# 	my $this_sql = "";
# 	foreach my $area (sort {$areas_priority{$a} <=> $areas_priority{$b}} keys %areas_priority)
# 	{
# 		$carea++;
# 		$this_sql = "INSERT INTO curricula_knowledgearea(id, \"name\", acronym, bok_id)\n";
# 		$this_sql.= "                            VALUES (<id>, \'<name>\', \'<acro>\', <bok_id>);\n";
# 		$this_sql =~ s/<id>/$carea/g;		$this_sql =~ s/<name>/$CS_Areas_description{$area}/g;
# 		$this_sql =~ s/<acro>/$area/g;		$this_sql =~ s/<bok_id>/$bok_id/g;
# 		$sql .= $this_sql;
# 		
# 	}
# 	$sql .= "\n";
# 
# # 	print($sql);
# 	$carea = 0;
# 	my $curr_area = "";
# 	while($txt_file =~ m/\\newcommand{(.*?)}{/g)
# 	{
# 		my $command = $1;
# 		my $body = "";
# 		my $cPar = 1;
# 		while($cPar > 0)
# 		{
# 			$txt_file =~ m/((.|\s))/g;
# 			$cPar++ if($1 eq "{");
# 			$cPar-- if($1 eq "}");
# 			$body .= $1 if($cPar > 0);
# # 			{
# # 				if( $1 eq "\n" )
# # 				{	$body .= "\\n";		}
# # 				else{			}
# # 			}
# 		}
# # 		foreach (split("\n", $body))
# # 		{	print "\"$_\"\n";		}
# # # 		print "\"$body\"";
# # 		exit;
# 
# # 		$body =~ s/\. }//g;
# # 		$body =~ s/\.}//g;
# # 		if( $body =~ m/(.*)\.(\s+)/)
# # 		{	$body = $1;		}
# 		my $subarea = "";
# 		if(	$command =~ m/\\(..).+Topic.+/)
# 		{
# 			$subarea = $1;
# 			#Flush existing header text
# 			if($this_sql =~ m/<nhoras>/)
# 			{
# 				$this_sql =~ s/<nhoras>/0/g;
# 				$sql     .= $this_sql;
# 				$this_sql = "";
# 			}
# 
# 			#Process this topic
# # 			$this_sql = "   INSERT INTO curricula_knowledgetopic(id, \"name\", unit_id, \"topicParent_id\")\n";
# # 			$this_sql.= "\t\t\tVALUES ($ctopic, \"$body\", $cunit, null);\n";
# 			($this_sql, $ctopic) = gen_bok_topic($ctopic, $body, $cunit, "   ");
# 			$sql      .= $this_sql;
# 		}elsif(	$command =~ m/\\(..).*Hours/)
# 		{
# 			$this_sql =~ s/<nhoras>/$body/g;
# 			$sql     .= $this_sql;
# 			$this_sql = "";
# # 			print "H=$this_sql";exit;
# 		}elsif($command =~ m/\\(..).+Def/ )
# 		{
# 			$subarea = $1;
# 			$this_sql = "";
# 			if(not $subarea eq $curr_area)
# 			{	$carea++;
# 				$curr_area = $subarea;
# 				$this_sql  = "\n";
# # 				print "current_area=$curr_area\n";
# 			}
# 			$cunit++;
# 			$this_sql .= "\n-- $body --\n";
# 			$this_sql .= "INSERT INTO curricula_knowledgeunit(id, \"name\", area_id, hours)\n";
# 			$this_sql .= "\tVALUES ($cunit, \'$body\', $carea, <nhoras>);\n";
# # 			$sql      .= $this_sql;
# 
# 		}
# 	}
# 	Util::write_file($outfile, $sql);
# }

# ok
sub remove_only_env($)
{
	my ($text_in) = (@_);
	while($text_in =~ m/((?:.|\n)*?)\\Only([A-Z]*?){/g)
	{
		my $prev_text = $1;
		my $type      = $2;
		my $count = 1;
		my $body1  = "";
		while($count > 0 and $text_in =~ m/(.|\n)/g)
		{
			my $this_char = $1;
			++$count if( $this_char eq "{" );
			--$count if( $this_char eq "}" );
			$body1 .= $this_char if($count > 0 );
		}
		
		#print "*********************************\n";
		#print "body=<$body>\n";
		#print "*********************************\n";
		my $body2 = replace_special_chars($body1);
		if( $type eq $institution )
		{
			my $text = "\\\\Only$institution"."{$body2}";
			$text_in =~ s/$text/$body1/g;
			print "\t\ttype =  \"$type\" processed\n";
		}
		else
		{
			my $_text = "\\\\Only$type"."{$body2}";
			$text_in =~ s/$_text//g;
			#print "\t\ttype =  \"$type\" (X)\n;
		}
	}
	return $text_in;
}

# sub replace_Pag_pagerefs($)
# {
# 	my ($text) = (@_);
# 	my $count  = 0;
# 	$text =~ s/\(Pág\.~\\pageref{.*?}\)//g;
# 	return ($text, $count);
# }
# 
# sub replace_bok_pagerefs($)
# {
# 	my ($text) = (@_);
# 	my $count  = 0;
# 	if($text =~ m/\\item\s(.*?)\s\(Pág\.\s\\pageref{(.*?)}\)/g)
# 	{	
# 		#my ($label1) = ($1);
# 		#print "label=\"$label1\" ... ";
# 		my ($title1, $label1) = ($1, $2);
# 		#print "title=\"$title1\"->\"$label1\"\n";
# 		my $title2 = replace_special_chars($title1);
# 		my $label2 = replace_special_chars($label1);
# 		$text =~ s/\\item\s$title2\s\(Pág\.\s\\pageref{$label2}\)/\\item \\htmlref{$title1}{$label1}/g;
# 		$count++;
# 	}
# 	return ($text, $count);
# }
# 
# sub readfile($$)
# {
# 	my ($filename, $area) = (@_);
# 	my $line;
# 	
# 	if(not -e "$filename")
# 	{
# 		print "readfile: \"$filename\" no existe\n";
# 		return "";
# 	}
# 	open(IN, "<$filename") or die "readfile: $filename no abre \n";
# 	my @lines = <IN>;
# 	close(IN);
# 	my $changes;
# 	my $count = 0;
# 	foreach $line (@lines)
# 	{	
# 		my $extratxt = "";
# 		if( $lines[$count] =~ m/^%/)
# 		{	$lines[$count] = "\n"; }
# 		elsif($filename eq "cs-bok-body.tex")
# 		{	($lines[$count], $changes)        = replace_bok_pagerefs($line);
# 		}
# 		elsif($filename eq "cs-tabla.tex" or $filename =~ m/pre\-prerequisites/)
# 		{	
# 			($lines[$count], $changes)        = replace_Pag_pagerefs($line);
# 		}
# 		elsif( $lines[$count] =~ m/(^.*)(.)%(.*)/)
# 		{	if($2 eq "\\")
# 			{}
# 			else
# 			{
# 				$lines[$count] = "$1$2\n" ; 
# 				#print "$line";
# 			}
# 		}
# 		$count++;
# 	}
# 	my $filetxt = join("", @lines);
# 	$filetxt =~ s/\\setmyfancyheader\s*\n//g;
# 	$filetxt =~ s/\\setmyfancyfoot\s*\n//g;
# 	$filetxt =~ s/\\hrulefill\s*//g;
# 	$filetxt =~ s/\\newcommand{\\siglas}{\\currentinstitution}//g;
# 	$filetxt =~ s/\\renewcommand{\\Only.*\n//g;
# 	$filetxt =~ s/\\renewcommand{\\OtherKeyStones/\\newcommand{\\OtherKeyStones/g;
# 	$filetxt =~ s/\\include{empty}//g;
# 	$filetxt =~ s/\\input{caratula}/\\input{caratula-web}/g;
# 	$filetxt =~ s/\\newcommand{\\currentarea}{.*?}//g;
# 	$filetxt =~ s/\\currentarea/$area/g;
# 	#$filetxt =~ s/\\begin{landscape}//g;
# 	#$filetxt =~ s/\\end{landscape}//g;
# 	$filetxt =~ s/cs-topics-by-course/cs-all-topics-by-course/g;
# 	$filetxt =~ s/cs-outcomes-by-course/cs-all-outcomes-by-course/g;
# 	return $filetxt;
# }

sub clean_file($)
{
	my ($filetxt) = (@_);
	$filetxt .= "\n";
	$filetxt =~ s/\\%/\\PORCENTAGE/g;
	$filetxt =~ s/%.*?\n/\n/g;
	$filetxt =~ s/\\PORCENTAGE/\\%/g;

	$filetxt =~ s/\\setmyfancyheader\s*\n//g;
	$filetxt =~ s/\\setmyfancyfoot\s*\n//g;
	$filetxt =~ s/\\hrulefill\s*//g;
	$filetxt =~ s/\\newcommand{\\siglas}{\\currentinstitution}//g;
	$filetxt =~ s/\\renewcommand{\\Only.*\n//g;
# 	$filetxt =~ s/\\renewcommand{\\OtherKeyStones/\\newcommand{\\OtherKeyStones/g;
	$filetxt =~ s/\\include{empty}//g;
	$filetxt =~ s/\\input{caratula}/\\input{caratula-web}/g;
	$filetxt =~ s/\\newcommand{\\currentarea}{.*?}//g;
	$filetxt =~ s/\\currentarea/$area/g;
	#$filetxt =~ s/\\begin{landscape}//g;
	#$filetxt =~ s/\\end{landscape}//g;
# 	$filetxt =~ s/cs-topics-by-course/cs-all-topics-by-course/g;
# 	$filetxt =~ s/cs-outcomes-by-course/cs-all-outcomes-by-course/g;
	return $filetxt;
}

# ok
sub expand_macros($)
{
	my ($text) = (@_);
	my $count = 0;
	
	#print "siglas = $config{macros}{siglas} x5";
	if(not defined($config{macros}{siglas}))
	{	Util::halt("\$config{macros}{siglas} does not exit !!!!\n");		}

	#print "macros{siglas} = $config{macros}{siglas}\n";
	#print "macros{currentarea} = $config{macros}{currentarea}\n";
	#print "macros{currentinstitution} = $config{macros}{currentinstitution}\n";
	my $ctemp = 1;
	while($ctemp > 0)
	{
		$ctemp = 0;
		foreach my $key (sort {length($b) <=> length($a)} keys %{$config{macros}})
		{
			#print "\"$key\"\n" if( $verbose == 1 );
			if($text =~ m/\\$key/)
			{	
				#print "\\$key, ";
				#print "\n\\$key->$config{macros}{$key}";
# 				if($key eq "DSDescription")
# 				{	print "DSDescription done\n";	
# 					Util::write_file("delete/temp.tex", $text);
# 					Util::print_message("****\n$config{macros}{DSDescription}\n****");
# 					exit;
# 				}
				$text =~ s/\\$key/$config{macros}{$key}/g;
				$count++;
				$ctemp++;
			}
		}
	}
	#print "siglas = $config{macros}{siglas} ... x7\n";
	return ($text, $count);
}

# 
sub expand_sub_file($$)
{
	my ($text, $temptype) = (@_);
	my $matchstr = "\\\\$temptype"."{(.*?)}";
	my $count = 0;
	
	#while($filetxt =~ m/\\begin{unit}{(.*)}{(.*)}\s*\n((?:.|\n)*?)\\end{unit}/g)
	my $prefix = "";
	#my $source_txt = "";
	while($text =~ m/$matchstr/)
	{
		my $sub_file = $1;
		my $source_txt = "\\\\$temptype"."{$sub_file}";
		if($temptype eq "\\include")
		{	$prefix = "\\newpage\n";	}

		$sub_file .= ".tex";
		my $JustName = $sub_file;
		if( $JustName =~ m/.*\/(.*)/ )
		{	$JustName = $1;		}

		if(defined($config{change_file}{$JustName}))
		{
			$sub_file =~ s/$JustName/$config{change_file}{$JustName}/g;
			Util::print_message("Replacing $JustName => $config{change_file}{$JustName} in $sub_file");
		}
		#print "Reading $sub_file ...";
		
		if( defined($config{except_file}{$JustName}) )
		{	print " $sub_file (X)\n";
			$text =~ s/$source_txt//g;
			next;
		}
                if(not -e $sub_file)
                {       Util::print_error("File \"$sub_file\" does not exists ...");    }
		my $sub_file_text = clean_file(Util::read_file($sub_file));
		   $sub_file_text = remove_only_env($sub_file_text);
		my $macros_changed = 0;
		#print "$institution: $sub_file ";
		($sub_file_text, $macros_changed) = expand_macros($sub_file_text);
		$count += $macros_changed;
		print " ($macros_changed macros changed)\n" if($macros_changed > 0);
		#print "\n";
		$text =~ s/$source_txt/$prefix$sub_file_text/g;
		$count++;
	}
	return ($text, $count);
}

# ok
sub expand_sub_files($)
{
	my ($text) = (@_);
	my ($count1, $count2) = (0, 0);
	($text, $count1) = expand_sub_file($text, "input");
	($text, $count2) = expand_sub_file($text, "include");
	return ($text, $count1+$count2);
}

sub filter_courses()
{
	Util::precondition("set_initial_configuration");
	my $input_file    = get_template("list-of-courses");
	Util::print_message("Reading courses ($input_file) ...");

 	my $courses_count 		= 0;
	$config{n_semesters}		= 0;
	if(not open(IN, "<$input_file"))
	{  Util::halt("parse_courses: $input_file does not open ...");	}

	while(<IN>)
	{
		if( m/^\\course{(.*)}{(.*)}{(.*)}{(.*)}{(.*)}{(.*)}{(.*)}{(.*)}{(.*)}{(.*)}{(.*)}{(.*)}{(.*)}{(.*)}{(.*)}{(.*)}{(.*)}%(.*)/)
		{
		      # \course{sem}{course_type} {cod}{alias}{name} {cr}{th}  {ph}  {lh} {ti}{Tot} {labtype}  {req} {rec} {corq}{grp} {axe} %filter
			my ($semester, $course_type, $codcour, $alias, $course_name) = ($1, $2, $3, $4, $5);
			my ($credits, $ht, $hp, $hl, $ti, $tot, $labtype)   = ($6, $7, $8, $9, $10, $11, $12);
			my $prerequisites                       = $13;
			my $recommended                         = $14;
			my $coreq		                = $15;
			my $group				= $16;
			my $axes				= $17;
			my $inst_wildcard			= $18;
			my @inst_array                          = split(",", $inst_wildcard);
			my $count                               = 0;
			my $priority = 0;
			foreach my $inst (@inst_array)
			{
				if(defined($config{valid_institutions}{$inst}))
				{	
				      $count++;
				      if($config{filter_priority}{$inst} > $priority)
				      {		$priority = $config{filter_priority}{$inst};		}
				}
			}
			if( $count == 0 ){next; }
			if( defined($course_info{$codcour}) ) # This course already exist, then verify if the new course has a higher priority
			{	if( $priority < $course_info{$codcour}{priority}) 
				{	
					Util::print_warning("Course $codcour (Sem #$course_info{$codcour}{semester},\"$course_info{$codcour}{inst_list}\"), has higher priority than $codcour (Sem #$semester, \"$inst_wildcard\")  ... ignoring the last one !!!");
					next;
				}
				#if( $priority == $course_info{$codcour}{priority})
			}
                        if($axes eq "")
                        {
                                Util::halt("Course $codcour has not area defined, see dependencies");
                        }
			$config{n_semesters} = $semester if($semester > $config{n_semesters});
			$courses_count++;
			#print "wildcards = $inst_wildcard\n";
			#Util::print_message("coursecode = $codcour, semester = $semester\n");
			print ".";
			Util::print_message(" $courses_count courses") if($courses_count % 10 == 0);
			$prerequisites =~ s/ //g;
			$recommended   =~ s/ //g;
			$coreq	       =~ s/ //g;
			
			#print_message("Processing coursecode=$codcour ...");
			$course_info{$codcour}{priority}		= $priority;
			$course_info{$codcour}{semester}       		= $semester;
			$course_info{$codcour}{course_type}    		= $course_type; # $config{dictionary}{$course_type};
			$course_info{$codcour}{short_type}     		= $config{dictionary}{MandatoryShort};
			$course_info{$codcour}{short_type} 	   	= $config{dictionary}{ElectiveShort} if($course_info{$codcour}{course_type} eq $Common::config{dictionary}{Elective});
			if($alias eq "") {	$alias = $codcour 			}
			else		{  $antialias_info{$alias} 	= $codcour;	}
			$course_info{$codcour}{alias}			= $alias;
			
			$course_info{$codcour}{axes}           		= $axes;
			$course_info{$codcour}{naxes}			= 0;

			my $prefix = get_area($codcour);
			$course_info{$codcour}{prefix}			= $prefix;
			
			# print "coursecode= $codcour, area= $course_info{$codcour}{axe}\n";
# 			$area_priority{$codcour}		      	= $axes;
			$course_info{$codcour}{textcolor}		= $config{colors}{$prefix}{textcolor};
			$course_info{$codcour}{bgcolor}			= $config{colors}{$prefix}{bgcolor};
			$course_info{$codcour}{course_name}		= $course_name;

			$course_info{$codcour}{cr}             	= $credits;
			($course_info{$codcour}{th}, $course_info{$codcour}{ph}, $course_info{$codcour}{lh})		= (0, 0, 0);
			$course_info{$codcour}{th}             	= $ht if(not $ht eq "");
			$course_info{$codcour}{ph}             	= $hp if(not $hp eq "");
			$course_info{$codcour}{lh}             	= $hl if(not $hl eq "");

                        ($course_info{$codcour}{ti}, $course_info{$codcour}{tot})            = (0, 0);
                        $course_info{$codcour}{ti}              = $ti if(not $ti eq "");
                        $course_info{$codcour}{tot}             = $tot if(not $tot eq "");

			$course_info{$codcour}{labtype}        	= $labtype;

			$course_info{$codcour}{full_prerequisites}	= []; # # CS101F. Name1 (1st Sem, Pág 56), CS101O. Name2 (2nd Sem, Pág 87), ...
			$course_info{$codcour}{code_name_and_sem_prerequisites} = "";
			$course_info{$codcour}{prerequisites_just_codes}= $prerequisites;
			$course_info{$codcour}{short_prerequisites}	= ""; # CS101F (1st Sem), CS101O (2nd Sem), ...
			$course_info{$codcour}{code_and_sem_prerequisites}= "";
			$course_info{$codcour}{recommended}   		= $recommended;
			$course_info{$codcour}{corequisites}		= $coreq;
			$course_info{$codcour}{group}          		= $group;
			%{$course_info{$codcour}{extra_tags}}		= ();
			$course_info{$codcour}{inst_list}      		= $inst_wildcard;
			$course_info{$codcour}{equivalence}		= "";
		}
	}
	close(IN);
	Util::check_point("filter_courses");
	Util::print_message("Read courses = $courses_count ($config{n_semesters} semesters)");
        Util::write_file(Common::get_template("out-nsemesters-file"), "$config{n_semesters}\\xspace");
}

# ok
sub parse_courses()
{
	Util::precondition("set_initial_configuration");
	Util::precondition("filter_courses");
 	my $input_file    = get_template("list-of-courses");
	Util::print_message("Reading courses ...");

	$counts{credits}{count} 	= 0;
	$counts{hours}{count} 		= 0;
	%{$config{used_areas}}		= ();
	$config{number_of_used_areas}	= 0;
 	my $courses_count 		= 0;
 	my $active_semester 		= 0;
 	my $maxE 			= 0;
 	my ($elective_axes, $elective_naxes) = ("", 0);
	my $axe 			= "";
	$config{n_semesters}		= 0;

	foreach my $codcour (sort {$course_info{$a}{semester} <=> $course_info{$b}{semester}} keys %course_info)
	{
		my $semester = $course_info{$codcour}{semester};
		$config{n_semesters} = $semester if($semester > $config{n_semesters});
		$courses_count++;
		#print "wildcards = $inst_wildcard\n";
		#Util::print_message("coursecode = $codcour, semester = $semester\n");
		#Util::print_message("$codcour($semester),");
		if($active_semester != $semester)
		{
			#print "Active Semester = $active_semester\n";
			if($active_semester != 0)
			{	
				foreach $axe (split(",", $elective_axes))
				{	$counts{credits}{areas}{$axe}	+= $maxE/$elective_naxes;	}
				$counts{credits}{count}			+= $maxE;
				#print "contador hasta el $active_semester = $counts{credits}{count}, maxE = $maxE\n";
			}
			$active_semester = $semester;
			$maxE = 0;
		}
		if(not defined($courses_by_semester{$semester}))
		{
			$courses_by_semester{$semester} = [];
		}
		push(@{$courses_by_semester{$semester}}, $codcour);
		#print_message("Processing coursecode=$codcour ...");
		my $prefix = get_area($codcour);
		if(not defined($config{used_areas}{$prefix}))   # YES HERE
		{
			$config{used_areas}{$prefix} = "";
			$config{number_of_used_areas}++;
		}
		# print "coursecode= $codcour, area= $course_info{$codcour}{axe}\n";
		$course_info{$codcour}{naxes}		= 0;
		foreach $axe (split(",", $course_info{$codcour}{axes}))
		{	$course_info{$codcour}{naxes}++;	}

		foreach $axe (split(",", $course_info{$codcour}{axes}))
		{
		      if(not defined($data{counts_per_standard}{$axe}))
		      {		$data{counts_per_standard}{$axe} 		= 0;	
				$list_of_courses_per_axe{$axe}{courses} 	= [];
		      }
		      $data{counts_per_standard}{$axe}     += $course_info{$codcour}{cr}/$course_info{$codcour}{naxes};
		      push(@{$list_of_courses_per_axe{$axe}{courses}}, $codcour);
		}
		if($course_info{$codcour}{course_type} eq "Elective")
		{
			$elective_axes 	= $course_info{$codcour}{axes};
			$elective_naxes = $course_info{$codcour}{naxes};
			my $credits = $course_info{$codcour}{cr};
			if($credits > $maxE)
			{	$maxE = $credits;
			}
                        my $group = $Common::course_info{$codcour}{group};
                        assert(not $group eq "");
                        if( defined($config{electives}{$semester}{$group}{cr}) )
                        {       #Util::print_message("electives{$group}{cr}=$electives{$group}{cr},  Common::course_info{$codcour}{cr}=$Common::course_info{$codcour}{cr}");
                                #Util::print_message("electives{$group}{prefix}=$electives{$group}{prefix}, Common::course_info{$codcour}{prefix}=$Common::course_info{$codcour}{prefix}");
                        }
                        else
                        {
                              $config{electives}{$semester}{$group}{cr}    = $Common::course_info{$codcour}{cr};
                              $config{electives}{$semester}{$group}{prefix}= $Common::course_info{$codcour}{prefix};
                              #Util::print_message("config{electives}{$semester}{$group}{cr}=$config{electives}{$semester}{$group}{cr}");
                              #$electives{$group}{prefix}= $Common::course_info{$codcour}{prefix};
                        }
		}
		if($course_info{$codcour}{course_type} eq "Mandatory")
		{
			#Util::print_message("codcour=$codcour, cr=$toadd");
			foreach $axe (split(",", $course_info{$codcour}{axes}))
			{	$counts{credits}{areas}{$axe} += $course_info{$codcour}{cr}/$course_info{$codcour}{naxes};
				#print "$axe -> $course_info{$codcour}{cr}/$course_info{$codcour}{naxes}\n" if($codcour eq "CS225T");
			}
			$counts{credits}{count}	      += $course_info{$codcour}{cr};
		}
		#print "codcour = $codcour, cr=$course_info{$codcour}{cr}, ($course_info{$codcour}{course_type}) $counts{credits}{count}, maxE = $maxE\n";
		#print "contador hasta el $active_semester = $counts{credits}{count}, maxE = $maxE\n";

		my $sep 		= "";
		$course_info{$codcour}{n_prereq} = 0;
		foreach my $codreq (split(",",$course_info{$codcour}{prerequisites_just_codes}))
		{	
			$codreq =~ s/ //g;
			if($codreq =~ m/$institution=(.*)/)
			{	  push(@{$course_info{$codcour}{full_prerequisites}}, $1);
				  $course_info{$codcour}{short_prerequisites}  .= "$sep$1";
			}
			elsif($codreq =~ m/(.*?)=(.*)/)
			{	 Util::print_warning("It seems that course $codcour ($semester$config{dictionary}{ordinal_postfix}{$semester} $config{dictionary}{Sem}) has an invalid req ($codreq) ... ignoring"); 			}
			else
			{	
				if(defined($antialias_info{$codreq}))
				{	$codreq = $antialias_info{$codreq};	}
				if(defined($course_info{$codreq}))
				{
					my $course_full_label = "$codreq. $course_info{$codreq}{course_name}";
					my $semester_prereq = $course_info{$codreq}{semester};
					my $this_prereq_full = "\\htmlref{$course_full_label}{sec:$codreq}~";
					$this_prereq_full   .= "($semester_prereq\$^{$config{dictionary}{ordinal_postfix}{$semester_prereq}}\$ ";
					$this_prereq_full   .= "$config{dictionary}{Sem}";
					$this_prereq_full   .= "-";
					$this_prereq_full   .= "$config{dictionary}{Pag}~\\pageref{sec:$codreq})";
					push(@{$course_info{$codcour}{full_prerequisites}}, $this_prereq_full);
					#$course_info{$codcour}{full_prerequisites} .= "$sep$codreq";

					
					$course_info{$codcour}{code_name_and_sem_prerequisites} .= "$sep\\htmlref{$course_full_label}{sec:$codcour}.~";
					$course_info{$codcour}{code_name_and_sem_prerequisites} .= "($semester_prereq\$^{$config{dictionary}{ordinal_postfix}{$semester_prereq}}\$~";
					$course_info{$codcour}{code_name_and_sem_prerequisites} .= "$config{dictionary}{Sem})\n";

					$course_info{$codcour}{short_prerequisites} .= "$sep\\htmlref{$codreq}{sec:$codcour} ";
					$course_info{$codcour}{short_prerequisites} .= "(\$$semester_prereq^{$config{dictionary}{ordinal_postfix}{$semester_prereq}}\$~";
					$course_info{$codcour}{short_prerequisites} .= "$config{dictionary}{Sem})";

					$course_info{$codcour}{code_and_sem_prerequisites} .= "$sep\\htmlref{$codreq}{sec:$codreq}~";
					$course_info{$codcour}{code_and_sem_prerequisites} .= "(\$$semester_prereq^{$config{dictionary}{ordinal_postfix}{$semester_prereq}}\$)";

				}
				else
				{
					Util::halt("parse_courses: Course $codcour (sem #$semester) has a prerequisite \"$codreq\" not defined");
				}
			}
			$sep = ", ";
			$course_info{$codcour}{n_prereq}++;
		}
		if($course_info{$codcour}{n_prereq} == 0)
		{	$course_info{$codcour}{full_prerequisites} = $config{dictionary}{None};	}

		# Hours Accumulator
		my $hours = 0;
		$hours += $course_info{$codcour}{th} if( not $course_info{$codcour}{th} eq "" );
		$hours += $course_info{$codcour}{ph} if( not $course_info{$codcour}{ph} eq "" );
		$hours += $course_info{$codcour}{lh} if( not $course_info{$codcour}{lh} eq "" );

		foreach $axe (split(",", $course_info{$codcour}{axes}))
		{
			if(not defined($counts{hours}{areas}{$axe}))
			{	$counts{hours}{areas}{$axe} = 0;		}
			$counts{hours}{areas}{$axe} += $hours/$course_info{$codcour}{naxes};
		}
		$counts{hours}{count} += $hours;
		#Util::print_message("codcour = $codcour, counts{credits}{count} = $counts{credits}{count}, counts{hours}{count} = $counts{hours}{count}");
		#Util::print_message("axe=$axe, data{counts_per_standard}{$axe} = $data{counts_per_standard}{$axe}");
		#exit if($courses_count == 50);
	}

	foreach $axe (split(",", $elective_axes))
	{	$counts{credits}{areas}{$axe}	+= $maxE/$elective_naxes;	}
	$counts{credits}{count}		 	+= $maxE;

	my $semester;
	for($semester=1; $semester <= $config{n_semesters} ; $semester++)
	{	$config{semester_electives}{$semester} = ();		}

	for($semester=1; $semester <= $config{n_semesters} ; $semester++)
	{
                $config{credits_this_semester}{$semester} = 0;
		foreach my $codcour (@{$courses_by_semester{$semester}})
		{
                        if($course_info{$codcour}{course_type} eq "Mandatory")
                        {
                              assert($course_info{$codcour}{group} eq "");
                              $Common::config{credits_this_semester}{$semester} += $course_info{$codcour}{cr};
                              #Util::print_message("Sem=$semester,acu=$Common::config{credits_this_semester}{$semester}, course_info{$codcour}{cr}=$course_info{$codcour}{cr}");
                        }
                        else
                        {
                            assert(not $course_info{$codcour}{group} eq "");
                            my $group = $course_info{$codcour}{group};
                            if( not defined($config{semester_electives}{$semester}{$group}{list}) )
                            {	$config{semester_electives}{$semester}{$group}{list} = [];	}
                            push(@{$config{semester_electives}{$semester}{$group}{list}}, $codcour);
                        }
			foreach $axe (split(",", $course_info{$codcour}{axes}))
			{
			      if(not defined($list_of_courses_per_area{$axe}))
			      {	$list_of_courses_per_area{$axe} = [];	}
			      push(@{$list_of_courses_per_area{$axe}}, $codcour);
                              $counts{credits}{areas}{$axe} += $course_info{$codcour}{cr}/$course_info{$codcour}{naxes};
			      #Util::print_message("codcour=$codcour, axe=$axe");
			}
                        
		}
                #Util::print_message("config{credits_this_semester}{$semester}=$config{credits_this_semester}{$semester}");
                if( defined($config{electives}{$semester}) )
                {
                      foreach my $group (keys %{$config{electives}{$semester}})
                      {
                          #Util::print_message("config{electives}{$semester}{$group}{cr} = $config{electives}{$semester}{$group}{cr}");
                          $config{credits_this_semester}{$semester}                    += $config{electives}{$semester}{$group}{cr};
                      }
                }
                #Util::print_message("config{credits_this_semester}{$semester}=$config{credits_this_semester}{$semester}");
	}
	if($courses_count < 5)
	{
	      Util::halt("It seems that I did not read many courses ($courses_count) ... verify file \"$input_file\" ...");
	}

	Util::check_point("parse_courses");
	Util::print_message("Read courses = $courses_count ($config{n_semesters} semesters)");
}

sub get_list_of_bib_files()
{
    Util::precondition("gen_syllabi");
    my $syllabus_container_dir 	= Common::get_template("InSyllabiContainerDir");
    for(my $semester = 1; $semester <= $Common::config{n_semesters}; $semester++)
    {
	foreach my $codcour (@{$Common::courses_by_semester{$semester}})
	{
# 		Util::print_message("codcour = $codcour, bibfiles=$Common::course_info{$codcour}{bibfiles}");
		foreach (split(",", $Common::course_info{$codcour}{bibfiles}))
		{
			$Common::config{allbibfiles}{"$syllabus_container_dir/$_"} = "";
		}
	}
    }
    my ($all_bib_items, $sep) = ("", "");
    foreach my $bibfile (keys %{$Common::config{allbibfiles}})
    {
	$all_bib_items .= "$sep$bibfile";
	$sep = ",";
    }
    return $all_bib_items;
}

sub read_min_max($$)
{
	my ($SpiderChartInfoDir,$standard) = (@_);
	my $input_file = "$SpiderChartInfoDir/$standard-MinMax.tex";
	my $filetxt = Util::read_file("$input_file");
	
	Util::print_message("read_min_max: reading $input_file");
	# This accumulator is only to calculate the final % compared with the total
	$config{StdInfo}{$standard}{min} = 0;
	$config{StdInfo}{$standard}{max} = 0;
	my $axe;
	foreach $axe (split(",", $config{SpiderChartAxes}))
	{
		$config{StdInfo}{$standard}{$axe}{min} = 0;
		$config{StdInfo}{$standard}{$axe}{max} = 0;
	}

	while($filetxt =~ m/\\topic{(.*?)}{(.*?)}{(.*?)}{(.*?)}/g)
	{
		$axe = $1;
		$config{StdInfo}{$standard}{$axe}{min} += $3;
		$config{StdInfo}{$standard}{$axe}{max} += $4;

		# This accumulator is only to calculate the final % compared with the total
		$config{StdInfo}{$standard}{min} += $3;
		$config{StdInfo}{$standard}{max} += $4;
	}
}

sub read_all_min_max()
{	
	my $SpiderChartInfoDir = get_template("SpiderChartInfoDir");
	foreach (split(",", $config{Standards}))
	{
		read_min_max($SpiderChartInfoDir, $_);
	}
	Util::print_message("read_all_min_max() OK!");
}

# ok
sub replace_generic_environments($$$$$)
{
	my ($text, $env_name, $label_text, $label_type, $new_env_name) = (@_);
	my $count  = 0;
	#Replace environment
	#print "(2) $env_name being processed ... \n" if($env_name eq "outcomes");
	while($text =~ m/\\begin{$env_name}\s*\n((.|\t|\s|\n)*?)\\end{$env_name}/g)
	{
 		#print "(3) $env_name processed OK !\n" if($env_name eq "outcomes");
		$count++;
		my $env_body_in  = $1;
		my $env_body_out = $env_body_in;
		$env_body_in = replace_special_chars($env_body_in);
		my $out_text = "\\$label_type"."{$label_text}";
		$text =~ s/\\begin{$env_name}\s*\n$env_body_in\\end{$env_name}/$out_text\n\\begin{$new_env_name}\n$env_body_out\\end{$new_env_name}/g;
	}
	return ($text, $count);
}

# ok
sub replace_bold_environments($$$$)
{
	my ($text, $env_name, $label_text, $label_type) = (@_);
	my $count  = 0;
	#Replace Sumillas
	while($text =~ m/\\begin{$env_name}\s*\n((?:.|\n)*?)\\end{$env_name}/g)
	{
		my $env_body_in = $1;
		my $env_body_out = $env_body_in;
		#print "### ($count)\n$env_body\n---\n";
		$env_body_in = Common::replace_special_chars($env_body_in);
		my $text_out = "\\$config{subsection_label}"."{$label_text}\n\n$env_body_out";
		$text =~ s/\\begin{$env_name}\s*\n$env_body_in\\end{$env_name}/$text_out/g;
		#print "*";
		$count++;
	}
	return ($text, $count);
}

sub replace_enumerate_environments($$$$)
{
	my ($text, $env_name, $label_text, $label_type) = (@_);
	my $count = 0;
	#print "(1) $env_name being processed ... $env_name, $label_text, $label_type,\n";
	($text, $count) = replace_generic_environments($text, $env_name, $label_text, $label_type, "enumerate");
	#print "(3) $env_name being processed ... $env_name, $label_text, $label_type,   (text, $count)\n";
	return ($text, $count);
}

sub replace_description_environments($$$$)
{
	my ($text, $env_name, $label_text, $label_type) = (@_);
	#print "(1) $env_name being processed ...\n" if($env_name eq "outcomes");
	return replace_generic_environments($text, $env_name, $label_text, $label_type, "description");
}

sub check_preconditions()
{
	for(my $semester = 1; $semester <= $Common::config{n_semesters}; $semester++)
	{
                foreach my $codcour ( @{$Common::courses_by_semester{$semester}} )
		{
			#Util::print_message("$codcour=>\"$Common::course_info{$codcour}{prefix}\"");
			if(not defined($Common::config{area_priority}{$Common::course_info{$codcour}{prefix}}))
			{
				my $area_all_config = get_template("in-area-all-config-file");
				Util::print_error("Course $codcour has an unknown prefix \"$Common::course_info{$codcour}{prefix}\" ... VERIFY $area_all_config");
			}
		}
	}
}

sub change_number_by_text($)
{
      my ($label) = (@_);
      my $count = 0;
      $count = $label =~ s/(\d)/$Numbers2Text{$1}/g;
      #Util::print_message($count);
      return $label;
}

1;