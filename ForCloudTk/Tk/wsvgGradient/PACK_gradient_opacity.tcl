package require svgwidgets
#package require canvas::gradient
variable tkpfr

catch {package require wm}
tk busy hold .dsvg

proc exitarm {t } {
	variable ::erm
	set mestok [mc "Are you sure you\nwant to quit?"]
	set erlib [mbutton new "$t.message" -type yesno  -fillnormal white -text "$mestok" ]
	set herlib [expr {int([winfo fpixels "$t.message" [$erlib config -height]])}]
	set werlib [expr {int([winfo fpixels "$t.message" [$erlib config -width]])}]
	wm resizable $t 0 0
	tk busy hold "$t.frame"
	set werlib [expr {[winfo width $t.frame] / 2 - $werlib / 2}]
	set herlib [expr {[winfo height $t.frame] / 4 }]
	set rr [$erlib place -in $t -x $werlib -y $herlib]
	tk busy forget "$t.frame"
	wm resizable $t 1 1
	if {$rr != "yes"} {
	    return
	}
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
		$oo destroy
	    }
	}
	destroy $t
	puts "Пример PACK_gradient_opacity.tcl завершен."
	tk busy forget .dsvg
	return
}


proc updatewin {went clfrv } {
    opacity 
    return
}

proc opacity {} {
    variable tkpfr
    $::b1 config -fillnormal {}
#updatewin $::b1 $::clfrv
    set ::winop 1
    set op 1
    foreach w1 [$tkpfr slavesoo] {
	$w1 fon
    }
    foreach w1 [$::b1 slavesoo] {
	$w1 fon
    }
    foreach w1 [$::clfrv slavesoo] {
	$w1 fon
    }

}
proc selwsvg {win x y} {
    set ::wwin [winfo containing $x $y]
#    puts "win=$::wwin wwin=$win x=$x y=$y"
    set ::wsvg -1
    foreach {wclass} "cbutton ibutton mbutton cmenu cframe" {
	set listoo [info class instances $wclass]
	foreach {oo} $listoo {
	    set type [$oo type]
	    if {[$oo canvas] == $::wwin} {
		set ::wsvg $oo
		puts $::wsvg
		return
	    } elseif {$type == "centry" || $type == "ccombo" || $type == "cspin" } {
		if {[$oo entry] == $::wwin} {
		    set ::wsvg $oo
		    puts $::wsvg
		    return
		}
	    }
	}
    }
    puts $::wsvg
}

#0 - нет прозрачности 1 - есть прозрачность
set ::winop 0

variable t
set t ".test"
destroy $t
toplevel $t
wm state $t withdraw
wm state $t normal
wm protocol $t WM_DELETE_WINDOW "exitarm [set t] "
wm title $t "tcl/tk pack gradient and opacity demo"

wm geometry $t 800x600+150+150
wm minsize $t 700 500

set tkpfr [cframe new $t.c -type frame -strokewidth 0 -stroke "" -fillnormal yellow]
set g4 [$t.c gradient create linear -method pad -units bbox -stops { { 0.0 cyan 1} { 1.0 yellow 1}} -lineartransition {0.0 0.0 0.0 1.0} ]
$tkpfr config -fillnormal $g4

update

pack $t.c -in $t -fill both -expand 1 -padx 3m -pady 3m
update
set went [cframe new $t.cent -type centry -rx 2m ]
$went pack -in $t.c -side top -fill x -expand 0 -padx 3c -pady "1c 2m" -anchor nw
set ::ww $went
#raise [$went canvas ]  $t.c
#SVG-фрейм
set ::b1 [cbutton new $t.frame -type frame -rx 5m ]
update
set ::xa1 [cbutton new $t.but1 -type rect  -text Прямоугольник]
set ::xa2 [cbutton new $t.but2 -type round  -text Полукруглый]
[$::xa2 canvas] configure -bg [$::b1 config -fillnormal]
set ::xa3 [cbutton new $t.but3 -type ellipse  -text Эллипс -fontweight bold -fontslant italic -fontfamily helvetica -fontsize 4m ]
#raise [$::xa3 canvas]
[$::xa3 canvas] configure -bg [$::b1 config -fillnormal]
set ::xa4 [cbutton new $t.but4 -type rect  -text {ВЫХОД (Закругленный)} -rx 2m -command "exitarm $t" -textfill red -fontweight bold -fontsize 4m]
[$::xa4 canvas] configure -bg [$::b1 config -fillnormal]
$::xa4 config  -textstroke black -textstrokewidth 0.7
$::b1 pack -in $t.c -fill both -expand 1 -padx 5m -pady 5m -side left -anchor nw
#$::b1 pack -in $t.c -fill y -expand 1 -padx 5m -pady 5m -side left -anchor nw
update
pack [$::xa1 canvas] -in $t.frame -padx 5m -pady "5m 0" -fill both -expand 1
pack [$::xa2 canvas] -in $t.frame -padx 5m -pady "5m 0" -fill both -expand 1
pack [$::xa3 canvas] -in $t.frame -padx 5m -pady "5m 0" -fill both -expand 1
#$::xa3 pack -in $t.frame -padx 1c -pady "5m 0" -fill both -expand 1
pack [$::xa4 canvas] -in $t.frame -padx 5m -pady "5m" -fill both -expand 1
#SVG-фрейм с заголовком
    set ::clfrv [cframe new $t.rgch -type clframe -text "radio/check кнопки" -rx 5m -strokewidth 1 -stroke red -fillnormal snow -fillopacity 1.0]
    $::clfrv boxtext
    $::clfrv config -fontsize 3.5m -fillbox cyan -fillopacity 0.5

$::clfrv pack -in $t.c -fill both -expand 1 -padx "0 5m" -pady 5m -side left -anchor nw

set ::rc1 [cbutton new $t.rbut1 -type radio  -text Radio1 -variable vrc1 -value 1]
set ::rc2 [cbutton new $t.rbut2 -type radio  -text Radio2 -variable vrc1 -value 0 ]
set ::rc3 [cbutton new $t.rbut3 -type check  -text Check1 -variable vrc3]
set ::rc4 [cbutton new $t.rbut4 -type check  -text Check2 -variable vrc4]
set ::rc5 [cbutton new $t.rbut5 -type circle  -text Круг]
set ::rc6 [cbutton new $t.rbut6 -type square  -text Квадрат -fillnormal ""]
if {0} {
$::rc1 pack -in [$::clfrv canvas] -padx 1c -pady "1c 0"
$::rc2 pack -in [$::clfrv canvas] -padx 1c -pady "5m 0"
$::rc3 pack -in [$::clfrv canvas] -padx 1c -pady "5m 0"
$::rc4 pack -in [$::clfrv canvas] -padx 1c -pady "5m" -fill both -expand 1
$::rc5 pack -in [$::clfrv canvas] -padx 1c -pady "5m 0"
$::rc6 pack -in [$::clfrv canvas] -padx 1c -pady "5m" -fill both -expand 1
}
if {1} {
set inwin [$::clfrv canvas]
pack [$::rc1 canvas] -in $inwin -padx 5m -pady "5m 0"
pack [$::rc2 canvas] -in $inwin -padx 5m -pady "5m 0"
pack [$::rc3 canvas] -in $inwin -padx 5m -pady "5m 0"
pack [$::rc4 canvas] -in $inwin -padx 5m -pady "5m" -fill both -expand 1
pack [$::rc5 canvas] -in $inwin -padx 5m -pady "5m 0"
pack [$::rc6 canvas] -in $inwin -padx 5m -pady "5m" -fill both -expand 1
}
#$::clfrv pack -in $t.c -fill both -expand 1 -padx 1c -pady 5m -side left -anchor nw
#lower [$::clfrv canvas] [$::rc1 canvas]
#Кнопка обновления фона фреймов
set upwin [cbutton new $t.butup -type round  -text {Обновить окно} -command {updatewin $b1 $::clfrv}]
$upwin config -width 120
[$upwin canvas] configure -width 120

#$::xa2 config -command "$::b1 fon;$::clfrv fon;$went fon;$::xa2 fon"
[$upwin canvas] configure -bg [$::b1 config -fillnormal]
$upwin place -in $t.c -x 2m -y 2m
#set bel [cbutton new $t.butbel -type round  -text {Прозрачный эллипс} -command {$::b1 config -fillnormal {};lower [$::xa3 canvas]; update;$::b1 fon; $::xa3 fon;$::xa3 config -fillnormal {};lower [$::b1 canvas] [$::xa1 canvas]}]
set bel [cbutton new $t.butbel -type rect -rx 4  -text {Прозрачность} -command {opacity}]
#$::xa2 config -command "$::b1 fon;$::clfrv fon;$went fon;$::xa2 fon"
#[$::xa2 canvas] configure -bg [$::b1 config -fillnormal]
$bel place -in $t.c -x 10c -y 2m

set ::bb $bel
set ::uu $upwin

puts "::rc1=$::rc1"
update
#$bel invoke

$tkpfr config -fillnormal $g4
$::clfrv config -fillopacity 0.3
bind $t <ButtonRelease-3> {selwsvg %W %X %Y}

wm withdraw .
$bel invoke
