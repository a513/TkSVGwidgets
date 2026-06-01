package require svg2can
catch {package require tclusvg}
catch {package require tkfe_svg}

package require svgwidgets

variable ans
set ans ""
#set ::initdir "/usr/share/icons"
set ::initdir [file join [file dirname [info script]] SVGimages]

proc exitxml {t} {
	if {![info exist ::listO]} {
	    set ::listO {}
	}
	set mestok [mc "Are you sure you\nwant to quit?"]
	set erlib [mbutton new "$t.message" -type yesno  -fillnormal white -text "$mestok" -textanchor n]
	set herlib [expr {int([winfo fpixels "$t.message" [$erlib config -height]])}]
	set werlib [expr {int([winfo fpixels "$t.message" [$erlib config -width]])}]

#Главное окно неизменяемое
	wm resizable $t 0 0
#	tk busy hold "$t.frame"
	set werlib [expr {[winfo width $t.c] / 2 - $werlib / 2}]
	set herlib [expr {[winfo height $t.c] / 4 }]
	set rr [$erlib place -in $t -x $werlib -y $herlib]
#	tk busy forget "$t.frame"
	if {$rr != "yes"} {
	    wm resizable $t 1 1
	    return
	}
#Убураем за собой!!!
	set allo "[info class instances cbutton] [info class instances ibutton] [info class instances mbutton] [info class instances cmenu]  [info class instances cframe]"
	foreach {oo} $allo {
	    set ind 0
	    foreach omain $::listO {
		if {"$oo" != "$omain"} {
		    continue
		}
		set ind 1
		break
	    }
	    if {$ind == 0} {
		if {[string rang [$oo canvas] 0 2] != ".st"} {
		    $oo destroy
		}
	    }
	}
	destroy $t
}

proc seldir {} {
    variable ans
    set typelist {{"File type" {".svg"} {}}}
    if {[package version "tkfe_svg"] == ""} {
	after 0 grab release ".__tk_filedialog"
	set ans [tk_getOpenFile -title "Choose SVG file" -filetypes $typelist -initialdir $::initdir]
    } else {
	set ans [::FE::fe_getopenfile -title "Choose SVG file" -filetypes $typelist -initialdir $::initdir]
    }
}
proc clearcan {w10m} {
    if {[info exist svg2can::gradientIDToToken]} {
	unset svg2can::gradientIDToToken
    }
set yim $w10m
set xim $w10m
set ximc $xim
	set yim [expr {$yim + $w10m * 2} ]
if (0) {
    set i  0



	foreach {oo} [info class instances ibutton] {
	    if {$i == 0} {
		incr i
		continue
	    }
	    $oo destroy
	}
}
    return "$yim $xim $ximc"
}


variable t
set t ".test"
destroy $t
toplevel $t


wm state $t withdraw
wm state $t normal

#####################
#wm geometry $t [winfo pixels . 10c]x[winfo pixels . 8c]+150+150
wm geometry $t 600x300+150+150
wm title $t "View SVG-file"
wm protocol $t WM_DELETE_WINDOW "exitxml [set t]"

wm geometry . [winfo pixels . 4c]x[winfo pixels . 4c]+50+50

set fr [cbutton new  $t.c -type frame -rx 0 -strokewidth 0 -stroke ""]
set bincan [bind $t.c <Configure>]
bind $t.c <Configure> {}

frame $t.main -background yellow
pack $t.main -in $t -fill both -expand 1

ttk::scrollbar $t.main.vscroll -command "$t.c yview"
ttk::scrollbar $t.main.hscroll -orient horiz -command "$t.c xview"
grid $t.main.vscroll -row 0 -column 1 -rowspan 1 -columnspan 1 -sticky news
grid $t.main.hscroll -row 1 -column 0 -rowspan 1 -columnspan 1 -sticky news
grid rowconfig  $t.main 0 -weight 1
grid columnconfig $t.main 0 -weight 1
$t.c configure  -xscrollcommand "$t.main.hscroll set"  -yscrollcommand "$t.main.vscroll set"

grid $t.c -in $t.main -column 0 -row 0 -sticky news -columnspan 2 -rowspan 2
grid columnconfigure $t.main 0 -weight 1
grid rowconfigure $t.main 0 -weight 1

set m1 [winfo fpixels $t.c 1m]
set w10m [winfo fpixels $t.c 10m]
set w15m [winfo fpixels $t.c 15m]
set yim $w10m
set xim $w10m
set iddir [ibutton new $t.c -x $xim -y $yim -text "Select SVG file" -help "You haven't selected a file yet" -height 1.0c -width 1c -command seldir -fontsize 5m]

set yim [expr {$yim + $w10m * 2} ]

update
#set gradCloud [[$fr canvas] gradient create linear -method pad -units bbox -stops { { 0.05 "#87ceeb" 1.00} { 0.17 "#ffffff" 1.00} { 0.29 skyblue 1.00} { 0.87 "#ffffff" 1.00} { 1.00 skyblue 1.00}} -lineartransition {1.00 0.00 0.75 1.00} ]
set gradCloud [[$fr canvas] gradient create radial -stops {{0 "#00bcd4"} {1 "#c0faff"}} -radialtransition {0.50 0.50 0.50 0.5 0.5}]

$fr config -fillnormal $gradCloud

$fr pack -in $t.main -fill both -expand 1
set bindcon [bind [$fr canvas] <Configure>]
bind [$fr canvas] <Configure> ""

foreach {x0 y0 x1 y1} [$t.c bbox all] { $fr config -width [expr {$x1 - $x0 + 200}] -height [expr {$y1 - $y0}] }

set gr1 -1
while {1} {
#Ждем выбора файла
    vwait ans

    if {$ans == ""} {
	continue
    } 

    if {$gr1 != -1} {
	$t.c delete $gr $gr1 $gr2 $gr3
    }
    wm geometry $t 600x300
    foreach  {yim xim ximc} [clearcan $w10m] {break}
$iddir destroy
after 0
update
set iddir [ibutton new $t.c -x $w10m -y $w10m -text "Select SVG file" -height 1.0c -width 1c -command seldir -fontsize 5m]
    set dirname [file dirname $ans]
    set ::initdir $dirname
puts "Choose file $ans"
    $iddir config -help $ans
    wm title . "File - $ans"
    set listSVG [glob -nocomplain -directory $dirname -types f *.svg]
    set svgim "[lsort $listSVG]"

    set img $ans
#puts "-> $img"
    if {[catch {open $img r} fd]} {
	set tail [file tail $img]
	tk_messageBox -icon error -title "Error" -message "Cannot read $tail : $fd"
	return
    }
    fconfigure $fd -encoding utf-8
    chan configure $fd -translation binary
    set xml_or [read $fd]
    close $fd
    if {[info commands tclusvg] == ""} {
	set usvg 0
	set xml $xml_or
    } else {
	set usvg 1
	set xml [tclusvg $xml_or -data]
    }

    if {[catch {svg2can::SVGXmlToCanvas $t.c $xml} gr] } {
	puts "Bad Xml: $xml er=$gr  IMG=$img"
    } else {
#Кнопку выбора файла на передний план
	$iddir config -height 1.0c -width 1c -fontsize [$iddir config -fontsize]
	$t.c raise [$iddir tag]
#$iddir config -isvg ".test.c [set gr]"
	foreach {x0 y0 xe ye} [$t.c bbox $gr] {
	    set wn [expr {($xe - $x0) * 4}]
	    set hn [expr {($ye - $y0) * 3}]
	}
#	  set gr1 [copyGroup $t.c $t.c $gr -x 100 -y 100 -width $wn -height $hn]
	  set gr1 [svg2can::copyGroup $t.c $t.c $gr -x 100 -y 100 -width 4c -height 3c]
#Изменение размеров - ширины и высоты
	set scalex 4
	set scaley 3

	set gr2 [svg2can::copyGroup $t.c $t.c $gr1 -x 300 -y 100]
	foreach {width height xy} [$t.c itemcget $gr1 -matrix] {break}
#skewX skewY
#puts "IMG=$img matrix=[$t.c itemcget $gr2 -matrix]"
	if {[$t.c itemcget $gr1 -matrix] == ""} {
	    if {$tkpath == "::tkp::canvas"} {
		$t.c itemconfigure $gr1 -matrix "{1 0} {0 1} {0 0}"
	    } else {
		$t.c itemconfigure $gr1 -matrix "1 0 0 1 0 0"
	    }
	}
	lassign [$t.c itemcget $gr1 -matrix]  w1 w0 h0 h1 x y
	set typec 0
	if {$h1 == ""} {
	    lassign "$h0" x y 
	    lassign "$w0" h0 h1 
	    lassign "$w1" w1 w0 
    	    set typec 1
	} 
	set w0 1
	set h0 0.5


	if {$typec == 1} {
	    $t.c itemconfigure $gr2 -matrix [list "$w1 $w0" "$h0 $h1" "$x $y"]
	} else {
	    $t.c itemconfigure $gr2 -matrix "$w1 $w0 $h0 $h1 $x $y"		
	}
	puts "IMG1=$img W1=$w1 w0-$w0 xy=$x$y"

if {0} {


	foreach {width height xy} [$t.c itemcget $gr2 -matrix] {
		foreach {w1 w0} $width {
puts "IMG=$img W1=$w1 w0-$w0 xy=$xy"
		    set w0 1
		}
		foreach {h0 h1} $height {
puts "IMG=$img H0=$h0 H1-$h1"
			set h0 0.5
		}
		$t.c itemconfigure $gr2 -matrix [list "$w1 $w0" "$h0 $h1" "$xy"]
	}	
}
	set gr3 [svg2can::copyGroup $t.c $t.c $gr2 -x 300 -y 75]
#puts "GR3=$gr3"
    $t.c delete $gr2 
#	svg2can::rotateid2angle $t.c $gr3 45
#puts "GR3=$gr3 ROTATE"
	
	
    }
#puts "bind $bincan"

    bind $t.c <Configure> "$bincan"

    bind $t.main.vscroll <Enter>  {foreach {x0 y0 x1 y1} [$t.c bbox all] { $fr config -width [expr {$x1 - $x0}] -height [expr {$y1 - $y0}] };.test.c configure -scrollregion [.test.c bbox all]}
    bind $t.main.hscroll <Enter>  {foreach {x0 y0 x1 y1} [$t.c bbox all] { $fr config -width [expr {$x1 - $x0}] -height [expr {$y1 - $y0}] };.test.c configure -scrollregion [.test.c bbox all]}

}
