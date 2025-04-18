package require svgwidgets
#Уствновить gradient
#canvas::gradient .c -direction x -colr1 yellow -color2 blue
package require canvas::gradient

variable b1
variable clfrv
variable went 
variable xaup
variable xgrad 
variable tkpfr

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
	svgwidget::clearclass
	destroy $t
	puts "Пример button_PACK_gradient завершен."
	return
}
proc updategrad {w gr} {
    variable b1
    variable xaup
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
    update
    after 100
    $b1 fon; $clfrv fon; $xgrad fon; $went fon; $xaup fon
}

variable t
set t ".test"
destroy $t
toplevel $t
wm state $t withdraw
wm state $t normal
wm protocol $t WM_DELETE_WINDOW {exitarm $t }

wm title $t "tcl/tk pack gradient demo"

wm geometry $t 800x600+150+150

set tkpfr [cframe new $t.c -type frame -strokewidth 0 -stroke "" -fillnormal yellow]
set g4 [$t.c gradient create linear -method pad -units bbox -stops { { 0.0 cyan 1} { 1.0 yellow 1}} -lineartransition {0.0 0.0 0.0 1.0} ]
$tkpfr config -fillnormal $g4
#tkp::canvas $t.c -bg yellow
#Уствновить gradient
#canvas::gradient .c -direction x -colr1 yellow -color2 blue
update

pack $t.c -in $t -fill both -expand 1 -padx 3m -pady 3m
update
set went [cframe new $t.cent -type centry -rx 2m ]
$went pack -in $t.c -side top -fill x -expand 0 -padx 3c -pady "1c 2m" -anchor nw
#SVG-фрейм
set b1 [cbutton new $t.frame -type frame -rx 5m ]
update

set xa1 [cbutton new $t.frame.but1 -type rect  -text Прямоугольник]
set xa2 [cbutton new $t.frame.but2 -type round  -text Полукруглый]
[$xa2 canvas] configure -bg [$b1 config -fillnormal]
set xa3 [cbutton new $t.frame.but3 -type ellipse  -text Эллипс -fontweight bold -fontslant italic -fontfamily helvetica -fontsize 4m ]
[$xa3 canvas] configure -bg [$b1 config -fillnormal]
set xa4 [cbutton new $t.frame.but4 -type rect  -text {ВЫХОД (Закругленный)} -rx 2m -command "exitarm $t" -textfill red -fontweight bold -fontsize 4m]
[$xa4 canvas] configure -bg [$b1 config -fillnormal]
$xa4 config  -textstroke black -textstrokewidth 0.7
$b1 pack -in $t.c -fill both -expand 1 -padx 1c -pady 5m -side left -anchor nw
update
pack [$xa1 canvas] -in $t.frame -padx 1c -pady "1c 0" -fill both -expand 1
pack [$xa2 canvas] -in $t.frame -padx 1c -pady "5m 0" -fill both -expand 1
pack [$xa3 canvas] -in $t.frame -padx 1c -pady "5m 0" -fill both -expand 1
#$xa3 pack -in $t.frame -padx 1c -pady "5m 0" -fill both -expand 1
pack [$xa4 canvas] -in $t.frame -padx 1c -pady "5m" -fill both -expand 1
#SVG-фрейм с заголовком
    set clfrv [cframe new $t.rgch -type clframe -text "radio/check кнопки" -rx 5m -strokewidth 1 -stroke red -fillnormal snow]
    $clfrv boxtext
    $clfrv config -fontsize 3.5m -fillbox cyan
$clfrv pack -in $t.c -fill both -expand 1 -padx 1c -pady 5m -side left -anchor nw
update
#При использовании градиентной заливки при изменяемых размерах виджетов
#виджеты целесообразно создавать  на независимых окнах
#set rc1 [cbutton new $t.rgch.but1 -type radio  -text Radio1 -variable vrc1 -value 1]
set rc1 [cbutton new $t.but1 -type radio  -text Radio1 -variable vrc1 -value 1]
[$rc1 canvas] configure -bg [$clfrv config -fillnormal]
#set rc2 [cbutton new $t.rgch.but2 -type radio  -text Radio2 -variable vrc1 -value 0 ]
set rc2 [cbutton new $t.but2 -type radio  -text Radio2 -variable vrc1 -value 0 ]
[$rc2 canvas] configure -bg [$clfrv config -fillnormal]
#set rc3 [cbutton new $t.rgch.but3 -type check  -text Check1 -variable vrc3]
set rc3 [cbutton new $t.but3 -type check  -text Check1 -variable vrc3]
[$rc3 canvas] configure -bg [$clfrv config -fillnormal]
#set rc4 [cbutton new $t.rgch.but4 -type check  -text Check2 -variable vrc4]
set rc4 [cbutton new $t.but4 -type check  -text Check2 -variable vrc4]
#[$rc4 canvas] configure -bg [$clfrv config -fillnormal]
[$rc4 canvas] configure -bg snow
#set rc5 [cbutton new $t.rgch.but5 -type circle  -text Круг]
set rc5 [cbutton new $t.but5 -type circle  -text Круг]
[$rc5 canvas] configure -bg [$clfrv config -fillnormal]
#set rc6 [cbutton new $t.rgch.but6 -type square  -text Квадрат]
set rc6 [cbutton new $t.but6 -type square  -text Квадрат]
[$rc6 canvas] configure -bg [$clfrv config -fillnormal]
$rc1 pack -in [$clfrv canvas] -padx 1c -pady "1c 0"
$rc2 pack -in [$clfrv canvas] -padx 1c -pady "5m 0"
$rc3 pack -in [$clfrv canvas] -padx 1c -pady "5m 0"
$rc4 pack -in [$clfrv canvas] -padx 1c -pady "5m" -fill both -expand 1
$rc5 pack -in [$clfrv canvas] -padx 1c -pady "5m 0" -fill none -expand 1
$rc6 pack -in [$clfrv canvas] -padx 1c -pady "5m" -fill both -expand 1

#Кнопка обновления фона фреймов
set xaup [cbutton new $t.butup -type round  -text {Обновить окно} -command "$b1 fon;$clfrv fon;$went fon" ]
$xaup config -width 120
[$xaup canvas] configure -width 120

$xaup config -command "$b1 fon;$clfrv fon;$went fon;$xaup fon"

[$xaup canvas] configure -bg [$b1 config -fillnormal]
$xaup place -in $t.c -x 2m -y 2m
#Обновить градиентную заливку главного окна
set xgrad [cbutton new $t.butgrad -type round  -text {Обновить градиент} -command "updategrad [$tkpfr canvas] [$tkpfr config -fillnormal]" -width 150]
[$xgrad canvas] configure -bg [$b1 config -fillnormal]
$xgrad place -in $t.c -relx 0.7 -y 2m 


puts "frame=$b1 clframe=$clfrv  entry=$went but=$xaup"
bind .test <Destroy> {if {"%W" == ".test"} {catch {exitarm .test}}}
#Обновить окно
update
$xaup invoke