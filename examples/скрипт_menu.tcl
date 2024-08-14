package require svgwidgets

variable foldersfirst
variable details
variable sepfolders
variable t
set t ".test1"
destroy $t
toplevel $t
wm state $t withdraw
wm state $t normal
wm protocol $t WM_DELETE_WINDOW {exitarm $t "Вы действительно\nхотите выйти?"}
set ::bgold [. cget -bg]
set ::geo [wm geometry .]
set ::min [wm minsize .]
#Меню создаются в окнах (toplevel) ::tmenu=1 в отдельных окнах, tmenu=0 - в главном окне
set ::tmenu 0

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

proc showSubMenu {w fm obj {mtype 0}} {
    variable t
puts "showSubMenu START: w=$w fm=$fm obj=$obj mtype=$mtype"
#	set ::submenu [cmenu new $fm.subMenu -tongue "0.45 0.5 0.55 2m" -strokewidth 2 -pad 1m]
#####################
set direct left
    if {$mtype == 1} {
	set fmWin ".$fm"
	catch {destroy $fmWin}
	toplevel $fmWin -class femenu
	wm overrideredirect $fmWin 1
	wm state $fmWin withdraw
#	set ::submenu [cmenu new $fmWin.$fm -tongue "0.45 0.5 0.55 2m" -direction $direct -strokewidth 2 -pad 1m -command "" -fillnormal snow  -stroke gray70 -height 6m]
	set ::submenu [cmenu new $fmWin.$fm -tongue "0.30 0.20 0.45 2m" -direction $direct -strokewidth 2 -pad 1m  -fillnormal snow -stroke gray70 -direction $direct -lockwindow $t]
    } else {
#	set ::cmenubut [cmenu new $win.$fm -tongue "0.45 0.5 0.55 2m" -direction $direct -strokewidth 2 -pad 1m -command "" -fillnormal snow  -stroke gray70 -height 6m]
	set tl [winfo toplevel $w]
	set ::submenu [cmenu new $t.subMenu -tongue "0.30 0.20 0.45 2m" -strokewidth 2 -pad 1m -fillnormal snow -stroke gray70 -direction $direct]
    }
	set i 0
#	foreach hcol  "$::FE::folder(displaycolumns)" {}
	foreach hcol  [list Размер Дата Полномочия] {
	    set ch$i [$::submenu add check -text "$hcol" -variable sub$i]
	    set chsep [$::submenu add separator ]
		$chsep config -stroke "" -fillnormal "" -fillenter "##"
#Состав расширенного просмотра
#	    set ::FE::folder(tree$hcol) 1
	    incr i
	}
#	    set ch$i [$::submenu add check -text [::msgcat::mc "$hcol"] -variable ::FE::folder(tree$hcol)]
puts "showSubMenu END: i=$i hcol=$hcol"
    set chsep [$::submenu add separator ]
    $chsep config -stroke "" -fillnormal "" -fillenter "##"
    set chsep [$::submenu add finish]
    return $::submenu
}

  proc showContextMenu {w x y rootx rooty fm typefb {mtype 0}} {
    variable dir
    set padddir "M 2 2 L 2 14 L 9 14 L 9 13 L 3 13 L 3 8 L 5 8 L 6.9980469 6 L 13 6 L 13 9 L 14 9 L 14 4 L 9.0078125 4 L 7.0078125 2 L 7 2.0078125 L 7 2 L 2 2 z \n
        M 11 9 L 11 11 L 9 11 L 9 12 L 11 12 L 11 14 L 12 14 L 12 12 L 14 12 L 14 11 L 12 11 L 12 9 L 11 9 z"
    set pdeldir "M 2 2 L 2 14 L 9 14 L 9 13 L 3 13 L 3 8 L 5 8 L 6.9980469 6 L 13 6 L 13 9 L 14 9 L 14 4 L 9.0078125 4 L 7.0078125 2 L 7 2.0078125 L 7 2 L 2 2 z \n
        M 11 11 L 11 11 L 9 11 L 9 12 L 14 12 L 14 11 L 12 11 L 11 11 z"
    set paddfile "M 3.0 11.4375 L 3.0 3.0 L 7.4296875 3.0 L 11.8330078125 3.0 L 14.28515625 5.4521484375 L 16.7109375 7.8779296875 L 16.7109375 9.6708984375 
	L 16.7109375 11.4375 L 15.65625 11.4375 L 14.6279296875 11.4375 L 14.548828125 9.9345703125 L 14.4697265625 8.4052734375 
	L 12.966796875 8.326171875 L 11.4638671875 8.2470703125 L 11.384765625 6.744140625 L 11.3056640625 5.2412109375 L 8.220703125 5.162109375 
	L 5.109375 5.0830078125 L 5.109375 11.4375 L 5.109375 17.765625 L 9.328125 17.765625 L 13.546875 17.765625 L 13.546875 18.8203125 
	L 13.546875 19.875 L 8.2734375 19.875 L 3.0 19.875 L 3.0 11.4375 Z
	M 17.0 13.0 L 17.0 15.0 L 15.0 15.0 L 15.0 16.0 L 17.0 16.0 L 17.0 18.0 L 18.0 18.0 L 18.0 16.0 L 20.0 16.0 L 20.0 15.0 L 18.0 15.0 
	L 18.0 13.0 L 17.0 13.0 Z"
    set pdelfile "M 3.0 11.4375 L 3.0 3.0 L 7.4296875 3.0 L 11.8330078125 3.0 L 14.28515625 5.4521484375 L 16.7109375 7.8779296875 L 16.7109375 9.6708984375 
	L 16.7109375 11.4375 L 15.65625 11.4375 L 14.6279296875 11.4375 L 14.548828125 9.9345703125 L 14.4697265625 8.4052734375 
	L 12.966796875 8.326171875 L 11.4638671875 8.2470703125 L 11.384765625 6.744140625 L 11.3056640625 5.2412109375 L 8.220703125 5.162109375 
	L 5.109375 5.0830078125 L 5.109375 11.4375 L 5.109375 17.765625 L 9.328125 17.765625 L 13.546875 17.765625 L 13.546875 18.8203125 
	L 13.546875 19.875 L 8.2734375 19.875 L 3.0 19.875 L 3.0 11.4375 Z
	M 12.0 13.0 L 12.0 13.0 L 19.5 13.0 L 19.5 15.25 L 12.0 15.25 Z"
    set prename "M 31.25 57.5 C 31.25 56.875 32.5 56.25 34.125 56.25 C 35.625 56.25 38.25 55.375 39.75 54.25 C 42.375 52.375 42.5 51.625 42.5 31.25 
	C 42.5 10.875 42.375 10.125 39.75 8.25 C 38.25 7.125 35.625 6.25 34.125 6.25 C 32.5 6.25 31.25 5.75 31.25 5.0 C 31.25 3.0 37.875 3.5 41.0 5.75 
	C 43.5 7.5 44.0 7.5 46.5 5.75 C 49.625 3.5 56.25 3.0 56.25 5.0 C 56.25 5.75 55.0 6.25 53.375 6.25 C 48.75 6.25 45.0 9.625 45.0 13.875 L 45.0 17.5 
	L 53.125 17.5 L 61.25 17.5 L 61.25 31.25 L 61.25 45.0 L 53.125 45.0 L 45.0 45.0 L 45.0 48.625 C 45.0 52.875 48.75 56.25 53.375 56.25 
	C 55.0 56.25 56.25 56.875 56.25 57.5 C 56.25 59.5 49.625 59.0 46.5 56.75 C 44.0 55.0 43.5 55.0 41.0 56.75 C 37.875 59.0 31.25 59.5 31.25 57.5 Z 
	M 58.75 31.25 L 58.75 20.0 L 51.875 20.0 L 45.0 20.0 L 45.0 31.25 L 45.0 42.5 L 51.875 42.5 L 58.75 42.5 L 58.75 31.25 Z 
	M 1.25 31.25 L 1.25 17.5 L 20.0 17.5 C 31.625 17.5 38.75 18.0 38.75 18.75 C 38.75 19.5 32.125 20.0 21.25 20.0 L 3.75 20.0 L 3.75 31.25 
	L 3.75 42.5 L 21.25 42.5 C 32.125 42.5 38.75 43.0 38.75 43.75 C 38.75 44.5 31.625 45.0 20.0 45.0 L 1.25 45.0 L 1.25 31.25 Z"
    set t {}
puts "showContextMenu: w=$w fm=$fm x=$x y=$y rootx=$rootx rooty=$rooty mtype=$mtype"
    if {$dir == 0} {
	set t "file"
    } else {
	set t "directory"
    }
    if {[winfo exists $fm.contextMenu]} {
	$::cmenudf destroy
    }
#В отдельном окне
    set m46 [winfo fpixels $fm 46m]
    set wcont [winfo width $w]
    set wrootx [winfo rootx $w]
#Если контекстное меню не умещается во фрейм, то оно создается в отдельном окне
#    if {$mtype == 1} {}
#    if {[expr {($rootx + $m46) >  ($wrootx + $wcont)}]} {}
    if {[expr {($rootx + $m46) >  ($wrootx + $wcont)}] || $m46 } {
	set mtype 1
set fmWin ".cont"
	catch {destroy $fmWin}
	toplevel $fmWin -class femenu
	wm overrideredirect $fmWin 1
	wm state $fmWin withdraw
	set cmenu1 [cmenu new $fmWin.contextMenu -tongue "0.5 0.5 0.5 0" -direction down -strokewidth 2 -pad 1m]
    } else {
	set cmenu1 [cmenu new .contextMenu -tongue "0.5 0.5 0.5 0" -direction down -strokewidth 2 -pad 1m]
    }
    eval "$cmenu1 config -command {catch {[set cmenu1] destroy};set ::fdmenu 1}"
    
    set canCtx [$cmenu1 canvas]
    set adddir [$canCtx create path "$padddir" -fill black -strokewidth 0]
set ::cmenudf $cmenu1
#Добавить команду separator а пока
    set cmd7 [$cmenu1 add separator]
      if {$t == "file"} {
	set renfile [$canCtx create path "$prename" ]
	set addfile [$canCtx create path "$paddfile" -fill black -strokewidth 0]
	set delfile [$canCtx create path "$pdelfile" -fill black -strokewidth 0]
        set cmd2 [$cmenu1 add command -height 7m]
	$cmd2 config -image "$canCtx $delfile"
	$canCtx delete $delfile
        eval "$cmd2 config -text \"Удалить файл\" -command {[set cmenu1] destroy;bind $fm <ButtonRelease-3> {};puts {Удаляем файл}; set ::fdmenu 1}"
	set cmd3 [$cmenu1 add command]
	$cmd3 config -image "$canCtx $renfile"
	$canCtx delete $renfile
        eval "$cmd3 config  -text \"Переименовать файл\" -command {[set cmenu1] destroy;bind $fm <ButtonRelease-3> {};puts {Переименовываем файл}; set ::fdmenu 1}"
	set cmd7 [$cmenu1 add command]
	$cmd7 config -image "$canCtx $addfile"
	$canCtx delete $addfile
	eval "$cmd7 config  -text {Создать пустой файл} -command {[set cmenu1] destroy;bind $fm <ButtonRelease-3> {};puts {Создаем пустой файл}; set ::fdmenu 1}"
	set cmd4 [$cmenu1 add separator]
      }
      if {$t == "directory"} {
	set deldir [$canCtx create path "$pdeldir" ]
	set rendir [$canCtx create path "$prename" ]
	set cmd4 [$cmenu1 add command]
        eval "$cmd4 config -text {Удалить каталог} -command {[set cmenu1] destroy;bind $fm <ButtonRelease-3> {};puts {Удаляем каталог}; set ::fdmenu 1}"
	$cmd4 config -image "$canCtx $deldir"
	$canCtx delete $deldir

	set cmd5 [$cmenu1 add command]
	eval "$cmd5 config  -text {Переименовать каталог} -command {[set cmenu1] destroy;bind $fm <ButtonRelease-3> {};puts {Переименовываем файл}; set ::fdmenu 1}"
	$cmd5 config -image "$canCtx $rendir"
	$canCtx delete $rendir
      }
	set cmd6 [$cmenu1 add command]
	eval "$cmd6 config  -text {Создать каталог} -command {[set cmenu1] destroy;bind $fm <ButtonRelease-3> {};puts {Создаем каталог}; set ::fdmenu 1}"
	$cmd6 config -image "$canCtx $adddir"
	$canCtx delete $adddir
	set cmd7 [$cmenu1 add separator]

    if {$mtype == 0} {
	set cmd "bind $fm <ButtonRelease-3> {}; set ::fdmenu 1"
	set cmd1 [subst "bind $fm <ButtonRelease-3> {if {\"\%W\" != \"$w\"} {$cmd}}"]
	eval $cmd1
    }
    set parcm [winfo parent [$cmenu1 canvas]]
puts "showContextMenu: cmenu1=$cmenu1 fm=$fm w=$w "
    if {[winfo class $parcm] != "femenu"} {
	tk busy hold $fm
    } else {
#	    tk busy hold [winfo toplevel $w]
	    tk busy hold $fm
    }
eval "bind [set fm]_Busy <ButtonRelease> {bind $t <Configure> {}; [set cmenu1] destroy;; set ::fdmenu 1}"
#Ширина
    set mbutc [$cmenu1 add finish]
    $mbutc config -fillnormal "#f4f5f5" -stroke gray70
    eval "$mbutc config -command {catch {[set cmenu1] destroy};set ::fdmenu 1}"
    
    if {$mtype == 1} {
#	set mbut [$cmenu1 place $rootx $rooty $mtype $fmWin down]
	set mbut [$cmenu1 place -x $rootx -y $rooty]
	place forget [$cmenu1 canvas]
	pack [$cmenu1 canvas] -side top -anchor nw
	wm state $fmWin normal
	wm geometry $fmWin +$rootx+$rooty
    } else {
#	set mbut [$cmenu1 place $x $y $mtype $fm down]
	set mbut [$cmenu1 place -x $x -y $y -in $fm]
    }
#    $mbut config -fillnormal "#e0dfde" -stroke gray70
update
#after 20
    if {$mtype == 1} {
	set cmd "bind $t <Configure> {if {\[winfo exist {.cont.contextMenu}\]} {bind .cont.contextMenu <ButtonRelease-3> {}};bind $t <Configure> {}; catch {[set cmenu1] destroy}; set ::fdmenu 1}"
	eval $cmd

    }
    set ::fdmenu 0
    vwait ::fdmenu
    if {[tk busy status "."]} {
	tk busy forget "."
    }
    if {[tk busy status $fm]} {
	tk busy forget $fm
    }
#return $cmenu1
}

proc createConfigMenu { oow fm direct {mtype 0}} {
# oow - кнопка, для которой создаем меню
# fm - имя виджета меню без точки
#direct - направление язычка
# mtype - 0 меню создается в окне кнопки; 1 - меню создается в отдельном окне 
#set mtype 0
    variable t

###################################
puts "createConfigMenu START oow=$oow fm=$fm direct=$direct mtype=$mtype"
    set mm2px [winfo pixels [$oow canvas] 1m]
#Создаётся отдельное окно для меню
    if {$mtype == 1} {
	set fmWin ".$fm"
	catch {destroy $fmWin}
	toplevel $fmWin -class femenu
	wm overrideredirect $fmWin 1
	wm state $fmWin withdraw
	set ::cmenubut [cmenu new $fmWin.$fm -tongue "0.45 0.5 0.55 2m" -direction $direct -strokewidth 2 -pad 1m -command "" -fillnormal snow  -stroke gray70 -height 6m -lockwindow $t]
    } else {
	set win [winfo toplevel [$oow canvas]]
	if {$win == "."} {
	    set win ""
	}
	set ::cmenubut [cmenu new $win.$fm -tongue "0.45 0.5 0.55 2m" -direction $direct -strokewidth 2 -pad 1m -command "" -fillnormal snow  -stroke gray70 -height 6m]
    }
#puts "showConfigMenu 1_2"
    set ch1 [$::cmenubut add check -text {Папки вверху} -variable foldersfirst]
    eval "variable foldersfirst;$ch1 config -command {puts \"Папки вверну foldersfirst=\$foldersfirst \"}"
puts "createConfigMenu 1_3"
#    $ch1 config -text "Папки вверху"
    set ch1 [$::cmenubut add separator]

    set gr [[$::cmenubut canvas] create group]
    set iprev [[$::cmenubut canvas] create path "M 3 3 L 13 13 3 23" -strokewidth 2 -parent $gr]

    set chcas [$::cmenubut add cascade -text "Состав данных" -menu "" -fillopacity 0.2 -fillenter "#3584e4" -strokewidth 0 -height 6m -compound none -ipad "4.5c 3m 2.5m 4m" ]
#puts "createConfigMenu 1_3 Состав_данных=$chcas menu=$fm.subMenu"
    $::cmenubut config -image "[$::cmenubut canvas] $gr" 
#puts "СОСТАВ ДАННЫХ=$chcas ::cmenubut=$::cmenubut chcas=$chcas iprev=$iprev"
    [$::cmenubut canvas] delete $gr
    set ch1 [$::cmenubut add separator]
#Создаем SubMenu
#set sm [showSubMenu [$chcas canvas] "submenu" "new" 1]
set sm [showSubMenu [$chcas canvas] "submenu" "new" $::tmenu]
#enter - отображать меню при наведении на кнопку с меню
$chcas config -menu $sm -displaymenu enter
set ::butsub $chcas
#release - отображать меню при щелчке по кнопке с меню
#$chcas config -menu $sm -displaymenu release

#puts "createConfigMenu 1_4 sm=$sm chcas=$chcas"
#placeSubMenu 1-й параметр кнопка, которую надо раскрыть, 2-й - объект submenu
#    $chcas config -command "[subst {placeSubMenu [set chcas] [set sm]}]"
    $chcas config -command ""

#puts "createConfigMenu 1_4"

    set cr0 [$::cmenubut add radio " -variable details -text {Только имена} -value 0"]
    eval "$cr0 config -command {puts \"Укороченный список\"}"
    set ch1 [$::cmenubut add separator -fillnormal ""]

    set cr1 [$::cmenubut add radio "-variable details -text {Расширенный список} -value 1"]
    eval "$cr1 config -command {puts \"Расширенный список\"}"
    set ch1 [$::cmenubut add separator]
#    $ch1 config -text ""
    set chlast [$::cmenubut add check "-text {Папки и файлы раздельно} -variable sepfolders"]
    $chlast config -command "puts {Папки и файлы раздельно}"

    set ch1 [$::cmenubut add separator]
    set mbut [$::cmenubut add finish]
    $mbut config -command ""
    $oow config -menu $::cmenubut -displaymenu release
    set ::osnmenu $oow
#    return $mbut
puts "creatConfigMenu end: cmenu=$::cmenubut callout=$mbut"
return $::cmenubut
}




#. configure -bg yellow
. configure -bg snow
wm state $t withdraw
wm state $t normal
wm geometry $t 800x600+150+150
frame $t.frame  -bg yellow
pack $t.frame  -in $t -fill both -expand 1 -padx 3m -pady 3m
set ch [cbutton new $t.type -type check -variable dir -text "Только каталоги" -bg yellow -fontsize 4.5m]
set mn [cbutton new $t.bmenu -type rect  -text "Выпадаюшее меню" -bg yellow -compound none -width 8c]
puts "Кнопка меню=$mn"
#$mn config -command "showConfigMenu [$mn canvas] $t.frame  0"
#$mn config -command "showConfigMenu $mn $t.frame  0"
set r1 [cbutton new $t.rad1 -type radio -variable rad -value release -text "Меню появляются при нажатии кнопки" -bg yellow -fontsize 4m]
set r2 [cbutton new $t.rad2 -type radio -variable rad -value enter -text "Меню появляются при наведении на кнопку" -bg yellow -fontsize 3.5m]
pack [$r1 canvas] -in $t.frame  -side top -padx "1c 0" -pady 1c -anchor nw
#-fill x -expand 1
pack [$r2 canvas] -in $t.frame  -side top -padx "1c 0" -pady 0c -anchor nw
# -fill x -expand 1

set went [cframe new $t.cent -type centry -rx 2m -bg yellow -height 7m]
#$t.cent configure -height 28
pack [$went canvas] -in $t.frame -side top -fill x -expand 0 -padx 3c -pady 5m -anchor nw
#set wmsg [cframe new $t.cent -type centry -rx 2m -bg yellow -height 7m]
set mes1 "Для вызова контекстного меню\nщелкните правой кнопкой мыши \nна свободном от виджевов поле"

set wmsg [mbutton new "$t.msg1" -type down -tongue "0.45 0.5 0.55 0" -text "$mes1" -textanchor n -bg yellow -state disabled]

pack [$wmsg canvas] -in $t.frame -side top -fill none -expand 0 -padx 1c -pady "5m 0" -anchor nw
#$wmsg pack  -in $t.frame -side top -fill none -expand 0 -padx 1c -pady "5m 0" -anchor nw


#$t.cent configure -height 28
pack [$went canvas] -in $t.frame -side top -fill x -expand 0 -padx 3c -pady 5m -anchor nw

pack [$ch canvas] -in $t.frame -side left -padx "1c 0" -pady "0 0" -anchor nw
#raise [$ch canvas]
pack [$mn canvas] -in $t.frame -side left -padx "3c 5m" -pady "0 0" -fill x -expand 0 -anchor n 
#raise [$mn canvas]




set  w "$t.frame "
set typefb $dir
#eval "bind $t.frame  <ButtonPress-3> {puts XAXA;showContextMenu %W %x %y %X %Y $w $typefb}"
#eval "bind $t.frame  <ButtonPress-3> {wm state $t withdraw;update;after 200;puts XAXA;showContextMenu %W %x %y %X %Y $w $typefb; wm state $t normal}"
eval "bind $t.frame  <ButtonPress-3> {update;after 200;puts XAXA;showContextMenu %W %x %y %X %Y $w $typefb}"
#createConfigMenu $mn ffff up 1
createConfigMenu $mn ffff up $::tmenu

set foldersfirst 1
set details	 0
set sepfolders	 1
puts "ГОТОВО=$mn r1=$r1 r2=$r2"
update
trace variable rad w displaymenu
#set rad enter
set rad release
if {$::tmenu == 0} {
    $::osnmenu config -command "bind $t <Configure> {catch {lower $t._Busy $t.ffff}}"
}



