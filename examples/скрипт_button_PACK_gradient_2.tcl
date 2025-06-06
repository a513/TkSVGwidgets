package require svgwidgets
#Уствновить gradient
#canvas::gradient .c -direction x -colr1 yellow -color2 blue
package require canvas::gradient
proc exitarm {t} {
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
	destroy $t
	puts "Пример button_PACK_gradient завершен."
	return
}

variable t
set t ".test"
destroy $t
toplevel $t
wm state $t withdraw
wm state $t normal
wm title $t "tcl/tk pack gradient demo"

wm geometry $t 800x600+150+150

tkp::canvas $t.c -bg yellow
#Уствновить gradient
#canvas::gradient .c -direction x -colr1 yellow -color2 blue
canvas::gradient $t.c -direction x -color1 cyan -color2 yellow
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
set gradCloud [[$clfrv canvas] gradient create linear -method pad -units bbox \
    -stops { { 0.05 "#87ceeb" 1.00} { 0.17 "#ffffff" 1.00} { 0.29 skyblue 1.00} { 0.87 "#ffffff" 1.00} { 1.00 skyblue 1.00}} -lineartransition {1.00 0.00 0.75 1.00} ]
    $clfrv boxtext
    $clfrv config -fontsize 3.5m -fillbox cyan 
set rc1 [cbutton new $t.rgbut1 -type radio  -text Radio1 -variable vrc1 -value 1]
[$rc1 canvas] configure -bg [$clfrv config -fillnormal]
set rc2 [cbutton new $t.rgbut2 -type radio  -text Radio2 -variable vrc1 -value 0 ]
[$rc2 canvas] configure -bg [$clfrv config -fillnormal]
set rc3 [cbutton new $t.rgbut3 -type check  -text Check1 -variable vrc3]
[$rc3 canvas] configure -bg [$clfrv config -fillnormal]
set rc4 [cbutton new $t.rgbut4 -type check  -text Check2 -variable vrc4]
[$rc4 canvas] configure -bg [$clfrv config -fillnormal]
set rc5 [cbutton new $t.rgbut5 -type circle  -text Круг]
[$rc5 canvas] configure -bg [$clfrv config -fillnormal]
set rc6 [cbutton new $t.rgbut6 -type square  -text Квадрат]
[$rc6 canvas] configure -bg [$clfrv config -fillnormal]
    $clfrv config -fillnormal $gradCloud
$clfrv pack -in $t.c -fill both -expand 1 -padx 1c -pady 5m -side left -anchor nw
if {1} {
update
pack [$rc1 canvas] -in [$clfrv canvas] -padx 1c -pady "1c 0"
pack [$rc2 canvas] -in [$clfrv canvas] -padx 1c -pady "5m 0"
pack [$rc3 canvas] -in [$clfrv canvas] -padx 1c -pady "5m 0"
pack [$rc4 canvas] -in [$clfrv canvas] -padx 1c -pady "5m" -fill both -expand 1
pack [$rc5 canvas] -in [$clfrv canvas] -padx 1c -pady "5m 0"
pack [$rc6 canvas] -in [$clfrv canvas] -padx 1c -pady "5m" -fill both -expand 1
}
update
if {1} {
$clfrv pack -in $t.c -fill both -expand 1 -padx 1c -pady 5m -side left -anchor nw
$rc1 pack -in [$clfrv canvas] -padx 1c -pady "1c 0"
$rc2 pack -in [$clfrv canvas] -padx 1c -pady "5m 0"
$rc3 pack -in [$clfrv canvas] -padx 1c -pady "5m 0"
$rc4 pack -in [$clfrv canvas] -padx 1c -pady "5m" -fill both -expand 1
$rc5 pack -in [$clfrv canvas] -padx 1c -pady "5m 0"
$rc6 pack -in [$clfrv canvas] -padx 1c -pady "5m" -fill both -expand 1
}
update
#lower  [$clfrv canvas] [$rc1 canvas]
#lower  [$clfrv canvas] [$rc1 canvas]
#Кнопка обновления фона фреймов
set xa2 [cbutton new $t.butup -type round  -text {Обновить окно} -command "lower [$b1 canvas];$b1 fon;lower [$clfrv canvas];$clfrv fon;lower  [$clfrv canvas] [$rc1 canvas];lower [$went canvas];$went fon;lower  [$clfrv canvas] [$rc1 canvas]"]
$xa2 config -command "$b1 fon;$clfrv fon;$went fon;$xa2 fon;lower  [$clfrv canvas] [$rc1 canvas];$rc4 fon;$rc6 fon"
[$xa2 canvas] configure -bg [$b1 config -fillnormal]
$xa2 place -in $t.c -x 2m -y 2m

puts "frame=$b1 clframe=$clfrv  entry=$went but=$xa2"
bind .test <Destroy> {if {"%W" == ".test"} {catch {exitarm .test}}}
#Обновить окно
#$b1 fon;$clfrv fon;$went fon
$b1 fon;$went fon
#lower  [$clfrv canvas] [$rc1 canvas]
