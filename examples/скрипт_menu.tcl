package require svgwidgets

variable foldersfirst
variable details
variable sepfolders
variable t
set t ".testmenu"
destroy $t
toplevel $t
wm state $t withdraw
wm state $t normal
wm title $t "Sample SVG menu"
wm protocol $t WM_DELETE_WINDOW {exitarm ".testmenu" [mc "Are you sure you\nwant to quit?"]}
set ::bgold [. cget -bg]
set ::geo [wm geometry .]
set ::min [wm minsize .]
#Меню создаются в окнах (toplevel) ::tmenu=1 в отдельных окнах, tmenu=0 - в главном окне
#Каждое меню создается на отдельном холсте
#set ::tmenu 0
#Каждое меню создается в отдельно окне
set ::tmenu 1
set ::cmenubut ""
set ::tsubmenu ""
if {![info exist ::lang]} {
    set ::lang "us"
}

proc exitarm {t mestok} {
	if {$t == "."} {
	    set t1 ""
	} else {
	    set t1 $t
	}
	set erlib [mbutton new "$t1.message" -type yesno  -fillnormal white -text "$mestok" -textanchor n]
	set herlib [expr {int([winfo fpixels "$t1.message" [$erlib config -height]])}]
	set werlib [expr {int([winfo fpixels "$t1.message" [$erlib config -width]])}]

#Главное окно неизменяемое
	wm resizable $t 0 0
	tk busy hold $t
	set werlib [expr {[winfo width $t] / 2 - $werlib / 2}]
	set herlib [expr {[winfo height $t] / 4 }]
#	eval bind . <Configure> \{raise $t1.message $t1._Busy\}
	set rr [$erlib place -in $t -x $werlib -y $herlib]
	if {[tk busy status $t]} {
	    tk busy forget $t
	}
#	bind . <Configure> {}
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
	foreach {oo} [info class instances cframe] {
	    $oo destroy
	}
#	destroy .b
	wm resizable $t 1 1
	wm geometry $t $::geo
	eval wm minsize $t $::min
	. configure -bg $::bgold
	wm title . "Следующий пример"
	if {$t != "."} {
	    destroy $t
	}
	if {$::argc > -1} {
	    exit
	}
	
}

proc displaymenu {name index op} {
    variable rad
    $::butsub config -displaymenu $rad
    $::osnmenu config -displaymenu $rad
}

proc showSubMenu {fm {mtype 0}} {
    variable t
puts "showSubMenu START:  fm=$fm  mtype=$mtype RETURN"
#return
#	set ::tsubmenu [cmenu new $fm.subMenu -tongue "0.45 0.5 0.55 2m" -strokewidth 2 -pad 1m]
#####################
    set direct left
    if {$::tsubmenu != ""}  {
	if {[info class instances cmenu $submenu] != ""} {
	    $::tsubmenu destroy
	}
    }
    if {$mtype == 1} {
	set mplace "window"
	set tekwin {}
    } else {
	set mplace "canvas"
	set tekwin $t
    }
    set ::tsubmenu [cmenu new $tekwin$fm -tongue "0.45 0.5 0.55 2m" -strokewidth 2 -pad 1m -fillnormal snow -stroke gray70 -direction $direct -place $mplace]

    set i 0
#    foreach hcol  [list Размер Дата Полномочия] {}
    foreach hcol  [list Size Date Permissions] {
	set tt [mc $hcol]
	set ch$i [$::tsubmenu add check -text $tt -variable sub$i]
	set chsep [$::tsubmenu add separator ]
	$chsep config -stroke "" -fillnormal "" -fillenter "##"
#Состав расширенного просмотра
	incr i
    }
puts "showSubMenu END: i=$i hcol=$hcol"
    set chsep [$::tsubmenu add separator ]
    $chsep config -stroke "" -fillnormal "" -fillenter "##"
    set chsep [$::tsubmenu add finish]
    return $::tsubmenu
}

proc showContextMenu {w x y rootx rooty fm typefb {mtype 0}} {
    variable t
#w - окно, в котором появляется контекстное меню
puts "showContextMenu START t=$t w=$w fm=$fm typrfb=$typefb ::tmenu=$::tmenu"
    variable dir
    set padddir1 "M 2 2 L 2 14 L 9 14 L 9 13 L 3 13 L 3 8 L 5 8 L 6.9980469 6 L 13 6 L 13 9 L 14 9 L 14 4 L 9.0078125 4 L 7.0078125 2 L 7 2.0078125 L 7 2 L 2 2 Z"
    set padddir2 "M 11 9 L 11 11 L 9 11 L 9 12 L 11 12 L 11 14 L 12 14 L 12 12 L 14 12 L 14 11 L 12 11 L 12 9 L 11 9 Z"
    set pdeldir1 "M 2 2 L 2 14 L 9 14 L 9 13 L 3 13 L 3 8 L 5 8 L 6.9980469 6 L 13 6 L 13 9 L 14 9 L 14 4 L 9.0078125 4 L 7.0078125 2 L 7 2.0078125 L 7 2 L 2 2 Z"
    set pdeldir2 "M 11 11 L 11 11 L 9 11 L 9 12 L 14 12 L 14 11 L 12 11 L 11 11 Z"
    set paddfile1 "M 3.0 11.4375 L 3.0 3.0 L 7.4296875 3.0 L 11.8330078125 3.0 L 14.28515625 5.4521484375 L 16.7109375 7.8779296875 L 16.7109375 9.6708984375 
	L 16.7109375 11.4375 L 15.65625 11.4375 L 14.6279296875 11.4375 L 14.548828125 9.9345703125 L 14.4697265625 8.4052734375 
	L 12.966796875 8.326171875 L 11.4638671875 8.2470703125 L 11.384765625 6.744140625 L 11.3056640625 5.2412109375 L 8.220703125 5.162109375 
	L 5.109375 5.0830078125 L 5.109375 11.4375 L 5.109375 17.765625 L 9.328125 17.765625 L 13.546875 17.765625 L 13.546875 18.8203125 
	L 13.546875 19.875 L 8.2734375 19.875 L 3.0 19.875 L 3.0 11.4375 Z"
    set paddfile2 "M 17.0 13.0 L 17.0 15.0 L 15.0 15.0 L 15.0 16.0 L 17.0 16.0 L 17.0 18.0 L 18.0 18.0 L 18.0 16.0 L 20.0 16.0 L 20.0 15.0 L 18.0 15.0 L 18.0 13.0 L 17.0 13.0 Z"

    set pdelfile1 "M 3.0 11.4375 L 3.0 3.0 L 7.4296875 3.0 L 11.8330078125 3.0 L 14.28515625 5.4521484375 L 16.7109375 7.8779296875 L 16.7109375 9.6708984375 
	L 16.7109375 11.4375 L 15.65625 11.4375 L 14.6279296875 11.4375 L 14.548828125 9.9345703125 L 14.4697265625 8.4052734375 
	L 12.966796875 8.326171875 L 11.4638671875 8.2470703125 L 11.384765625 6.744140625 L 11.3056640625 5.2412109375 L 8.220703125 5.162109375 
	L 5.109375 5.0830078125 L 5.109375 11.4375 L 5.109375 17.765625 L 9.328125 17.765625 L 13.546875 17.765625 L 13.546875 18.8203125 
	L 13.546875 19.875 L 8.2734375 19.875 L 3.0 19.875 L 3.0 11.4375 Z"
    set pdelfile2 "M 12.0 13.0 L 12.0 13.0 L 19.5 13.0 L 19.5 15.25 L 12.0 15.25 Z"

    set prename1 "M 31.25 57.5 C 31.25 56.875 32.5 56.25 34.125 56.25 C 35.625 56.25 38.25 55.375 39.75 54.25 C 42.375 52.375 42.5 51.625 42.5 31.25 
	C 42.5 10.875 42.375 10.125 39.75 8.25 C 38.25 7.125 35.625 6.25 34.125 6.25 C 32.5 6.25 31.25 5.75 31.25 5.0 C 31.25 3.0 37.875 3.5 41.0 5.75 
	C 43.5 7.5 44.0 7.5 46.5 5.75 C 49.625 3.5 56.25 3.0 56.25 5.0 C 56.25 5.75 55.0 6.25 53.375 6.25 C 48.75 6.25 45.0 9.625 45.0 13.875 L 45.0 17.5 
	L 53.125 17.5 L 61.25 17.5 L 61.25 31.25 L 61.25 45.0 L 53.125 45.0 L 45.0 45.0 L 45.0 48.625 C 45.0 52.875 48.75 56.25 53.375 56.25 
	C 55.0 56.25 56.25 56.875 56.25 57.5 C 56.25 59.5 49.625 59.0 46.5 56.75 C 44.0 55.0 43.5 55.0 41.0 56.75 C 37.875 59.0 31.25 59.5 31.25 57.5 Z "
    set prename2 "M 58.75 31.25 L 58.75 20.0 L 51.875 20.0 L 45.0 20.0 L 45.0 31.25 L 45.0 42.5 L 51.875 42.5 L 58.75 42.5 L 58.75 31.25 Z "
    set prename3 "M 1.25 31.25 L 1.25 17.5 L 20.0 17.5 C 31.625 17.5 38.75 18.0 38.75 18.75 C 38.75 19.5 32.125 20.0 21.25 20.0 L 3.75 20.0 L 3.75 31.25 
	L 3.75 42.5 L 21.25 42.5 C 32.125 42.5 38.75 43.0 38.75 43.75 C 38.75 44.5 31.625 45.0 20.0 45.0 L 1.25 45.0 L 1.25 31.25 Z"

#puts "showContextMenu: w=$w fm=$fm x=$x y=$y rootx=$rootx rooty=$rooty mtype=$mtype"
    if {$dir == 0} {
	set tcont "file"
    } else {
	set tcont "directory"
    }
    if {[info exist ::cmenudf] && $::cmenudf != "" } {
	if {[info class instances cmenu $::cmenudf] != ""} {
	    $::cmenudf destroy
	}
    }
if {0} {
#В отдельном окне
    set m46 [winfo fpixels $fm 46m]
    set wcont [winfo width $w]
    set wrootx [winfo rootx $w]
#Если контекстное меню не умещается во фрейм, то оно создается в отдельном окне
#    if {$mtype == 1} {}
#    if {[expr {($rootx + $m46) >  ($wrootx + $wcont)}]} {}
    if {[expr {($rootx + $m46) >  ($wrootx + $wcont)}] || $::tmenu} {
# || $m46
	set mtype 1
    } else {
	set mtype 0
    }
}
    if {$::tmenu == 1 } {
	set mplace "window"
	set tekwin {}
    } else {
	set mplace "canvas"
	set tekwin $t
    }
if {[info exist ::contMenu]} {
    if {[info class instances cmenu $::contMenu] != ""} {
	$::contMenu destroy
    }
    unset ::contMenu
}
    set cmenu1 [cmenu new "[set tekwin]$fm" -tongue "0.5 0.5 0.5 0" -direction down -strokewidth 0.5m -stroke chocolate -pad 1m -height 6m -place $mplace -fillnormal snow]
set ::contMenu $cmenu1
#    eval "$cmenu1 config -command {catch {[set cmenu1] destroy};set ::fdmenu 1}"
    
    set canCtx [$cmenu1 canvas]
    set adddir [$canCtx create group]
    set adddir1 [$canCtx create path "$padddir1" -fill black -strokewidth 0 -parent $adddir]
    set adddir2 [$canCtx create path "$padddir2" -fill black -strokewidth 0 -parent $adddir]
    set ::cmenudf $cmenu1
#Добавить команду separator а пока
    set cmd7 [$cmenu1 add separator]

      if {$tcont == "file"} {
	set renfile [$canCtx create group]
	set renfile1 [$canCtx create path "$prename1" -parent $renfile -stroke black]
	set renfile2 [$canCtx create path "$prename2" -parent $renfile -stroke black ]
	set renfile3 [$canCtx create path "$prename3" -parent $renfile -stroke black ]

	set addfile [$canCtx create group]
	set addfile1 [$canCtx create path "$paddfile1" -fill black -strokewidth 0 -parent $addfile]
	set addfile2 [$canCtx create path "$paddfile2" -fill black -strokewidth 0 -parent $addfile]
#set gr [$canCtx create group]
	set delfile [$canCtx create group]
	set delfile1 [$canCtx create path "$pdelfile1" -fill black -strokewidth 0 -parent $delfile]
	set delfile2 [$canCtx create path "$pdelfile2" -fill black -strokewidth 0 -parent $delfile]
        set cmd2 [$cmenu1 add command -height 7m -text [mc "Delete file"] -ipad "1m 5m 1m 5m" -compound left]
	$cmd2 config -image "$canCtx $delfile"
#puts "DELFILE canCtx=$canCtx gr=$gr delfile=$delfile"
puts "DELFILE cmd2=$cmd2 canCtx=$canCtx gr=[$cmd2 config -isvg]"
	$canCtx delete $delfile
        eval "$cmd2 config -command {[set cmenu1] forget;puts {Удаляем файл}; set ::fdmenu 1; tk busy forget [set t]}"
	set cmd3 [$cmenu1 add command -text [mc "Rename file"] -ipad "1m 5m 1m 5m" -compound left]
	$cmd3 config -image "$canCtx $renfile"
puts "RenameFILE cmd3=$cmd3 canCtx=$canCtx gr=[$cmd3 config -isvg]"
	$canCtx delete $renfile
	set isvg [$cmd3 config -isvg]
	[$cmd3 canvas] itemconfigure $isvg -strokewidth 2.0
	
        eval "$cmd3 config -command {[set cmenu1] forget;puts {Переименовываем файл}; set ::fdmenu 1; tk busy forget [set t]}"
	set cmd7 [$cmenu1 add command -text [mc {Create an empty file}] -compound left]
	$cmd7 config -image "$canCtx $addfile"
#	$canCtx delete $addfile
	eval "$cmd7 config -command {[set cmenu1] forget;puts {Создаем пустой файл}; set ::fdmenu 1; tk busy forget [set t]}"
	set cmd4 [$cmenu1 add separator]
      }
      if {$tcont == "directory"} {
	set deldir [$canCtx create group]
	set deldir1 [$canCtx create path "$pdeldir1" -parent $deldir]
	set deldir2 [$canCtx create path "$pdeldir2" -parent $deldir]
	set rendir [$canCtx create group]
	set rendir1 [$canCtx create path "$prename1" -parent $rendir -stroke black]
	set rendir2 [$canCtx create path "$prename2" -parent $rendir -stroke black ]
	set rendir3 [$canCtx create path "$prename3" -parent $rendir -stroke black ]
	set cmd4 [$cmenu1 add command -text [mc {Delete folder}]  -compound left]
        eval "$cmd4 config -command {[set cmenu1] forget;puts {Удаляем каталог}; set ::fdmenu 1; tk busy forget [set t]}"
	$cmd4 config -image "$canCtx $deldir"
	$canCtx delete $deldir

	set cmd5 [$cmenu1 add command -text [mc {Rename folder}]  -compound left]
	eval "$cmd5 config -command {[set cmenu1] forget;puts {Переименовываем каталог}; set ::fdmenu 1; tk busy forget [set t]}"
	$cmd5 config -image "$canCtx $rendir"
	$canCtx delete $rendir
	set isvg [$cmd5 config -isvg]
	[$cmd5 canvas] itemconfigure $isvg -strokewidth 2.0
      }

	set cmd6 [$cmenu1 add command -text [mc {Create folder}]  -compound left]
	$cmd6 config -command {puts CASCADE}
#$cmenu1 add separator
	eval "$cmd6 config -command {[set cmenu1] forget;puts {Создаем каталог}; set ::fdmenu 1; tk busy forget [set t]}"
	$cmd6 config -isvg "[$cmd6 canvas] $adddir" 
	$canCtx delete $adddir
puts "ADDDIR cmd6=$cmd6 canCtx=$canCtx gr=[$cmd6 config -isvg]"
	set cmd7 [$cmenu1 add separator]

    if {$mtype == 0} {
	set cmd "bind [set tekwin]$fm <ButtonRelease-3> {}; set ::fdmenu 1"
	set cmd1 [subst "bind [set tekwin]$fm <ButtonRelease-3> {if {\"\%W\" != \"$w\"} {$cmd}}"]
	eval $cmd1
    }
    set parcm [winfo parent [$cmenu1 canvas]]
    set topw [winfo toplevel [set tekwin]$fm]
#    tk busy hold $topw
    tk busy hold $t
    if {$topw != "."} {
	set topw1 "[set topw]."
    } else {
	set topw1 $topw
    }
#Ширина

    set mbutc [$cmenu1 add finish]
    $mbutc config -fillnormal "#f4f5f5" -stroke "#ef0000"
#    eval "$mbutc config -command {catch {[set cmenu1] destroy};set ::fdmenu 1}"
if {[winfo exist [set t]._Busy]} {
    eval "bind [set t]._Busy <ButtonRelease> {bind $t <Configure> {};tk busy forget [set t]; [set cmenu1] destroy;puts XA1; set ::fdmenu 1}"
}
    if {$::tmenu == 1} {
#	eval "bind $t <Configure> {if {\"\%W\" == \"[set t]\"} {[set cmenu1] forget;puts XA2; set ::fdmenu 1;bind $t <Configure> {};tk busy forget [set t]}};"
	set mbut [$cmenu1 place -x $rootx -y $rooty]
#	eval "bind [set fm] <FocusOut> { [set cmenu1] forget;puts XA44; set ::fdmenu 1; tk busy forget [set t];bind [set t] <Configure> {}}"
    } else {
	set mbut [$cmenu1 place -x $x -y $y -in [winfo toplevel [set tekwin]$fm]]
    }
    if {$::tmenu == 1} {
	set topl [winfo toplevel $w]
	set cmd "bind $topl <Configure> {tk busy forget [set t];bind $topl <Configure> {};bind $topl <FocusOut> {}; catch {[set cmenu1] destroy}}"
	eval $cmd
	set cmd "bind $topl <FocusOut> {tk busy forget [set t];catch {[set cmenu1] destroy};bind $topl <Configure> {};bind $topl <FocusOut> {};puts XA3}"
	eval $cmd
    }
}

proc createConfigMenu { oow fm direct {mtype 0}} {
# oow - кнопка, для которой создаем меню
# fm - имя виджета меню без точки
#direct - направление язычка
# mtype - 0 меню создается в окне кнопки; 1 - меню создается в отдельном окне 
#set mtype 0
    variable t
if {$::cmenubut != "" }  {
    if {[info class instances cmenu $::cmenubut] != ""} {
	$::cmenubut destroy
    }
}

###################################
puts "createConfigMenu START oow=$oow fm=$fm direct=$direct mtype=$mtype"
    set mm2px [winfo pixels [$oow canvas] 1m]
#Создаётся отдельное окно для меню
    if {$mtype == 1} {
	set mplace "window"
	set tekwin {}
    } else {
	set mplace "canvas"
	set tekwin $t
    }
    set ::cmenubut [cmenu new "$tekwin$fm" -tongue "0.45 0.5 0.55 2m" -direction $direct -strokewidth 0.5m  -command "" -fillnormal cyan  -stroke chocolate -height 6m -place $mplace]

set tt [mc {Folders at the top}]
    set ch1 [$::cmenubut add check -text "$tt"  -variable foldersfirst]
    eval "variable foldersfirst;$ch1 config -command {puts \"Папки вверну foldersfirst=\$foldersfirst \"}"

    set ch1 [$::cmenubut add separator -fillnormal ""]
set tt [mc "Data contents"]
    set chcas [$::cmenubut add cascade -text "$tt" -menu "" -fillopacity 0.2 -fillenter "#3584e4" -strokewidth 0 -compound none -ipad "4.5c 3m 2.5m 4m" ]
#Иконки на кнопках в меню можно выставлять после команды add finish !!!!!
    set gr [[$::cmenubut canvas] create group]
    set iprev [[$::cmenubut canvas] create path "M 3 3 L 13 13 3 23" -strokewidth 2 -parent $gr]

    set ch1 [$::cmenubut add separator]
#Создаем SubMenu
    set sm [showSubMenu ".submenu" $::tmenu]

#enter - отображать меню при наведении на кнопку с меню
    $chcas config -menu $sm -displaymenu release -command {puts "SUBMENU=$::tsubmenu";set sub0 $sub0; set sub1 $sub1}
    set ::butsub $chcas
#release - отображать меню при щелчке по кнопке с меню

set tt [mc {Names only}]
    set cr0 [$::cmenubut add radio  -variable details -text "$tt"  -value 0]
    eval "$cr0 config -command {puts \"Укороченный список\"}"
    set ch1 [$::cmenubut add separator -fillnormal ""]
set tt [mc {Extended list}]
    set cr1 [$::cmenubut add radio -variable details -text "$tt"  -value 1]
    eval "$cr1 config -command {puts \"Расширенный список\"}"
    set ch1 [$::cmenubut add separator]
set tt [mc {Folders and files are separat}]
    set chlast [$::cmenubut add check -text "$tt"  -variable sepfolders]
    $chlast config -command "puts {Папки и файлы раздельно}"

    set ch1 [$::cmenubut add separator]
    set mbut [$::cmenubut add finish]
    $chcas config -isvg "[$::cmenubut canvas] $gr" 
    [$::cmenubut canvas] delete $gr

    $mbut config -command ""
    $oow config -menu $::cmenubut -displaymenu release
    set ::osnmenu $oow
puts "creatConfigMenu end: cmenu=$::cmenubut callout=$mbut"
    return $::cmenubut
}

proc recreateMenu {} {
puts "recreateMenu: TMENU=$::tmenu;::mn=$::mn";
if {$::tsubmenu != ""}  {
	if {[info class instances cmenu $::tsubmenu] != ""} {
	    $::tsubmenu destroy
	}
    set ::tsubmenu {}
}
if {$::cmenubut != "" }  {
    if {[info class instances cmenu $::cmenubut] != ""} {
	$::cmenubut destroy
    }
    set ::cmenubut {}
}
createConfigMenu $::mn ".ffff" up $::tmenu 

}
#. configure -bg yellow
#. configure -bg snow
wm state $t withdraw
wm state $t normal
wm geometry $t 800x600+150+150
set frcol "#b4e4f4"
#frame $t.frame  -bg $frcol
cframe create frmenu $t.frame -type frame -bg $frcol
#frmenu config -fillnormal [lindex [[frmenu canvas] gradient names] 0]
frmenu config -fillnormal "#c4e5fd" -stroke "#ce7053"

pack $t.frame  -in $t -fill both -expand 1 -padx 3m -pady 3m
set ch [cbutton new $t.frame.type -type check -variable dir -text [mc "Folders only"]  -fontsize 4.5m -bg $frcol]
set mn [cbutton new $t.bmenu -type rect  -text [mc "Dropdown menu"] -bg $frcol -compound none -width 8c]
$mn config -command {set details $details; set foldersfirst $foldersfirst;set sepfolders $sepfolders;$mn config -command {}}
set ::mn $mn
puts "Кнопка меню=$mn"
set r0 [cbutton new $t.rad0 -type check -variable ::tmenu -text [mc "Menus are created in separate windows (toplevel)"] -fontsize 4m]
$r0 config  -command {recreateMenu}
set r1 [cbutton new $t.rad1 -type radio -variable rad -value release -text [mc "Menus appear when you press a button"] -bg $frcol -fontsize 4m]
set r2 [cbutton new $t.rad2 -type radio -variable rad -value enter -text [mc "Menus appear when you hover over a button"] -bg $frcol -fontsize 3.5m]
pack [$r0 canvas] -in $t.frame  -side top -padx "1c 0" -pady "1c 0" -anchor nw
pack [$r1 canvas] -in $t.frame  -side top -padx "1c 0" -pady 1c -anchor nw
pack [$r2 canvas] -in $t.frame  -side top -padx "1c 0" -pady 0c -anchor nw

set went [cframe new $t.cent -type centry -rx 2m -bg $frcol -height 7m]
pack [$went canvas] -in $t.frame -side top -fill x -expand 0 -padx 3c -pady 5m -anchor nw

if {$::lang == "ru"} {
	set mes1 "Для вызова контекстного меню\nщелкните правой кнопкой мыши \nна свободном от виджевов поле.\nСостав меню регламентируется\nкнопкой \"Только каталоги\""
} else {
	set mes1 "To open the context menu,\nright-click on an area free of widgets.\nThe menu contents are controlled by the \n\"Folders only\" button"
}
set wmsg [mbutton new "$t.msg1" -type down -tongue "0.45 0.5 0.55 0" -text "$mes1" -textanchor n -bg $frcol  -state disabled]

pack [$wmsg canvas] -in $t.frame -side top -fill none -expand 0 -padx 1c -pady "5m 0" -anchor nw
#$wmsg config -bg yellow

pack [$went canvas] -in $t.frame -side top -fill x -expand 0 -padx 3c -pady 5m -anchor nw

pack [$ch canvas] -in $t.frame -side left -padx "1c 0" -pady "0 0" -anchor nw
pack [$mn canvas] -in $t.frame -side left -padx "3c 5m" -pady "0 0" -fill x -expand 0 -anchor n 

set  w "$t.frame "
set typefb "directory"
#eval "bind $t.frame  <ButtonPress-3> {showContextMenu %W %x %y %X %Y $w $typefb}"
eval "bind $t.frame  <ButtonPress-3> {showContextMenu %W %x %y %X %Y .cont $typefb}"
#reateConfigMenu $mn ffff up 1
set ::cmenubut {}
createConfigMenu $mn ".ffff" up $::tmenu 
#puts "ГОТОВО=$mn r1=$r1 r2=$r2"
update
trace add variable rad write displaymenu
if {1} {
set foldersfirst 1
set details	 0
set sepfolders	 1
set sub0 1
set sub1 1
}
set rad release
focus -force [$went entry]
set ::tmenu $::tmenu
set dir $dir

#set rad enter

