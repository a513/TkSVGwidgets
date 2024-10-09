package require svgwidgets
package require canvas::gradient

proc exitarm {t} {
#Подчищаем за собою
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

	destroy $t
	puts "Пример button_PACK_gradient завершен."
	return
}

proc updatewin {went clfrv } {
#    puts "Updatewin ::b1=$::b1 ::xa1=$::xa1"
	lower [$::xa3 canvas]
    $::xa3  fon
	lower [$::b1 canvas]
    $::b1 fon
	lower [$clfrv canvas]
    $clfrv fon
	lower [$went canvas]
    $went fon
#Прозрачный эллипс
#    $::xa3  fon
    lower [$::b1 canvas] [$::xa1 canvas]
#puts "updatewin ::rc1=$::rc1"
    lower [$clfrv canvas] [$::rc1 canvas]
if {0} {
    if {$::winop} {
	opacity $went $clfrv
    }
}
}

proc opacity {frame1 frame2} {
    $::b1 config -fillnormal {}
updatewin $::b1 $::clfrv
    set ::winop 1
    set op 1
    foreach w1 "$::bb $::uu $::ww" {
	lower [$w1 canvas]
update
	$w1 fon
    }


    foreach w1 "$::xa1 $::xa2 $::xa3 $::xa4" {
	lower [$w1 canvas]
update
	$w1 fon
    }
#    lower [$::b1 canvas] [$::xa1 canvas]
puts "opacity ::rc1=$::rc1"
    foreach w1 "$::rc1 $::rc2 $::rc3 $::rc4 $::rc5 $::rc6" {
	lower [$w1 canvas]
update
	$w1 fon

    }
#    lower [$::clfrv canvas] [$::rc1 canvas]

}
#0 - нет прозрачности 1 - есть прозрачность
set ::winop 0

variable t
set t ".test"
destroy $t
toplevel $t
wm state $t withdraw
wm state $t normal
wm title $t "tcl/tk pack gradient and opacity demo"

wm geometry $t 798x598+150+150

tkp::canvas $t.c -bg yellow
#Уствновить gradient
#canvas::gradient .c -direction x -colr1 yellow -color2 blue
canvas::gradient $t.c -direction x -color1 cyan -color2 yellow
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
$::b1 pack -in $t.c -fill both -expand 0 -padx 5m -pady 5m -side left -anchor nw
#$::b1 pack -in $t.c -fill y -expand 1 -padx 5m -pady 5m -side left -anchor nw
update
pack [$::xa1 canvas] -in $t.frame -padx 5m -pady "5m 0" -fill both -expand 1
pack [$::xa2 canvas] -in $t.frame -padx 5m -pady "5m 0" -fill both -expand 1
pack [$::xa3 canvas] -in $t.frame -padx 5m -pady "5m 0" -fill both -expand 1
#$::xa3 pack -in $t.frame -padx 1c -pady "5m 0" -fill both -expand 1
pack [$::xa4 canvas] -in $t.frame -padx 5m -pady "5m" -fill both -expand 1
#SVG-фрейм с заголовком
    set ::clfrv [cframe new $t.rgch -type clframe -text "radio/check кнопки" -rx 5m -strokewidth 1 -stroke red -fillnormal snow -fillopacity 0.3]
    $::clfrv boxtext
    $::clfrv config -fontsize 3.5m -fillbox cyan -fillopacity 0.5

$::clfrv pack -in $t.c -fill both -expand 1 -padx "0 5m" -pady 5m -side left -anchor nw
set ::rc1 [cbutton new $t.rbut1 -type radio  -text Radio1 -variable vrc1 -value 1]
[$::rc1 canvas] configure -bg [$::clfrv config -fillnormal]
set ::rc2 [cbutton new $t.rbut2 -type radio  -text Radio2 -variable vrc1 -value 0 ]
[$::rc2 canvas] configure -bg [$::clfrv config -fillnormal]
set ::rc3 [cbutton new $t.rbut3 -type check  -text Check1 -variable vrc3]
[$::rc3 canvas] configure -bg [$::clfrv config -fillnormal]
set ::rc4 [cbutton new $t.rbut4 -type check  -text Check2 -variable vrc4]
[$::rc4 canvas] configure -bg [$::clfrv config -fillnormal]
set ::rc5 [cbutton new $t.rbut5 -type circle  -text Круг]
[$::rc5 canvas] configure -bg [$::clfrv config -fillnormal]
set ::rc6 [cbutton new $t.rbut6 -type square  -text Квадрат -fillnormal ""]
[$::rc6 canvas] configure -bg [$::clfrv config -fillnormal]
if {0} {
$::rc1 pack -in [$::clfrv canvas] -padx 1c -pady "1c 0"
$::rc2 pack -in [$::clfrv canvas] -padx 1c -pady "5m 0"
$::rc3 pack -in [$::clfrv canvas] -padx 1c -pady "5m 0"
$::rc4 pack -in [$::clfrv canvas] -padx 1c -pady "5m" -fill both -expand 1
$::rc5 pack -in [$::clfrv canvas] -padx 1c -pady "5m 0"
$::rc6 pack -in [$::clfrv canvas] -padx 1c -pady "5m" -fill both -expand 1
}
pack [$::rc1 canvas] -in [$::clfrv canvas] -padx 5m -pady "5m 0"
pack [$::rc2 canvas] -in [$::clfrv canvas] -padx 5m -pady "5m 0"
pack [$::rc3 canvas] -in [$::clfrv canvas] -padx 5m -pady "5m 0"
pack [$::rc4 canvas] -in [$::clfrv canvas] -padx 5m -pady "5m" -fill both -expand 1
pack [$::rc5 canvas] -in [$::clfrv canvas] -padx 5m -pady "5m 0"
pack [$::rc6 canvas] -in [$::clfrv canvas] -padx 5m -pady "5m" -fill both -expand 1

#$::clfrv pack -in $t.c -fill both -expand 1 -padx 1c -pady 5m -side left -anchor nw
#lower [$::clfrv canvas] [$::rc1 canvas]
#Кнопка обновления фона фреймов
set upwin [cbutton new $t.butup -type round  -text {Обновить окно} -command {updatewin $b1 $::clfrv}]
#$::xa2 config -command "$::b1 fon;$::clfrv fon;$went fon;$::xa2 fon"
[$upwin canvas] configure -bg [$::b1 config -fillnormal]
$upwin place -in $t.c -x 2m -y 2m
#set bel [cbutton new $t.butbel -type round  -text {Прозрачный эллипс} -command {$::b1 config -fillnormal {};lower [$::xa3 canvas]; update;$::b1 fon; $::xa3 fon;$::xa3 config -fillnormal {};lower [$::b1 canvas] [$::xa1 canvas]}]
set bel [cbutton new $t.butbel -type round  -text {Прозрачность} -command {opacity $went $::clfrv}]
#$::xa2 config -command "$::b1 fon;$::clfrv fon;$went fon;$::xa2 fon"
#[$::xa2 canvas] configure -bg [$::b1 config -fillnormal]
$bel place -in $t.c -x 10c -y 2m

set ::bb $bel
set ::uu $upwin

bind .test <Destroy> {if {"%W" == ".test"} {catch {exitarm .test}}}
#Обновить окно
wm geometry $t 800x600+150+150
$::b1 fon;$::clfrv fon;$went fon
lower [$::b1 canvas] [$::xa1 canvas]
#raise [$::xa3 canvas]
lower [$::clfrv canvas] [$::rc1 canvas]
raise [$went canvas ]  $t.c
$bel invoke
puts "::rc1=$::rc1"
