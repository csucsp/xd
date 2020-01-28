#!/bin/csh
set pdfparam=$1
set htmlparam=$2
set pdf=0
set html=0

if($pdfparam == "y" || $pdfparam == "Y" || $pdfparam == "yes" || $pdfparam == "Yes" || $pdfparam == "YES") then
    set pdf=1
else if($pdfparam == "n" || $pdfparam == "N" || $pdfparam == "no" || $pdfparam == "No" || $pdfparam == "NO") then
    set pdf=0
else
    echo "Error in pdf param"
    exit
endif

if($htmlparam == "y" || $htmlparam == "Y" || $htmlparam == "yes" || $htmlparam == "Yes" || $htmlparam == "YES") then
    set html=1
else if($htmlparam == "n" || $htmlparam == "N" || $htmlparam == "no" || $htmlparam == "No" || $htmlparam == "NO") then
    set html=0
else
    echo "Error in html param"
    exit
endif
echo "pdf=$pdf, html=$html"

set LogDir=./out/log
date > ./out/log/Peru-IS-UNSA-time.txt
#--BEGIN-FILTERS--
set institution=UNSA
setenv CC_Institution UNSA
set filter=UNSA,SPC
setenv CC_Filter UNSA,SPC
set version=final
setenv CC_Version final
set area=IS
setenv CC_Area IS
set CurriculaParam=IS-UNSA
#--END-FILTERS--
set curriculamain=curricula-main
setenv CC_Main curricula-main
set current_dir = `pwd`

set Country=Peru
set OutputDir=./out/Peru/IS-UNSA
set OutputTexDir=./out/Peru/IS-UNSA/tex
set OutputScriptsDir=./out/Peru/IS-UNSA/scripts
set OutputHtmlDir=./out/Peru/IS-UNSA/html

./clean
# ls IS*.tex | xargs -0 perl -pi -e 's/CATORCE/UNOCUATRO/g' 

mkdir -p ./out/log
./scripts/process-curricula.pl IS-UNSA 
./out/Peru/IS-UNSA/scripts/gen-eps-files.sh IS UNSA Peru Espanol
./scripts/gen-graph.sh IS UNSA Peru Espanol small 

mkdir -p ./out/Peru/IS-UNSA/bin
if($pdf == 1) then
      # latex -interaction=nonstopmode curricula-main
      latex curricula-main
      bibtex curricula-main1
      
      ./scripts/compbib.sh curricula-main > ./out/log/Peru-IS-UNSA-errors-bib.txt

      latex curricula-main
      latex curricula-main

      echo IS-UNSA
      dvips -o ./out/Peru/IS-UNSA/bin/IS-UNSA.ps curricula-main.dvi
      echo IS-UNSA
      ps2pdf ./out/Peru/IS-UNSA/bin/IS-UNSA.ps out/pdfs/IS-UNSA.pdf
      rm -rf ./out/Peru/IS-UNSA/bin
endif

./scripts/update-page-numbers.pl IS-UNSA
./scripts/gen-graph.sh IS UNSA Peru Espanol big

if($html == 1) then
      rm unified-curricula-main* 
      ./scripts/gen-html-main.pl IS-UNSA

      latex unified-curricula-main
      bibtex unified-curricula-main
      latex unified-curricula-main
      latex unified-curricula-main

      dvips -o unified-curricula-main.ps unified-curricula-main.dvi
      ps2pdf unified-curricula-main.ps unified-curricula-main.pdf
      rm unified-curricula-main.ps unified-curricula-main.dvi

      rm -rf ./out/Peru/IS-UNSA/html
      mkdir -p ./out/Peru/IS-UNSA/html
      mkdir ./out/Peru/IS-UNSA/html/figs
      cp ./in/lang.Espanol/figs/pdf.jpeg ./in/lang.Espanol/figs/star.gif ./in/lang.Espanol/figs/none.gif ./out/Peru/IS-UNSA/html/figs/.

      latex2html -t "Curricula IS-UNSA" \
      -dir "./out/Peru/IS-UNSA/html/" -mkdir \
      -toc_stars -local_icons -show_section_numbers \
      -address "Generado por <A HREF='http://socios.spc.org.pe/ecuadros/'>Ernesto Cuadros-Vargas</A> <ecuadros AT spc.org.pe><BR>basado en el modelo de la <A HREF='http://www.spc.org.pe/'>Sociedad Peruana de Computación</A> y en la Computing Curricula de <A HREF='http://www.acm.org/'>ACM</A>/<A HREF='http://www.aisnet.org/'>AIS</A>" \
      unified-curricula-main
      #-split 3 -numbered_footnotes -images_only -timing -html_version latin1 \

      ./scripts/update-analytic-info.pl IS-UNSA
endif

./scripts/compile-simple-latex.sh small-graph-curricula IS-UNSA-small-graph-curricula ./out/Peru/IS-UNSA/tex
./scripts/compile-simple-latex.sh Computing-poster IS-UNSA-poster ./out/Peru/IS-UNSA/tex

./out/Peru/IS-UNSA/scripts/gen-syllabi.sh

if ($pdf == 1) then
      # Generate Books
      ./scripts/gen-book.sh IS UNSA Peru BookOfSyllabi       	pdflatex
      ./scripts/gen-book.sh IS UNSA Peru BookOfDeliveryControl       pdflatex      
      ./scripts/gen-book.sh IS UNSA Peru BookOfDescriptions  	pdflatex
      ./scripts/gen-book.sh IS UNSA Peru BookOfUnitsByCourse 	latex
      ./scripts/gen-book.sh IS UNSA Peru BookOfBibliography  	pdflatex
endif

if($html == 1) then
      #./out/Peru/IS-UNSA/scripts/gen-syllabi.sh
      mkdir ./out/Peru/IS-UNSA/html/syllabi
      cp ./out/Peru/IS-UNSA/tex/syllabi/* ./out/Peru/IS-UNSA/html/syllabi/*
endif

date >> ./out/log/Peru-IS-UNSA-time.txt
more ./out/log/Peru-IS-UNSA-time.txt
#./scripts/testenv.pl
beep
beep
