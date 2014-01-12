#!/bin/bash
echo "Wich file?"
read fn
grep "S1 10" $fn > ${fn}10
grep "S0 01" $fn > ${fn}01
declare -A labels
labels=([3]=cccc [4]=beta [5]=tau)
for i in ${!labels[@]}
do
value=${labels[$i]}
################# Figure 1 ####################
cat > gnuplot.script << MOROKUMA
set title "${fn} : $value"
set output '${fn}${value}.png'
set terminal pngcairo size 2048,1060 enhanced font ", 25"
set yrange [-500:100]
set key off
plot "$fn" u 2:$i lw 0.5 linecolor rgb "black" w lines, "${fn}01" u 2:$i pt 7 ps 1.5 w p, "${fn}10" u 2:$i pt 7 ps 1.5 w p
MOROKUMA
###############################################
gnuplot < gnuplot.script
rm gnuplot.script
done

