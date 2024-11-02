package require svgwidgets
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
	foreach {oo} [info class instances clframe] {
	    $oo destroy
	}
if {0} {
	cbutton destroy
	ibutton destroy
	mbutton destroy
	cmenu destroy
	cframe destroy
}
	destroy $t
	puts "Пример button_GRID завершен."
	return
}

variable t
set t ".test"
destroy $t
toplevel $t
wm state $t withdraw
wm state $t normal

wm geometry $t 800x450+150+150
wm title $t "Виджеты класса cbutton"

frame $t.c -bg yellow
#tkp::canvas $t.c -bg yellow
#canvas::gradient $t.c -direction x -color1 cyan -color2 yellow

pack $t.c -in $t -fill both -expand 1 -padx 3m -pady 3m
update

#set went [cframe new $t.cent -type centry -rx 2m ]
#set went [cbutton new $t.cent -type rect  -text "SVG-виджеты класса CBUTTON" -rx 2m -fillenter "##" -fillpress "##" -bg yellow -fontweight bold -fontsize 4m -textfill red -textfillopacity 0.5 -textstroke blue -textstrokewidth 0.5]
set went [cbutton new $t.cent -type rect  -text "SVG-виджеты класса CBUTTON" -rx 2m -state disabled -bg yellow -fontweight bold -fontsize 4m -textfill red -textfillopacity 0.5 -textstroke blue -textstrokewidth 0.5]
[$went canvas] configure -bg yellow
grid [$went canvas] -in $t.c -row 0  -column 0 -columnspan 3 -pady "5m 0" -padx 0 -sticky n
grid rowconfigure $t.c "0" -weight 0

#SVG-фрейм
set b1 [cbutton new $t.frame -type frame -rx 5m ]
[$b1 canvas] configure -bg yellow

puts "b1=$b1"
update
set xa0 [cbutton new $t.frame.lab -type rect  -text "Кнопки rect, round, ellipse, rect" -rx 2m -state disabled -bg snow -fontweight bold]

#set xa1 [cbutton new $t.frame.but1 -type rect  -text Прямоугольник]
set xa1 [cbutton create Прямоугольник $t.frame.but1 -type rect  -text Прямоугольник -bg [$b1 config -fillnormal] -compound right -ipad "-1m 5m 1m 1m"]
#$xa1 config -image ::svgwidget::tpblank
set xa2 [cbutton new $t.frame.but2 -type round  -text Полукруглый]
[$xa2 canvas] configure -bg [$b1 config -fillnormal]
set xa3 [cbutton new $t.frame.but3 -type ellipse  -text Эллипс]
[$xa3 canvas] configure -bg [$b1 config -fillnormal]
set xa4 [cbutton new $t.frame.but4 -type rect  -text Закругленный -rx 2m]
[$xa4 canvas] configure -bg [$b1 config -fillnormal]
grid [$b1 canvas] -in $t.c -row 1 -column 0 -padx "5m 0" -pady 1c -sticky nswe
update
pack [$xa0 canvas] -in $t.frame -padx 2m -pady "3m 0" 
pack [$xa1 canvas] -in $t.frame -padx 1c -pady "5m 0" -fill both -expand 1
pack [$xa2 canvas] -in $t.frame -padx 1c -pady "5m 0" -fill both -expand 1
pack [$xa3 canvas] -in $t.frame -padx 1c -pady "5m 0" -fill both -expand 1
pack [$xa4 canvas] -in $t.frame -padx 1c -pady "5m" -fill both -expand 1

set clfrv [cbutton new $t.rdch -type frame -rx 2m -strokewidth 1 -stroke red -fillnormal snow -bg yellow]

set rc0 [cbutton new $t.rdch.lab -type rect  -text "Кнопки radio и check " -rx 2m -state disabled -bg snow -fontweight bold]

set rc1 [cbutton new $t.rdch.but1 -type radio  -text Radio1 -variable vrc1 -value 1]
[$rc1 canvas] configure -bg [$clfrv config -fillnormal]
set rc2 [cbutton new $t.rdch.but2 -type radio  -text Radio2 -variable vrc1 -value 0 ]
[$rc2 canvas] configure -bg [$clfrv config -fillnormal]
set rc3 [cbutton new $t.rdch.but3 -type check  -text Check1 -variable vrc3]
[$rc3 canvas] configure -bg [$clfrv config -fillnormal]
set rc4 [cbutton new $t.rdch.but4 -type check  -text Check2 -variable vrc4]
[$rc4 canvas] configure -bg [$clfrv config -fillnormal]
pack $t.rdch.lab -in $t.rdch -padx 2m -pady "3m 0"
pack $t.rdch.but1 -in $t.rdch  -padx 1c -pady "5m 0" -anchor nw
pack $t.rdch.but3 -in $t.rdch  -padx 1c -pady "5m 0" -anchor nw
pack $t.rdch.but2 -in $t.rdch  -padx 1c -pady "5m 0" -fill both -expand 1 -anchor nw
pack $t.rdch.but4 -in $t.rdch  -padx 1c -pady "5m 5m" -fill both -expand 1 -anchor nw
grid [$clfrv canvas] -in $t.c -row 1  -column 1 -padx "5m 5m" -pady 1c -sticky nswe -ipadx 1c


set clfrv [cbutton new $t.rdch1 -type frame -rx 5m -strokewidth 1 -stroke gray76 -fillnormal snow -bg yellow]

set rc0 [cbutton new $t.rdch1.lab -type rect  -text "Кнопки circle и  square" -rx 2m -state disabled -bg snow -fontweight bold]


set rc1 [cbutton new $t.rdch1.but1 -type circle  -text Circle1]
[$rc1 canvas] configure -bg [$clfrv config -fillnormal]
set rc2 [cbutton new $t.rdch1.but2 -type square  -text Square]
[$rc2 canvas] configure -bg [$clfrv config -fillnormal]
set rc5 [cbutton new $t.rdch1.but5 -type circle  -text Круг]
[$rc5 canvas] configure -bg [$clfrv config -fillnormal]
#set rc6 [cbutton new $t.rdch1.but6 -type square  -text Квадрат]
set rc6 [cbutton create Квадрат $t.rdch1.but6 -type square -text Квадрат ]
[$rc6 canvas] configure -bg [$clfrv config -fillnormal]
$rc0 pack -in [$clfrv canvas] -padx 2m -pady "3m 0"
$rc1 pack -in [$clfrv canvas] -padx 1c -pady "5m 0" -anchor nw
$rc2 pack -in [$clfrv canvas] -padx 1c -pady "5m 0" -anchor nw
$rc5 pack -in [$clfrv canvas] -padx 1c -pady "5m 0" -fill both -expand 1 -anchor nw
$rc6 pack -in [$clfrv canvas] -padx 1c -pady "5m" -fill both -expand 1 -anchor nw
#pack [$clfrv canvas] -in $t.c -fill both -expand 1 -padx 1c -pady 1c -side left
grid [$clfrv canvas] -in $t.c -row 1  -column 2 -padx "0m 5m" -pady 1c -sticky nswe

grid rowconfigure $t.c "1" -weight 1
grid columnconfigure $t.c "0 1 2 " -weight 1 -uniform b

bind .test <Destroy> {if {"%W" == ".test"} {catch {exitarm .test}}}
set vrc1 1
set vrc4 1
