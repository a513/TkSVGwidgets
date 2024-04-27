#!/usr/bin/wish
#Не забыть убрать
#lappend auto_path ../SVGWIDGETS

package require svgwidgets

variable t
set t ".test"
destroy $t
toplevel $t
wm state $t withdraw
wm state $t normal


proc exitarm {t mestok} {
	variable ::erm
	set erlib [mbutton new "$t.message" -type yesno  -fillnormal white -text "$mestok" -textanchor n]
	set herlib [expr {int([winfo fpixels "$t.message" [$erlib config -height]])}]
	set werlib [expr {int([winfo fpixels "$t.message" [$erlib config -width]])}]

#Главное окно неизменяемое
	wm resizable $t 0 0
	tk busy hold "$t.frame"
	set werlib [expr {[winfo width $t.frame] / 2 - $werlib / 2}]
	set herlib [expr {[winfo height $t.frame] / 4 }]
	set rr [$erlib place -in $t -x $werlib -y $herlib]
	tk busy forget "$t.frame"
	if {$rr != "yes"} {
	    wm resizable $t 1 1
	    return
	}
#Убураем за собой!!!
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
	destroy $t
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
    set path1 [$canv create path "M 0.0 0.0 L 0.0 1.0 L 0.0 16.0 L 1.0 16.0 L 16.0 16.0 L 16.0 15.0 L 16.0 2.0 L 9.0 2.0 L 7.0 0.0 L 7.0 0.0 L 7.0 0.0 L 1.0 0.0 L 0.0 0.0 Z M 1.0 1.0 L 4.0 1.0 L 6.6 1.0 L 7.6 2.0 L 3.6 6.0 L 3.6 6.0 L 1.0 6.0 L 1.0 1.0 Z M 6.0 5.0 L 15.0 5.0 L 15.0 15.0 L 1.0 15.0 L 1.0 7.0 L 2.6 7.0 L 4.0 7.0 L 4.0 7.0 L 4.0 7.0 L 6.0 5.0 Z"]
    $canv itemconfigure $path1 -parent $grfolder -fill $fcol -strokewidth 1 -stroke $fcol
    return $grfolder
}
proc iconExitR {canv fcol} {
    set grfolder [$canv create group]
#Выход смотрит вправо
    set path1 [$canv create path "M 40.0 38.18 L 40.0 52.0 A 2.8 2.8 0.0 0 1 37.19 54.8 L 12.0 54.8 A 2.8 2.8 0.0 0 1 9.16 52.0 L 9.16 11.77 A 2.8 2.8 0.0 0 1 12.0 9.0 L 37.19 9.0 A 2.8 2.8 0.0 0 1 40.0 11.77 L 40.0 25.0" ]
    $canv itemconfigure $path1 -parent $grfolder -fill $fcol -strokewidth 2
    set path [$canv create path "M 46.02 21.95 L 55.93 31.86 L 46.02 41.77 M 55.93 31.86 L 19.59 31.86 " -parent $grfolder -strokewidth 2]
    return $grfolder
}
proc iconExitL {canv fcol} {
    set grfolder [$canv create group]
#Выход смотрит влево
    set path1 [$canv create path "M 19.16 25 L 19.16 11.77 A 2.8 2.8 0.0 0 1 22.0 9.0 L 47.19 9.0 A 2.8 2.8 0.0 0 1 50.0 11.77 L 50.0 52.0  A 2.8 2.8 0.0 0 1 47.19 54.8 L 22.0 54.8 A 2.8 2.8 0.0 0 1 19.16 52.0 L 19.16 38" ]
    $canv itemconfigure $path1 -parent $grfolder -fill $fcol -strokewidth 2
    set path [$canv create path "M 10 21 L 0 31 L 10 41 M 0 31 L 32 31" -parent $grfolder -strokewidth 2]
    return $grfolder
}

proc mesWarn {cb  arrow tinfo anchor {border 2} } {
    variable t
    set  wpoint [$cb canvas]

    switch $arrow {
	"down" {
	    set tongue "0.5 0.3 0.7 5m"
	    set tongue "0.47 0.5 0.52 5m"
	}
	"up" {
	    set tongue "0.5 0.3 0.7 5m"
	}
	"left" {
	    set tongue "0.5 0.3 0.7 5m"
	}
	"right" {
	    set tongue "0.5 0.3 0.7 5m"
	}
	"mes" {
	    set tongue "0.5 0.5 0.5 0m"
#	    set arrow yesno
	    set arrow msg
#	    set arrow up
	}
	default {
puts "Unknown arrow=$tinfo"
	    return
	}
    }
    set erlib [mbutton new "$t.message" -type $arrow -fillnormal aquamarine -tongue "$tongue" -text "$tinfo\n " -textanchor $anchor]
#    set erlib [mbutton new "$t.message" -type "msg" -fillnormal aquamarine -tongue "$tongue" -text "$tinfo\n " -textanchor $anchor]
    puts "erlib=$erlib"
	set wcan [$cb canvas]
	set tlb [winfo toplevel [$cb canvas]]
#Виджет собстаенно  меню 
	set tlm [winfo toplevel [$erlib canvas]]
	set rootx [winfo rootx $wcan]
	set rooty [winfo rooty $wcan]
	set rootxtlb [winfo rootx $tlb]
	set rootytlb [winfo rooty $tlb]
	set x [expr {$rootx - $rootxtlb}]
	set y [expr {$rooty - $rootytlb}]

	set wb [winfo width $wcan] 
	set hb [winfo height $wcan] 
	foreach {x1m y1m x2m y2m} [[$erlib canvas] bbox 0] {break}
	set wm [expr {$x2m - $x1m}]
	set hm [expr {$y2m - $y1m}]
#puts "Method showmenu: x1m=$x1m y1m=$y1m x2m=$x2m y2m=$y2m wm=$wm hm=$hm tlb=$tlb tlm=$tlm"
    switch $arrow {
	down {
		    set x [expr {$x - $wm / 2 + $wb / 2}]
		    set y [expr {$y - $hm + $hb / 2}]
	}
	up {
		    set x [expr {$x - $wm / 2 + $wb / 2}]
		    set y [expr {$y + $hb / 2}]
	    
	}
	left {
		    set x [expr {$x + $wb / 2}]
		    set y [expr {$y + $hb / 2 - $hm / 2}]
	}
	right {
		    set x [expr {$x - $wm + $wb/2 }]
		    set y [expr {$y + $hb / 2 - $hm / 2}]
	}
	msg -
	mes {
		    set x [expr {$x + $wb / 2 - $wm / 2}]
		    set y [expr {$y + $hb / 2 - $hm / 2}]
	}
    }

    wm resizable $t 0 0
    tk busy hold "$t.frame"
    $erlib leave
    update
    after 30
    $erlib place -in $t -x $x -y $y
    tk busy forget "$t.frame"
    wm resizable $t 1 1
}



wm title $t "tcl/tk pack and callout demo"

#Если хотим иметь окно 400x400
$t configure -height 450 -width 450
pack propagate $t 0

$t configure -bg cyan
frame $t.frame -bg yellow
pack $t.frame -fill both -expand 1 -padx 2m -pady 2m 
tkp::canvas $t.c
set svgf [folderbrown $t.c]
set svge [iconExitL $t.c "tan1"]
set mside [list up left down right up left down right up left down right]
set i 0
for { set n 0 } {$n < 4} {incr n} {
    foreach {sd type} {top rect  left round bottom ellipse right rect} {
	set j $i
        incr i
#        label $t.frame.l$i -text $i -relief ridge -bg gray73
	if {$sd == "right"} {
	    set rx "-rx 2m"
	} else {
	    set rx ""
	}
	if {$type == "rect1"} {
	    append rx " -image \\\"$t.c $svgf\\\""
	}
#	puts "[subst "cbutton new $t.frame.l$i -width 7m -height 7m -text $i -type $type $rx"]"
	if {$i == 4 || $i == 8 || $i == 12 } {
	    set cb [eval [subst "cbutton new $t.frame.l$i -width 7m -height 7m -rotate 90 -text {Вертикаль $i} -type $type $rx -compound top -ipad {1m 5m 1m 5m}"] ]
	} elseif {$i == 8 || $i == 116 } {
	    set cb [eval [subst "cbutton new $t.frame.l$i -width 7m -height 7m -text $i -type $type $rx -compound top -ipad {1m 5m 1m 5m}"] ]
	} elseif {$i == 1 || $i == 5} {
	    set cb [eval [subst "cbutton new $t.frame.l$i -width 7m -height 7m -text $i -type $type $rx -compound left -ipad {1m 2c 1m 5m}"] ]
	} else {
	    set cb [eval [subst "cbutton new $t.frame.l$i -width 7m -height 7m -text $i -type $type $rx -compound none"] ]
	}
	$cb config -image "$t.c $svgf" 

#Нажатие клавиши l1 - l4
	if {$i > 0 && $i < 13} {
	    set txt "mesWarn $cb [lindex $mside $j] \{$cb - Вы нажали кнопку\n$t.frame.l$i\nДля закрытия сообщения\nщелкните по мне\} n "

#puts "txt=$txt"
	    $cb config -command  "[set txt]"
	}

        pack $t.frame.l$i -in $t.frame -side $sd -fill both -expand 1
    }
}

set cbut1 [cbutton new $t.frame.b  -text "Выход" -command {exitarm $t  "Вы действительно\n хотите выйти?"} -width 3c -rx 1m -ipad "1m 7m 2m 4m"]

# -bg gray76
set g1 [[$cbut1 canvas] gradient create linear -stops {{0 "#FF3B00"} {1 "#FFFF00"}} -lineartransition {0 0.50 1 0.50}]
set g2 [[$cbut1 canvas] gradient create linear -stops {{0 "#FFFF00"} {1 "#FF3B00"}} -lineartransition {0 0.50 1 0.50}]
set g3 [[$cbut1 canvas] gradient create radial -method pad -units bbox -stops { { 0.00 "#FF3B00" 0.50} { 1.00 "#FFFF00" 0.80}} -radialtransition {0.50 0.46 0.50 0.25 0.25} ]
set g4 [[$cbut1 canvas] gradient create radial -method pad -units bbox -stops { { 0.00 "#FFFF00" 0.50} { 1.00 "#FF3B00" 0.80}} -radialtransition {0.46 0.50 0.50 0.25 0.25} ]
$cbut1 config -fillnormal $g1 -fillenter $g2 -fillpress $g4 -image "$t.c $svge"
pack $t.frame.b -side left -expand 1 -fill both -padx 2m -pady 1m
update
set minw [winfo width $t]
set minh [winfo height $t]
wm minsize $t $minw $minh
mesWarn $cbut1 "mes" "Для начала щелкните по мне\nЗатем можете пощелкать по кнопкам.\nДля выхода щелкните по кнопке Выход" "n"
