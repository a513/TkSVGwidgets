package require svgwidgets
#set tkp::pixelalign 1
#set tkp::depixelize 1

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
	if {$t == "."} {
	    set t1 ""
	} else {
	    set t1 $t
	}
	set erlib [mbutton new "$t1.message" -type yesno  -fillnormal white -text "Вы действительно\nхотите выйти?" -textanchor n -strokewidth 3]
	set g4 [$t1.message gradient create linear -method pad -units bbox -stops { { 0.00 #ffffff 1} { 1.00 #dbdbdb 1}} -lineartransition {0.00 0.00 0.00 1.00} ]
	$erlib config -fillnormal $g4
	set herlib [expr {int([winfo fpixels "$t1.message" [$erlib config -height]])}]
	set werlib [expr {int([winfo fpixels "$t1.message" [$erlib config -width]])}]

#Главное окно неизменяемое
	wm resizable $t 0 0
	tk busy hold $t
	set werlib [expr {[winfo width $t] / 2 - $werlib / 2}]
	set herlib [expr {[winfo height $t] / 4 }]
	set rr [$erlib place -in $t -x $werlib -y $herlib]
	if {[tk busy status $t]} {
	    tk busy forget $t
	}
	if {$rr != "yes"} {
	    wm resizable $t 1 1
	    return
	}
#Подчищаем за собою
	svgwidget::clearclass
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
wm protocol $t WM_DELETE_WINDOW {exitarm $t }

#####################
wm geometry $t 800x600+150+150
wm title $t "tcl/tk svg widgets pack demo"

#tkp::canvas $t.c -bg yellow
#frame $t.c -bg yellow
set rfr [cbutton new $t.c -type frame -rx 0  -fillnormal yellow -bg yellow -strokewidth 0 -stroke {}]

pack $t.c -in $t -fill both -expand 1 -padx 3m -pady 3m
update
#Кнопка консоли
set cons [cbutton create Консоль $t.cons -type rect -rx 2m -height 7m -bg yellow -text "__Показать консоль__" \
    -command {if {[Консоль config -text] == "  Показать консоль"} {console show;Консоль config -text "  Скрыть консоль"} \
    else {console hide;::Консоль config -text "  Показать консоль" ;}}]
$cons config -text "  Показать консоль"
#puts "Поле консоли: $cons"

pack $t.cons -in $t.c -side top -fill none -expand 0 -padx 3c -pady "2m 2m"

set went [cframe new $t.cent -type centry -rx 2m -height 7m -bg yellow]
puts "Поле ввода: $went"
$t.cent configure -height 28

pack $t.cent -in $t.c -side top -fill x -expand 0 -padx 3c -pady "2m 2m" -anchor nw

#SVG-фрейм
set b1 [cbutton new $t.frame -type frame -rx 5m ]
#Создаем градиент
set grforb1 [[$b1 canvas] gradient create radial -method pad -units bbox -stops { { 0.00 "#ffff00" 0.50} { 1.00 "#d42b11" 0.80}} -radialtransition {0.50 0.46 0.50 0.25 0.25} ]
#Устанавливаем градиентную заливку
#$b1 config -fillnormal $grforb1

#[$b1 canvas ] configure -bg [$t.c cget -bg]
#Или
$t.frame configure -bg [$t.c cget -bg]

set bg [$b1 config -fillnormal]
set xa1 [cbutton create Прямоугольник $t.frame.but1 -type rect  -text Прямоугольник -fontweight bold -compound left]
eval  [subst {$xa1 config -command {puts "Прямоугольник=[set xa1] Левый фрейм=[set b1] градиент=$grforb1"}}]
#after 0 [subst {$xa1 config -command {puts "[set xa1] [set b1]"}}]

set xa2 [cbutton new $t.but2 -type round  -text Полукруглый -fontsize 3m -bg $bg]
eval  [subst {$xa2 config -command {puts "Полукруглый=[set xa2] Левый фрейм=[set b1]"}}]
#[$xa2 canvas] configure -bg [$b1 config -fillnormal]
#set xa3 [cbutton new $t.frame.but3 -type ellipse  -text Эллипс -fontsize 5m -fontslant italic -bg $bg]
set xa3 [cbutton new $t.but3 -type ellipse  -text Эллипс -fontsize 5m -fontslant italic -bg $bg]
eval  [subst {$xa3 config -command {puts "Эллипс=[set xa3] Левый фрейм=[set b1]"}}]
set xa4 [cbutton new $t.but4 -type rect  -text Закругленный -fontsize 4m -rx 2m -bg $bg -compound left]
eval  [subst {$xa4 config -command {puts "Закругленный=[set xa4] Левый фрейм=[set b1]"}}]
set img [foldercolor [$xa4 canvas] "blue" ]
$xa4 config -image "[$xa4 canvas] $img" -ipad "2m 10m  2m 12m"
[$xa4 canvas] delete $img

pack [$b1 canvas] -in $t.c -fill both -expand 1 -padx 1c -pady 5m -side left -anchor nw 

pack [$xa1 canvas] -in $t.frame -padx 1c -pady "1c 0" -fill both -expand 1
pack [$xa2 canvas] [$xa3 canvas] -in $t.frame -padx 1c -pady "5m 0" -fill both -expand 1
pack [$xa4 canvas] -in $t.frame -padx 1c -pady "5m" -fill both -expand 1

#SVG-фрейм с заголовком
set clfrv [cframe new $t.rdch -type clframe -text "radio/check кнопки" -rx 1m -strokewidth 1 -stroke red -fillnormal snow ]
set gradCloud [[$clfrv canvas] gradient create linear -method pad -units bbox \
    -stops { { 0.05 "#87ceeb" 1.00} { 0.17 "#ffffff" 1.00} { 0.29 skyblue 1.00} { 0.87 "#ffffff" 1.00} { 1.00 skyblue 1.00}} -lineartransition {1.00 0.00 0.75 1.00} ]

[$clfrv canvas] configure -background [$t.c cget -background]
$clfrv boxtext
$clfrv config -fontsize 3.5m -fillbox cyan

set bg [$clfrv config -fillnormal]

set rc1 [cbutton new $t.rbut1 -type radio  -text Radio1 -variable vrc1 -value 1 -bg $bg]
$rc1 fon
eval  [subst {$rc1 config -command {puts "Radio1=[set rc1] Правый фрейм=[set clfrv]"}}]

pack [$clfrv canvas] -in $t.c -fill both -expand 1 -padx 1c -pady 5m -side left -anchor ne 
update
#after 30
set rc2 [cbutton new $t.rbut2 -type radio  -text Radio2 -variable vrc1 -value 0 -bg $bg ]
$rc2 fon
eval  [subst {$rc2 config -command {puts "Radio2=[set rc2] Правый фрейм=[set clfrv]"}}]
set rc3 [cbutton new $t.rbut3 -type check  -text Check1 -variable vrc3 -bg $bg]
eval  [subst {$rc3 config -command {puts "Check1=[set rc3] Правый фрейм=[set clfrv]"}}]
set rc4 [cbutton new $t.rbut4 -type check  -text Check2 -variable vrc4 -bg $bg]
eval  [subst {$rc4 config -command {puts "Check2=[set rc4] Правый фрейм=[set clfrv]"}}]
set rc5 [cbutton new $t.rbut5 -type circle  -text Круг -bg $bg]
eval  [subst {$rc5 config -command {puts "Круг=[set rc5] Правый фрейм=[set clfrv]"}}]
set rc6 [cbutton new $t.rbut6 -type square  -text Квадрат -ipad "1m 1m 1m 1m" -bg $bg]
eval  [subst {$rc6 config -command {puts "Квадрат=[set rc6] Правый фрейм=[set clfrv]"}}]
set rc7 [ibutton create Картинка $t.rbut7 -width 1c -height 1c -text Картинка -pad "1m 1m 1m 1m" -bg $bg -image "::tk::icons::error"]
eval  [subst {$rc7 config -command {puts "Картинка=[set rc7] Правый фрейм=[set clfrv]"}}]
set img [folderbrown [$rc6 canvas]]
$rc6 config -image "[$rc6 canvas] $img"
$rc6 config -fillnormal cyan
#puts "Квадрат=$rc6"
[$rc6 canvas] delete $img

update
#Второй способ согласования цветов!!!
if {0} {
$rc1 pack -in [$clfrv canvas] -padx 1c -pady "1c 0"
$rc2 pack -in [$clfrv canvas] -padx 1c -pady "2m 0" -fill both -expand 1
$rc3 pack -in [$clfrv canvas] -padx 1c -pady "2m 0"
[$rc3 canvas] delete fon
$rc4 pack -in [$clfrv canvas] -padx 1c -pady "2m" -fill both -expand 1
$rc5 pack -in [$clfrv canvas] -padx 1c -pady "2m 0" -fill none -expand 1 -anchor n
$rc7 pack -in [$clfrv canvas] -padx 1c -pady "2m 0" -fill x -expand 1
$rc6 pack -in [$clfrv canvas] -padx 1c -pady "2m 5m" -fill both -expand 1
}

if {1} { 
set inwin [$clfrv canvas]
pack [$rc1 canvas] -in $inwin -padx 1c -pady "1c 0"
pack [$rc2 canvas] -in $inwin -padx 1c -pady "2m 0" -fill both -expand 1
pack [$rc3 canvas] -in $inwin -padx 1c -pady "2m 0"
pack [$rc4 canvas] -in $inwin -padx 1c -pady "2m" -fill both -expand 1
pack [$rc5 canvas] -in $inwin -padx 1c -pady "2m 0" -fill none -expand 1 -anchor n
pack [$rc7 canvas] -in $inwin -padx 1c -pady "2m 5m" -fill both -expand 1
pack [$rc6 canvas] -in $inwin -padx 1c -pady "2m 0" -fill x -expand 1
}
pack configure [$rc7 canvas] -expand 0 

