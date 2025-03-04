lappend auto_path SVG2CAN
lappend auto_path TclXML
package require svg2can
#package require tinydom

package require svgwidgets
variable ans
set ans ""
set ::initdir "/usr/share/icons"

proc exitarm {t} {
#Уничтожаем массив с именами gradient-ов
#	unset svg2can::gradientIDToToken
#parray svg2can::gradientIDToToken
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
	destroy $t.c
	destroy $t
	puts "Пример Folder with SVG Files завершен."
	return
}
proc seldir {} {
    variable ans
    set typelist {{"Тип фийла" {".svg"} {}}}
    set ans [tk_getOpenFile -title "Choose directory" -filetypes $typelist -initialdir $::initdir]
}
proc clearcan {w10m} {
    if {[info exist svg2can::gradientIDToToken]} {
	unset svg2can::gradientIDToToken
    }
set yim $w10m
set xim $w10m
set ximc $xim
	set yim [expr {$yim + $w10m * 2} ]
    set i  0
	foreach {oo} [info class instances ibutton] {
	    if {$i == 0} {
		incr i
		continue
	    }
	    $oo destroy
	}

    return "$yim $xim $ximc"
}


variable t
set t ".test"
destroy $t
toplevel $t
set gr1 -1

wm state $t withdraw
wm state $t normal

#####################
wm geometry $t [winfo pixels . 10c]x[winfo pixels . 8c]+150+150
wm title $t "Folder with svg-images"
bind $t <Destroy> {if {"%W" == ".test"} {exitarm .test}}

wm geometry . [winfo pixels . 4c]x[winfo pixels . 4c]+50+50

set fr [cbutton new  $t.c -type frame -rx 0 -strokewidth 0 -stroke ""]
set bincan [bind $t.c <Configure>]
bind $t.c <Configure> {}

#tkp::canvas $t.c -xscrollcommand ".main.hscroll set"  -yscrollcommand ".main.vscroll set"
frame $t.main -background gray86
#grid .main -in . -column 0 -row 0 -sticky news
pack $t.main -in $t -fill both -expand 1
if {1} {
ttk::scrollbar $t.main.vscroll -command "$t.c yview"
ttk::scrollbar $t.main.hscroll -orient horiz -command "$t.c xview"
grid $t.main.vscroll -row 0 -column 1 -rowspan 1 -columnspan 1 -sticky news
grid $t.main.hscroll -row 1 -column 0 -rowspan 1 -columnspan 1 -sticky news
grid rowconfig  $t.main 0 -weight 1
# -minsize 0
#LISSI
#grid columnconfig $t.main 1 -weight 0 -minsize 0
grid columnconfig $t.main 0 -weight 1
# -minsize 0
}
$t.c configure  -xscrollcommand "$t.main.hscroll set"  -yscrollcommand "$t.main.vscroll set"

#[$fr canvas] configure -bg yellow
grid $t.c -in $t.main -column 0 -row 0 -sticky news
set m1 [winfo fpixels $t.c 1m]
set w10m [winfo fpixels $t.c 10m]
set w15m [winfo fpixels $t.c 15m]
set yim $w10m
set xim $w10m
if {1} {
#    set iddir [ibutton new $t.c -x $xim -y $yim -text "Кнопка выбора SVG-файла" -help "Вы еще не выбрали файл" -height 1.0c -width 1c -command seldir]
    set iddir [ibutton new $t.c -x 5c -y $yim -text "Кнопка выбора SVG-файла" -help "Вы еще не выбрали файл" -height 1.0c -width 1c -command seldir]
	set yim [expr {$yim + $w10m * 2} ]
#	set xim [expr {$ximc + $w10m / 2.0}]
}

update
set gradCloud [[$fr canvas] gradient create linear -method pad -units bbox -stops { { 0.05 "#87ceeb" 1.00} { 0.17 "#ffffff" 1.00} { 0.29 skyblue 1.00} { 0.87 "#ffffff" 1.00} { 1.00 skyblue 1.00}} -lineartransition {1.00 0.00 0.75 1.00} ]
$fr config -fillnormal $gradCloud

$fr pack -in $t.main -fill both -expand 1
#pack   [$fr canvas] -fill both -expand 1
set bindcon [bind [$fr canvas] <Configure>]
bind [$fr canvas] <Configure> ""

foreach {x0 y0 x1 y1} [$t.c bbox all] { $fr config -width [expr {$x1 - $x0 + 200}] -height [expr {$y1 - $y0}] }

while {1} {
#Ждем выбора файла
    vwait ans

    if {$ans == ""} {
	continue
    } 
    if {$gr1 != -1} {
catch {	$t.c delete $gr $gr1 $gr2 $gr3}
    }

    foreach  {yim xim ximc} [clearcan $w10m] {break}
    set dirname [file dirname $ans]
    set ::initdir $фты
puts "Choose file $ans"
    $iddir config -help $ans
    wm title . "File - $ans"
    set listSVG [glob -nocomplain -directory $dirname -types f *.svg]
    set svgim "[lsort $listSVG]"

    set img $ans
#puts "-> $img"
    if {[catch {svg2can::SVGFileToCanvas $t.c $img} gr] } {
	puts "Bad file: $img er=$gr"
    } else {
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
	foreach {width height xy} [$t.c itemcget $gr2 -matrix] {
		foreach {w1 w0} $width {
		    set w0 1
		}
		foreach {h0 h1} $height {
			set h0 0.5
		}
		$t.c itemconfigure $gr2 -matrix [list "$w1 $w0" "$h0 $h1" "$xy"]
	}	
	set gr3 [svg2can::copyGroup $t.c $t.c $gr2 -x 500 -y 100]
	svg2can::rotateid2angle $t.c $gr3 45
    }
#puts "bind $bincan"

if {1} {
    bind $t.c <Configure> "$bincan"
#foreach {x0 y0 x1 y1} [$t.c bbox all] { $fr config -width [expr {$x1 - $x0 + 200}] -height [expr {$y1 - $y0}] }

    bind $t.main.vscroll <Enter>  {foreach {x0 y0 x1 y1} [$t.c bbox all] { $fr config -width [expr {$x1 - $x0}] -height [expr {$y1 - $y0}] };.test.c configure -scrollregion [.test.c bbox all]}
    bind $t.main.hscroll <Enter>  {foreach {x0 y0 x1 y1} [$t.c bbox all] { $fr config -width [expr {$x1 - $x0}] -height [expr {$y1 - $y0}] };.test.c configure -scrollregion [.test.c bbox all]}

}
}
