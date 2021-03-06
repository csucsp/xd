#!/bin/csh

set institution=<INST>
setenv CC_Institution <INST>
set filter=<FILTER>
setenv CC_Filter <FILTER>
set version=<VERSION>
setenv CC_Version <VERSION>
set area=<AREA>
setenv CC_Area <AREA>
set CurriculaParam=<AREA>-<INST>
#--END-FILTERS--
set curriculamain=curricula-main
setenv CC_Main $curriculamain
set current_dir = `pwd`
set UnifiedMain=<UNIFIED_MAIN_FILE>
#set UnifiedMain = `echo $FullUnifiedMainFile | sed s/.tex//`

set InTexDir=<IN_LANG_DIR>/<AREA>.tex
set OutputInstDir=<OUTPUT_INST_DIR>
set OutputTexDir=<OUTPUT_TEX_DIR>
set OutputFigDir=<OUTPUT_FIG_DIR>
set OutputHtmlDir=<OUTPUT_HTML_DIR>
set OutputScriptsDir=.<OUTPUT_SCRIPTS_DIR>
set Country=<COUNTRY>
set Language=<LANG>     # Espanol
set current_dir = `pwd`

if($area == "CS") then
    cd <IN_LANG_DIR>/<AREA>.tex/tex4fig
    foreach tmptex ('Pregunta1'  'Pregunta2'  'Pregunta3' 'Pregunta4'  'Pregunta5'  'Pregunta6' 'Pregunta7'  'Pregunta8'  'Pregunta9' 'Pregunta10'  'Pregunta11'  'Pregunta12' 'Pregunta13' 'Pregunta14')
	    if( ! -e $current_dir/<OUTPUT_FIG_DIR>/$tmptex.eps && ! -e $current_dir/<OUTPUT_FIG_DIR>/$tmptex.png ) then
		    echo "******************************** Compiling Questions $area-$institution ($tmptex) ...******************************** "
		    latex $tmptex;
	    #          dvips -Ppdf -Pcmz -o $tmptex.ps $tmptex;
		    dvips -o $tmptex.ps $tmptex;
		    convert $tmptex.eps $tmptex.png;
		    ps2eps -f $tmptex.ps;
		    cp $tmptex.eps $tmptex.png $current_dir/<OUTPUT_FIG_DIR>;
		    rm -f $tmptex.aux $tmptex.dvi $tmptex.log $tmptex.ps $tmptex.eps $tmptex.png;
		    ./scripts/updatelog "$tmptex generated";
		    echo "******************************** File ($tmptex) ... OK ! ********************************";
	    else
		    echo "Figures $tmptex.eps $tmptex.png already exist ... jumping";
	    endif
    end
    cd $current_dir;
endif

cd <IN_LANG_DIR>/<AREA>.tex/tex4fig;
foreach tmptex ('<AREA>' 'course-levels' 'course-coding')
	if( ! -e $current_dir/<OUTPUT_FIG_DIR>/$tmptex.eps && ! -e $current_dir/<OUTPUT_FIG_DIR>/$tmptex.png ) then
		echo "******************************** Compiling coding courses $area-$institution ($tmptex) ...******************************** "
		latex $tmptex;
		dvips -o $tmptex.ps $tmptex;
		ps2eps -f $tmptex.ps;
		convert $tmptex.eps $tmptex.png;
		cp $tmptex.eps $tmptex.png $current_dir/<OUTPUT_FIG_DIR>/.;
		rm $tmptex.aux $tmptex.dvi $tmptex.log $tmptex.ps $tmptex.eps $tmptex.png;
		./scripts/updatelog "$tmptex generated";
		echo "******************************** File ($tmptex) ... OK ! ********************************";
	else
		echo "Figures $tmptex.eps $tmptex.png already exist ... jumping";
	endif
end
echo "Creating coding courses figures ... done !";
cd $current_dir;

cd <OUTPUT_TEX_DIR>;
foreach tmptex ('pie-credits' 'pie-by-levels') # 'pie-horas'
	if( ! -e $current_dir/<OUTPUT_FIG_DIR>/$tmptex.eps && ! -e $current_dir/<OUTPUT_FIG_DIR>/$tmptex.png ) then
		echo "******************************** Compiling pies $area-$institution ($tmptex) ...******************************** ";
		latex $tmptex-main;
		dvips -o $tmptex.ps $tmptex-main;
		echo $area-$institution;
		ps2eps -f $tmptex.ps;
		convert $tmptex.eps $tmptex.png;
		cp $tmptex.eps $tmptex.png $current_dir/<OUTPUT_FIG_DIR>/. ;
		rm $tmptex.aux $tmptex.dvi $tmptex.log $tmptex.ps $tmptex.eps $tmptex.png;
		./scripts/updatelog "$tmptex generated";
		echo "******************************** File ($tmptex) ... OK ! ********************************";
	else
		echo "Figures $tmptex.eps $tmptex.png already exist ... jumping" ;
	endif
end
cd $current_dir;
echo "Creating pies ... done !";

cd <OUTPUT_TEX_DIR>;
foreach graphtype ('curves' 'spider')
    foreach tmptex ('CE' 'CS' 'IS' 'IT' 'SE')
	 set file=$graphtype-$area-with-$tmptex
	 if( ! -e $current_dir/<OUTPUT_FIG_DIR>/$file.eps && ! -e $current_dir/<OUTPUT_FIG_DIR>/$file.png ) then
	      echo "******************************** Compiling curves and spiders $area-$institution ($file) ...******************************** ";
	      latex $file-main;
	      dvips -o $file.ps $file-main.dvi;
	      ps2eps -f $file.ps;
	      convert $file.eps $file.png;
	      cp $file.eps $file.png $current_dir/<OUTPUT_FIG_DIR>/.;
	      rm -f $file.aux $file.dvi $file.log $file.ps $file.eps $file.png;
	      ./scripts/updatelog "$tmptex generated";
	      echo "******************************** File ($file) ... OK ! ********************************";
	else
	      echo "Figures $file.eps $file.png already exist ... jumping" ;
	endif
    end
end
cd $current_dir;

echo "gen-eps-files.sh Done !";

