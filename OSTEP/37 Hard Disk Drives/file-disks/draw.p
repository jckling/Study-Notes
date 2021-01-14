set title "Shortest Access Time First (SATF)"
set xlabel "Size of scheduling window"
set ylabel "Time"

set grid

set term pngcairo truecolor nocrop enhanced size 3000,2000 font "arial bold,30" linewidth 3
set output "result.png"

plot "data" using 1:2 title "Seek" with lines,\
    "data" using 1:3 title "Rotate" with lines,\
    "data" using 1:4 title "Transfer" with lines,\
    "data" using 1:5 title "Total" with lines
