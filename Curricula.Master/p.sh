#!/bin/csh
# ./scripts/process-bok.pl CS-UCSP

# ./scripts/gen-scripts.pl CS-UTEC
# ./scripts/process-curricula.pl CS-UTEC
# ../Curricula.out/Peru/CS-UTEC/cycle/2017-I/Plan2017/scripts/gen-eps-files.sh;
# ../Curricula.out/Peru/CS-UTEC/cycle/2017-I/Plan2017/scripts/gen-graph.sh small &
# ./scripts/update-outcome-itemizes.pl CS-UTEC &
# ./scripts/update-page-numbers.pl CS-UTEC;
# ../Curricula.out/Peru/CS-UTEC/cycle/2017-I/Plan2017/scripts/gen-graph.sh big &
# ../Curricula.out/Peru/CS-UTEC/cycle/2017-I/Plan2017/scripts/gen-map-for-course.sh &
# ../Curricula.out/Peru/CS-UTEC/cycle/2017-I/Plan2017/scripts/compile-simple-latex.sh Computing-poster CS-UTEC-poster ../Curricula.out/Peru/CS-UTEC/cycle/2017-I/Plan2017/tex;

./scripts/process-curricula.pl CS-UNSA
./scripts/update-outcome-itemizes.pl CS-UNSA &
./scripts/update-page-numbers.pl CS-UNSA;
../Curricula.out/Peru/CS-UNSA/cycle/2017-I/Plan2017/scripts/gen-graph.sh big &
../Curricula.out/Peru/CS-UNSA/cycle/2017-I/Plan2017/scripts/gen-map-for-course.sh &
../Curricula.out/Peru/CS-UNSA/cycle/2017-I/Plan2017/scripts/compile-simple-latex.sh Computing-poster CS-UNSA-poster ../Curricula.out/Peru/CS-UNSA/cycle/2017-I/Plan2017/tex;
