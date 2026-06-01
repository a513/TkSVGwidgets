package require svg2can
catch {package require tclusvg}
catch {package require tkfe_svg}

package require svgwidgets

variable ans
set ans ""

#set ::initdir "/usr/share/icons"
set ::initdir [file join [file dirname [info script]] SVGimagesDevices]

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

proc exitfsvg {t} {
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
	set ans [tk_getOpenFile -title "Choose directory" -filetypes $typelist -initialdir $::initdir]
    } else {
	set ans [::FE::fe_getopenfile -title "Choose directory" -filetypes $typelist -initialdir $::initdir]
    }
}
proc clearcan {w10m listIm} {
    if {[info exist svg2can::gradientIDToToken]} {
	unset svg2can::gradientIDToToken
    }
    foreach oo $listIm {
	$oo destroy
    }
    update
    set yim $w10m
    set xim $w10m
    set ximc $xim
    set yim [expr {$yim + $w10m * 2} ]
    return "$yim $xim $ximc"
}

variable t
set t ".test"
destroy $t
toplevel $t

wm state $t withdraw
wm state $t normal

wm geometry $t [winfo pixels . 10c]x[winfo pixels . 8c]+150+150
wm title $t "SVG files folder"

wm protocol $t WM_DELETE_WINDOW "exitfsvg [set t]"

wm geometry . [winfo pixels . 4c]x[winfo pixels . 4c]+50+50

set fr [cframe new  $t.c -type frame -rx 0 -strokewidth 0 -stroke ""]
set bincan [bind $t.c <Configure>]
bind $t.c <Configure> {}

frame $t.main -background gray86
pack $t.main -in $t -fill both -expand 1
if {1} {
ttk::scrollbar $t.main.vscroll -command "$t.c yview"
grid $t.main.vscroll -row 0 -column 1 -rowspan 1 -columnspan 1 -sticky news
grid rowconfig  $t.main 0 -weight 1
grid columnconfig $t.main 0 -weight 1
}
$t.c configure  -yscrollcommand "$t.main.vscroll set"

grid $t.c -in $t.main -column 0 -row 0 -sticky news
set m1 [winfo fpixels $t.c 1m]
set w10m [winfo fpixels $t.c 10m]
set w15m [winfo fpixels $t.c 15m]
set yim $w10m
set xim $w10m

set iddir [ibutton new $t.c -x $xim -y $yim -text "Selecting a folder with SVG files" -help {You haven't selected a folder yet} -height 1.0c -width 1c -command seldir -fontsize 4m]
set yim [expr {$yim + $w10m * 2} ]
set fgr [svg2can::SVGXmlToCanvas $t.c $fpic]
$t.c lower $fgr
$iddir config -image "$t.c $fgr" -pad 1m

update
#set gradCloud [[$fr canvas] gradient create linear -method pad -units bbox -stops { { 0.05 "#87ceeb" 1.00} { 0.17 "#ffffff" 1.00} { 0.29 skyblue 1.00} { 0.87 "#ffffff" 1.00} { 1.00 skyblue 1.00}} -lineartransition {1.00 0.00 0.75 1.00} ]
set gradCloud [[$fr canvas] gradient create radial -stops {{0 "#00bcd4"} {1 "#c0faff"}} -radialtransition {0.50 0.50 0.50 0.5 0.5}]

$fr config -fillnormal $gradCloud
$fr pack -in $t.main -fill both -expand 1
set bindcon [bind [$fr canvas] <Configure>]

foreach {x0 y0 x1 y1} [$t.c bbox all] { $fr config -width [expr {$x1 - $x0 + 200}] -height [expr {$y1 - $y0}] }
#Проверяем наличие пакета tclusvg
    if {[info commands tclusvg] == ""} {
	set usvg 0
    } else {
	set usvg 1
    }
set lsvgO [list ]
while {1} {
#Ждем выбора файла
    vwait ans
    if {$ans == ""} {
	continue
    } 
    tk busy hold .test
    wm geometry $t [winfo pixels . 10c]x[winfo pixels . 8c]
    wm resizable $t 0 0
    after 0
    update
    $iddir config -height 1.0c -width 1c -fontsize [$iddir config -fontsize]
    $iddir config -image "$t.c [$iddir config -isvg]" -pad 1m
puts "VWAIT  ans=$ans"
    if {$ans == ""} {
	continue
    } 

    foreach  {yim xim ximc} [clearcan $w10m $lsvgO] {break}
    set lsvgO [list ]
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
    set nrow [expr {[llength $svgim] / 5}]
    set ncol [expr {[llength $svgim] / 5}]
    foreach img $svgim {
    if {$j == 5} {
	set yim [expr {$yim + $w10m  + $w10m / 2} ]
	set xim [expr {$w10m + 0 }]
	set j 0
    }
    set fimg [file tail $img]
    set zz [ibutton new $t.c -x $xim -y $yim -width 1c -height 1c -text "" -help "$fimg" ]
    lappend lsvgO $zz
    set xim [expr {$xim + $w15m}]

    if {$usvg == 1} {
	set ifd [open $img]
	chan configure $ifd -translation binary
	set xx [read $ifd]
	close $ifd
	set xx [tclusvg $xx -data]
    } else {
	set ifd [open $img]
	chan configure $ifd -translation binary
	set xx [read $ifd]
	close $ifd
    }
    if {![catch {svg2can::SVGXmlToCanvas $t.c $xx} gr] } {
	$zz config -image "$t.c $gr" 
#Уничтожаем оригинал
#puts "GR=$gr"
	$t.c delete $gr
	
	foreach {x0 y0 x1 y1} [$t.c bbox [$zz tag]] {
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
  }

#puts "bind $bincan"
    bind $t.c <Configure> "$bincan"

    bind $t.main.vscroll <Enter>  {foreach {x0 y0 x1 y1} [$t.c bbox all] { $fr config -width [expr {$x1 - $x0}] -height [expr {$y1 - $y0}] };.test.c configure -scrollregion [.test.c bbox all]}
    tk busy forget .test
    wm resizable $t 1 1
}
