package require svgwidgets
#source "../SVGWIDGETS/svgwidgets.tcl"

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
	puts "Пример button_PACK завершен."
	return
}

variable t
set t ".test"
destroy $t
toplevel $t
wm state $t withdraw
wm state $t normal

#####################
wm geometry $t 800x600+150+150
wm title $t "tcl/tk svg widgets pack demo"

#tkp::canvas $t.c -bg yellow
frame $t.c -bg yellow

pack $t.c -in $t -fill both -expand 1 -padx 3m -pady 3m
update

set went [cframe new $t.cent -type centry -rx 2m -height 7m -bg yellow]
puts "Поле ввода: $went"
$t.cent configure -height 28

pack $t.cent -in $t.c -side top -fill x -expand 1 -padx 3c -pady "1c 2m" -anchor nw

#SVG-фрейм
set b1 [cbutton new $t.frame -type frame -rx 5m ]
#[$b1 canvas ] configure -bg [$t.c cget -bg]
#Или
$t.frame configure -bg [$t.c cget -bg]

set bg [$b1 config -fillnormal]
set xa1 [cbutton create Прямоугольник $t.frame.but1 -type rect  -text Прямоугольник -fontweight bold]
set xa2 [cbutton new $t.frame.but2 -type round  -text Полукруглый -fontsize 3m -bg $bg]
#[$xa2 canvas] configure -bg [$b1 config -fillnormal]
set xa3 [cbutton new $t.frame.but3 -type ellipse  -text Эллипс -fontsize 5m -fontslant italic -bg $bg]
set xa4 [cbutton new $t.frame.but4 -type rect  -text Закругленный -fontsize 4m -rx 2m -bg $bg -compound none]
set img [foldercolor [$xa4 canvas] "blue" ]
$xa4 config -image "[$xa4 canvas] $img" -ipad "2m 10m  2m 12m"
[$xa4 canvas] delete $img

pack [$b1 canvas] -in $t.c -fill both -expand 1 -padx 1c -pady 5m -side left -anchor nw -ipady 300

pack [$xa1 canvas] -in $t.frame -padx 1c -pady "1c 0" -fill both -expand 1
pack [$xa2 canvas] [$xa3 canvas] -in $t.frame -padx 1c -pady "5m 0" -fill both -expand 1
pack [$xa4 canvas] -in $t.frame -padx 1c -pady "5m" -fill both -expand 1

#SVG-фрейм с заголовком
set clfrv [cframe new $t.rdch -type clframe -text "radio/check кнопки" -rx 1m -strokewidth 1 -stroke red -fillnormal snow ]
[$clfrv canvas] configure -background [$t.c cget -background]
$clfrv boxtext
$clfrv config -fontsize 3.5m -fillbox cyan

set bg [$clfrv config -fillnormal]
set rc1 [cbutton new $t.rdch.but1 -type radio  -text Radio1 -variable vrc1 -value 1 -bg $bg]
#[$rc1 canvas] configure -bg [$clfrv config -fillnormal]
set rc2 [cbutton new $t.rdch.but2 -type radio  -text Radio2 -variable vrc1 -value 0 -bg $bg ]
set rc3 [cbutton new $t.rdch.but3 -type check  -text Check1 -variable vrc3 -bg $bg]
set rc4 [cbutton new $t.rdch.but4 -type check  -text Check2 -variable vrc4 -bg $bg]
set rc5 [cbutton new $t.rdch.but5 -type circle  -text Круг -bg $bg]
set rc6 [cbutton new $t.rdch.but6 -type square  -text Квадрат -ipad "1m 1m 1m 1m" -bg $bg]
set rc7 [ibutton create Картинка $t.rdch.but7 -width 1c -height 1c -text Картинка -pad "1m 1m 1m 1m" -bg $bg -image "::tk::icons::error"]
set img [folderbrown [$rc6 canvas]]
$rc6 config -image "[$rc6 canvas] $img"
$rc6 config -fillnormal cyan
puts "Квадрат=$rc6"
[$rc6 canvas] delete $img

#Второй способ согласования цветов!!!
$rc1 pack -in [$clfrv canvas] -padx 1c -pady "1c 0"
$rc2 pack -in [$clfrv canvas] -padx 1c -pady "2m 0"
$rc3 pack -in [$clfrv canvas] -padx 1c -pady "2m 0"
$rc4 pack -in [$clfrv canvas] -padx 1c -pady "2m" -fill both -expand 1
$rc5 pack -in [$clfrv canvas] -padx 1c -pady "2m 0"
$rc7 pack -in [$clfrv canvas] -padx 1c -pady "2m 0" -fill x
$rc6 pack -in [$clfrv canvas] -padx 1c -pady "2m 5m" -fill both -expand 1
pack [$clfrv canvas] -in $t.c -fill both -expand 1 -padx 1c -pady 5m -side left -anchor ne -ipady 300

bind .test <Destroy> {if {"%W" == ".test"} {catch {exitarm .test}}}

