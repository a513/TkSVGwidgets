#lappend auto_path SVG2CAN
#lappend auto_path TclXML
package require svg2can

package require svgwidgets

#source "svgfile2canvas.tcl"
variable ans
set ans ""
#set ::initdir "/usr/share/icons"
set ::initdir [file home]

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
set arrow_prevision {<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
  <defs id="defs3051">
    <style type="text/css" id="current-color-scheme">
      .ColorScheme-Text {
        color:#232629;
      }
      </style>
  </defs>
  <g transform="translate(1,1)">
    <path style="fill:currentColor;fill-opacity:1;stroke:none" d="m14.292969 3l-6.125 6.125-1.875 1.875 1.875 1.875 6.125 6.125.707031-.707031-6.125-6.125-1.167969-1.167969 1.167969-1.167969 6.125-6.125-.707031-.707031" class="ColorScheme-Text"/>
  </g>
</svg>
}
set arrow_next {<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
  <defs id="defs3051">
    <style type="text/css" id="current-color-scheme">
      .ColorScheme-Text {
        color:#232629;
      }
      </style>
  </defs>
  <g transform="translate(1,1)">
    <path style="fill:currentColor;fill-opacity:1;stroke:none" d="m7.707031 3l-.707031.707031 6.125 6.125 1.167969 1.167969-1.167969 1.167969-6.125 6.125.707031.707031 6.125-6.125 1.875-1.875-1.875-1.875-6.125-6.125" class="ColorScheme-Text"/>
  </g>
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
#    .test.c delete [lindex [.test.c find all] $::delid] end
    return "$yim $xim $ximc"
}


variable t
set t ".test"
destroy $t
toplevel $t


wm state $t withdraw
wm state $t normal

#####################
wm geometry $t [winfo pixels . 12c]x[winfo pixels . 8c]+150+150
wm title $t "Folder with svg-images"
bind $t <Destroy> {if {"%W" == ".test"} {exitarm .test}}

wm geometry . [winfo pixels . 4c]x[winfo pixels . 4c]+50+50

#set fr [cframe new  $t.c -type frame -rx 0 -strokewidth 0 -stroke ""]

if {![info exist ::svg2can::tkpath]} {
    set fr [tkp::canvas $t.c -bg yellow]
} else {
    set fr [[set ::svg2can::tkpath] $t.c -bg yellow]
}

set bincan [bind $t.c <Configure>]
bind $t.c <Configure> {}

ttk::scrollbar $t.vscroll -command "$t.c yview"
ttk::scrollbar $t.hscroll -orient horiz -command "$t.c xview"
grid $t.vscroll -row 0 -column 1 -rowspan 1 -columnspan 1 -sticky news
grid $t.hscroll -row 1 -column 0 -rowspan 1 -columnspan 1 -sticky news
grid rowconfig  $t 0 -weight 1
grid columnconfig $t 0 -weight 1

$t.c configure  -xscrollcommand "$t.hscroll set"  -yscrollcommand "$t.vscroll set"

grid $t.c -in $t -column 0 -row 0 -sticky news
set m1 [winfo fpixels $t.c 1m]
set w10m [winfo fpixels $t.c 10m]
set w15m [winfo fpixels $t.c 15m]
set yim $w10m
set xim $w10m
    set iddir [ibutton new $t.c -x $xim -y $yim -text "Выбора папки с SVG-файлами" -help "Вы еще не выбрали папку" -height 1.0c -width 1c -command seldir]
    set fgr [svg2can::SVGXmlToCanvas $t.c $fpic]
#    set fgr [svg2can::SVGFileToCanvas $t.c "ВыборПапки.svg"]
    $iddir config -image "$t.c $fgr" -pad 1m
    $t.c delete $fgr
    foreach {x1 y1 x2 y2} [$t.c bbox [$iddir move 0 0]] {
	set xprev [expr {$x2 + $m1*2}]
    }
    set yim [expr {$yim + $m1 * 1} ]
    set prev [ibutton new $t.c -x $xprev -y $yim -text "" -help "Предыдущий файл" -height 8m -width 8m -command "variable ans;set ans -1"]
    set fgr [svg2can::SVGXmlToCanvas $t.c $arrow_prevision]
    $prev config -image "$t.c $fgr" -pad 1m
    $t.c delete $fgr
    set xprev [expr {$x2 + $m1 * 10}]
    set next [ibutton new $t.c -x $xprev -y $yim -text "" -help "Следующий файл" -height 8m -width 8m -command "variable ans;set ans 1"]
    set fgr [svg2can::SVGXmlToCanvas $t.c $arrow_next]
    $next config -image "$t.c $fgr" -pad 1m
    $t.c delete $fgr
    set xprev [expr {$x2 + $m1 * 10 * 2}]
    set cmd [cbutton new $t.c -type rect -x $xprev -y $yim -text "Cmds" -rx 1m -height 8m -width 15m -compound none -command "variable ans;set ans Cmds"]

update
grid   $fr -in .test -column 0 -row 0 -sticky news
raise $fr

foreach {x0 y0 x1 y1} [$t.c bbox all] { $fr configure -width [expr {$x1 - $x0 + 200}] -height [expr {$y1 - $y0}] }

set ::delid [llength [$t.c find all]]

while {1} {
variable ans
#Ждем выбора файла
    vwait ans

puts "VWAIT  ans=$ans"
    if {$ans == ""} {
	continue
    }
    if {$ans == "Cmds"} {
	if {[catch {svg2can::SVGFileToCmds $t.c $img} gr] } {
	    puts "Bad file: $img er=$gr"
	} else {
	    if {[info exist img]} {
		puts "File: $img"
		foreach cmd $gr {
		    puts "CMDS=$cmd"
		}
	    }
	}
	continue
    }
    set tekans $ans
    while {[llength [$t.c find all]] > $::delid} {
	    $t.c delete [lindex [$t.c find all] $::delid] end
    }
    foreach  {yim xim ximc} [clearcan $w10m] {break}
    if {$ans != -1 && $ans != 1} {
	catch {unset listSVG}
	set dirname [file dirname $ans]
	set ::initdir $dirname
puts "Choose directory $dirname"
	$iddir config -help $dirname 
	wm title . "Folder - $dirname"
	set listSVG [glob -nocomplain -directory $dirname -types f *.svg]
	set svgim "[lsort $listSVG]"
	set ::tekind [lsearch -exact $svgim "$ans"]
	set ::lendir [llength $svgim]
#	set tekans [lindex $svgim $::tekind]
    } else {
	incr ::tekind $ans
	if {$::tekind < 0} {
	    set ::tekind [expr {$::lendir - 1}]
	} elseif {$::tekind > $::lendir || $::tekind == $::lendir} {
	    set ::tekind 0	    
	}
	
    }
    set tekans [lindex $svgim $::tekind]

    set j 0
    set ximc $xim
    set yimc $yim
#set lencan [expr {[llength $svgim] / 2}]
#nrow - кол-во строк по 5 колонок
    set nrow [expr {[llength $svgim] / 5}]
#ncol - кол-во колонок в последней строке
    set ncol [expr {[llength $svgim] / 5}]
    set t ".test"
#    foreach img $svgim {}
    foreach img $tekans {
#puts "-> $img"
	if {[catch {svg2can::SVGFileToCanvas $t.c $img} gr] } {
	    puts "Bad file: $img er=$gr"
	} else {
	    puts "Ok file: $img groupSVG=$gr bbox=[.test.c bbox $gr]"
#Размещение со сдаигом в низ 
	    lassign [$t.c bbox $gr] x1 y1 x2 y2
	    set svgorig [ibutton new $t.c -x 5m -y 3c -width [expr {$x2 - $x1 + 4}] -height [expr {$y2 - $y1 + 4}] -isvg "$t.c $gr" -stroke black -pad "2" -help "[file tail $img]" -text ""]
	    $t.c delete $gr
	}
    }
}
