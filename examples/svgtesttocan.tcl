#lappend auto_path SVG2CAN
#lappend auto_path TclXML
package require svg2can
#package require tinydom

package require svgwidgets

#source "svgfile2canvas.tcl"
variable ans
set ans ""
set ::initdir "/usr/share/icons"

#SVG-картинка для выбора папки с svg-файлами
set fpic {<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <defs id="defs3051">
    <style type="text/css" id="current-color-scheme">
      .ColorScheme-Text {
        color:#31363b;
      }
      .ColorScheme-Highlight {
        color:#3daee9;
      }
      </style>
  </defs>
 <path 
     style="fill::currentColor;fill-opacity:1;stroke:none" 
     d="M 2 3 L 2 10 L 1 10 L 1 29 L 12 29 L 13 29 L 31 29 L 31 8 L 30 8 L 30 5 L 16 5 L 14 3 L 2 3 z "
     class="ColorScheme-Highlight"
     />
 <path 
     style="fill-opacity:0.33;fill-rule:evenodd"
     d="m 2,3 0,7 9,0 L 13,8 30,8 30,5 16,5 14,3 2,3 Z"
     />
 <path 
     style="fill:#ffffff;fill-opacity:0.2;fill-rule:evenodd"
     d="M 14 3 L 15 6 L 30 6 L 30 5 L 16 5 L 14 3 z M 13 8 L 11 10 L 1 10 L 1 11 L 12 11 L 13 8 z "
     />
 <path 
     style="fill-opacity:0.2;fill-rule:evenodd"
     d="M 13 8 L 11 9 L 2 9 L 2 10 L 11 10 L 13 8 z M 1 28 L 1 29 L 31 29 L 31 28 L 1 28 z "
     class="ColorScheme-Text"
     />
 <path 
     style="fill:currentColor;fill-opacity:0.6;stroke:none" 
     d="M 11 13 L 11 23 L 21 23 L 21 21 L 21 13 L 11 13 z M 12 14 L 20 14 L 20 20 L 18 18 L 15 21 L 20 21 L 20 22 L 12 22 L 12 14 z M 14 15 A 1 1 0 0 0 13 16 A 1 1 0 0 0 14 17 A 1 1 0 0 0 15 16 A 1 1 0 0 0 14 15 z M 15 19 L 13 21 L 14 21 L 15.5 19.5 L 15 19 z "
     class="ColorScheme-Text"
     />
</svg>
}

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


wm state $t withdraw
wm state $t normal

#####################
wm geometry $t [winfo pixels . 10c]x[winfo pixels . 8c]+150+150
wm title $t "Folder with svg-images"
bind $t <Destroy> {if {"%W" == ".test"} {exitarm .test}}

wm geometry . [winfo pixels . 4c]x[winfo pixels . 4c]+50+50

set fr [cframe new  $t.c -type frame -rx 0 -strokewidth 0 -stroke ""]
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
    set iddir [ibutton new $t.c -x $xim -y $yim -text "Кнопка выбора папки с SVG-файлами" -help "Вы еще не выбрали папку" -height 1.0c -width 1c -command seldir]
	set yim [expr {$yim + $w10m * 2} ]
#	set xim [expr {$ximc + $w10m / 2.0}]
    set fgr [svg2can::SVGXmlToCanvas $t.c $fpic]
    $iddir config -image "$t.c $fgr" -pad 1m
    $t.c delete $fgr
}

update
set gradCloud [[$fr canvas] gradient create linear -method pad -units bbox -stops { { 0.05 "#87ceeb" 1.00} { 0.17 "#ffffff" 1.00} { 0.29 skyblue 1.00} { 0.87 "#ffffff" 1.00} { 1.00 skyblue 1.00}} -lineartransition {1.00 0.00 0.75 1.00} ]
$fr config -fillnormal $gradCloud

$fr pack -in $t.main -fill both -expand 1
#pack   [$fr canvas] -fill both -expand 1
set bindcon [bind [$fr canvas] <Configure>]
#bind [$fr canvas] <Configure> ""

foreach {x0 y0 x1 y1} [$t.c bbox all] { $fr config -width [expr {$x1 - $x0 + 200}] -height [expr {$y1 - $y0}] }

while {1} {
#Ждем выбора файла
    vwait ans

puts "VWAIT  ans=$ans"
    if {$ans == ""} {
	continue
    } 

    foreach  {yim xim ximc} [clearcan $w10m] {break}
set dirname [file dirname $ans]
set ::initdir $dirname
puts "Choose directory $dirname"
    $iddir config -help $dirname 
wm title . "Folder - $dirname"
set listSVG [glob -nocomplain -directory $dirname -types f *.svg]
set svgim "[lsort $listSVG]"

set j 0
set ximc $xim
set yimc $yim
#set lencan [expr {[llength $svgim] / 2}]
#nrow - кол-во строк по 5 колонок
set nrow [expr {[llength $svgim] / 5}]
#ncol - кол-во колонок в последней строке
set ncol [expr {[llength $svgim] / 5}]
foreach img $svgim {
    if {$j == 5} {
#	set yim $w10m
	set yim [expr {$yim + $w10m  + $w10m / 2} ]
	set xim [expr {$w10m + 0 }]
	set j 0
    }
    set fimg [file tail $img]
    set zz [ibutton new $t.c -x $xim -y $yim -width 1c -height 1c -text "" -help "$fimg" ]
#    set yim [expr {$yim + $w15m}]
    set xim [expr {$xim + $w15m}]

#    set gr [SVGFileToCanvas $t.c $img]
#puts "-> $img"
    if {![catch {svg2can::SVGFileToCanvas $t.c $img} gr] } {
	$zz config -image "$t.c $gr" 
#Уничтожаем оригинал
#puts "GR=$gr"
	$t.c delete $gr
	
	foreach {x0 y0 x1 y1} [$t.c bbox [$zz move 0 0]] {
	    if {$x1 > $ximc} {
		set ximc $x1
	    }
	}
	incr j
#	$zz config -pad "0.5m 1m 0.5m 1m" 
	$zz config -pad 1.5m
    } else {
	puts "Bad file: $img er=$gr"
    }
    
    
    update
    $t.c configure -scrollregion [$t.c bbox all]
    foreach {x0 y0 x1 y1} [$t.c bbox all] {
	$fr config -width [expr {$x1 - $x0}] -height [expr {$y1 - $y0}]
    }
}

if {0} {
foreach img $svgim {
    if {$j == $lencan} {
	set yim $w10m
	set yim [expr {$yim + $w10m * 2} ]
	set xim [expr {$ximc + $w10m / 2.0}]
    }
    set fimg [file tail $img]
    set zz [ibutton new $t.c -x $xim -y $yim -width 1c -height 1c -text "" -help "$fimg" ]
    set yim [expr {$yim + $w15m}]

#    set gr [SVGFileToCanvas $t.c $img]
#puts "-> $img"
    if {![catch {SVGFileToCanvas $t.c $img} gr] } {
	$zz config -image "$t.c $gr" 
#Уничтожаем оригинал
#puts "GR=$gr"
	$t.c delete $gr
	
	foreach {x0 y0 x1 y1} [$t.c bbox [$zz move 0 0]] {
	    if {$x1 > $ximc} {
		set ximc $x1
	    }
	}
	incr j
#	$zz config -pad "0.5m 1m 0.5m 1m" 
	$zz config -pad 1.5m
    } else {
	puts "Bad file: $img er=$gr"
    }
    
    
    update
$t.c configure -scrollregion [$t.c bbox all]
foreach {x0 y0 x1 y1} [$t.c bbox all] {
    $fr config -width [expr {$x1 - $x0}] -height [expr {$y1 - $y0}]
}
}
}

puts "bind $bincan"
bind $t.c <Configure> "$bincan"


#foreach {x0 y0 x1 y1} [$t.c bbox all] { $fr config -width [expr {$x1 - $x0 + 200}] -height [expr {$y1 - $y0}] }

bind $t.main.vscroll <Enter>  {foreach {x0 y0 x1 y1} [$t.c bbox all] { $fr config -width [expr {$x1 - $x0}] -height [expr {$y1 - $y0}] };.test.c configure -scrollregion [.test.c bbox all]}
bind $t.main.hscroll <Enter>  {foreach {x0 y0 x1 y1} [$t.c bbox all] { $fr config -width [expr {$x1 - $x0}] -height [expr {$y1 - $y0}] };.test.c configure -scrollregion [.test.c bbox all]}
}