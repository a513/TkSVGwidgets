package require svgwidgets
#source "../SVGWIDGETS/svgwidgets.tcl"
#package require canvas::gradient
#set tkp::pixelalign 1
#set tkp::depixelize 1
variable b1
variable clfrv
variable went 
variable xgrad 
variable tkpfr

proc updategrad {w gr} {
    variable b1
    variable clfrv
    variable went 
    variable xgrad 
    variable tkpfr
    set gg [gengrad::generateGradient $w $gr]
    if {$gg == ""} {
	return
    }
    update
    set newgr [eval [$tkpfr canvas] [set gg]]
    $tkpfr config -fillnormal $newgr
}

proc folderbrown {canv} {
    set grfolder [$canv create group]
    set path1 [$canv create path "M 2 3 L 2 10 L 1 10 L 1 29 L 12 29 L 13 29 L 31 29 L 31 8 L 30 8 L 30 5 L 16 5 L 14 3 L 2 3 z "]
    $canv itemconfigure $path1 -parent $grfolder -fill "#8b6039" -strokewidth 0
    set path2 [$canv create path "m 2 3 0 7 9 0  L 13 8 30 8 30 5 16 5 14 3 2 3 Z"]
    $canv itemconfigure $path2  -parent $grfolder -fillopacity 0.33 -fillrule "evenodd" -fill black -strokewidth 0
    set path3 [$canv create path "M 14 3 L 15 6 L 30 6 L 30 5 L 16 5 L 14 3 z M 13 8 L 11 10 L 1 10 L 1 11 L 12 11 L 13 8 z"]
    $canv itemconfigure $path3 -parent $grfolder -fillopacity 0.2 -fillrule "evenodd" -fill "#ffffff"  -strokewidth 0
    set path4 [$canv create path "M 13 8 L 11 9 L 2 9 L 2 10 L 11 10 L 13 8 z M 1 28 L 1 29 L 31 29 L 31 28 L 1 28 z"]
    $canv itemconfigure $path4 -parent $grfolder -fillopacity 0.2 -stroke "#614d2e" -fill "#614d2e" -fillrule "evenodd" -strokewidth 0
    return $grfolder
}

proc foldercolor {canv fcol} {
    set grfolder [$canv create group]
    set path1 [$canv create path "M 0.0 0.0 L 0.0 1.0 L 0.0 16.0 L 1.0 16.0 L 16.0 16.0 L 16.0 15.0 L 16.0 2.0 L 9.0 2.0 L 7.0 0.0 L 7.0 0.0 L 7.0 0.0 L 1.0 0.0 L 0.0 0.0 Z \
	    M 1.0 1.0 L 4.0 1.0 L 6.6 1.0 L 7.6 2.0 L 3.6 6.0 L 3.6 6.0 L 1.0 6.0 L 1.0 1.0 Z \
	    M 6.0 5.0 L 15.0 5.0 L 15.0 15.0 L 1.0 15.0 L 1.0 7.0 L 2.6 7.0 L 4.0 7.0 L 4.0 7.0 L 4.0 7.0 L 6.0 5.0 Z"]
    $canv itemconfigure $path1 -parent $grfolder -fill $fcol -strokewidth 1 -stroke $fcol
    return $grfolder
}

proc exitarm {t} {
	foreach {oo} [info class instances cbutton] {
	    $oo destroy
	}
	foreach {oo} [info class instances ibutton] {
	    $oo destroy
	}
	foreach {oo} [info class instances mbutton] {
	    $oo destroy
	}
	foreach {oo} [info class instances cmenu] {
	    $oo destroy
	}
	foreach {oo} [info class instances cframe] {
	    $oo destroy
	}
	destroy $t
	puts "Пример button_PACK завершен."
	return
}

variable t
set t ".test"
destroy $t
toplevel $t
wm state $t withdraw
wm state $t normal

#####################
wm geometry $t 800x600+150+150
wm title $t "tcl/tk svg widgets canvas demo with resize"

#tkp::canvas $t.c -bg yellow
set tkpfr [cframe new $t.c -type frame -strokewidth 0 -stroke "" -fillnormal yellow]

#canvas::gradient $t.c -direction x -color1 cyan -color2 yellow
#Обязательно выполнить update !!!!
update
pack $t.c -in $t -fill both -expand 1 -padx 3m -pady 3m
set bb [bind $t.c <Configure> ]
#bind $t.c <Configure> "scaleGroup %W %w %h %x %y;[set bb]"

set went [cframe new $t.c -type centry -rx 2m -height 7m  -x 110 -y 40 -width 410]

#SVG-фрейм
set b1 [cbutton new $t.c -type frame -rx 5m -y 90 -height 340 -x 40 -width 260]
set hrect 130
set xa1 [cbutton create Прямоугольник $t.c -type rect  -text Прямоугольник -fontweight bold -x 80 -width 180 -y $hrect -height 45]
set hrect [expr {$hrect + 45 + 20}]
set xa2 [cbutton new $t.c -type round  -text Полукруглый -fontsize 3m -x 80 -width 180 -y $hrect -height 45]
set hrect [expr {$hrect + 45 + 20}]
set xa3 [cbutton new $t.c -type ellipse  -text Эллипс -fontsize 5m -fontslant italic -x 80 -width 180 -y $hrect -height 45]
set hrect [expr {$hrect + 45 + 20}]
set xa4 [cbutton new $t.c -type rect  -text Закругленный -fontsize 4m -rx 2m  -compound none -x 80 -width 180 -y $hrect -height 45 -ipad "1m 7m  3m 7m"]
set img [foldercolor [$xa4 canvas] "blue" ]
$xa4 config -image "[$xa4 canvas] $img"
[$xa4 canvas] delete $img

set clfrv [cframe new $t.c -type clframe -text "radio/check кнопки" -rx 1m -strokewidth 1 -stroke red -fillnormal snow -width 220 -height 340]
$clfrv move 430 90
$clfrv boxtext
$clfrv config -fontsize 3.5m -fillbox cyan

set hrect 130
set dy 8
set rc1 [cbutton new $t.c -type radio  -text Radio1 -variable vrc1 -value 1 -x 500 -y $hrect]
set hrect [expr {$hrect + 28 + $dy}]
set rc2 [cbutton new $t.c -type radio  -text Radio2 -variable vrc1 -value 0 -x 500 -y $hrect]
set hrect [expr {$hrect + 28 + $dy}]
set rc3 [cbutton new $t.c -type check  -text Check1 -variable vrc3 -x 500 -y $hrect]
set hrect [expr {$hrect + 28 + $dy}]
set rc4 [cbutton new $t.c -type check  -text Check2 -variable vrc4 -x 470 -y $hrect]
set hrect [expr {$hrect + 28 + $dy}]
set rc5 [cbutton new $t.c -type circle  -text Круг -x 500 -y $hrect]
set hrect [expr {$hrect + 28 + $dy}]
set rc7 [ibutton create Картинка $t.c -width 2c -height 1c -text Картинка -pad "1m 1m 1m 1m" -x 470 -y $hrect -image "::tk::icons::error"]
#set rc7 [ibutton new $t.c -width 2c -height 1c -text Картинка -pad "1m 1m 1m 1m" -x 420 -y $hrect -image "::tk::icons::error"]
set hrect [expr {$hrect + 28 + $dy + 15}]
set rc6 [cbutton new $t.c -type square  -text Квадрат -ipad "1m 1m 1m 1m" -x 470 -y $hrect]
set img [folderbrown [$rc6 canvas]]
$rc6 config -image "[$rc6 canvas] $img"
$rc6 config -fillnormal cyan
puts "Квадрат=$rc6"
[$rc6 canvas] delete $img

bind .test <Destroy> {if {"%W" == ".test"} {catch {exitarm .test}}}
if {$svgwidget::tkpath != "::tko::path"} {
    $tkpfr config -fillnormal gradient5
} else {
    $tkpfr config -fillnormal ::tko::gradient5
}
update
#Кнопка смены драдиента нв основном фрейме
set xgrad [cbutton new $t.c -type round -x 2m -y 2m  -text {Обновить градиент} -command "variable tkpfr;updategrad \[\$tkpfr canvas] \[\$tkpfr config -fillnormal]" -width 150 -height 25]
#$xgrad place -in $t.c -x 2m -y 2m
#

#Меню
set menu [cmenu new $t.c -x 310 -y 440 -direction up ]
$menu add check -text check1 -variable z2
$menu add command -text Команда -command {puts "Нажали кнопку Команда"}
$menu add radio -text radio1 -variable z1 -value 0
$menu add radio -text radio2 -variable z1 -value 1
set mbut [$menu add finish]
$mbut config -stroke chocolate

#.test.c gradient names
if {$svgwidget::tkpath != "::tko::path"} {
    $clfrv config -fillnormal gradient29
} else {
    $clfrv config -fillnormal ::tko::gradient29
}
set gradCloud [[$b1 canvas] gradient create linear -method pad -units bbox -stops { { 0.05 "#87ceeb" 1.00} { 0.17 "#ffffff" 1.00} { 0.29 skyblue 1.00} { 0.87 "#ffffff" 1.00} { 1.00 skyblue 1.00}} -lineartransition {1.00 0.00 0.75 1.00} ]
#set gradCloud1 [tkp::gradient create linear -method pad -units bbox -stops { { 0.05 "#87ceeb" 1.00} { 0.17 "#ffffff" 1.00} { 0.29 skyblue 1.00} { 0.87 "#ffffff" 1.00} { 1.00 skyblue 1.00}} -lineartransition {1.00 0.00 0.75 1.00} ]

#$b1 config -fillnormal gradient45
$b1 config -fillnormal $gradCloud

