package require tkpath
package require treectrl

namespace eval ::svgwidget {

image create photo ::svgwidget::tpblank \
  -data {R0lGODlhFAAUAIAAAAAAAP///yH5BAkAAAAALAAAAAAUABQAAAIRhI+py+0Po5y02ouz3rz7rxUAOw==} \
  -gamma {1.0} -height {0}  -width {0}

#Контроль изменения переменной в radio-кнопке
proc trace_rb {var ind op} {
    global $var

    if {$ind != ""} {
	set var1 "[set var]([set ind])"
    } else {
	set var1 $var
	global $var1
    }
    
#puts "trace_rb: var1=$var1 value1=[set  $var1] ind=$ind op=$op"
    foreach b [info class instances cbutton] {
	set tpv [$b type]
	if {$tpv != "radio" && $tpv != "check"} {continue}
#Проверяем, что виджет отображается
	set cvt [$b canvas]
	if {![winfo exist $cvt]} {
	    $b destroy
	    continue
	}
	if {[winfo viewable [$b canvas]] == 0} {continue}
	if {[$b config -variable] != $var1} {continue}
#puts "trace_rb for radio: var=$var ind=\"$ind\" op=$op obj=$b var1=$var1"
	if {$tpv == "radio"} {
	    if {[$b config -value] != [set $var1]} {continue}
	    set trc 0
	} else { 
	    if {[$b config -vlast] == [set $var1]} {
		continue
	    }
	    set trc 1
	}

	$b press
	$b release [winfo rootx $cvt] [winfo rooty $cvt] $trc

#puts "trace_rb: var=$var  type=$tpv b=$b"
    }
}
#Вернуть объект в исходное (угол поворота 0)
proc id2angleZero {w id } {
    set m [list {1.0 0.0} {-0.0 1.0} {0.0 0.0}]
    $w itemconfigure $id -m $m
}

#Центр описывающего прямоугольника
proc id2center {w id} {
#Координаты прямоугольника вокруг объекта
    if { [$w bbox $id] == ""} {
	return ""
    }
    foreach {x0 y0 x1 y1} [$w bbox $id] {break}
#точка вращения - центр
    set xc [expr {($x1 - $x0) / 2.0 + $x0 }]
    set yc [expr {($y1 - $y0) / 2.0 + $y0 }]
    return [list $xc $yc]
}

#Повернуть id на угол с учетом существующего угла
proc idrotateAddAngle {w id deg {retm 0}} {
    set pi [expr 2*asin(1)]
    set phi [expr {$deg * $pi / 180.0}]
#puts "rotateid2angle id=$id deg=$deg phi=$phi"
    foreach {xr yr} [::svgwidget::id2center $w $id] {break}
#С КООРДИНАТАМИ ЛЕВОООГО ВЕРХНЕГО УГЛА
    set m1 [::tkp::matrix rotate $phi $xr $yr]
	if {$retm != 0} {
	    return $m1
	}
#Читаем что было
    set mOrig [$w itemcget $id -m]
    if {$mOrig != ""} {
	    set m1 [::tkp::matrix mult $mOrig $m1]
    }
    $w itemconfigure $id -m $m1
    return
}
#Повернуть id на угол от вертикали (прежнее значение не учитывается)
proc idrotate2angle {w id deg {retm 0}} {
    set pi [expr 2*asin(1)]
    set phi [expr {$deg * $pi / 180.0}]
#puts "rotateid2angle id=$id deg=$deg phi=$phi"
    if {[::svgwidget::id2center $w $id] == ""} {
	return
    }
    foreach {xr yr} [::svgwidget::id2center $w $id] {break}
#С КООРДИНАТАМИ ЛЕВОООГО ВЕРХНЕГО УГЛА
    set m1 [::tkp::matrix rotate $phi $xr $yr]
	if {$retm != 0} {
	    return $m1
	}
    $w itemconfigure $id -m $m1
    return
}
#move id - переместить по оси x и y на dx и dy
proc moveid2dxdy {w id dx dy } {
#Читаем что было
    set mOrig [$w itemcget $id -m]
    if {$mOrig == ""} {
#	return
	::svgwidget::id2angleZero $w $id
	set mOrig [$w itemcget $id -m]
    }
    foreach {x y} [lindex $mOrig 2] {break}
    set xnew [expr {$x + $dx}]
    set ynew [expr {$y + $dy}]
    set co3 "$xnew $ynew"
    set mnew [list "[lindex $mOrig 0]" "[lindex $mOrig 1]" "$co3"]
    $w itemconfigure $id -m $mnew
    return
}
proc cloneGrad {canv grad wcan} {
#Клонируем градиент 
    set type [$canv gradient type $grad]
    set cmd "$wcan gradient create $type "
    foreach option [$canv gradient configure $grad] {
	set optval [lindex $option 4]
	if {$optval != {}} {
	    lappend cmd [lindex $option 0] $optval
	} 
    }
#    puts "cloneGrad: cmd=$cmd"
    return [eval $cmd]
}
}
#Проверка загруженности класса
if {[info class instances ::oo::class ::cbutton] != ""} {
    cbutton destroy
}

oo::class create cbutton {
#idt - текст
#idr - прямоугольник вокруг кнопки
#idm - маркер radio/check button
#idg - группв, объединяющая idr,idt и $idm
#Переменные для check и radio должны быть глобальными, т.е. начинаться с ::  !!!!!!
  variable wcan
  variable idr
  variable idor
  variable idi
  variable idm
  variable idt
  variable tbut
  variable nexttag
  variable onemm2px
  variable canvasb
  variable btag
  variable Options
  variable wclass
  variable lmenu
#fr = 0 кнопки создаются на внешнем холсте
#fr - 1 кнопки создаются на внутреннем холсте для внешнего фрейма
  variable fr
  constructor {w {args "-text cbutton"}} {
    set wcan $w
    set lmenu [list ]
    set type "rect"
    set ind [lsearch $args "-type"]
    if {$ind > -1} {
	incr ind
	set type [lindex $args $ind]
    }
    set tbut $type
    set nexttag 0
    set wclass "cbutton"
    catch {unset Options}
    set Options(-relcom) 0
    set  Options(-state) "normal"
#    set  Options(-width) 25m
    set Options(-displaymenu) "release"
    set  Options(-width) 7m
    set  Options(-height) 7m
    set  Options(-rotate) 0
    set  Options(-compound) "left"
# Отступ слева, ширина, отступ сверху, отступ снизу
    set  Options(-ipad) [list 1m 1m 1m 1m]
    set Options(-strokewidth) 1
    set fr 0
    set Options(-x) 0
    set Options(-y) 0
    set canvasb "canvasb"
    set ind [lsearch $args "-strokewidth"]
    if {$ind > -1} {
	incr ind
	set Options(-strokewidth) [lindex $args $ind]
    }
    
    if {![winfo exists $wcan]} {
	tkp::canvas $wcan -bd 0 -highlightthickness 0
	set cwidth [winfo fpixels $wcan $Options(-width)]
	set cheight [winfo fpixels $wcan $Options(-height)] 
	set clw [winfo class [winfo parent $wcan]]

	if { [catch {[winfo parent $wcan] cget -background} xcolor] == 0 } {
    	    $wcan configure -background $xcolor
        } else {
	    set stylepar [[winfo parent $wcan] cget -style]
	    if {$stylepar == ""} {
		set bgc [ttk::style configure $clw -background]
	    } else {
		set bgc [ttk::style configure $stylepar -background]
	    }
	    if {$bgc != ""} {
    		$wcan configure -background $bgc
	    }
        }
        set fr 1

        append canvasb "fr"
    }
    set defx [winfo fpixels $w 25m]
    set defy [winfo fpixels $w 7m]
    set defrx [winfo fpixels $w 3.5m]
    set defry [winfo fpixels $w 12.5m]
    set tremm2px [winfo fpixels $w 3m]
    set twomm2px [winfo fpixels $w 2m]
    set onemm2px [winfo fpixels $w 1m]
    array set font [font actual systemSystemFont]
    set Options(-image) ""
    set Options(-isvg) ""
    set Options(-fontfamily) $font(-family)
    set Options(-fontsize) $tremm2px
    set Options(-fontweight) "normal"
    set Options(-fillnormal) white
    set Options(-textfill) black
#    set Options(-fillnormal) "#e9eeef"
    set Options(press) 0
    set Options(-fillenter) skyblue

    set Options(-fillpress) green

#    set Options(-stroke) gray40
    set Options(-stroke) #00bcd4
#    set Options(-strokenormal) #00bcd4
    set Options(-strokenormal) #00bcd4
    set Options(-strokeenter) #d3d7db
    set Options(-strokepress) #00bcd4
    set g3 [$wcan gradient create linear -method pad -units bbox -stops { { 0.00 #dbdbdb 1} { 1.00 #bababa 1}} -lineartransition {0.00 0.00 0.00 1.00} ]
    set g4 [$wcan gradient create linear -method pad -units bbox -stops { { 0.00 #ffffff 1} { 1.00 #dbdbdb 1}} -lineartransition {0.00 0.00 0.00 1.00} ]

    set  Options(-rx) 0
    set  Options(-ry) 0

    switch $type {
	check {
	    set Options(-width) $Options(-height)
	    set Options(-fillenter) #cccccc
	    set Options(-fillnormal) #eeeeee
	    set Options(-fillok) #2196f3
	    set Options(-text) checkbutton
	    set Options(-vlast) 0

	}
	radio {
	    set Options(-width) $Options(-height)
	    set Options(-fillenter) #cccccc
	    set Options(-fillnormal) #eeeeee
	    set Options(-fillok) #2196f3
	    set Options(-text) radiobutton
	    set Options(-value) ""
	
	}
	circle {
	    set Options(-width) $Options(-height)
	    set Options(-text) ccbutton
	    set  Options(-rx) [expr {[winfo fpixels $wcan $Options(-height)] / 2.0}]
    	    set g2 [$wcan gradient create radial -method pad -units bbox -stops { { 0.00 #ffff00 0.50} { 1.00 #d42b11 0.80}} -radialtransition {0.50 0.46 0.50 0.25 0.25} ]
	    set Options(-fillnormal) $g2
	}
	square {
	    set  Options(-ipad) [list 1m 5m 1m 5m]
	    set Options(-tintamount) 0.0
	    set Options(-tintcolor) chocolate
	    set Options(-width) $Options(-height)
	    set Options(-text) csbutton
	    set Options(-fillnormal) chocolate
	    set  Options(-ipad) "1m 1m 1m 1m"
	}
	ellipse {
	    set g1 [$wcan gradient create linear -stops {{0 "#bababa"} {1 "#454545"}} -lineartransition {0 0 0 1}]
	    set Options(-text) cebutton
	    set Options(-fillnormal) $g4
	    set Options(-fillenter) $g3
	    set Options(-fillpress) "cyan"
	    set Options(-strokenormal) #d3d7db
	    set Options(-strokeenter) "cyan"
	    set Options(-strokepress) #dadada
	    set  Options(-rx) [expr {[winfo fpixels $wcan $Options(-width)] / 2.0}]
	    set  Options(-ry) [expr {[winfo fpixels $wcan $Options(-height)] / 2.0}]
	}
	round {
	    set Options(-text) crbutton
	    set  Options(-rx) $defrx
#	    set Options(-fillnormal) tan
#	    set g3 [$wcan gradient create linear -method pad -units bbox -stops { { 0.00 #dbdbdb 0.50} { 1.00 #bababa 0.80}} -lineartransition {0.00 0.00 0.00 1.00} ]
#	    set g4 [$wcan gradient create linear -method pad -units bbox -stops { { 0.00 #ffffff 0.50} { 1.00 #dbdbdb 0.80}} -lineartransition {0.00 0.00 0.00 1.00} ]
#	    set g3 [$wcan gradient create linear -method pad -units bbox -stops { { 0.00 #dbdbdb 1} { 1.00 #bababa 1}} -lineartransition {0.00 0.00 0.00 1.00} ]
#	    set g4 [$wcan gradient create linear -method pad -units bbox -stops { { 0.00 #ffffff 1} { 1.00 #dbdbdb 1}} -lineartransition {0.00 0.00 0.00 1.00} ]
	    set Options(-fillnormal) $g4
	    set Options(-stroke) #dadada
	    set Options(-strokenormal) #dadada
	    set Options(-strokeenter) "cyan"
	    set Options(-strokepress) #dadada
	}
	rect {
# отступ слева (или справа), ширина картинки, отступ сверху (или/и снизу), высота картинки
	    set  Options(-ipad) [list 1m 5m 1m 5m]

	    set Options(-tintamount) 0.0
#	    set Options(-tintcolor) skyblue
	    set Options(-tintcolor) chocolate
	#Градиентная заливка
    	    set g_norm [$wcan gradient create linear -stops {{0 "#c0faff"} {1 "#00bcd4"}} -lineartransition {0 0.50 1 0.501}]
    	    set g_ent  [$wcan gradient create linear -stops {{0 "#00bcd4"} {1 "#c0faff"}} -lineartransition {0 0.50 1 0.501}]
    	    set g_press [$wcan gradient create radial -stops {{0 "#00bcd4"} {1 "#c0faff"}} -radialtransition {0.50 0.50 0.50 0.5 0.5}]
	
	    set g1_1 [$wcan gradient create linear -stops {{0 "#55ffff"} {1 "#00aaff"}} -lineartransition {0 0 0 1}]
	    set Options(-fillnormal) $g_norm
	    set Options(-fillenter) $g_ent
	    set Options(-fillpress) $g_press
#########GGGGGGGGGA###############
	    set Options(-fillnormal) $g4
	    set Options(-fillenter) $g3
	    set Options(-fillpress) "cyan"
	    set Options(-stroke) #dadada
#	    set Options(-strokenormal) #dadada
	    set Options(-strokenormal) #d3d7db
	    set Options(-strokeenter) "cyan"
	    set Options(-strokepress) #dadada
	    
	    set Options(-text) cbutton
	}
	frame {
	    set  Options(-rx) 2m
	    set Options(-fillnormal) snow
	    set Options(-stroke) gray85
	    set Options(-strokewidth) 0.5m
	    set Options(-width)		10m
	    set Options(-height)	7m
	    
	    set Options(-text) ""
	    set Options(-command) ""
	    set Options(-fillenter) "##"
	    set Options(-fillpress) "##"
	}
	default {
    	    error "Unknown type=$type..." 
	}
    
    } 

    set Options(-command) {}
    my config $args
    if {$Options(-text) != ""} {
	set w25 [winfo fpixels $w 25m]
	set h7 [winfo fpixels $w 7m]
	foreach {pxl pxr pyl pyr} $Options(-ipad) {break}
	set pxl [winfo fpixels $wcan $pxl]
	set pxr [winfo fpixels $wcan $pxr]
	set pyl [winfo fpixels $wcan $pyl]
	set pyr [winfo fpixels $wcan $pyr]
	switch $type {
	    rect -
	    round -
	    ellipse {
		set fontsize [winfo fpixels $wcan $Options(-fontsize)]
		set idt [$w create ptext 3 3 -text "$Options(-text)" -fontfamily $Options(-fontfamily) -fontsize $fontsize -fill $Options(-textfill) -fontweight $Options(-fontweight)]
		set ww [winfo fpixels $wcan $Options(-width)]
		set hw [winfo fpixels $wcan $Options(-height)]

		if {[info exists idt] && $Options(-text) != ""} {
		    ::svgwidget::idrotate2angle $wcan $idt $Options(-rotate)
		}

		foreach {xt1 yt1 xt2 yt2} [$wcan bbox $idt] {break} 
		set wt [expr {$xt2 - $xt1}]
		set ht [expr {$yt2 - $yt1}]
		$wcan delete $idt
		switch $Options(-compound)  {
		    right -
		    left {
			if {[expr {$wt + $pxr + $pxl * 2}] > $ww} {
			    set Options(-width) [expr {$wt + $pxr + $pxl * 2}]
			    if {[expr {$wt + $pxr + $pxl * 2}] < $w25} {
				set Options(-width) $w25
			    }
			}
			if {$ht > $hw} {
			    set Options(-height) $ht
			    if {$ht < $h7} {
				set Options(-width) $h7
			    }
			}
		    }
		    bottom -
		    top {
			if {[expr {$ht + $pyr + $pyl * 2}] > $hw} {
			    set Options(-height) [expr {$ht + $pyr + $pyl * 2}]
			    if {[expr {$ht + $pyr + $pyl * 2}] < $h7} {
				set Options(-height) $h7
			    }
			}
			if {$wt > $ww} {
			    set Options(-width) $wt
			    if {$wt < $w25} {
				set Options(-width) $w25
			    }
			}
		    }
		    none {
			if {$wt > $ww} {
			    set Options(-width) $wt
			    if {$wt < $w25} {
				set Options(-width) $w25
			    }
			}
			if {$ht > $hw} {
			    set Options(-height) $ht
			    if {$ht < $h7} {
				set Options(-width) $h7
			    }
			}
		    }
		}
	    }
	}
    }
    set x1 [winfo fpixels $wcan $Options(-x)]
    set y1 [winfo fpixels $wcan $Options(-y)]
    unset Options(-x)
    unset Options(-y)
    set x2 [expr {$x1 + [winfo fpixels $wcan $Options(-width)]}]
    set y2 [expr {$y1 + [winfo fpixels $wcan $Options(-height)]}]
    if {$tbut == "circle" || $type == "radio"} {
	set Options(-rx) [expr {[winfo fpixels $wcan $Options(-height)] / 2.0}]
    } else {
	set Options(-rx) [expr {[winfo fpixels $wcan $Options(-rx)]}]
    }
    set strwidth1 [winfo fpixels $wcan $Options(-strokewidth)]
    if {$fr == 1} {
	set entwidth [winfo fpixels $wcan $Options(-width)]
	$wcan configure -width $entwidth
	set entwidth [winfo fpixels $wcan $Options(-height)]
	$wcan configure -height $entwidth
    }

    if {$fr} {    
	set ch [$wcan cget -height]
	set cw [$wcan cget -width]	
    } else {
	set ch [winfo fpixels $wcan $Options(-height)]
	set cw [winfo fpixels $wcan $Options(-width)]
    }
#puts "ch=$ch cw=$cw ycoords=$ycoords xc0=$xc0 yc0=$yc0 strwidth=$strwidth"
    set idr [$wcan create prect $x1 $y1 [expr {$x1 + $cw}] [expr {$y1 + $ch}] -stroke {} -strokewidth 0] 
    my changestrwidth
    foreach {xr1 yr1 wrr hrr} [$wcan coords $idr] {break}
    set xr2 [expr {$x1 + $wrr}]
    set yr2 [expr {$y1 + $hrr}]


#puts "cbutton type=$type x1=$x1 y1=$y1"
    set btag "canvasb[string range [self] [string first Obj [self]] end]"
    set strwidth [winfo fpixels $wcan $Options(-strokewidth)]

#    $wcan itemconfigure $idr -fill $Options(-fillnormal) -stroke $Options(-stroke) -strokewidth $strwidth -rx $Options(-rx) -tags [list Rectangle obj $canvasb $btag [linsert $btag end rect] utag$idr]
    $wcan itemconfigure $idr -fill $Options(-fillnormal) -stroke $Options(-stroke) -rx $Options(-rx) -tags [list Rectangle obj $canvasb $btag [linsert $btag end rect] utag$idr]
    
    set idr "utag$idr"
    if {$type == "check"} {
	set mm1 [winfo fpixels $wcan 1m]
	set idm [$wcan create polyline "[expr {$x1 + $mm1 * 1.5}] [expr {$y1 + $mm1 * 3.0}] [expr {$x1 + $mm1 * 3}] [expr {$y1 + $mm1 * 5.0}] [expr {$x1 + $mm1 * 5.5}] [expr {$y1 + $mm1 * 2.0 }]"]

	$wcan itemconfigure $idm -strokewidth [expr {$mm1 * 0.75}] -stroke {}
	$wcan itemconfigure $idm -tags [list mark obj $canvasb $btag [linsert $btag end mark] utag$idm]
    }
    if {$type == "radio"} {
	set idm [$wcan create prect [expr {$xr1 + $wrr / 4}] [expr {$yr1 + $wrr / 4}] [expr {$xr2 - $wrr / 4}] [expr {$yr2 - $wrr / 4}]  -strokewidth 0 -stroke ""]
	$wcan itemconfigure $idm -rx [expr {$wrr / 4}] 
	$wcan itemconfigure $idm -tags [list mark obj $canvasb $btag [linsert $btag end mark] utag$idm]
    }
#Метка кнопки
    set testfont "sans-serif 12 normal"
    if {$type != "circle" && $type != "square" && $type != "radio" && $type != "check"} {
	set x [expr { ($x1 + $x2) / 2.0 }]
	set y [expr { ($y1 + $y2) / 2.0 }]
	set anc c
    } else {
	set x [expr {$x2 + $onemm2px}]
	set y [expr { ($y1 + $y2) / 2.0}]
	set anc w 
    }
    set fontsize [winfo fpixels $wcan $Options(-fontsize)]
    set idt [$w create ptext $x $y -textanchor $anc -text "$Options(-text)" -fontfamily $Options(-fontfamily) -fontsize $fontsize -fill $Options(-textfill) -fontweight $Options(-fontweight)]
    $wcan itemconfigure $idt -tags [list text obj $canvasb $btag [linsert $btag end text] utag$idt]

    set idt utag$idt

    set idor [$wcan create prect [$wcan coords $idr] -strokewidth 0 -stroke {} -rx $Options(-rx) -fillopacity 0 -strokeopacity 0 -fill red -tags [list idor obj $canvasb $btag [linsert $btag end idor]]]

    eval "$wcan bind $idor <Enter> {[self] enter}"
    eval "$wcan bind $idor <Leave> {[self] leave}"
    eval "$wcan bind $idor <ButtonPress-1> {[self] press}"
    eval "$wcan bind $idor <ButtonRelease-1> {[self] release %X %Y}"

    if {$tbut == "square" || $tbut == "citcle" || $tbut == "check" || $tbut == "radio"} {
	eval "$wcan bind $idt <Enter> {[self] enter}"
	eval "$wcan bind $idt <Leave> {[self] leave}"
    }
    $wcan itemconfigure $idr -fill $Options(-fillnormal) -stroke $Options(-stroke)
    if {$tbut == "ellipse"} {
	set ry [expr {[winfo fpixels $wcan $Options(-height)] / 2.0}]
	$wcan itemconfigure $idr -ry $ry
    }
#    puts "[self]"
    my config [array get Options]
    if {$tbut == "check"} {
	if {[info exists $Options(-variable)]} {
	    set $Options(-variable) [set $Options(-variable)]
	}
    }

    if {$fr == 1} {
	eval "bind $wcan  <Configure> {[self] resize %w %h 0}"
#	eval "bind $wcan  <ButtonRelease> {[self] fon}"
    }

  }

  method canvas {} {
    return $wcan
  }

  method type {} {
    return $tbut
  }

  

  method mcoords {} {
#Добавляем 0.5 для сохранения позиции???
    set crds {}
#puts "cbutton: idr=$idr wcan=$wcan coords=[$wcan coords $idr]"
    foreach {x0 y0 x1 y1} [$wcan coords $idr] {
	lappend crds "[expr {int(($x0 + 0.5) / $onemm2px)}]m"
	lappend crds "[expr {int(($y0 + 0.5) / $onemm2px)}]m"
    }
    set Options(-width) "[expr {($x1 - $x0) / $onemm2px}]m"
    set Options(-height) "[expr {($y1 - $y0) / $onemm2px}]m"
#puts $crds
    return $crds
  }
  
  method state {stat} {
#stat - normal|disabled|hidden
    if {![info exists idr] || ![info exists idor]} {
	return
    }
    switch $stat {
	normal -
	disabled {
	    $wcan itemconfigure $idr -state $stat
	    $wcan itemconfigure $idt -state $stat
	    $wcan itemconfigure $idor -state $stat
	}
	hidden {
	    $wcan itemconfigure $idr -state $stat
	    $wcan itemconfigure $idt -state $stat
	}
	default {
	    error "Bad state=$stat"
	}
    }
  }
  
  method move {dx dy} {
	if {$fr == 1} {
	    return $btag
	}
#puts "cbutton move canvasb=$btag"
	$wcan move $btag  $dx $dy
	return $btag
  }
  method options {} {
    if {[info exists Options(-rx)]} {
	    set Options(-rx) [$wcan itemcget $idr -rx]
    }
    if {[info exists Options(-ry)]} {
	    set Options(-ry) [$wcan itemcget $idr -ry]
    }
    if {$tbut != "check" && $tbut != "radio"} {
	set Options(-strokewidth) [$wcan itemcget $idr -strokewidth]
    }
    set Options(-fontfamily) [$wcan itemcget $idt -fontfamily]
    set Options(-fontsize) "[string range [expr {[$wcan itemcget $idt -fontsize] / $onemm2px } ] 0 4]m"

    return [array get Options]
  }

  method enter {} {
	if {$tbut == "frame"} { return}
	variable Options
	if {$tbut == "check" || $tbut == "radio"} {
	    set fok [$wcan itemcget $idr -fill] 
	    if {$fok == $Options(-fillok)} {
		return
	    }
	} elseif {[info exist Options(-menu)] && $Options(-menu) != ""} {
	    if {$Options(-displaymenu) != "enter"} {
		return
	    }
	    foreach {xm ym } [my showmenu] {break}
	    puts "Method enter -> showmenu: Кнопка=[self] xm=$xm ym=$ym Options(-menu)=$Options(-menu)"
	} 
	if {$Options(-fillenter) == "##"} {
	    return
	}

	set strwidth [winfo fpixels $wcan $Options(-strokewidth)]
	my changestrwidth [expr {$strwidth + $strwidth / 2.0}]

	$wcan itemconfigure $idr -fill $Options(-fillenter) -stroke $Options(-strokeenter)
  }
  method leave {} {
    variable Options
	if {$tbut == "frame"} { return}
	if {$tbut == "check" || $tbut == "radio"} {
	    set fok [$wcan itemcget $idr -fill] 
	    if {$fok == $Options(-fillok)} {
		return
	    }
	    if {$tbut == "radio"} {
		$wcan itemconfigure $idm -fill $Options(-fillnormal)
	    }
	}
    if {!$Options(press)} {
	set strwidth [winfo fpixels $wcan $Options(-strokewidth)]
	$wcan itemconfigure $idr -stroke $Options(-strokenormal)  -fill $Options(-fillnormal)
	my changestrwidth $strwidth

    }
#    set Options(press) 0
  }
  method press {} {
    variable Options
    if {$tbut == "frame"} { return}
    set Options(press) 1
    if {$tbut != "check" && $tbut != "radio" && $Options(-fillpress) != "##"} {
	$wcan itemconfigure $idr -fill $Options(-fillpress) -stroke $Options(-strokepress)
    }
  }
  

  method release {x y {trc 0}} {
    variable Options
#puts "RELEASE cbutton wcan=$wcan x=$x y=$y"
    if {$tbut == "frame"} { return}
    set tfr 1
    if {$fr || !$fr} {
	set x1 [winfo rootx $wcan]
	set x2 [expr {$x1 + [winfo width $wcan]}] 
	set y1 [winfo rooty $wcan]
	set y2 [expr {$y1 + [winfo height $wcan]}] 
	if {$x < $x1 || $x > $x2 || $y < $y1 || $y > $y2} {
	    if {$tbut == "check" || $tbut == "radio"} { 
		set tfr 0
		set Options(press) 0
		return
	    }
	    if {$Options(-relcom) == 0} {
		set tfr 0
		set Options(press) 0
	    }
	}
    }
    if {[info exist Options(-menu)] && $Options(-menu) != ""} {
	if {$Options(-displaymenu) != "release"} {
	    return
	}
	foreach {xm ym } [my showmenu] {break}
	if {$xm == -1 && $ym == -1} {
	    puts "Method release -> sgowmenu: Кнопка=[self] xm=$xm ym=$ym Options(-menu)=$Options(-menu)"
	    catch {$wcan itemconfigure $idr -fill $Options(-fillenter) -stroke $Options(-strokeenter)}
	    return
	}
	puts "Method release -> sgowmenu: Кнопка=[self] xm=$xm ym=$ym Options(-menu)=$Options(-menu)"
    }
    
    if {!($Options(press) && $tfr)} {
	$wcan itemconfigure $idr -fill $Options(-fillnormal)  -stroke $Options(-strokenormal)
	return
    }
	set Options(press) 0
	if {$tbut == "check" || $tbut == "radio"} {
	    if {[info exists Options(-variable)]} {
		set value $Options(-variable)
		set ind1 [string first "(" $value]
		set ind2 [string last ")" $value]
		if {$ind1 == -1 || $ind2 == -1 || $ind1 > $ind2} {
		    global $value
		} else {
		    global [string range $value 0 $ind1-1]
		}
	    }
	    set fok [$wcan itemcget $idr -fill] 
	    if {$fok == $Options(-fillok)} {
		if {$tbut == "check"} {
		    if {$trc == 0} {
			set $Options(-variable) 0
			return
		    }
		    $wcan itemconfigure $idr -fill $Options(-fillenter)
		    $wcan itemconfigure $idm -stroke {}
		    my changestrwidth 

		    set Options(-vlast) 0
		}
	    } else {
		if {$tbut == "check" && $trc == 0 } {
		    set $Options(-variable) 1
		    return
		}
		$wcan itemconfigure $idr -fill $Options(-fillok)
		$wcan itemconfigure $idm -stroke white 
		$wcan itemconfigure $idr  -stroke {}
		my changestrwidth 0

		if {$tbut == "radio"} {
		    $wcan itemconfigure $idm -fill white
#Сбрасываем другие radio кнопки
		    set lrb {}
		    foreach b [info class instances cbutton] {
			if {[self] == $b} {continue}
			if {[$b type] != "radio" } {continue}
			if {[$b config -variable] != "$Options(-variable)"} {continue}
			$b config -fill $Options(-fillnormal)
			$b leave
		    }
		    set $Options(-variable) $Options(-value)
		} else {
		    set Options(-vlast) 1
		}
	    }
	}
	if {$tbut != "check" && $tbut != "radio" } {
	    catch {$wcan itemconfigure $idr -fill $Options(-fillenter) -stroke $Options(-strokeenter)}
	}
	if {$Options(-command) != ""} {
#puts "CBUTTON x=$x y=$y"
	    set cmd [subst "set x [set x];set y [set y];"]
	    append cmd [my config -command]
	    after 0 eval $cmd
	}
  }
  
  method invoke {} {
    if {$tbut == "frame"} { return}
    my enter
    my press
    set xi [expr {[winfo rootx $wcan] + 2}]
    set yi [expr {[winfo rooty $wcan] + 2}]
    my release $xi $yi 
    my leave
  }

  method resize {wx hy {from 1}} {
#from = 1 resize делает пользователь
#from = 0 resize вызывается событием Configure

#puts "cbutton resize: fr=$fr wx=$wx hy=$hy"
    if {$tbut == "frame"}  {
	set wx [winfo fpixels $wcan $wx]
	set hy [winfo fpixels $wcan $hy]
	foreach {x0 y0 x1 y1} [$wcan coords $idr] {break}
#puts "x0=$x0 y0=$y0 x1=$x1 y1=$y1"
	set swidth [$wcan itemcget $idr -strokewidth]
	if {$fr == 1} {
	    set x1 [expr {$wx - $swidth}]
	    set y1 [expr {$hy - $swidth}]
#puts "NEW x0=$x0 y0=$y0 x1=$x1 y1=$y1"
	} else {
	    set x1 [expr {$x0 + $wx - $swidth}]
	    set y1 [expr {$y0 + $hy - $swidth}]
	}
	my config -width $x1
	my config -height $y1

	return
    }
    if {$fr == 0} {
	return
    }

    set wx [winfo fpixels $wcan $wx]
    set hy [winfo fpixels $wcan $hy]
    if {$wx < $onemm2px || $hy < $onemm2px} {
	return
    }

    if {$tbut == "radio" || $tbut == "circle" || $tbut == "check" || $tbut == "square" } {
	set yold [expr {[winfo fpixels $wcan $hy] / [winfo fpixels $wcan [my config -height] ]}]
	set wold [expr {([winfo fpixels $wcan $wx] - [winfo fpixels $wcan $hy]) / [winfo fpixels $wcan [my config -width]]}]
    } else {
	set wold [expr {[winfo fpixels $wcan $wx] / [winfo fpixels $wcan [my config -width] ]}]
	set yold [expr {[winfo fpixels $wcan $hy] / [winfo fpixels $wcan [my config -height] ]}]
    }
    set strwidth [winfo fpixels $wcan [my config -strokewidth]]
    if {$tbut == "square"} {
	if {$hy < $wx} {
	    set wx $hy
	}
    }
    my config -width $wx
    my config -height $hy
#Пока отложим
if {0} {
    if {$Options(-text) != ""} {
	set fold [$wcan itemcget $idt -fontsize]
	set forig [winfo fpixels $wcan [my config -fontsize]]
	set nfont [expr {$fold  * min ($wold, $yold)}]
	if {$forig > $nfont} {
	    set nfont $forig
	}
	$wcan itemconfigure $idt -fontsize $nfont
    }
}

    if {$tbut == "frame"} {
	return
    }
    if {$tbut == "round"} {
	if {$wx > $hy} {
	    set rx [expr {$hy / 2.0}]
	} else {
	    set rx [expr {$wx / 2.0}]
	}
	my config -rx $rx
    }
    foreach {x1 xh y1 y2} [my config -ipad] {break} 
    if {$tbut == "square" } {
	set wold $yold
	set ipad [expr {[winfo fpixels $wcan $x1] * $wold}]
    } else {
	set ipad [expr {[winfo fpixels $wcan $x1]}]
    }
    append ipad " [expr {[winfo fpixels $wcan $xh] * $wold }]"
    append ipad " [expr {[winfo fpixels $wcan $y1] * $yold}]"
    append ipad " [expr {[winfo fpixels $wcan $y2] * $yold}]"
#puts "cbutton resize: fr=$fr wold=$wold yold=$yold ipad=$ipad"

    my config -ipad "[set ipad]"
    if {$from && $fr} {
	foreach {x1 y1 x2 y2} [$wcan bbox 0] {break}
	set cw [expr {$x2 + $x1}]
	set ch [expr {$y2 + $y1}]
	my config -width $cw -height $ch 
	$wcan configure -width $cw -height $ch
    }
  }

  
  method config args {
    set svgtype [list circle ellipse group path  pline polyline ppolygon prect ptext]
#pimage - это делается отдельно
    if {[llength $args] == 1} {
	set args [lindex "$args" 0]
    }
    if {[llength $args] == 0} {
	return [array get Options]
    }

    if {[llength $args] % 2 != 0} {
#Чтение значения аттрибута
	if {[llength $args] == 1} {
#puts "config $args : $Options($args)"
	    return $Options($args)
	}
#puts "Error args length: $args"
      error "use is: <object> config ?-option value?...\nargs=$args" 
    }

    foreach {option value} $args {
        switch $option \
        {
	    -background -
	    -bg {
		if {$fr} {
		    set  Options($option) $value
		    $wcan configure -background $value
		}
	    }
    	    -menu {
		if { $tbut != "check" &&  $tbut != "radio"} {
		    set  Options($option) $value
		}
    	    }
    	    -displaymenu {
    		if {[lsearch [list "release" "enter" ] $value] == -1} {
    		    error "Error for displaymenu ($value): -displaymenu \[ release | enter \]"
		    continue
    		}
		set  Options($option) $value
    	    }
    	    -relcom {
    		if {$value == 0 || $value == 1} {
		    set  Options($option) $value
		}
    	    }
    	    -compound {
    		if {[lsearch [list "top" "bottom" "left" "right" "none"] $value] == -1} {
    		    error "Error for side ($value): -compound \[ top | bottom | left | right | none \]"
		    continue
    		}
		set  Options($option) $value
    	    }
	    -rotate {
		set  Options($option) $value
		if {[info exists idt] && $Options(-text) != ""} {
		    ::svgwidget::idrotate2angle $wcan $idt $value
		}
	    }
	    -x -
	    -y {
    		if {[info exists idr] || $fr} {
    		    continue
    		}
		set  Options($option) $value
	    }
	    -type {
    		if {[info exists idr]} {
    		    continue
    		}
		set  Options($option) $value
	    }
	    -ipad {
    		if {![info exists idr]} {
		    set  Options($option) $value
		    continue
    		}

		set lpad [llength $value]
# 1 - Отступ везде одинаков - сверху, снизу, слева, справа; ширина == высоте кнопки
# 2 - Отступ по x слева и справа первый параметр, отступ - сверху и снизу второй параметр; ширина == высоте
# 3 - Отступ по x слева и справа первый параметр и ширина картинки - второй параметр, отступ - сверху и снизу третий параметр
# 4 - Отступ по x слева и справа первый и ширина картинки - второй параметр, отступ - сверху и снизу третий и четвертый параметры
# Чтобы не было проблем задавайте все четыре числа
		switch $lpad {
		    1 {
if {1} {
    			if {$tbut != "square"} {
			    set Options(-ipad) [list 1m $value 1m $value]
			} else {
			    set Options(-ipad) [list $value $value $value $value]
			}
}
#			    set Options(-ipad) [list $value $value $value $value]
		    }
		    2 {
			foreach {l1 l2} $value {break}
if {1} {
    			if {$tbut != "square"} {
			    set Options(-ipad) [list 1m $l1 1m $l2]
			} else {
			    set Options(-ipad) [list $l1 $l1 $l2 $l2]
			}
}
#			    set Options(-ipad) [list $l1 $l1 $l2 $l2]
		    }
		    3 {
			foreach {l1 l2 l3} $value {break}
    			if {$tbut != "square"} {
			    set Options(-ipad) [list $l1 $l2 $l1 $l3]
			} else {
			    set Options(-ipad) [list $l1 $l2 $l3 $l3]
			}
		    }
		    4 {
			set Options(-ipad) $value
		    }
		    default {
    			puts "Bad value option -ipad: $option=$value"
    			continue
		    }
		}
		if {$Options(-isvg) != ""} {
    		    my config -image "$wcan $Options(-isvg)"
		} elseif {[info exists idi]} {
    		    my config -image $Options(-image)
		}
	    }
	    -image {
    		if {$tbut != "rect" && $tbut != "square"} {
#    		    puts "-image not rect"
    		    continue
    		}
		if {![info exists idr] } {
    		    set Options($option) "$value"
    		    continue
		}
		if {[llength $value] == 2} {
    		    my config -isvg "$value"
    		    return
		}
    		if {[info exists Options(-isvg)] && $Options(-isvg) != ""} {
			$wcan delete $Options(-isvg)
			set Options(-isvg) ""
		}
		    foreach {pxl pxr pyl pyr} $Options(-ipad) {break}
		    set pxl [winfo fpixels $wcan $pxl]
		    set pxr [winfo fpixels $wcan $pxr]
		    set pwidth $pxr
		    set pyl [winfo fpixels $wcan $pyl]
		    set pyr [winfo fpixels $wcan $pyr]
		    set pheight $pyr

    		if {$value == ""} {
    		    set Options($option) "$value"
		    if {[info exists idi]} {
			foreach {xi1 yi1 xi2 yi2} [$wcan bbox $idi] {break}
    			$wcan delete $idi
    			unset idi    
			if {$tbut != "square" && $tbut != "circle"} {
			    foreach {x1 y1 x2 y2} [$wcan bbox $idr] {break}
			    set x [expr { ($x1 + $x2) / 2.0}]
			    set y [expr { ($y1 + $y2) / 2.0}]
			    $wcan coords $idt "$x $y "
			    $wcan itemconfigure  $idt -textanchor c
			}
		    }
    		    continue
    		}
		if {![info exists idr] } {
    		    set Options($option) "$value"
    		    continue
		}
		set itype [catch {image type $value}]
		if {$itype == 0} {
    		    set Options($option) $value
    		    if {[info exists Options(-isvg)]} {
			$wcan delete $Options(-isvg)
			set Options(-isvg) ""
    		    }
		    foreach {xt1 yt1 xt2 yt2} [$wcan bbox $idt] {break}
		    
    		    if {[info exists idr] && ![info exists idi]} {
#Учесть координаты для compound - left и т.д.
    			foreach {x1 y1 x2 y2} [$wcan bbox $idr] {break}
    			set x2 [expr {$x1 + $x2}]
    			set y2 [expr {$y1 + $y2}]

#Создаём image!!!
			if {$tbut != "square"} {
			    set idi [$wcan create pimage [expr {$x1 + $pxl}] [expr {$y1 + $pyl}] -image $Options(-image) -tintcolor $Options(-tintcolor) -tintamount 0.0  \
				-width $pwidth -height $pheight -anchor nw]
			} else {
			    set idi [$wcan create pimage [expr {$x1 + $pxl}] [expr {$y1 + $pyl}] -image $Options(-image) -tintcolor $Options(-tintcolor) -tintamount 0.0  \
				-width [expr {($x2 - $x1) - ($pxl + $pxr)}] -height [expr {($y2 - $y1) - ($pyl + $pyr)}] -anchor nw]
			}

			$wcan itemconfigure $idi -tags [list pimage obj $canvasb $btag [linsert $btag end pimage] utag$idt]

    		    }
		    if {[info exists idi]} {
    			foreach {x1 y1 x2 y2} [$wcan bbox $idr] {break}
    			set x2 [expr {$x1 + $x2}]
    			set y2 [expr {$y1 + $y2}]
#Посчитать с учётом -ipad
			set w [image width $value]
			set h [image height $value]
			if {$tbut != "square"} {
			    $wcan itemconfigure $idi $option $value -width $pwidth -height $pheight  -srcregion [list 0 0 $w $h] -state normal
			} else {
			    $wcan itemconfigure $idi $option $value -width [expr {($x2 - $x1) - ($pxl + $pxr)}]  -height [expr {($y2 - $y1) - ($pyl + $pyr)}]  -srcregion [list 0 0 $w $h] -state normal
			}
			foreach {cxi cyi} [$wcan coords $idi] {break}
			$wcan coord $idi [expr {$x1 + $pxl}] [expr {$y1 + $pyl}]
			if {$tbut != "square"} {
			    foreach {xi1 yi1 xi2 yi2} [$wcan bbox $idi] {break}
			} else {
    			    foreach {xi1 yi1 xi2 yi2} [$wcan bbox $idr] {break}
    			    set xi2 [expr {$xi1 + $xi2}]
    			    set yi2 [expr {$yi1 + $yi2}]
			}
			if {$tbut != "square" && $tbut != "circle"} {
			    set x [expr {$xi2 + $pxl}]
			    set y [expr { ($y1 + $y2) / 2.0}]
			    set tanchor  "w"
			    switch $Options(-compound)  {
				left {
				    set x [expr {$xi2 + $pxl}]
				    set y [expr { ($y1 + $y2) / 2.0}]
				    set tanchor  "w"
				}
				right {
				    set y [expr { ($y1 + $y2) / 2.0}]
				    set tanchor  "w"
#				    puts "right"
				
				}
				top {
#				    set x [expr {$xi2 + $pxl}]
				    set x [expr { ($x1 + $x2) / 2.0}]
				    set y [expr { $yi2 + $pyl * 0 }]
				    set tanchor  "n"
				}
				bottom {
				    set x [expr { ($x1 + $x2) / 2.0}]
				    set y [expr { 0 + $pyl * 1.0 }]
				    set tanchor  "n"
#				    puts "bottom"
				}
				none {
				    foreach {x1 y1 x2 y2} [$wcan bbox $idr] {break}
				    set x [expr { ($x1 + $x2) / 2.0}]
				    set y [expr { ($y1 + $y2) / 2.0}]
				    $wcan coords $idt "$x $y "
				    $wcan itemconfigure  $idt -textanchor c
				    $wcan raise $idt
				}
			    }
#puts "Options(-compound)=$Options(-compound) X=$x Y=$y tanchor=$tanchor"
			    if {[info exist idt] && $Options(-text) != "" && $Options(-compound) != "none" } {
				::svgwidget::id2angleZero $wcan $idt
				$wcan itemconfigure  $idt -textanchor $tanchor
				$wcan coords $idt "$x $y "
				if {$Options(-rotate) != 0} {
				    ::svgwidget::idrotate2angle $wcan $idt $Options(-rotate)
				    foreach {xt1 yt1 xt2 yt2} [$wcan bbox $idt] {break}
				    ::svgwidget::id2angleZero $wcan $idt
				    set dx 0
				    set dy [expr {$yi2 + $pyl - $yt1}]
				    $wcan move $idt $dx $dy
				    ::svgwidget::idrotate2angle $wcan $idt $Options(-rotate)
				}
				foreach {ix iy} [$wcan coords $idi] {break}
				foreach {tx1 ty1 tx2 ty2} [$wcan bbox $idt] {break}
				if {$Options(-compound) == "bottom"} {
				    set iy [expr {$ty2 + $pyl}]
				    $wcan coords $idi $ix $iy
				} elseif {$Options(-compound) == "right"} {
				    foreach {bix1 biy1 bix2 biy2} [$wcan bbox $idi] {break}
				    foreach {x1 y1 x2 y2} [$wcan bbox $idr] {break}
				    set ix [expr {$x2 - ($bix2 - $bix1 + $pxl * 2)}]
				    $wcan coords $idi $ix $iy
				}

    				$wcan raise $idt $idr

			    }
			}
    			$wcan raise $idor
		    }
		    continue 
		} else {
    			puts "Bad value option -image: $option=$value"
    			continue
		}
	    }
    	    -isvg {
    		if {$tbut != "rect" && $tbut != "square"} {
#    		    puts "-isvg not rect"
    		    continue
    		}

    		if {$value == ""} {
    		    if {[info exists Options(-isvg)]} {
			if {$Options(-isvg) != ""} {
    			    $wcan delete $Options(-isvg)
    			    unset Options(-isvg)
			}
    		    }
    		    continue
    		}
####################
#Проверяем, что это картинка SVG
		if {[llength $value] == 3} {
		    set value [lrange $value 1 2]
		}
		if {[llength $value] != 2} {
    		    error "for svg image ($value): -isvg \"<canvas> <tagORidItem>\""
		}
		if {![info exists idr] } {
    		    set Options($option) "$value"
    		    continue
		}
		foreach {canv item} $value {break}
#puts "ISVG: canv=$canv item=$item"
		if {$canv == "$wcan" && $item == $Options(-isvg)} {
		    set value $item
    		    set isvg $Options(-isvg)
		    set isvgold ""
#    $wcan scale $isvg 0 0 1 1
		} else {
		    set value [my copyItem $canv $item 0 0]

#puts "ISVG: canv=$canv item=$item value=$value"
    		    set itype [$wcan type $value]
    		    if {$itype == ""} {
			error "cbutton: Bad svg image=$itype, value=$value"
    		    }
    		    if {[lsearch $svgtype $itype] == -1} {
			error "cbutton: Bad1 svg image=$itype, value=$value"
    		    }
    		    set isvgold ""
    		    if {[info exists Options(-isvg)]} {
    			set isvgold $Options(-isvg)
    			$wcan itemconfigure $isvgold -state normal
    		    }
		    set  Options(-isvg) $value
		    if {![info exists idr]} {
    			puts "-isvg IDR NOT"
			continue
		    }
#puts "cbutton: -isvg ok"
    		    set isvg $Options(-isvg)
		    $wcan itemconfigure $isvg -tags [list isvg obj $canvasb $btag [linsert $btag end isvg] utag$idt]
		}
    		foreach {sx1 sy1 sx2 sy2} [$wcan bbox $isvg] {break}
    		if {$tbut == "rect" } {
    		    foreach {rx1 ry1 rx2 ry2} [$wcan bbox $idr] {break}
    		    set rx2 [expr {$rx1 + $rx2}]
    		    set ry2 [expr {$ry1 + $ry2}]
    		} else {
    		    foreach {rx1 ry1 rx2 ry2} [$wcan bbox "$btag rect"] {break}
    		    set rx2 [expr {$rx1 + $rx2}]
    		    set ry2 [expr {$ry1 + $ry2}]    		    
    		}
    		
		foreach {pxl pxr pyl pyr} [my config -ipad] {break}
		set pxl [winfo fpixels $wcan $pxl]
		set pxr [winfo fpixels $wcan $pxr]
		set pwidth $pxr
		set pyl [winfo fpixels $wcan $pyl]
    		set pyr [winfo fpixels $wcan $pyr]
		set pheight $pyr
    		if {$tbut == "rect" } {
    		    set scalex [expr {$pwidth  / ($sx2 - $sx1 )}]
    		    set scaley [expr {$pheight / ($sy2 - $sy1 )}]
		} else {
    		    set scalex [expr {($rx2 - $rx1 - ($pxr + $pxl)) / ($sx2 - $sx1 )}]
    		    set scaley [expr {($ry2 - $ry1 - ($pyr + $pyl)) / ($sy2 - $sy1 )}]
		}
#puts "scalex=$scalex scaley=$scaley"
    		$wcan scale $isvg 0 0 $scalex $scaley
    		foreach {snx1 sny1 snx2 sny2} [$wcan bbox $isvg] {break}

    		$wcan move $isvg [expr {$rx1 - $snx1 + $pxl}] [expr {$ry1 - $sny1 + $pyl}]
    		if {$isvgold != "" } {
    		    $wcan delete $isvgold
    		}
    		$wcan raise $isvg $idr
    		$wcan raise $idor
    		if {$tbut == "rect" } {
		    foreach {ix1 iy1 ix2 iy2} [$wcan bbox $Options(-isvg)] {break}
    		} else {
    		    foreach {ix1 iy1 ix2 iy2} [$wcan bbox "$btag rect"] {break}
    		}
		if {$tbut == "square" || $tbut == "rect"} {
		    $wcan delete "$btag pimage"
		    if { [info exists idi] } {
			unset idi
		    }
		}
			if {$tbut != "square" && $tbut != "circle"} {
			    set x [expr {$ix2 + $pxl}]
			    set y [expr { ($ry1 + $ry2) / 2.0}]
			    set tanchor  "w"
			    switch $Options(-compound)  {
				left {
				    set x [expr {$ix2 + $pxl}]
				    foreach {x1 y1 x2 y2} [$wcan bbox $idr] {break}
				    set y [expr { ($y1 + $y2) / 2.0}]

				    set tanchor  "w"
				    set dy 0
				    set dx 0
				}
				right {
				    puts "right 1"
				
				}
				top {
#				    set x [expr {$xi2 + $pxl}]
				    set x [expr { ($rx1 + $rx2) / 2.0}]
#ВРЕМЕННО
#				    set y [expr { $iy2 + $pyl   }]
				    set y [expr { $iy2 + $pyl * 0  }]
				    set tanchor  "n"
				    set dx 0 
#			    set dy [expr {($yt2 - $yt1) / 2.0 - $pyr * 0 } ]
				}
				bottom {
				    puts "bottom 1"
				}
				none {
				    foreach {x1 y1 x2 y2} [$wcan bbox $idr] {break}
				    set x [expr { ($x1 + $x2) / 2.0}]
				    set y [expr { ($y1 + $y2) / 2.0}]
				    $wcan coords $idt "$x $y "
				    $wcan itemconfigure  $idt -textanchor c
				    $wcan raise $idt
#    				    $wcan raise $idt $idr
				}
			    }
#puts "Options(-compound)=$Options(-compound) X=$x Y=$y tanchor=$tanchor"
			    if {[info exist idt] && $Options(-text) != "" && $Options(-compound) != "none"} {
				::svgwidget::id2angleZero $wcan $idt
				$wcan itemconfigure  $idt -textanchor $tanchor
				$wcan coords $idt "$x $y "
				if {$Options(-rotate) != 0} {
				    ::svgwidget::idrotate2angle $wcan $idt $Options(-rotate)
				    foreach {xt1 yt1 xt2 yt2} [$wcan bbox $idt] {break}
				    ::svgwidget::id2angleZero $wcan $idt
				    set dx 0
				    set dy [expr {$iy2 + $pyl - $yt1}]
				    $wcan move $idt $dx $dy
				    ::svgwidget::idrotate2angle $wcan $idt $Options(-rotate)
				}
    				    $wcan raise $idt $idr
			    }
			}

    	    }
	    -state {
		switch $value {
		    normal -
		    disabled -
		    hidden {
			set  Options($option) $value
			if {[info exists idr]} {
#	   		 $wcan itemconfigure $idg -state $stat
			    $wcan itemconfigure $idor -state $value
			    $wcan itemconfigure $idr -state $value
			    $wcan itemconfigure $idt -state $value
			}
		    }
		    default {
			error "Bad state=$value"
		    }
		}
	    }
	    -width {
#puts "width fr=$fr"
		set valold [winfo fpixels $wcan $Options($option)]
		set  Options($option) $value
		set val [winfo fpixels $wcan $value]
		set strwidth [winfo fpixels $wcan $Options(-strokewidth)]
		if { $tbut == "frame"} {
		    if {[info exists idr]} {
    		set Options($option) $value
			foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
			set x2 [expr {$x1 + $val}]
			$wcan coords $idr "$x1 $y1 [expr {$x2 - $strwidth / 2}]  [expr {$y2 - $strwidth }]"
		    }
    		    continue
		} 
		if { $tbut == "rect" || $tbut == "round" || $tbut == "ellipse"} {
		    if {[info exists idr]} {
			foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
			set x2 [expr {$x1 + $val}]
			$wcan coords $idr "$x1 $y1 [expr {$x2 - $strwidth / 2}]  [expr {$y2 - $strwidth}]"
			if {$tbut == "ellipse"} {
			    set rx [expr {$val / 2.0}]
			    $wcan itemconfigure $idr -rx $rx
			}
			if { $tbut == "rect" && $Options(-isvg) != ""} {
    			    my config [list -isvg "$wcan $Options(-isvg)"]
			} else {
			    set x2 [expr {$x1 + $val / 2.0}]
			    foreach {x1 y1} [$wcan coords $idt] {break}
			    $wcan coords $idt "$x2 $y1"
			    ::svgwidget::idrotate2angle $wcan $idt $Options(-rotate)
			}
			$wcan itemconfigure $idt -text $Options(-text)
		    } else {
			if { $tbut == "rect" && $Options(-isvg) != ""} {
    			    my config [list -isvg "$wcan $Options(-isvg)"]
			}
		    }
		} elseif { $tbut == "square" ||  $tbut == "circle"} {
		    set  Options(-height) $Options($option)
		    if {[info exists idr]} {
			foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
			set x2 [expr {$x1 + $val}]
			set y2n [expr {$y1 + $val}]
			$wcan coords $idr "$x1 $y1 $x2 [expr {$y2n - $strwidth * 0}]"
			if {$tbut == "circle"} {
			    set rx [expr {$val  / 2.0}]
			    $wcan itemconfigure $idr -rx $rx
			}
			if { $tbut == "square" && $Options(-isvg) != ""} {
    			    my config [list -isvg "$wcan $Options(-isvg)"]
			}
			foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
			set x [expr {$x2 + $onemm2px}]
			set y [expr { ($y1 + $y2) / 2.0}]
			$wcan coords $idt "$x $y"
		    }
		} elseif { $tbut == "check" ||  $tbut == "radio"} {
		    set  Options(-height) $Options($option)
		    if {[info exists idr]} {
			foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
			set x2 [expr {$x1 + $val}]
			set y2n [expr {$y1 + $val}]
			$wcan coords $idr "$x1 $y1 $x2 [expr {$y2n - $strwidth * 0}]"
			if {$tbut == "radio"} {
			    set rx [expr {$val  / 2.0}]
			    $wcan itemconfigure $idr -rx $rx
			    set xr1 $x1
			    set yr1 $y1
			    set xr2 $x2
			    set yr2 [expr {$y2n - $strwidth * 0}]
			    set wrr [expr {$xr2 - $xr1}]
			    set hrr [expr {$yr2 - $yr1}]
			    $wcan coords $idm [expr {$xr1 + $wrr / 4}] [expr {$yr1 + $wrr / 4}] [expr {$xr2 - $wrr / 4}] [expr {$yr2 - $wrr / 4}]
			    $wcan itemconfigure $idm -rx [expr {$wrr / 4}] 
			}
			foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
			set x [expr {$x2 + $onemm2px}]
			set y [expr { ($y1 + $y2) / 2.0}]
			$wcan coords $idt "$x $y"
			if {$tbut == "check"} {
#Размер масштабирования
			    set scalexy [expr {$val / $valold}]
#puts "scalexy=$scalexy"
			    $wcan scale $idm 0 0 $scalexy $scalexy
			    foreach {rx1 ry1 rx2 ry2} [$wcan coords $idr] {break}
			    set rx2 [expr {$rx1 + $rx2}]
			    set ry2 [expr {$ry1 + $ry2}]
			    foreach {mx1 my1 mx2 my2} [$wcan bbox $idm] {break}

		    	    set dx [expr {(($rx2 + $rx1) - ($mx2 + $mx1)) / 2.0}]
			    set dy [expr {(($ry2 + $ry1) - ($my2 + $my1)) / 2.0}]
#puts "DX=$dx DY=$dy"
			    $wcan move $idm $dx $dy
			}			
		    }
		}
		if {[info exists idr] && [info exists idor]} {
			$wcan coords $idor [$wcan coords $idr]
			$wcan itemconfigure $idor -rx [$wcan itemcget $idr -rx]
		}
	    }
	    -height {
#puts "height fr=$fr"
		set valold [winfo fpixels $wcan $Options($option)]
		set  Options($option) $value
		set val [winfo fpixels $wcan $value]
		set strwidth [winfo fpixels $wcan $Options(-strokewidth)]
#Размер масштабирования
		if {$tbut == "frame"} {
		    if {[info exists idr]} {
			foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
			set y2 [expr {$y1 + $val}]
			$wcan coords $idr "$x1 $y1 [expr {$x2 - $strwidth / 2}]  [expr {$y2 - $strwidth}]"
		    }
		    continue
		} 
		set scalexy [expr {$val / $valold}]
		if { $tbut == "rect" || $tbut == "ellipse" ||  $tbut == "round" } {
		    if {[info exists idr]} {
			foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
			set y2 [expr {$y1 + $val}]
			$wcan coords $idr "$x1 $y1 [expr {$x2 - $strwidth / 2}]  [expr {$y2 - $strwidth}]"
			set y2 [expr {$y1 + $val / 2.0}]
			foreach {x1 y1} [$wcan coords $idt] {break}
			if { $tbut == "rect" && $Options(-isvg) != ""} {
    			    my config -isvg "$wcan $Options(-isvg)"
			} elseif { $tbut == "rect" && [info exists idi]} {
    			    my config -image "$Options(-image)"
			} else {
			    ::svgwidget::id2angleZero $wcan $idt
			    $wcan coords $idt "$x1 $y2"
			    ::svgwidget::idrotate2angle $wcan $idt $Options(-rotate)
			}
			if {$tbut == "ellipse"} {
			    set ry [expr {$val / 2.0}]
			    $wcan itemconfigure $idr -ry $ry
			}
			if {[info exists idt]} {
			    $wcan itemconfigure $idt -text $Options(-text)
			    ::svgwidget::idrotate2angle $wcan $idt $Options(-rotate)
			}
		    } else {
			if { $tbut == "rect" && $Options(-isvg) != ""} {
    			    my config -isvg "$wcan $Options(-isvg)"
			}
		    }
		} elseif { $tbut == "square" ||  $tbut == "circle"} {
		    set  Options(-width) $Options($option)
		    if {[info exists idr]} {
			foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
			set x2 [expr {$x1 + $val}]
			set y2n [expr {$y1 + $val}]
			$wcan coords $idr "$x1 $y1 $x2 [expr {$y2n - $strwidth * 1}]"
			if {$tbut == "circle"} {
			    set rx [expr {$val  / 2.0}]
			    $wcan itemconfigure $idr -rx $rx
			}
			if { $tbut == "square" && $Options(-isvg) != ""} {
    			    my config [list -isvg "$wcan $Options(-isvg)"]
			} 
			foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
			set x [expr {$x2 + $onemm2px}]
			set y [expr { ($y1 + $y2) / 2.0}]
			$wcan coords $idt "$x $y"
		    }
		} elseif { $tbut == "check" ||  $tbut == "radio"} {
		    set  Options(-width) $Options($option)
		    if {[info exists idr]} {
			foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
			set x2 [expr {$x1 + $val}]
			set y2n [expr {$y1 + $val}]
			$wcan coords $idr "$x1 $y1 $x2 [expr {$y2n - $strwidth}]"
			if {$tbut == "radio"} {
			    set rx [expr {$val  / 2.0}]
			    $wcan itemconfigure $idr -rx $rx
			    set xr1 $x1
			    set yr1 $y1
			    set xr2 $x2
			    set yr2 [expr {$y2n - $strwidth}]
			    set wrr [expr {$xr2 - $xr1}]
			    set hrr [expr {$yr2 - $yr1}]
			    $wcan coords $idm [expr {$xr1 + $wrr / 4}] [expr {$yr1 + $wrr / 4}] [expr {$xr2 - $wrr / 4}] [expr {$yr2 - $wrr / 4}]
			    $wcan itemconfigure $idm -rx [expr {$wrr / 4}] 
			}
			foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
			set x [expr {$x2 + $onemm2px}]
			set y [expr { ($y1 + $y2) / 2.0}]
			$wcan coords $idt "$x $y"
			if {$tbut == "check"} {
			    $wcan scale $idm 0 0 $scalexy $scalexy
			    foreach {rx1 ry1 rx2 ry2} [$wcan bbox $idr] {break}
			    foreach {mx1 my1 mx2 my2} [$wcan bbox $idm] {break}

			    set dx [expr {(($rx2 + $rx1) - ($mx2 + $mx1)) / 2.0}]
			    set dy [expr {(($ry2 + $ry1) - ($my2 + $my1)) / 2.0}]
#puts "DX=$dx DY=$dy"
			    $wcan move $idm $dx $dy
			}
		    }
		}
		if {[info exists idr] && [info exists idor]} {
			$wcan coords $idor [$wcan coords $idr]
			$wcan itemconfigure $idor -rx [$wcan itemcget $idr -rx]
		}
	    }
	    -deselect {
		if { $tbut != "check" && $tbut != "radio"} {
    		    error "Bad option $option for cbutton type=$tbut" 
		    return
		}
	    }
	    -select {
		if { $tbut != "check" && $tbut != "radio"} {
    		    error "Bad option $option for cbutton type=$tbut" 
		    return
		}
	    }
	    -variable {
		set ind1 [string first "(" $value]
		set ind2 [string last ")" $value]
		if {$ind1 == -1 || $ind2 == -1 || $ind1 > $ind2} {
		    global $value
		} else {
		    global [string range $value 0 $ind1-1]
		}
		if {[trace info variable $value] == ""} {
		    trace variable $value w ::svgwidget::trace_rb
		}

    		set Options($option) $value
    		if {![info exists $value]} {
    		    set $value 0
    		}
#puts "VALUE ($value) -variable: [subst $$value]"
	    }
	    -tintcolor -
	    -tintamount -
	    -value -
	    -command -
	    -strokeenter -
	    -strokepress -
    	    -fillenter -
    	    -fillok -
    	    -fillpress {
    		set Options($option) $value
    	    }
    	    -fillnormal {
    		set Options($option) $value
		if {[info exists idr]} {
		    if { $tbut != "check" && $tbut != "radio"} {
			$wcan itemconfigure $idr -fill $value
    		    }
		}
    	    }
    	    -strokenormal {
    		set Options($option) $value
		if {[info exists idr]} {
		    if { $tbut != "check" && $tbut != "radio"} {
			$wcan itemconfigure $idr -stroke $value
    		    }
		}
    	    }
    	    -strokeopacity -
    	    -fillopacity {
    		set Options($option) $value
		if {[info exists idr]} {
		    if { $tbut != "check" && $tbut != "radio"} {
			$wcan itemconfigure $idr $option $value
    		    }
		}
    	    }
	    -strokewidth {
    		set Options($option) $value
		if {[info exists idr]} {
		    my changestrwidth
		}
    	    }
	    -ry -
	    -rx {
		if {$tbut == "round" || $tbut == "rect" || $tbut == "frame"} {
		    set Options($option) $value
		    if {[info exists idr]} {
			$wcan itemconfigure $idr $option [winfo fpixels $wcan $value]
			$wcan itemconfigure $idor $option [winfo fpixels $wcan $value]
		    }
		}
	    }
    	    -fill {
		if {[info exists idr]} {
		    $wcan itemconfigure $idr $option $value
		}
	    }        
	    -textfill -
    	    -textstrokeopacity -
	    -textfillopacity -
	    -textstroke -
	    -textstrokewidth {
		if {$tbut != "frame"} {		
    		    set Options($option) $value
		    if {[info exists idt]} {
			set opt [string range $option 5 end]
#puts "option=$option opt=$opt"
			$wcan itemconfigure $idt "-$opt" $value
    			$wcan raise $idt $idr
		    } 
		}
	    }
	    -fontslant -
	    -fontweight -
	    -fontfamily -
	    -text {
		if {$tbut != "frame"} {		
    		    set Options($option) $value
		    if {[info exists idt]} {
			foreach {xe0 ye0 xe1 ye1} [$wcan bbox $idt] {break}
			$wcan itemconfigure $idt $option $value
    			$wcan raise $idt $idr
			set xx [winfo pixels $wcan $Options(-width)]
			if {[$wcan bbox $idt] == ""} {
			    continue
			}
			foreach {xt0 yt0 xt1 yt1} [$wcan bbox $idt] { break}
		    
			if {$fr && $tbut != "round" && $tbut != "rect" && $tbut != "ellipse"} {
			    set xx [expr {$xx + ($xt1 - $xt0)}]
			    $wcan configure -width $xx
			} else {
			    set xx1 [expr {$xt1 - $xt0}]
			    if {$xx1 > $xx}  {
				set del [expr {$xx1 - ($xe1 - $xe0)}]
				my config -width [expr {$xx + $del}]
			    }
			}
		    } 
		}
	    }
	    -fontsize {
		if {$tbut != "frame"} {		
    		    set Options($option) $value
		    if {[info exists idt]} {
			$wcan itemconfigure $idt $option [winfo fpixels $wcan $value]
			if { $tbut == "square" ||  $tbut == "circle" || $tbut == "check" ||  $tbut == "radio"} {
			    foreach {x1 y1 x2 y2} [$wcan bbox $canvasb] {break}
#puts "FONTSIZE canvasb=$canvasb x1=\"$x1\" y1=\"$y1\" x2=\"$x2\" y2=\"$y2\""
			    $wcan configure -width [expr {$x2 + $x1}] -height [expr {$y2 + $y1}]
			}
		    } 
		}
	    }
	    -stroke {
    		set Options($option) $value
    		set Options(-strokenormal) $value
		if {[info exists idr]} {
		    $wcan itemconfigure $idr $option $value
		}
	    }
	    -vlast {
		if {$tbut == "check"} {
    		    set Options($option) $value
    		}
	    }
	    press {
		;
	    }
    	    default {
    		puts "cbutton: Bad option $option for type=$tbut"
    	    }
        }
    }
  }

  destructor {
    if {[winfo exists $wcan]} { 

	$wcan bind $idor <Enter> {}
	$wcan bind $idor <Leave> {}
	$wcan bind $idor <ButtonPress-1> {}
	$wcan bind $idor <ButtonRelease-1> {}
	$wcan bind $idr <Enter> {}
	$wcan bind $idr <Leave> {}
	$wcan bind $idr <ButtonPress-1> {}
	$wcan bind $idr <ButtonRelease-1> {}
	$wcan bind $idt <Enter> {}
	$wcan bind $idt <Leave> {}
	$wcan bind $idt <ButtonPress-1> {}
        $wcan bind $idt <ButtonRelease-1> {}
        $wcan delete $idt $idr $idor
	if { $tbut == "check" || $tbut == "radio"} {
	    $wcan bind $idm <Enter> {}
    	    $wcan bind $idm <Leave> {}
	    $wcan bind $idm <ButtonPress-1> {}
	    $wcan bind $idm <ButtonRelease-1> {}
	    $wcan delete $idm
	}
	if {[info exists Options(-isvg)]} {
	    set isvg $Options(-isvg)
	    $wcan bind $isvg <Enter> {}
    	    $wcan bind $isvg <Leave> {}
	    $wcan bind $isvg <ButtonPress-1> {}
	    $wcan bind $isvg <ButtonRelease-1> {}
	    $wcan delete $isvg
	}
	if {$fr} {
    	    bind $wcan  <Configure> {}
	    destroy $wcan
	}
    }
  }
}

oo::class create ibutton {
#iidt - текст
#idr - прямоугольник вокруг картинки
#idor - прозрачный прямоугольник вокруг картинки
#idi - картинка
#idh - подсказка
  variable wcan
  variable idr
  variable idor
  variable idt
  variable idi
  variable idh
  variable nexttag
  variable onemm2px
  variable canvasb
  variable btag
  variable fr
  variable wclass
    variable Options
  variable wlast
  variable hlast
  
  constructor {w args} {
    catch {unset Options}
    set x0 0
    set y0 0
    set idor -1
    set nexttag 0
    set wclass "ibutton"
    set wcan $w
#Для стандартного прямоуголника - 25ь
#    set  Options(-width) 25m
    set Options(-relcom) 0
    set Options(-strokelinejoin) miter
    set Options(-state) "normal"
    set Options(-displaymenu) "release"
    set Options(-width) 7m
    set Options(-height) 7m
    set Options(-pad) "0 0 0 0"
    set Options(-strokewidth) 1
    set fr 0
    set canvasb "canvasb"
    set ind [lsearch $args "-strokewidth"]
    if {$ind > -1} {
	incr ind
	set Options(-strokewidth) [lindex $args $ind]
    }
    set ind [lsearch $args "-width"]
    if {$ind > -1} {
	incr ind
	set Options(-width) [lindex $args $ind]
    }
    set ind [lsearch $args "-height"]
    if {$ind > -1} {
	incr ind
	set Options(-height) [lindex $args $ind]
    }
    if {![winfo exists $wcan]} {
	tkp::canvas $wcan -bd 0 -highlightthickness 0
	set strwidth [winfo fpixels $wcan $Options(-strokewidth)]
	set cwidth [winfo fpixels $wcan $Options(-width)]
	set cheight [winfo fpixels $wcan $Options(-height)] 
	$wcan configure -width [expr {$strwidth * 2.0 + $cwidth}] -height [expr {$strwidth * 2.0 + $cheight}]
	set clw [winfo class [winfo parent $wcan]]
	if { [catch {[winfo parent $wcan] cget -background} xcolor] == 0 } {
    	    $wcan configure -background $xcolor
        } else {
	    set stylepar [[winfo parent $wcan] cget -style]
	    if {$stylepar == ""} {
		set bgc [ttk::style configure $clw -background]
	    } else {
		set bgc [ttk::style configure $stylepar -background]
	    }
	    if {$bgc != ""} {
    		$wcan configure -background $bgc
	    }
        }
        set x0 [expr {$strwidth / 2}]
        set y0 [expr {$strwidth / 2}]

        set fr 1
        append canvasb "fr"
    } else {
	set ind [lsearch $args "-x"]
	if {$ind > -1} {
	    incr ind
	    set x0 [lindex $args $ind]
	}
	set ind [lsearch $args "-y"]
	if {$ind > -1} {
	    incr ind
	    set y0 [lindex $args $ind]
	}
    }
    array set font [font actual systemSystemFont]
    set onemm2px [winfo pixels $wcan 1m]
    set Options(-fontfamily) $font(-family)
    set tremm2px [winfo fpixels $w 3m]
    set Options(-fontsize) $tremm2px
#puts "costructor: w=\"$w\""
    set Options(-tintamount) 0.0
#    set Options(-tintcolor) skyblue
    set Options(-tintcolor) chocolate
#puts "[self] mcoords x0=$x0 y0=$y0"
    set x0 [winfo fpixels $wcan $x0]
    set y0 [winfo fpixels $wcan $y0]
#puts "[self] 1 mcoords x0=$x0 y0=$y0"

    set defx [winfo pixels $w 5m]
    set defy [winfo pixels $w 5m]
    set defrx [winfo pixels $w 1m]
    set twomm2px [winfo pixels $w 2m]
    set  Options(-rx) 0
    set  Options(-ry) 0
    set  Options(-image) "::svgwidget::tpblank"
    set  Options(-text) "ibutton"
    set  Options(-help) ""

    set x1 [winfo fpixels $wcan $x0]
    set y1 [winfo fpixels $wcan $y0]

    set Options(press) 0
    set Options(-fillenter) skyblue

    set Options(-fillnormal) white
#    set Options(-fillnormal) "#e9eeef"

    set Options(-fillpress) green

#    set Options(-stroke) gray40
    set Options(-stroke) cyan
#    set Options(-stroke) "#e9eeef"

    set Options(-command) {}

#puts "costructor 0: Options(-width)=$Options(-width) Options(-height)=$Options(-height)"
    my config $args
    foreach {pxl pxr pyl pyr} $Options(-pad) {break}
    set pxl [winfo fpixels $wcan $pxl]
    set pxr [winfo fpixels $wcan $pxr]
    set pyl [winfo fpixels $wcan $pyl]
    set pyr [winfo fpixels $wcan $pyr]

    
    set sw [winfo fpixels $wcan $Options(-strokewidth)]
    set wr [expr {[winfo fpixels $wcan $Options(-width)] - 0 * $sw}]
    set hr [expr {[winfo fpixels $wcan $Options(-height)] - 0 * $sw}]

    set x2 [expr {$x1 + $wr }]
    set y2 [expr {$y1 + $hr }]

    set idr [$wcan create prect $x1 $y1 $x2 $y2 -strokelinecap butt -stroke {} -strokewidth 0]
    my changestrwidth
    foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
    set btag "canvasb[string range [self] [string first Obj [self]] end]"
    $wcan itemconfigure $idr -fill $Options(-fillnormal) -strokelinejoin $Options(-strokelinejoin) -stroke $Options(-stroke)  -rx $Options(-rx) -tags [list Rectangle obj $canvasb $btag [linsert $btag end rect] utag$idr] -fill {}

    set idr "utag$idr"
#Метка кнопки
    set x [expr {$x2 + $onemm2px}]
    set y [expr { ($y1 + $y2) / 2.0}]
    set anc w 

    set imageOrig $Options(-image)
    set idi [$wcan create pimage [expr {$x1 + $pxl }] [expr {$y1 + $pyl }] -image "::svgwidget::tpblank" -tintcolor $Options(-tintcolor) -tintamount 0.0  \
	-width [expr {$wr - ($pxl + $pxr) }] -height [expr {$hr - ($pyl + $pyr) }] -anchor nw]

    $wcan itemconfigure $idi -tags [list image obj canvasi $btag [linsert $btag end image] utag$idi]
    set idi "utag$idi"

    set ibox [$wcan bbox $idi]
#Если не менять размеры и координаты прямоугольника, то закомментировать
#    $wcan coords $idr $ibox
    
    foreach {x1 y1 x2 y2} $ibox {break}
    set x [expr {$x2 + $onemm2px}]
    set y [expr { ($y1 + $y2) / 2.0}]

    
    set idt [$w create ptext $x $y -textanchor $anc -text $Options(-text) -fontfamily $Options(-fontfamily) -fontsize [winfo fpixels $wcan $Options(-fontsize)]]
    $wcan itemconfigure $idt -tags [list text obj $canvasb $btag [linsert $btag end text] utag$idt]
    set idt utag$idt

    eval "$wcan bind $idt <Enter> {[self] enter}"
    eval "$wcan bind $idt <Leave> {[self] leave}"
    eval "$wcan bind $idt <ButtonPress-1> {[self] press}"
    eval "$wcan bind $idt <ButtonRelease-1> {[self] release %X %Y}"
    eval "$wcan bind $idr <Enter> {[self] enter}"
    eval "$wcan bind $idr <Leave> {[self] leave}"
    eval "$wcan bind $idi <Enter> {[self] enter}"
    eval "$wcan bind $idi <Leave> {[self] leave}"
    eval "$wcan bind $idr <ButtonPress-1> {[self] press}"
    eval "$wcan bind $idr <ButtonRelease-1> {[self] release %X %Y}"
    eval "$wcan bind $idi <ButtonPress-1> {[self] press}"
    eval "$wcan bind $idi <ButtonRelease-1> {[self] release %X %Y}"
    $wcan itemconfigure $idr -fill $Options(-fillnormal) -stroke $Options(-stroke) -rx $Options(-rx)
    if {[info exists Options(-ry)]} {
	if {$Options(-ry) == -1} {
	    set Options(-ry) $defry
	}
	$wcan itemconfigure $idr -rx $Options(-ry)
    }
    if {[info exists Options(-text)]} {
	$wcan itemconfigure $idt -text $Options(-text)
    }

#    puts "[self]"

    my config [array get Options]
    if {$fr == 1} {
	set strwidth [winfo fpixels $wcan $Options(-strokewidth)]
	foreach {x1 y1 x2 y2} [$wcan bbox $btag] {break}
	set wlast [expr {$x2 + $x1 * 1.5}]
	set hlast [expr {$y2 + $y1 * 1.5}]
    }
    if {$fr == 1} {
	eval "bind $wcan  <Configure> {[self] resize %w %h 0}"
    }
    set $Options(-image) $imageOrig
    my config -image $Options(-image)
  }

  method canvas {} {
    return $wcan
  }

  method type {} {
    return "ibutton"
  }

  method move {dx dy} {
	if {$fr == 1} {
	    return $btag
	}
#puts "iutton move btag=$btag"
	$wcan move $btag  $dx $dy
	return $btag
  }

  method mcoords {} {
#Добавляем 0.5 для сохранения позиции???
    set crds {}
    foreach {x0 y0 x1 y1} [$wcan coords $idr] {
#Почему-то onemm2px имеет неверное значение!!!!
	set onemm2px [winfo pixels $wcan 1m]

	lappend crds "[expr {int(($x0 + 0.5) / [winfo fpixels $wcan 1m])}]m"
	lappend crds "[expr {int(($y0 + 0.5) / [winfo fpixels $wcan 1m])}]m"
    }
#puts "[self] $crds"
    return $crds
  }

  method options {} {
    return [array get Options]
  }
 
  method enter {} {
    variable Options
    if {[info exists idh]} {
	$wcan delete $idh
	unset idh
    }
    if {[my config -state] == "disabled"} {
	return
    }
    if {[info exist Options(-menu)] && $Options(-menu) != ""} {
	if {$Options(-displaymenu) != "enter"} {
	    return
	}
	foreach {xm ym } [my showmenu] {break}
	puts "Method ibutton enter-> showmenu: Кнопка=[self] xm=$xm ym=$ym Options(-menu)=$Options(-menu)"
    }
    if {$Options(-fillenter) == "##"} {
	    return
    }
    set sw [winfo fpixels $wcan $Options(-strokewidth)]
#    $wcan itemconfigure $idr -strokewidth [expr {$sw + 1}]


    $wcan itemconfigure $idr -fill $Options(-fillenter) -stroke $Options(-stroke)
    if {[info exists idi]} {
	$wcan itemconfigure $idi -tintamount 0.5
    }
#    $Options(-tintamount)
    if {$Options(-help) != "" && $fr == 0} {
	    set twomm2px [winfo pixels $wcan 2m]
	    foreach {x0r y0r x1r y1r} [$wcan coords $idr] {break}
	    set idh [$wcan create ptext $x0r [expr {$y0r - $twomm2px * 2}] -textanchor nw -text $Options(-help)]
	    update
    }
  }
  method leave {} {
    variable Options
    if {[info exists idh]} {
	$wcan delete $idh
	update
	unset idh
    }
    if {[my config -state] == "disabled"} {
	return
    }
    if {!$Options(press)} {
	set sw [winfo fpixels $wcan $Options(-strokewidth)]
	$wcan itemconfigure $idr -stroke $Options(-stroke)  -fill $Options(-fillnormal)
	my changestrwidth $sw 
    }
#    set Options(press) 0
    if {[info exists idi]} {
	$wcan itemconfigure $idi -tintamount 0.0
    }
  }
  method resize {wx hy {from 1}} {
    set onemm2px [winfo pixels $wcan 1m]
#puts "cbutton resize: fr=$fr wx=$wx hy=$hy"
    if {$fr == 0} {
	return
    }
#puts "RESIZE WIDTH=[winfo width $wcan] wx=$wx hy=$hy -width=$Options(-width)"
    set wxc [winfo fpixels $wcan $wx]
    set hyc [winfo fpixels $wcan $hy]
    if {$wxc < $onemm2px || $hyc < $onemm2px} {
	return
    }

    foreach {x1 y1 x2 y2} [$wcan bbox "$btag text"] {break}
    set strwidth [winfo fpixels $wcan [my config -strokewidth]]
    set wold [expr {$wxc / $wlast}]
#puts "WXC=$wxc WLAST=$wlast HYC=$hyc"
    set wlast $wxc
    set nfont [expr {[winfo fpixels $wcan $Options(-fontsize)] * $wold}]

    foreach {x1 y1 x2 y2} [$wcan bbox "$btag rect"] {break}
    foreach {x1t y1t x2t y2t} [$wcan bbox "$btag text"] {break}
    if {![info exists x1t]} {
	foreach {x1t y1t x2t y2t} "0 0 0 0" {break}
    }
    set yold [expr {$hyc / $hlast}] 
    set hlast $hyc
    set nwidth [expr {[winfo fpixels $wcan $wx] - ($x2t - $x1t)}]

    set nheight [expr {[winfo fpixels $wcan $hy] - $strwidth * 1 }]

#puts "my config -height $nheight -width $nwidth"
    my config -width $nwidth
    my config -height $nheight -width [my config -width]
  }

  method press {} {
    variable Options
    if {[my config -state] == "disabled"} {
	return
    }
    set Options(press) 1
    if {$Options(-fillpress) == "##"} {
	    return
    }
    $wcan itemconfigure $idr -fill $Options(-fillpress)
  }
  method release {x y} {
    variable Options
    if {[my config -state] == "disabled" } {
	return
    }
    if {[info exist Options(-menu)] && $Options(-menu) != ""} {
	if {$Options(-displaymenu) != "release"} {
	    return
	}
	foreach {xm ym } [my showmenu] {break}
	puts "Method ibutton release-> showmenu: Кнопка=[self] xm=$xm ym=$ym Options(-menu)=$Options(-menu)"
    }

#puts "RELEASE ibutton wcan=$wcan  X=$x Y=$y"
    set tfr 1
    if {$fr && $Options(-relcom) == 0 } {
	set x1 [winfo rootx $wcan]
	set x2 [expr {$x1 + [winfo width $wcan]}] 
	set y1 [winfo rooty $wcan]
	set y2 [expr {$y1 + [winfo height $wcan]}] 
    
	if {$x < $x1 || $x > $x2 || $y < $y1 || $y > $y2} {
	    set tfr 0
	    set Options(press) 0
	}
    }

    if {$Options(press) && $tfr} {
	set Options(press) 0
	if {$Options(-fillenter) != "##"} {
	    $wcan itemconfigure $idr -fill $Options(-fillenter)
	}
	if {$Options(-command) != ""} {
	    set cmd [subst "set x [set x];set y [set y];"]
	    append cmd [my config -command]
	    after 0 eval $cmd
	}
    } else {
	$wcan itemconfigure $idr -fill $Options(-fillnormal)
    }
  }

  method invoke {} {
    set xi [expr {[winfo rootx $wcan] + 2}]
    set yi [expr {[winfo rooty $wcan] + 2}]
    my enter
    my press
    my release $xi $yi 
    my leave

	my press
	my release 0 0
  }
  method config args {
    set svgtype [list circle ellipse group path  pline polyline ppolygon prect ptext]
    variable Options
    if {[llength $args] == 1} {
	set args [lindex "$args" 0]
    }
    if {[llength $args] == 0} {
	return [array get Options]
    }

    if {[llength $args] % 2 != 0} {
#Чтение значения аттрибута
	if {[llength $args] == 1} {
#puts "config $args : $Options($args)"
	    return $Options($args)
	}
#puts "Error args length: $args"
      error "use is: <object> config ?-option value?...\nargs=$args" 
    }
    
    foreach {option value} $args {
        switch $option {
	    -background -
	    -bg {
		if {$fr} {
		    set  Options($option) $value
		    $wcan configure -background $value
		}
	    }
    	    -menu {
		    set  Options($option) $value
    	    }
    	    -displaymenu {
    		if {[lsearch [list "release" "enter" ] $value] == -1} {
    		    error "Error for ibutton displaymenu ($value): -displaymenu \[ release | enter \]"
		    continue
    		}
		set  Options($option) $value
    	    }
    	    -x -
    	    -y 	{
    		    continue
    		}
    	    -relcom {
    		if {$value == 0 || $value == 1} {
		    set  Options($option) $value
		}
    	    }
	    -strokelinejoin {
    		set Options($option) $value
		if {[info exists idr]} {
			$wcan itemconfigure $idr $option $value
		}
	    }
	    -tintcolor -
	    -tintamount {
    		set Options($option) $value
		if {[info exists idi]} {
			$wcan itemconfigure $idi $option $value
		}
    	    }
	    -command -
	    -stroke -
    	    -fillenter -
    	    -fillpress -
    	    -help -
	    -tintcolor1 -
	    -tintamount1 -
    	    -fillopacity -
    	    -fillnormal {
    		set Options($option) $value
    	    }
	    -strokewidth {
    		set Options($option) $value
		if {[info exists idr]} {
		    my changestrwidth [winfo fpixels $wcan $value]
		}
    	    }
	    -ry -
	    -rx {
		if {$value == -2} {
#Какой-то анахронизм
    		    set Options($option) $value
		}
		if {[info exists idr]} {
		    $wcan itemconfigure $idr $option [winfo fpixels $wcan $value]
		}
	    }        
    	    -fill {
		if {[info exists idr]} {
		    $wcan itemconfigure $idr $option $value
		}
	    }        
	    -fontfamily -
	    -text {
    		set Options($option) $value
		if {[info exists idt]} {
		    $wcan itemconfigure $idt $option $value
		    if {$fr} {
			foreach {x1 y1 x2 y2} [$wcan bbox $btag] {break}
			$wcan configure -width [expr {$x2 + $x1}] -height [expr {$y2 + $y1}]
		    }
		} 
	    }        
	    -fontsize {
    		set Options($option) $value
		if {[info exists idt]} {
		    $wcan itemconfigure $idt $option [winfo fpixels $wcan $value]
		    if {$fr == 1} {
			foreach {x1 y1 x2 y2} [$wcan bbox $btag] {break}
#			$wcan configure -width [expr {$x2 + $x1}] -height [expr {$y2 + $y1}]
		    }
		} 
	    }
	    -state {
		switch $value {
		    normal -
		    disabled -
		    hidden {
			set  Options($option) $value
			if {[info exists idr]} {
			    if {$value ==  "normal"} {
				$wcan itemconfigure $idor -state $value
				$wcan itemconfigure $idr -state $value
				$wcan itemconfigure $idt -state $value
				$wcan itemconfigure $idi -state $value
				$wcan itemconfigure $idi -tintamount 0 -tintcolor $Options(-tintcolor)
			    } elseif {$value ==  "disabled"} {
				[my canvas] itemconfigure $idi -tintamount 1.0 
				$wcan itemconfigure $idor -state $value
				$wcan itemconfigure $idr -state $value
				$wcan itemconfigure $idt -state $value
				$wcan itemconfigure $idi -state $value
			    }
			}
		    }
		    default {
			error "Bad state=$value"
		    }
		}
	    }
	    -isvg -
	    -image {
#puts "IMAGE START: value=$value"
    		if {$value == ""} {
		    set value "::svgwidget::tpblank"
    		}
		set itype [catch {image type $value}]
		if {$itype == 0} {
    		    set Options($option) $value
    		    if {[info exists Options(-isvg)]} {
			$wcan delete $Options(-isvg)
			catch {unset Options(-isvg)}
    		    }
		    if {[info exists idi]} {
#Посчитать с учётом -ipad
			set w [image width $value]
			set h [image height $value]
			$wcan itemconfigure $idi $option $value -srcregion [list 0 0 $w $h] -state normal
			set pd [my config -pad]
			my config -pad "$pd"
		    }
#puts "IMAGE START: value=$$value END"
		    continue 
		}
#Проверяем, что это картинка SVG
		if {[llength $value] != 2} {
    		    error "for svg image ($value): -image \"<canvas> <tagORidItem>\""
		}
		if {![info exists idr]} {
    		    puts "-isvg IDR NOT Options(-isvg) $value"
    		    set Options($option) $value
		    continue
		}
		foreach {canv item} $value {break}
		set value [my copyItem $canv $item 0 0]
		
    		set itype [$wcan type $value]
    		if {[lsearch $svgtype $itype] == -1} {
			error "ibutton: Bad svg image=$itype, value=$value"
    		}
###########
    		set isvgold ""
    		if {[info exists Options(-isvg)]} {
    		    set isvgold $Options(-isvg)
    		    $wcan delete $isvgold 
    		}
		set  Options(-isvg) $value
    		set isvg $Options(-isvg)
		$wcan itemconfigure $isvg -tags [list isvg obj $canvasb $btag [linsert $btag end isvg]]
		
		my config -pad "$Options(-pad)"
		if {$idor > 0} {
		    $wcan delete $idor
		}
#Плюха в винде: тодщина строки в svg и обрамления вместо нуля остается фактически равной одному, поэтому далается пустая заливка
		set idor [$wcan create prect [$wcan bbox $value] -strokewidth 0 -stroke {} -fillopacity 0 -strokeopacity 0 -fill red -tags [list isvg obj $canvasb $btag [linsert $btag end isvg]]]
		eval "$wcan bind $idor <Enter> {[self] enter}"
		eval "$wcan bind $idor <Leave> {[self] leave}"
		eval "$wcan bind $idor <ButtonPress-1> {[self] press}"
		eval "$wcan bind $idor <ButtonRelease-1> {[self] release %X %Y}"

    		$wcan itemconfigure $idi -state hidden
    		$wcan raise $isvg $idr
    		$wcan raise $idor
#puts "IMAGE: -image END"
	    }
	    -pad {
		set lpad [llength $value]
		set padold $Options(-pad)
# 1 - Отступ везде одинаков - сверху, снизу, слева, справа
# 2 - Отступ по x слева и справа первый параметр, отступ - сверху и снизу второй параметр
# 3 - Отступ по x слева и справа первый и второй параметр, отступ - сверху и снизу третий параметр
# 4 - Отступ по x слева и справа первый и второй параметр, отступ - сверху и снизу третий и четвертый параметры
		switch $lpad {
		    1 {
			set Options(-pad) [list $value $value $value $value]
		    }
		    2 {
			foreach {l1 l2} $value {break}
			set Options(-pad) [list $l1 $l1 $l2 $l2]
		    }
		    3 {
			foreach {l1 l2 l3} $value {break}
			set Options(-pad) [list $l1 $l2 $l3 $l3]
		    }
		    4 {
			set Options(-pad) $value
		    }
		    default {
    			puts "Bad value option -pad: $option=$value"
    			continue
		    }
		}
		if {[info exists idi]} {
		    if {[info exists Options(-isvg)]} {
#puts "-pad: Options(-isvg)=$Options(-isvg) pad=Options(-pad) idr=$idr"
			set strwidth [winfo fpixels $wcan $Options(-strokewidth)]
#НОВОЕ
    			set isvg $Options(-isvg)
#puts "ibutton: -isvg ok isvg=$isvg idr=$idr"
    			foreach {sx1 sy1 sx2 sy2} [$wcan bbox $isvg] {break}
    			foreach {rx1 ry1 rx2 ry2} [$wcan bbox $idr] {break}
    			set rx2 [expr {$rx1 + $rx2}]
    			set ry2 [expr {$ry1 + $ry2}]

			foreach {pxl pxr pyl pyr} $Options(-pad) {break}
			set pxl [winfo fpixels $wcan $pxl]
			set pxr [winfo fpixels $wcan $pxr]
			set pyl [winfo fpixels $wcan $pyl]
    			set pyr [winfo fpixels $wcan $pyr]

    			set scalex [expr {($rx2 - $rx1 - ($pxr + $pxl) - $strwidth * 0 ) / ($sx2 - $sx1 + $strwidth * 1)}]
    			set scaley [expr {($ry2 - $ry1 - ($pyr + $pyl) - $strwidth * 0 ) / ($sy2 - $sy1 + $strwidth * 0)}]

    			$wcan scale $isvg 0 0 $scalex $scaley

    			foreach {snx1 sny1 snx2 sny2} [$wcan bbox $isvg] {break}

    			$wcan move $isvg [expr {$rx1 - $snx1 + $pxl + $strwidth * 1 * 0 }] [expr {$ry1 - $sny1 + $pyl + $strwidth * 1 * 0 }]
#puts "-pad: Options(-isvg)=$Options(-isvg) pad=Options(-pad) idr=$idr END"

		    } else {
#Старое pad
			foreach {opxl opxr opyl opyr} $padold {break}
			set opxl [winfo fpixels $wcan $opxl]
			set opxr [winfo fpixels $wcan $opxr]
			set opyl [winfo fpixels $wcan $opyl]
			set opyr [winfo fpixels $wcan $opyr]
			set wim [$wcan itemcget $idi -width]
			set him [$wcan itemcget $idi -height]
			set wim [expr {$wim + $opxl + $opxr}]
			set him [expr {$him + $opyl + $opyr}]

####################
			foreach {x1 y1} [$wcan coords $idi] {break}
			foreach {pxl pxr pyl pyr} $Options(-pad) {break}
			set pxl [winfo fpixels $wcan $pxl]
			set pxr [winfo fpixels $wcan $pxr]
			set pyl [winfo fpixels $wcan $pyl]
			set pyr [winfo fpixels $wcan $pyr]
			$wcan coords $idi [expr {$x1 + $pxl - $opxl}] [expr {$y1 + $pyl - $opyl}]
			$wcan itemconfigure $idi -width [expr {$wim - ($pxl + $pxr)}]
			$wcan itemconfigure $idi -height [expr {$him - ($pyl + $pyr)}]
    		    }
		}

	    }
	    -width {
    		set Options($option) $value
		set val [winfo fpixels $wcan $value]
		set strwidth [winfo fpixels $wcan $Options(-strokewidth)]
		if {[info exists idi]} {
		    foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
		    set x2 [expr {$x1 + $val - $strwidth * 2}]
		    $wcan coords $idr "$x1 $y1 $x2 $y2"
    		    if {[info exists Options(-isvg)]} {
    			set old $Options(-isvg)
    			my config -image "$wcan $Options(-isvg)"
    			$wcan delete $old
    		    } else {
################### с учётом -pad #############################
			foreach {pxl pxr pyl pyr} $Options(-pad) {break}
			set pxl [winfo fpixels $wcan $pxl]
			set pxr [winfo fpixels $wcan $pxr]
			set pyl [winfo fpixels $wcan $pyl]
			set pyr [winfo fpixels $wcan $pyr]
			$wcan itemconfigure $idi $option [expr {$val - ($pxl + $pxr)}]
			my config -pad $Options(-pad)
		    }
		    set x [expr {$x2 + $onemm2px}]
		    set y [expr { ($y1 + $y2) / 2.0}]
		    $wcan coords $idt "$x $y"
		}
	    }
	    -height {
    		set Options($option) $value
		set val [winfo fpixels $wcan $value]
		set strwidth [winfo fpixels $wcan $Options(-strokewidth)]
		if {[info exists idi]} {
		    foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
		    set y2 [expr {$y1 + $val - $strwidth}]
		    $wcan coords $idr "$x1 $y1 $x2 $y2"
    		    if {[info exists Options(-isvg)]} {
    			set old $Options(-isvg)
    			my config [list -image "$wcan $Options(-isvg)"]
    			$wcan delete $old
    		    } else {
################### с учётом -pad #############################
			foreach {pxl pxr pyl pyr} $Options(-pad) {break}
			set pxl [winfo fpixels $wcan $pxl]
			set pxr [winfo fpixels $wcan $pxr]
			set pyl [winfo fpixels $wcan $pyl]
			set pyr [winfo fpixels $wcan $pyr]
			$wcan itemconfigure $idi $option [expr {$val - ($pyl + $pyr)}]
			my config -pad $Options(-pad)
		    }
		    foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
		    set x [expr {$x2 + $onemm2px}]
		    set y [expr { ($y1 + $y2) / 2.0}]
		    $wcan coords $idt "$x $y"
		}
	    }
	    press {
		;
	    }
    	    default {
    		puts "ibutton:Bad option $option"
    	    }
        }
    }
  }

  destructor {
    if {[winfo exists $wcan]} { 
	$wcan bind $idr <Enter> {}
	$wcan bind $idr <Leave> {}
	$wcan bind $idt <Enter> {}
	$wcan bind $idt <Leave> {}
	$wcan bind $idi <Enter> {}
	$wcan bind $idi <Leave> {}
	$wcan bind $idr <ButtonPress-1> {}
	$wcan bind $idr <ButtonRelease-1> {}
	$wcan bind $idt <ButtonPress-1> {}
	$wcan bind $idt <ButtonRelease-1> {}
	$wcan bind $idi <ButtonPress-1> {}
	$wcan bind $idi <ButtonRelease-1> {}
     
	catch {$wcan delete $idt $idr $idi}
	catch {$wcan delete $idh}
        catch {$wcan delete $idm}
        catch {$wcan delete $idor}
	if {[info exists Options(-isvg)]} {
	    set isvg $Options(-isvg)
	    eval "$wcan bind $isvg <Enter> {}"
	    eval "$wcan bind $isvg <Leave> {}"
	    eval "$wcan bind $isvg <ButtonPress-1> {}"
	    eval "$wcan bind $isvg <ButtonRelease-1> {}"
	    eval "$wcan delete $isvg"
	}
	if {$fr} {
	    destroy $wcan
	}
    }
  }
}
#################### Подмешиваемые классы
set copycanitem {
  method copyItem {canv item x0 y0} {
    set command ""
    lappend command $wcan create
    set type [$canv type $item]
    if {$type == ""} {
	error "copycanitem: Bad svg image=$type, value=\"$canv $item\""
    }
    if {$type == "group"} {
	return [my copyGroup $canv $item $x0 $y0]
    }
    set grnew [$wcan create group]
    lappend command $type
    eval lappend command "\"[$canv coords $item]\""
#Читаем аттрибуты
    set options [list]
    foreach conf [$canv itemconfigure $item] {
	if {[lindex $conf 0] == "-matrix"} {continue}
	if {[lindex $conf 0] == "-parent"} {continue}
	if {[lindex $conf 0] == "-tags"} {continue}
	set default [lindex $conf 3]
	set value [lindex $conf 4]
	if {[lindex $conf 0] == "-fill" && [string first "gradient" $value] == 0} {
	    set value [::svgwidget::cloneGrad $canv $value $wcan]
    	    lappend options [lindex $conf 0] $value
	} elseif {[string compare $default $value] != 0} {
    	    lappend options [lindex $conf 0] $value
	}
    }
#  return $options
############
#    eval lappend command [getObjectOptions $utagORid $flag]
#puts "options=$options"
#    lappend command "[lindex $options 0]"
    append command " $options"
#puts "COMMAND=$command"
    set copytag [eval $command]
#Создаем объект и ставим в нужное место
    if {$copytag == ""} {return -1}
#Бобавить tags
    set btag "canvasb[string range [self] [string first Obj [self]] end]"
    $wcan itemconfigure $copytag -tags [list $type obj $canvasb $btag [linsert $btag end frame] utag$copytag]
    $wcan itemconfigure $copytag -parent $grnew
    foreach {x1 y1 x2 y2} [$wcan bbox $grnew] {break}
    
    set dx [expr { [winfo fpixels $wcan $x0] - $x1}] 
    set dy [expr { [winfo fpixels $wcan $y0] - $y1}]

    $wcan move $copytag $dx $dy

    foreach {x1 y1 x2 y2} [$wcan bbox $grnew] {break}
    set dx0 [expr {$x0 - $x1 }]
    set dy0 [expr {$y0 - $y1 }]
    $wcan itemconfigure $copytag -m [list {1 0} {0 1} "[set dx0] [set dy0]"]
#    $wcan move $copytag $dx0 $dy0

    return $grnew

  }
  method copyGroup {canv group x0 y0} {
    if {[$canv type $group] != "group"} {
	return -1
    }
    set grnew [$wcan create group]
    foreach item [$canv children $group] {

	set command ""
	lappend command $wcan create
	set type [$canv type $item]
	if {$type == ""} {
	    puts "copyGroup: Bad svg group=$group item=$item canv=$canv wcan=$wcan"
	    continue
	}
	lappend command $type
	eval lappend command "\"[$canv coords $item]\""
#Читаем аттрибуты
	set options [list]
	foreach conf [$canv itemconfigure $item] {
	    if {[lindex $conf 0] == "-matrix"} {continue}
	    if {[lindex $conf 0] == "-tags"} {continue}
	    if {[lindex $conf 0] == "-parent"} {continue}
	    set default [lindex $conf 3]
	    set value [lindex $conf 4]
	    if {[lindex $conf 0] == "-fill" && [string first "gradient" $value] == 0} {
		set value [::svgwidget::cloneGrad $canv $value $wcan]
    		lappend options [lindex $conf 0] $value
	    } elseif {[string compare $default $value] != 0} {
    		lappend options [lindex $conf 0] $value
	    }
	}
	append command " $options"
#Создаем объект
	set copytag [eval $command]
	if {$copytag == ""} {return -1}
	$wcan itemconfigure $copytag -parent $grnew
#Добавить tags
	set btag "canvasb[string range [self] [string first Obj [self]] end]"
	$wcan itemconfigure $copytag -tags [list $type obj $canvasb $btag [linsert $btag end frame] utag$copytag]
    }
#Ставим группу в нужное место
    foreach {x1 y1 x2 y2} [$wcan bbox $grnew] {break}
    set dx [expr { [winfo fpixels $wcan $x0] - $x1}] 
    set dy [expr { [winfo fpixels $wcan $y0] - $y1}]

    $wcan move $grnew $dx $dy

    foreach {x1 y1 x2 y2} [$wcan bbox $grnew] {break}
    set dx0 [expr {$x0 - $x1 }]
    set dy0 [expr {$y0 - $y1 }]
    $wcan itemconfigure $grnew -m [list {1 0} {0 1} "[set dx0] [set dy0]"]
#    $wcan move $grnew $dx0 $dy0

    return $grnew
  }

}
oo::define ibutton {
    eval $copycanitem
}
oo::define cbutton {
    eval $copycanitem
}


set methodman {
  method changestrwidth {{strw -1}} {
    if {![info exist idr]} {
	return
    }
#Текущая толшина строки
    set tsw [$wcan itemcget $idr -strokewidth]
#Требуемая толшина строки
    if {$strw == -1} {
	set nst [winfo fpixels $wcan $Options(-strokewidth)]
    } else {
	set nst [winfo fpixels $wcan $strw]
    }
#puts "changestrwidth tsw=$tsw nst=$nst"
    if {$tsw == $nst} {
	return
    }
#Нв сколько меняем и делим попалам
    set dst [expr {($nst - $tsw) / 2.0}]
    foreach {x y w h} [$wcan coords $idr] {break}
#puts "changestrwidth nst=$nst dst=$dst x=$x y=$y w=$w h=$h"
    foreach {xo yo wo ho} [$wcan bbox $idr] {break}
    $wcan itemconfigure $idr -strokewidth $nst
    update
    if {$wclass == "mbutton"} {
	return
    }
    if {![winfo exist $wcan]} {return}    
    foreach {xn yn wn hn} [$wcan bbox $idr] {break}
#    set dst [expr {($wn - $wo) / 2.0}]
#puts "changestrwidth tsw=$tsw nst=$nst dst=$dst x=$x y=$y"

    set x [expr {$x + $dst}]
    set y [expr {$y + $dst}]
    set w [expr {$w - $dst}]
    set h [expr {$h - $dst}]
#puts "changestrwidth NEW x=$x y=$y w=$w h=$h"
    $wcan coords $idr  $x $y $w $h
    if {[winfo manager $wcan] != ""} {
	if {!$Options(press)} {
	    $wcan itemconfigure $idr -strokewidth $nst
#	     -stroke $Options(-strokenormal)  -fill $Options(-fillnormal)
	}
    }
  }
  
  method manager {type args} {
#puts "MANAGER wcan=$wcan fr=$fr type=$type args=$args"
    if {$fr == 0} {
	return
    }

    if {[winfo manager $wcan] == ""} {
	    eval $type $wcan [lindex $args 0]
	    lower $wcan
	    update
    }
    my fon
  }
#Какие окна размещены в этом окне
  method slaves {} {
    set man [winfo manager $wcan]
    if { $man == ""} {
	return ""
    }
    return [$man slaves $wcan]
  }
#В каком окне размешено текущее окно
  method islocate {} {
    set man [winfo manager $wcan]
    if { $man == ""} {
	return ""
    }
    set pars [$man info [$wcan]]
    set lwin ""
    set ind [lsearch $pars "-in"]
    if {$ind > -1} {
	incr ind
	set lwin [lindex $args $ind]
    }
    return $lwin
  }

 method fon {} {
    $wcan delete fon
    set rx [winfo rootx $wcan]
    set ry [winfo rooty $wcan]

    set wb [winfo width $wcan]
    set hb [winfo height $wcan]
#puts "MANAGER COORDS type=$type rx=$rx ry=$ry wb=$wb hb=$hb args=$args"
if {1} {
    set cc [my slaves]
#puts "islocate $cc"
    if {$cc != ""} {
	foreach slave "$cc" {
	    if {[winfo parent $slave] != $wcan} {
	        lower $slave
	    }
	}
    }
}
    lower $wcan
    update
    after 30
#Скриншот без кнопки
    set screencan [image create photo -width $wb -height $hb]
#Делаем скриншот нужного widget
#Создаём картинку виджета $y - 2 ???
    loupe $screencan [expr {$rx + $wb / 2}] [expr {$ry + $hb / 2}] $wb $hb
#Сождаём фон из картинки
    set fon [$wcan create image 0 0 -image $screencan -anchor nw  -tags {fon}]
    $wcan lower $fon
    update
#    raise $wcan 
if {1} {
    set cc [my slaves]
#puts "islocate $cc"
#	lower $wcan
    if {$cc != ""} {
	foreach slave "$cc" {
	    if {[winfo parent $slave] != $wcan} {
	        raise $slave
	    }
	}
    }
}
	raise $wcan 
 }
  
  method place {args} {
# puts "MANAGER PLACE self=[self] args=\"$args\""
    append args " -bordermode outside"
    my manager place $args
    if {$wclass == "mbutton"} {
	vwait $Options(-variable)
	return [set $Options(-variable)]
    }
  }
  method pack {args} {
#puts "MANAGER PACK args=$args"
    my manager pack $args
  }
  method grid {args} {
    my manager grid $args
  }
  method forget { } {
    set man [winfo manager $wcan]
    eval $man forget $wcan
  }
  method class {} {
    return $wclass
  }
  method refresh {} {
    set man [winfo manager $wcan]
    if {$man == ""} { return}
    set args [[set man] info $wcan]
    eval "[self] $man $args"
  }

}
oo::define ibutton {
    eval $methodman
}
oo::define cbutton {
    eval $methodman
}

set methshowmenu {

  method showmenu {} {
#Виджет кнопки меню
	set tlb [winfo toplevel [[self] canvas]]
#Виджет собстаенно  меню 
	set tlm [winfo toplevel [[my config -menu] canvas]]
#	set x [winfo x $wcan]
#	set y [winfo y $wcan]
	set rootx [winfo rootx $wcan]
	set rooty [winfo rooty $wcan]
	set rootxtlb [winfo rootx $tlb]
	set rootytlb [winfo rooty $tlb]
	set x [expr {$rootx - $rootxtlb}]
	set y [expr {$rooty - $rootytlb}]

	set wb [winfo width $wcan] 
	set hb [winfo height $wcan] 
	foreach {x1m y1m x2m y2m} [[[my config -menu] canvas] bbox 0] {break}
	set wm [expr {$x2m - $x1m}]
	set hm [expr {$y2m - $y1m}]
#puts "Method showmenu: x1m=$x1m y1m=$y1m x2m=$x2m y2m=$y2m wm=$wm hm=$hm tlb=$tlb tlm=$tlm"

	set direct [[my config -menu] config -direction]
#puts "Method showmenu: self=[self] Options(-menu)=$Options(-menu) menu=[my config -menu] tlb=$tlb tlm=$tlm direct=$direct wb=$wb hb=$hb rootx=$rootx rooty=$rooty"
	if {$tlb == $tlm} {
	    set mtype 0
	} else {
	    set mtype 1
	}
	switch $direct {
	    up {
		if {$mtype} {
		    set rootx [expr {$rootx - $wm / 2 + $wb / 2}]
		    set rooty [expr {$rooty + $hb}]

		} else {
		    set x [expr {$x - $wm / 2 + $wb / 2}]
		    set y [expr {$y + $hb}]
		
		}
	    
	    }
	    down {
		if {$mtype} {
		    set rootx [expr {$rootx - $wm / 2 + $wb / 2}]
		    set rooty [expr {$rooty - $hm}]

		} else {
		    set x [expr {$x - $wm / 2 + $wb / 2}]
		    set y [expr {$y - $hm}]
		
		}
	    }
	    left {
		if {$mtype} {
		    set rootx [expr {$rootx + $wb}]
		    set rooty [expr {$rooty + $hb / 2 - $hm / 2}]
		} else {
		    set x [expr {$x + $wb}]
		    set y [expr {$y + $hb / 2 - $hm / 2}]
		}
	    }
	    right {
		if {$mtype} {
		    set rootx [expr {$rootx - $wm}]
		    set rooty [expr {$rooty + $hb / 2 - $hm / 2}]
		} else {
		    set x [expr {$x - $wm}]
		    set y [expr {$y + $hb / 2 - $hm / 2}]
		}
	    }
	    default {
			error "Method showmenu: Bad direction=$direct"
	    }
	}
	set sttlb 0
	
	if {$mtype} {
	  if {[wm state $tlm] != "normal"} {
	    set mbut [[my config -menu] place -x $rootx -y $rooty ]
	    place forget [[my config -menu] canvas]
	    pack [[my config -menu] canvas] -side top -anchor nw
#	    wm state $tlm normal
	    wm geometry $tlm +$rootx+$rooty
	    set tlb [[my config -menu] config -lockwindow]
	    set ptlb [winfo toplevel $tlb]
#	    set ptlb [winfo parent $tlb]
	    if {$ptlb == ""} {
		set ptlb $tlb
	    }
	    if {[tk busy status $ptlb]} {
		set sttlb 1
	    } else {

		if {[winfo class [winfo toplevel [[self] canvas]]] != "femenu"} {
		    tk busy hold $ptlb
		}
	    }
	    set ptlbw [winfo toplevel $ptlb]
	    set brel ""
	    if {$ptlbw != $ptlb ||  $ptlb == "."} {
		set brel [bind [set ptlb]_Busy <ButtonRelease>]
	    } else {
		set brel [bind [set ptlb]._Busy <ButtonRelease>]
	    }

	    if {$ptlbw != $ptlb ||  $ptlb == "."} {
		set bconf [bind [set ptlb]_Busy <Configure>]
	    } else {
		set bconf [bind [set ptlb]._Busy <Configure>]
	    }
	    if { $sttlb } {
		if {$ptlbw != $ptlb ||  $ptlb == "."} {
		    eval "bind [set ptlb]_Busy <ButtonRelease> {bind [set ptlb]_Busy <ButtonRelease> {$brel}; tk busy forget $ptlb; wm state $tlm withdraw}"
		    eval "bind [set ptlb]_Busy <Configure> {bind [set ptlb] <Configure> {$bconf};catch {tk busy forget $ptlb}; wm state $tlm withdraw}"
		} else {
		    eval "bind [set ptlb]._Busy <ButtonRelease> {bind [set ptlb]._Busy <ButtonRelease> {$brel}; wm state $tlm withdraw;}"
		    eval "bind [set ptlb]._Busy <Configure> {bind [set ptlb] <Configure> {$bconf};catch {tk busy forget $ptlb}; wm state $tlm withdraw}"
		}
	    } else {
		if {$ptlbw != $ptlb ||  $ptlb == "."} {
		    eval "bind [set ptlb]_Busy <ButtonRelease> {bind [set ptlb]_Busy <ButtonRelease> {$brel}; tk busy forget $ptlb; wm state $tlm withdraw};"
		    eval "bind [set ptlb]_Busy <Configure> {bind [set ptlb] <Configure> {$bconf};catch {tk busy forget $ptlb}; wm state $tlm withdraw}"
		} else {
		    eval "bind [set ptlb]._Busy <ButtonRelease> {bind [set ptlb]._Busy <ButtonRelease> {$brel}; tk busy forget $ptlb; wm state $tlm withdraw};"
		    eval "bind [set ptlb]._Busy <Configure> {bind [set ptlb] <Configure> {$bconf};catch {tk busy forget $ptlb}; wm state $tlm withdraw}"
		}
	    }
	    wm state $tlm normal
	  }
	    return "$rootx $rooty"
	} else {

	    if {[tk busy status $tlb]} {
		set sttlb 1
		set tlbw [winfo toplevel $tlb]
		if {$tlbw != $tlb ||  $tlb == "."} {
		    set brel [bind [set tlb]_Busy <ButtonRelease>]
		} else {
		    set brel [bind [set tlb]._Busy <ButtonRelease>]
		}
	    } else {
		tk busy hold $tlb
		set brel ""
	    }
	    if {[place info [[my config -menu] canvas]] == ""} {
		set oom [my config -menu]
		set clm [$oom class]
		set mbut [$oom place -x $x -y $y ]

		if {[info class instances $clm $oom] == ""} {
		    return "-1 -1"
		}
		set winm [[my config -menu] canvas]
#puts "LMENU: $brel"
		set bconf [bind [set tlb] <Configure>]
		set tlbw [winfo toplevel $tlb]
		if { $sttlb } {
		    if {$tlbw != $tlb ||  $tlb == "."} {
			eval "bind [set tlb]_Busy <ButtonRelease> {bind [set tlb]_Busy <ButtonRelease> {$brel};place forget $winm}"
		    } else {
			eval "bind [set tlb]._Busy <ButtonRelease> {bind [set tlb]._Busy <ButtonRelease> {$brel};place forget $winm}"
		    }
		} else {
		    if {$tlbw != $tlb ||  $tlb == "."} {
			eval "bind [set tlb]_Busy <ButtonRelease> {bind [set tlb]_Busy <ButtonRelease> {$brel};tk busy forget $tlb; place forget $winm}"
		    } else {
			eval "bind [set tlb]._Busy <ButtonRelease> {bind [set tlb]._Busy <ButtonRelease> {$brel};tk busy forget $tlb; place forget $winm}"
		    }    
		}
	    }
	    return "$x $y"
	}
  }
  
}
oo::define ibutton {
    eval $methshowmenu
}
oo::define cbutton {
    eval $methshowmenu
}
oo::class create mbutton {
#iidt - текст
#idr - прямоугольник вокруг кнопки
#idm - маркер radio/check button
#idg - группв, объединяющая idr,idt и $idm
#Переменные для check и radio должны быть глобальными, т.е. начинаться с ::  !!!!!!

  variable wcan
  variable idr
  variable idm
  variable idt
  variable idg
  variable tbut
  variable cbut
  variable cbut1
  variable nexttag
  variable onemm2px
  variable canvasb
  variable btag
  variable Options
  variable wclass
#fr = 0 кнопки создаются на внешнем холсте
#fr - 1 кнопки создаются на внутреннем холсте для внешнего фрейма
  variable fr
  
  constructor {w {args "-text mbutton"}} {
    set wcan $w
    set type "msg"
    set ind [lsearch $args "-type"]
    if {$ind > -1} {
	incr ind
	set type [lindex $args $ind]
    }
    set tbut $type
    set Options(-x) 0
    set Options(-y) 0

    set wclass "mbutton"
    set nexttag 0
    catch {unset Options}
    set  Options(-state) normal
    set  Options(-width) 4c
    set  Options(-height) 3c
    set Options(-strokewidth) 1
    set Options(-direction) $type
    set Options(-strokeopacity) 1.0
    set Options(-variable) ::_mbut
    set ::_mbut ""
    set fr 0
    set canvasb "canvasb"
    set ind [lsearch $args "-strokewidth"]
    if {$ind > -1} {
	incr ind
	set Options(-strokewidth) [lindex $args $ind]
    }
    if {![winfo exists $wcan]} {
	tkp::canvas $wcan -bd 0 -highlightt 0
	set strwidth [winfo fpixels $wcan $Options(-strokewidth)]
	set cwidth [winfo fpixels $wcan $Options(-width)]
	set cheight [winfo fpixels $wcan $Options(-height)] 
        $wcan configure -bg [[winfo parent $wcan] cget -bg]
        set Options(-x) $strwidth
        set Options(-y) $strwidth
        set fr 1
        append canvasb "fr"
    }
    set g4 [$wcan gradient create linear -method pad -units bbox -stops { { 0.00 #ffffff 1} { 1.00 #dbdbdb 1}} -lineartransition {0.00 0.00 0.00 1.00} ]
#puts "MBUTTON fr=$fr costructor: w=\"$w\""
    set defx [winfo fpixels $w 25m]
    set defy [winfo fpixels $w 7m]
    set defrx [winfo fpixels $w 3.5m]
    set defry [winfo fpixels $w 12.5m]
    set twomm2px [winfo fpixels $w 2m]
    set onemm2px [winfo fpixels $w 1m]
    array set font [font actual systemSystemFont]
    set Options(-fontfamily) $font(-family)
    set Options(-fontweight) $font(-weight)
    set Options(-fontslant) "normal"
    set Options(-textanchor) "nw"
    set tremm2px [winfo fpixels $w 3m]
#    set Options(-fontsize) "[string range [expr {$font(-size) / $onemm2px}] 0 4]m"
    set Options(-fontsize) $tremm2px

#puts "type=$type args=\"$args\""
#    set Options(-fillnormal) white
    set Options(-fillnormal) $g4
#    set Options(-fillnormal) "#e9eeef"
    set Options(press) 0
    set Options(-fillenter) skyblue

    set Options(-fillpress) green

#    set Options(-stroke) gray40
    set Options(-stroke) #00bcd4

    set  Options(-rx) 2m
    set Options(-tongue) [list 0.5 0.9 0.8 5m]

    switch $type {
	msg -
	yesno {
#	    set Options(-tongue) [list 0.5 0.9 0.8 0.75]
	    set Options(-text) "Yes\ No"
	    set Options(-fillpress) "##"
	    set Options(-fillenter) "##"
	}
	left -
	right {
#	    set Options(-tongue) [list 0.5 0.9 0.8 0.75]
	    set Options(-tongue) [list 0.45 0.5 0.55 5m]
	    set Options(-text) "Callout\ $type"
	}
	down {
#	    set Options(-tongue) [list 0.5 0.9 0.8 0.75]
	    set Options(-tongue) [list 0.5 0.9 0.8 5m]
	    set Options(-text) "Callout\ Down"
	}
	up {
	    set Options(-tongue) [list 0.5 0.9 0.8 5m]
#	    set Options(-tongue) [list 0.5 0.9 0.8 0]
	    set Options(-text) "Callout\n Up"
	}
	default {
    	    error "mbutton: Unknown type=$type..." 
	}
    
    } 

    set Options(-command) {}

    my config $args
    set x1 [winfo fpixels $wcan $Options(-x)]
    set y1 [winfo fpixels $wcan $Options(-y)]

#parray Options
    if {$Options(-text) != "" } {
#Размеры текста
	if {$type == "msg" || $type == "yesno"} { 
	    foreach {Options(-width) Options(-height)} [my btext "$Options(-text)\nYes"] {break}
	} else {
	    foreach {Options(-width) Options(-height)} [my btext "$Options(-text)"] {break}
	
	}
    }
    set anc $Options(-textanchor)
    switch $type {
	msg -
	yesno {
	    set Options(-tongue) [list 0.5 0.5 0.5 0]
		set x2 [expr {$x1 + [winfo fpixels $wcan $Options(-width)]}]
#2m - это расстояние до нижней границы Подумать
		set hyesno [winfo fpixels $wcan "8m"]
		set y2 [expr {$y1 + [winfo fpixels $wcan $Options(-height)] + $hyesno / 2}]
		set rx [winfo fpixels $wcan $Options(-rx)]
#Метка кнопки
#set testfont "sans-serif 12 normal"
		set xt [expr { $x1 + $rx }]
		set yt [expr { $y1 + $rx }]
	    }
	left -
	right {
		set x2 [expr {$x1 + [winfo fpixels $wcan $Options(-width)]}]
		set y2 [expr {$y1 + [winfo fpixels $wcan $Options(-height)]}]
		set rx [winfo fpixels $wcan $Options(-rx)]
#Метка кнопки
#set testfont "sans-serif 12 normal"
		set xt [expr { $x1 + $rx }]
		set yt [expr { $y1 + $rx }]
	
	}
	down {
		set x2 [expr {$x1 + [winfo fpixels $wcan $Options(-width)]}]
		set y2 [expr {$y1 + [winfo fpixels $wcan $Options(-height)]}]
		set rx [winfo fpixels $wcan $Options(-rx)]
#Метка кнопки
#set testfont "sans-serif 12 normal"
		set xt [expr { $x1 + $rx }]
		set yt [expr { $y1 + $rx }]
	    }
	up {
		set x2 [expr {$x1 + [winfo fpixels $wcan $Options(-width)]}]
		set y2 [expr {$y1 + [winfo fpixels $wcan $Options(-height)] + 30}]
		set rx [winfo fpixels $wcan $Options(-rx)]
#Метка кнопки
#set testfont "sans-serif 12 normal"
		foreach {p1x p2x p3x theight } $Options(-tongue) {break}
		set htongue [winfo fpixels $wcan $theight]
		set xt [expr { $x1 + $rx }]
		set yt [expr { $y1 + $rx +$htongue}]
	    }
	default {
    	    error "mbutton 1: Unknown type=$type..." 
	} 
    }   
#puts "TYPE=$type x1=$x1 y1=$y1 x2=$x2 y2=$y2"
    set d [my coordspath "$x1 $y1" "$x2 $y2" $rx "$Options(-tongue)" $type]
#puts "TYPE=$type path=$d"
    set idr [$wcan create path  "$d" -stroke {} -strokewidth 0] 
#$wcan lower $idr
    set btag "canvasb[string range [self] [string first Obj [self]] end]"
    set strwidth [winfo fpixels $wcan $Options(-strokewidth)]
    $wcan itemconfigure $idr -fill white -stroke black -strokewidth $strwidth  -tags [list Rectangle obj $canvasb $btag [linsert $btag end frame] utag$idr]
    set idr "utag$idr"
     
    set tbox [my placetext $wcan "$Options(-text)" $xt $yt $anc]
    set idt $tbox
    set tbox [$wcan bbox $idt]
    $wcan itemconfigure $idt -tags [list text obj $canvasb $btag [linsert $btag end text] text$btag]
    set idt text$btag
    $wcan delete IDOR
    set idor [$wcan create path  "$d" -stroke {} -strokewidth $strwidth -fill yellow -fillopacity 0 -tag IDOR] 
    eval "$wcan bind $idor <Enter> {[self] enter}"
    eval "$wcan bind $idor <Leave> {[self] leave}"
    eval "$wcan bind $idor <ButtonPress-1> {[self] press %W}"
    eval "$wcan bind $idor <ButtonRelease-1> {[self] release %X %Y}"

    $wcan itemconfigure $idr -fill $Options(-fillnormal) -stroke $Options(-stroke)
#Сдвигается почему-то idr?????
#    my config [array get Options]

    if {$type == "yesno"} {
	set wyesno [expr {$x2 - $x1}]
#puts "hyesno=$hyesno wyesno=$wyesno y2=$y2 yt=$yt self=[self]"
	set fontsize [winfo fpixels $wcan 3.5m]
	foreach {xr1 yr1 xr2 yr2} [$wcan bbox $idr] {break}
#puts "xr1=$xr1 yr1=$yr1 xr2=$xr2 yr2=$yr2 idr=$idr height=[my config -height]"
	set yr2 [winfo pixels $wcan [my config -height]]

	set idtyn [$w create ptext $xr1 [expr {$yr2 - ( $hyesno / 2)}] -textanchor c -text "Нет" -fontfamily $Options(-fontfamily) -fontsize $fontsize]
	set boxyn [$wcan bbox $idtyn]
	foreach {tx1 ty1 tx2 ty2} $boxyn {break}
	$wcan delete $idtyn
#	puts "hyesno=$hyesno wyesno=$wyesno boxyn=$boxyn"
	set dx [expr {($xr2 - $xr1 - ($tx2 - $tx1) * 2) / 3.0}]
	set cbut [cbutton new "$wcan" -type round -x [expr {$xr1 + $dx}] -y [expr {$yr2 - ( $hyesno / 2) + 0 * $onemm2px}] -text "Да"  -fontfamily $Options(-fontfamily) -fontsize $fontsize]
	set cbut1 [cbutton new "$wcan" -type round -x [expr {$xr1 + $dx * 2 + ($tx2 - $tx1)}] -y [expr {$yr2 - ( $hyesno / 2) + 0 * $onemm2px}] -text " Нет"  -fontfamily $Options(-fontfamily) -fontsize $fontsize]
	$cbut config -width [expr {$tx2 - $tx1 + 4}] -height [expr {$ty2 - $ty1 - $onemm2px}] -rx 4 -command "variable $Options(-variable);[set cbut] destroy;[set cbut1] destroy;[self] destroy;set $Options(-variable) yes"
	$cbut1 config -width [expr {$tx2 - $tx1 + 4}] -height [expr {$ty2 - $ty1 - $onemm2px}] -rx 4 -command "variable $Options(-variable);[set cbut] destroy;[set cbut1] destroy;[self] destroy;set $Options(-variable) no"
#puts "hyesno=$hyesno self=[self] Yes=$cbut No=$cbut1"
	[self] config -state disabled
    } elseif {$type == "msg"} {
	set wyesno [expr {$x2 - $x1}]
#puts "hyesno=$hyesno wyesno=$wyesno y2=$y2 yt=$yt self=[self]"
	set fontsize [winfo fpixels $wcan 3.5m]
	foreach {xr1 yr1 xr2 yr2} [$wcan bbox $idr] {break}
#puts "xr1=$xr1 yr1=$yr1 xr2=$xr2 yr2=$yr2 idr=$idr height=[my config -height]"
	set yr2 [winfo pixels $wcan [my config -height]]

	set idtyn [$w create ptext $xr1 [expr {$yr2 - ( $hyesno / 2)}] -textanchor c -text "Нет" -fontfamily $Options(-fontfamily) -fontsize $fontsize]
	set boxyn [$wcan bbox $idtyn]
	foreach {tx1 ty1 tx2 ty2} $boxyn {break}
	$wcan delete $idtyn
#	puts "hyesno=$hyesno wyesno=$wyesno boxyn=$boxyn"
	set dx [expr {($xr2 - $xr1 - ($tx2 - $tx1) * 1) / 2.0}]
	set cbut [cbutton new "$wcan" -type round -x [expr {$xr1 + $dx}] -y [expr {$yr2 - ( $hyesno / 1) + 2 * $onemm2px}] -text "Да"  -fontfamily $Options(-fontfamily) -fontsize $fontsize]
#	set cbut [cbutton new "$wcan" rect [expr {$xr1 + $dx}] [expr {$yr2 - ( $hyesno / 1) + 1.5 * $onemm2px}] -text "Да"  -fontfamily $Options(-fontfamily) -fontsize $fontsize]
	$cbut config -width [expr {$tx2 - $tx1 + 4}] -height [expr {$ty2 - $ty1 - $onemm2px}] -rx 4
#Переменная erm для ожидания ответа от пользователя (нажатия кнрпки Ок)
#	$cbut config -command "global erm; [self] destroy; [set cbut] destroy; set erm 1"
	$cbut config  -command "variable $Options(-variable); [set cbut] destroy;[self] destroy;set $Options(-variable) yes"
	[self] config -state disabled
#puts "hyesno=$hyesno self=[self] Yes=$cbut"
    }
    if {$type != "msg" && $type != "yesno"} {
	[self] config  -command "variable $Options(-variable);[self] destroy;set $Options(-variable) yes"
    } else {
	[self] config  -strokeopacity $Options(-strokeopacity)
    }
#Приводим в соответствие размеры холста с размерами mbutton 
    if {$fr} {
#	my config -width $Options(-width) -height $Options(-height)
	if {$tbut == "left"} {
	    foreach {p1x p2x p3x theight } $Options(-tongue) {break}
	    set htongue [winfo fpixels $wcan $theight]
	    $wcan move 0 [expr {$htongue - 2 }] 0
	}
	foreach {x0 y0 x1 y1} [$wcan bbox 0] {break}
#	$wcan configure -width [expr {$x1 + $x0}] -height [expr {$y1 + $y0}]
	$wcan configure -width [expr {$x1}] -height [expr {$y1}]
    }
    if {$Options(-command) != ""} {
#	set cmd [my config -command]
	set cmd "variable $Options(-variable);$Options(-command);set $Options(-variable) yes"
	my config -command $cmd
    }
    $wcan raise $idor $idt
#    puts "[self]"
  }
  
  method coordspath {p1 p2 rx ton type} {
    foreach {x1 y1} $p1 {break}
    foreach {x2 y2} $p2 {break}
    foreach {p1x p2x p3x theight } $ton {break}
    set p1y [winfo fpixels $wcan $theight]

    if { $p1y < 0} {
#puts "coordspath error 1"
	return -1
    }
    switch $type {
	up {
		set y1_1 $y1
		set y1 [expr {$y2 - $p1y}]
		set y2 $y1_1
	}
	left -
	right  {
	    if {$type == "left"} {
		set x1_1 $x1
		set x1 $x2
		set x2 $x1_1
		set rx [expr {$rx * -1.0}]
		set my [expr {$y1 - $rx}]
	    } else {
		set my [expr {$y1 + $rx}]
	    }
	    
	    set mx $x1
#Первая вершина
	    set q1_1x $x1
	    set q1_1y $y1
	    set q1_2x [expr {$x1 + $rx}]
	    set q1_2y $y1
#Отрезок между первой и второй вершиной
    	    set l1_x [expr {$x2 - $rx}]
	    set l1_y $y1
#Вторая  вершина
	    set l2_x $x2
	    set q2_1x $x2
	    set q2_1y $y1
	    set q2_2x $x2

	    if {$type == "right"} {
		set l2_y [expr {$y2 + $rx}]
		set q2_2y [expr {$y1 + $rx}]
	    } else {
		set l2_y [expr {$y2 - $rx}]
		set q2_2y [expr {$y1 - $rx}]
	    }

#puts "Вторая вершина type=$type "
#Отрезок между второй вершиной и верхней точкой язычка
	    set t1   [expr {($y2 - $y1) * $p1x + $y1}]
	    set l3_x $x2
	    set l3_y $t1
#Вершина язычка - вторая точка язычка
	    if {$type == "right"} {
		set l4_x [expr {$x2 + $p1y}]
	    } else {
		set l4_x [expr {$x2 - $p1y}]
	    }
	    set l4_y [expr {($y2 - $y1) * $p2x + $y1}]
#Первая/нижняя точка язычка
	    set l5_x $x2
	    set l5_y [expr {($y2 - $y1) * $p3x + $y1}]
#puts "l5_y=$l5_y l5_x=$l5_x y2=$y2 y1=$y1 p1x=$p1x"
#Отрезок между нижней/первой вершиной язычка и третьей вершиной прямоугольника
	    set l6_x $x2
#Третья  вершина
	    set q3_1x $x2
	    set q3_1y $y2

	    set q3_2x [expr {$x2 - $rx}]
	    set q3_2y $y2 
#Отрезок между третьей и четвёртой вершиной прямоугольника
	    if {$type == "right"} {
		set l6_y [expr {$y2 - $rx }]
		set q4_2y [expr {$y2 - $rx}]
	    } else {
		set l6_y [expr {$y2 + $rx }]
		set q4_2y [expr {$y2 + $rx}]
	    }
	    set l7_x [expr {$x1 + $rx}]
	    set l7_y $y2
#Четвёртая вершина
	    set q4_1x $x1
	    set q4_1y $y2
	    set q4_2x $x1
	    set coords [list M $mx $my Q $q1_1x $q1_1y $q1_2x $q1_2y L $l1_x $l1_y Q $q2_1x $q2_1y $q2_2x $q2_2y L $l3_x $l3_y $l4_x $l4_y $l5_x $l5_y $l6_x $l6_y Q $q3_1x $q3_1y $q3_2x $q3_2y L $l7_x $l7_y Q $q4_1x $q4_1y $q4_2x $q4_2y Z]
#puts "RIGHT=$coords"
	    return $coords

	}
    }
    set y2orig $y2
#Начальная точка
    set mx $x1
#puts "x2=$x2 > x1=$x1 && y2=$y2 < y1=$y1"
    if {($x2 > $x1 && $y2 < $y1) || ($x2 < $x1 && $y2 > $y1)} {
	set my [expr {$y1 - $rx}]
	set y2 [expr {$y2 + $p1y}]
    } else {
	set my [expr {$y1 + $rx}]
	set y2 [expr {$y2 - $p1y}]
    }
#Первая вершина
    set q1_1x $x1
    set q1_1y $y1
    set q1_2x [expr {$x1 + $rx}]
    set q1_2y $y1
#Отрезок между первой и второй вершиной
    set l1_x [expr {$x2 - $rx}]
    set l1_y $y1
#Вторая  вершина
    set q2_1x $x2
    set q2_1y $y1
    set q2_2x $x2
    if {($x2 > $x1 && $y2 < $y1) || ($x2 < $x1 && $y2 > $y1)} {
	set q2_2y [expr {$y1 - $rx}]
    } else {
	set q2_2y [expr {$y1 + $rx}]
    }
#Отрезок между второй и третьей вершиной
    set l2_x $x2
    if {($x2 > $x1 && $y2 < $y1) || ($x2 < $x1 && $y2 > $y1)} {
	set l2_y [expr {$y2 + $rx}]
    } else {
	set l2_y [expr {$y2 - $rx}]
    }
#Третья  вершина
    set q3_1x $x2
    set q3_1y $y2
    set q3_2x [expr {$x2 - $rx}]
    set q3_2y $y2 
#Отрезок между третьей и правой точкой язычка
    set t1   [expr {($x2 - $x1) * $p3x + $x1}]
    set l3_x $t1
    set l3_y $y2
#Вершина язычка - вторая точка язычка
    set l4_x [expr {($x2 - $x1) * $p2x + $x1}]
    set l4_y $y2orig
#Первая/левая точка язычка
    set l5_x [expr {($x2 - $x1) * $p1x + $x1}]
    set l5_y $y2
#Отрезок между левой/первой вершиной язычка и четвёртой вершиной прямоугольника
    set l6_x [expr {$x1 + $rx}]
    set l6_y $y2
#Четвёртая вершина
    set q4_1x $x1
    set q4_1y $y2
    set q4_2x $x1
    if {($x2 > $x1 && $y2 < $y1) || ($x2 < $x1 && $y2 > $y1)} {
	set q4_2y [expr {$y2 + $rx}]
    } else {
	set q4_2y [expr {$y2 - $rx}]
    }
#Отрезок между четвёртой вершиной и начальной точкой
#Замыкаем path	    Z
    set coords [list M $mx $my Q $q1_1x $q1_1y $q1_2x $q1_2y L $l1_x $l1_y Q $q2_1x $q2_1y $q2_2x $q2_2y L $l2_x $l2_y Q $q3_1x $q3_1y $q3_2x $q3_2y L $l3_x $l3_y $l4_x $l4_y $l5_x $l5_y $l6_x $l6_y Q $q4_1x $q4_1y $q4_2x $q4_2y Z]
    return $coords
  }

  method canvas {} {
    return $wcan
  }

  method type {} {
    return "$tbut"
  }
  method class {} {
    return $wclass
  }

  method mcoords {} {
#Добавляем 0.5 для сохранения позиции???
    set crds {}
    foreach {x0 y0 x1 y1} [$wcan coords $idr] {
	lappend crds "[expr {int(($x0 + 0.5) / $onemm2px)}]m"
	lappend crds "[expr {int(($y0 + 0.5) / $onemm2px)}]m"
    }
    set Options(-width) "[expr {($x1 - $x0) / $onemm2px}]m"
    set Options(-height) "[expr {($y1 - $y0) / $onemm2px}]m"
    return $crds
  }
  
  method state {stat} {
#stat - normal|disabled|hidden
    switch $stat {
	normal -
	disabled -
	hidden {
	    $wcan itemconfigure $idr -state $stat
	    $wcan itemconfigure $idt -state $stat
	}
	default {
	    error "Bad state=$stat"
	}
    }
  }
  
  method move {dx dy} {
    $wcan move $idr  $dx $dy
    $wcan move $idt  $dx $dy
    if {$tbut == "yesno"} {
	$cbut move $dx $dy
	$cbut1 move $dx $dy
    }
    return $btag
  }

  method options {} {
    if {[info exists Options(-rx)]} {
	    set Options(-rx) [$wcan itemcget $idr -rx]
    }
    if {[info exists Options(-ry)]} {
	    set Options(-ry) [$wcan itemcget $idr -ry]
    }
    if {$tbut != "check" && $tbut != "radio"} {
	set Options(-strokewidth) [$wcan itemcget $idr -strokewidth]
    }
    set Options(-fontfamily) [$wcan itemcget $idt -fontfamily]
    set Options(-fontsize) "[string range [expr {[$wcan itemcget $idt -fontsize] / $onemm2px } ] 0 4]m"

    return [array get Options]
  }

  method enter {} {
	variable Options
	set strwidth [winfo fpixels $wcan $Options(-strokewidth)]
	if {$tbut == "check" || $tbut == "radio"} {
	    set fok [$wcan itemcget $idr -fill] 
	    if {$fok == $Options(-fillok)} {
		return
	    }
	    $wcan itemconfigure $idr -strokewidth [expr {$strwidth + $strwidth / 2.0}]
	}
	if {[my config -state] == "disabled" } {
	    return
	}
	if {$Options(-fillenter) != "##"} {
	    my changestrwidth [expr {$strwidth + $strwidth / 2.0}]
	    $wcan itemconfigure $idr -fill $Options(-fillenter) -stroke $Options(-stroke)
	}
  }
  
  method leave {} {
    variable Options
    if {$tbut == "check" || $tbut == "radio"} {
	    set fok [$wcan itemcget $idr -fill] 
	    if {$fok == $Options(-fillok)} {
		return
	    }
	    if {$tbut == "radio"} {
		$wcan itemconfigure $idm -fill $Options(-fillnormal)
	    }
    }
    if {!$Options(press)} {
	my changestrwidth [winfo fpixels $wcan $Options(-strokewidth)]
	$wcan itemconfigure $idr  -stroke $Options(-stroke)  -fill $Options(-fillnormal)
    }
#    set Options(press) 0
  }
  method press {w} {
	variable Options
	if {[my config -state] == "disabled" } {
	    return
	}
	set Options(press) 1
	if {$tbut != "check" && $tbut != "radio"} {
	    if {$Options(-fillpress) != "##"} {
		$wcan itemconfigure $idr -fill $Options(-fillpress)
	    }
	}
  }
  method release {x y} {
    variable Options
    if {[my config -state] == "disabled" } {
	return
    }
    set tfr 1
    if {$fr || !$fr} {
	set x1 [winfo rootx $wcan]
	set x2 [expr {$x1 + [winfo width $wcan]}] 
	set y1 [winfo rooty $wcan]
	set y2 [expr {$y1 + [winfo height $wcan]}] 
	if {$x < $x1 || $x > $x2 || $y < $y1 || $y > $y2} {
	    set tfr 0
	    set Options(press) 0
	}
    }

    if {$Options(press) && $tfr} {
	set Options(press) 0
	eval $Options(-command)
    } else {
	$wcan itemconfigure $idr -fill $Options(-fillnormal)
    }
  }
  method invoke {} {
	eval $Options(-command)
  }

  method placetext {can text xt yt {textanchor nw} } {
    if {$text == ""} {
	return ""
    }
    set sfont [winfo pixels $wcan $Options(-fontsize)]
    set ltext [split "$text" "\n"]
    set ystr $yt
    set grt [$can create group]
    $can delete boxText
    set i 0
    foreach {txt}  "$ltext" {
	set tekb [$can create ptext $xt $ystr -text "$txt" -fontfamily $Options(-fontfamily) -fontweight $Options(-fontweight) -fontsize $sfont -fontslant $Options(-fontslant) -textanchor $textanchor  -tag "boxText$i" -parent $grt -textanchor nw]

	foreach {x0  y0 x1 y1} [$can bbox $tekb] {break}
	set ystr $y1
	incr i
    }
    foreach {x0 y0 x1 y1} [$can bbox $grt] {break}
	for {set j 0} {$j < $i} {incr j} {
	    set id [$can find withtag boxText$j]
	    switch $textanchor {
		"nw" {
		    set xt $xt
		}
		"n" {
		    set xt [expr {($x0 + $x1) / 2.0}]
		}
		"ne" {
		    set xt $x1
		}
	    }
	    foreach {xttek yt} [$can coords $id] {
		$can coords $id $xt $yt
		$can itemconfigure $id  -textanchor $textanchor
		$can itemconfigure $id  -tag boxText
	    }
	}
    return "$grt"
  }

  method btext {text} {
	set rx [winfo fpixels $wcan $Options(-rx)]
	set sw [winfo fpixels $wcan $Options(-strokewidth)]
	set  sfont [winfo fpixels $wcan $Options(-fontsize)]
	set tbox [my placetext $wcan $text 0 0]
	foreach {x0 y0 x1 y1} [$wcan bbox $tbox] {break}
	$wcan delete $tbox
	set w "[expr {($x1 - $x0 + 2 * $rx)}]"
	set h "[expr {($y1 - $y0 + 2 * $rx)}]"
	foreach {p1x p2x p3x theight } $Options(-tongue) {break}
#Возвращается высота ширина и высота блока для текста в мм 
# с учетом загруглённости углов
# высота (длина) язычка
# и скругление углов
	return [list $w $h $theight $Options(-rx)]
  }

  method config args {
    variable Options
#    set svgtype [list circle ellipse group path  pline polyline ppolygon prect ptext]
#pimage - это делается отдельно
    if {[llength $args] == 1} {
	set args [lindex "$args" 0]
    }
#puts "Config args=$args length=[llength $args]"
    if {[llength $args] == 0} {
	return [array get Options]
    }
    if {[llength $args] % 2 != 0} {
#Чтение значения аттрибута
	if {[llength $args] == 1} {
#puts "config $args : $Options($args)"
	    return $Options($args)
	}
#puts "Error args length: $args"
      error "use is: <object> config ?-option value?...\nargs=$args" 
    }
#puts "MBUTTON CONFIG args=$args"
    foreach {option value} $args {
        switch -exact  $option \
        {
	    -background -
	    -bg {
		if {$fr} {
		    set  Options($option) $value
		    $wcan configure -background $value
		}
	    }
    	    -type -
    	    -direction {
    		continue
    	    }
	    -x -
	    -y {
    		if {[info exists idr] || $fr} {
    		    continue
    		}
		set  Options($option) $value
	    }
	    -state {
		switch $value {
		    normal -
		    disabled -
		    hidden {
			set  Options($option) $value
			if {[info exists idr]} {
#	   		 $wcan itemconfigure $idg -state $stat
			    $wcan itemconfigure $idr -state $value
			    $wcan itemconfigure $idt -state $value
			}
		    }
		    default {
			error "Bad state=$value"
		    }
		}
	    }
	    -textanchor {
    		if {[lsearch [list "nw" "n" "ne"] $value] == -1} {
    		    error "Error for side ($value): -compound \[ top | bottom | left | right | none \]"
		    continue
    		}
		set  Options($option) $value
	    }
	    -height -
	    -width {
		set valold [winfo fpixels $wcan $Options($option)]
		set  Options($option) $value
		set val [winfo fpixels $wcan $value]
		set strwidth [winfo fpixels $wcan $Options(-strokewidth)]
		if {[info exists idr]} {
		    if {$fr == 1} {
			set strwidth [winfo fpixels $wcan $Options(-strokewidth)]
    			set x1 $strwidth
    			set y1 $strwidth
		    } else {
			foreach {m x1 y1 last} [$wcan coords $idr] {break}
    			set x1 [expr {$strwidth * 2}]
    			set y1 [expr {$strwidth * 2}]
		    }
#puts "x1=$x1\ny1=$y1\nlast=$last"
		    switch $tbut {
			msg -
			yesno -
			right -
			left -
			up -
			down {
			    set rx [winfo fpixels $wcan $Options(-rx)]
			    set x2 [expr {$x1 + [winfo fpixels $wcan $Options(-width)] - $strwidth * 0 }]
			    set y2 [expr {$y1 + [winfo fpixels $wcan $Options(-height)] - $strwidth * 0 }]
			    set d [my coordspath "$x1 $y1" "$x2 $y2" $rx "$Options(-tongue)" $tbut]
#Переставитьь текст!!!!
			}
    			default {
    			    puts "nbutton: conffig Unknown type $tbut"
    			}
		    }
		    foreach {x0 y0 x1 y1} [$wcan bbox $idr] {break}
		    $wcan coords $idr "$d"
		    foreach {x0n y0n x1n y1n} [$wcan bbox $idr] {break}
		    $wcan move $idr [expr {$x0 - $x0n}] [expr {$y0 - $y0n}]
		}
		if {$fr} {
		    set xx [winfo fpixels $wcan $value]
		    set xx [expr {$xx + $strwidth * 2.0 }]
		    $wcan configure $option $xx
		}
	    }
	    -deselect {
		if { $tbut != "check" && $tbut != "radio"} {
    		    error "Bad option $option for mbutton type=$tbut" 
		    return
		}
	    }
	    -select {
		if { $tbut != "check" && $tbut != "radio"} {
    		    error "Bad option $option for mbutton type=$tbut" 
		    return
		}
	    }
	    -variable {
		variable $value
    		set Options($option) $value
    		if {![info exists $value]} {
    		    set $value 0
    		}
#puts "VALUE ($value) -variable: [subst $$value]"
	    }
	    -tintamount -
	    -value -
	    -command -
    	    -fillenter -
    	    -fillok -
    	    -fillpress {
    		set Options($option) $value
    	    }
    	    -fillnormal {
    		set Options($option) $value
		if {[info exists idr]} {
		    if { $tbut != "check" && $tbut != "radio"} {
			$wcan itemconfigure $idr -fill $value
    		    }
		}
    	    }
	    -strokewidth {
    		set Options($option) $value
		if {[info exists idr]} {
			$wcan itemconfigure $idr -strokewidth [winfo fpixels $wcan $value]
		}
    	    }
	    -rx {
		    set Options($option) $value
		    if {[info exists idr]} {
#			$wcan itemconfigure $idr $option [winfo fpixels $wcan $value]
		    }
	    }
    	    -fill {
		if {[info exists idr]} {
		    $wcan itemconfigure $idr $option $value
		}
	    }        
	    -text {
    		set Options($option) $value
		if {[info exists idt]} {
		    $wcan itemconfigure $idt $option $value
    		    $wcan raise $idt $idr
		    if {$fr == 1} {
#			foreach {x1 y1 x2 y2} [$wcan bbox $canvasb] {break}
			foreach {x1 y1 x2 y2} [$wcan bbox 0] {break}
			$wcan configure -width $x2 -height $y2
		    }
		} 
	    }
	    -fontfamily -
	    -fontsize -
	    -fontslant -
	    -fontweight {
    		set Options($option) $value
		if {[info exists idt]} {
if {1} {
		    if {$option == "-fontsize"} {
		    	$wcan itemconfigure $idt $option [winfo pixels $wcan $Options(-fontsize)]
		    } else {
		    	$wcan itemconfigure $idt $option $value
		    }
}
		    if {$fr == 1} {
			foreach {x1 y1 x2 y2} [$wcan bbox $canvasb] {break}
			$wcan configure -width $x2 -height $y2
		    }
		} 
	    }
	    -fontsizeOLD {
    		set Options($option) $value
		if {[info exists idt]} {
		    $wcan itemconfigure $idt $option [winfo fpixels $wcan $value]
		} 
	    }
	    -stroke {
    		set Options($option) $value
		if {[info exists idr]} {
		    if { $tbut != "check" && $tbut != "radio"} {
			$wcan itemconfigure $idr -stroke $value
    		    }
		}
	    }
	    -strokeopacity {
    		set Options($option) $value
		if {[info exists idr]} {
		    if { $tbut != "check" && $tbut != "radio"} {
			$wcan itemconfigure $idr -strokeopacity $value
    		    }
		}
	    }
	    press {
		;
	    }
	    -tongue {
		if {$tbut != "msg" && $tbut != "yesno"} {
    		    set Options($option) $value
    		    my config -width $Options(-width)
    		} 
	    }
    	    default {
    		puts "mbutton: Bad option $option args=$args"
    	    }
        }
    }
  }


  destructor {
    if {$tbut == "yesno"} {
    	    catch {$cbut destroy}
    	    catch {$cbut1 destroy}
    } elseif {$tbut == "msg"} {
    	    catch {$cbut destroy}
    }
    if {[winfo exists $wcan]} { 
	$wcan bind $idr <Enter> {}
	$wcan bind $idr <Leave> {}
	$wcan bind $idt <Enter> {}
	$wcan bind $idt <Leave> {}
	$wcan bind $idr <ButtonPress-1> {}
	$wcan bind $idr <ButtonRelease-1> {}
	$wcan bind $idt <ButtonPress-1> {}
        $wcan bind $idt <ButtonRelease-1> {}
        $wcan delete $idt $idr
	set par [winfo parent $wcan]

	if {$fr == 1} {
	    destroy $wcan 
	}
	if {[winfo class $par] == "femenu"} {
	    destroy $par
	}
    }
  }
}

oo::class create cmenu {
  variable wcan
  variable Options
  variable listmenu
  variable xc
  variable yc
  variable m3
  variable idr
  variable wclass
  variable erlib
#fr = 0 кнопки создаются на внешнем холсте
#fr - 1 кнопки создаются на внутреннем холсте для внешнего фрейма
  variable fr

  constructor {w {args ""}} {
    if {[winfo exists $w]} {
#	error "cmenu cmenu $w already exist"
	puts "class create cmenu: cmenu $w already exist"
	destroy $w
    }
    set erlib ""
    set wcan $w
    set fr 0
    if {![winfo exists $wcan]} {
	set fr 1
    }
    set wclass "cmenu"
    tkp::canvas $wcan -bd 0 -highlightt 0
    catch {unset Options}
    set  Options(-height) 5m
    set  Options(-fillnormal) white
    set  Options(-fontsize) 3m
    set Options(-strokewidth) 1
    set Options(-stroke) ""
    set Options(-command) ""
    set Options(-pad) 1m
    set Options(-direction) "up"
#Блокирукмое окно при отображении меню
    set Options(-lockwindow) ""
    set Options(-tongue) [list 0.45 0.5 0.55 5m]
    set xc [winfo fpixels $wcan $Options(-strokewidth)]
    set m3 [winfo fpixels $wcan 3m]
    set yc $m3
    set listmenu [list]
    my config $args
#puts "cmenu constructor: Options(-strokewidth)=$Options(-strokewidth)"
    set xc [expr {$xc + [winfo fpixels $wcan $Options(-strokewidth)] / 2.0}]
    set yc [expr {$yc + [winfo fpixels $wcan $Options(-strokewidth)] / 1.0}]
    return self
  }

  method resize {} {
    if {$fr == 1} {
	set wx [$wcan cget -width]
#Два справа???
	set hy [$wcan cget -height]
    } else {
	set wx [winfo fpixels $wcan $Options(-width)]
	set hy [winfo fpixels $wcan $Options(-height)]
    }

    foreach {x0 y0 x1 y1} [$wcan coords $idr] {break}
#puts "x0=$x0 y0=$y0 x1=$x1 y1=$y1"
    set swidth [$wcan itemcget $idr -strokewidth]
    if {$fr == 1} {
	set x1 [expr {$wx - $swidth}]
	set y1 [expr {$hy - $swidth}]
#puts "NEW x0=$x0 y0=$y0 x1=$x1 y1=$y1"
    } else {
	set x1 [expr {$x0 + $wx - $swidth}]
	set y1 [expr {$y0 + $hy - $swidth}]
    }

    $wcan coords $idr $x0 $y0 $x1 $y1
#    puts "1 WX=$wx HY=$hy"
  }

  method canvas {} {
    return $wcan
  }

  method type {} {
    return "cmenu"
  }
  
  method add {type {args "-text [self]"}} {
    set m2_s [winfo fpixels $wcan 2m]
    set m2 [winfo fpixels $wcan 2m]
    set m1 [winfo fpixels $wcan 1m]
#set m2 0
#    set xc [winfo fpixels $wcan 3m]
#puts "add type=$type args=$args m2=$m2 xc=$xc yc=$yc"
    set srect [$wcan create prect 0 0 10 10 -stroke ""]
    if {[llength $args] == 1} {
	set args [lindex "$args" 0]
    }
#puts "args=\"$args\""
    set cbut ""
    switch $type {
	check {
#puts "check=$type args=[lindex $args 0]"	
    	    set cbut [eval "cbutton new $wcan -type check -x $xc -y $yc -stroke \"$Options(-stroke)\"  $args  -height $Options(-height) -fontsize $Options(-fontsize)"]
	    lappend listmenu $cbut
	}
	radio {
#puts "radio=$type"	
    	    set cbut [eval "cbutton new $wcan -type radio -x $xc -y $yc -stroke \"$Options(-stroke)\" $args" -height $Options(-height) -fontsize $Options(-fontsize)]
	    lappend listmenu $cbut
	}
	submenu -
	cascade {
#puts "cascade|submenu=$type"
	    set ind [lsearch $args "-menu"]
    	    if {$ind > -1} {
#		incr ind
		set args [lreplace $args $ind $ind]
		set menu [lindex $args $ind]
		set args [lreplace $args $ind $ind]

    		set cbut [eval "cbutton new $wcan -type rect -x $xc -y $yc -ipad \"$Options(-pad)\" -stroke \"$Options(-stroke)\" $args"]
#    		$cbut config -image "$wcan $srect"
		lappend listmenu $cbut
#Ниже две строки равнозначны.
#Сгененить конанду при наведении появляется меня или оставить при нажатии
#		eval "$cbut config -command {puts \\\"Submenu menu=$menu\\\"}"
#		$cbut config -command "[subst {puts \\\{Submenu menu=[set menu] but=[set cbut]\\\}}]"

#		set cmd "set wc \[winfo width $wcan\];set xc \[winfo width $wcan\];;set yc [winfo width $wcan] "

	    } else {
#puts "metod add cascade: нет опции -menu"
		error "cmanu: bad add cascade: add cascade -menu ..."
	    }
#puts "cascade|submenu: cmenubut=[self] menu=$menu args=$args win=[my canvas] wcan=$wcan but=$cbut"
	    
	}
	command {
#puts "command=$type"	
    	    set cbut [eval "cbutton new $wcan -type rect -x $xc -y $yc -pad \"$Options(-pad)\" -stroke \"$Options(-stroke)\" $args"  -fontsize $Options(-fontsize)]
	    if {[$cbut config -image] == ""} {
    		$cbut config -image "$wcan $srect"
	    }
#    		$cbut config -image "$wcan $srect"
    	    
	    lappend listmenu $cbut
	}
	separator {
#puts "command=$type"	
    	    set cbut [cbutton new "$wcan" -type rect -x 0 -y [expr {$yc + $m1}] -command "" -text "" -height 0.5m -fillenter "##" -fillpress "##" -fillnormal gray80]
	    $cbut config $args
    	    
    	    $cbut config -width [expr {[winfo fpixels $wcan [$cbut config -width]] + $xc}] -stroke [$cbut config -fillnormal] -fillenter "##"
	    lappend listmenu $cbut
	}
	callout -
	finish {
	    set old 0
#Определяем список объектов с тэгом canvasbXXX, которые входят в меню
	    set listtag ""
	    foreach obj $listmenu {
		append listtag "canvasb[string range $obj 6 end] "
	    }
#Высчитываем размеры холста сообщения
# 0 - группа, которая включает в себя все объекты холста
#    foreach {x0 y0 x1 y1} [$wcan bbox 0] {}
#    foreach {x0 y0 x1 y1} [$wcan bbox canvasb] {}

#Учесть толщину строки
	    set  strw [winfo pixels $wcan $Options(-strokewidth)]

	    foreach {x0 y0 x1 y1} [eval $wcan bbox $listtag] {
#puts "cmenu place: x0=$x0 x1=$x1 y0=$y0 y1=$y1 listtag=$listtag"
		set wx [expr {$x1 - $x0}]
		set wxAll [expr {$x1 - $x0}]
		set hy [expr {$y1 - $y0}]
	    }

	    foreach {p1x p2x p3x theight } $Options(-tongue) {break}
	    set htongue [expr {int ([winfo fpixels $wcan $theight])}]
#Возврат в начальную точку
	    foreach {bx0 by0 bx1 by1} [$wcan bbox all] { 
#puts "Смещение bx0=$bx0 by0=$by0 bx1=$bx1 by1=$by1 old=$old"
		break 
	    }
	    set direction $Options(-direction)
	    switch $direction {
		down {
		    set hy [expr {$hy + $htongue + 20}]
		}
		up {
		    set hy [expr {$hy + $htongue +20}]
		    $wcan move 0 0 $htongue
#puts "place up htongue=$htongue"
		}
		right {
		    set wx [expr {$wx + $htongue}]
		}
		left {
		    set wx [expr {$wx + $htongue}]
		    if {$old == 1} {
			$wcan move 0 [expr {$htongue * -1}] 0
		    } else {
			$wcan move 0 $htongue 0
		    }
		}

		default {
puts "cmenu finish: uuncnown direction=$direction"
		}
	    }
	    set  strw2 [expr {$strw / 2.0}]
#  -fillnormal $Options(-fillnormal)
	    set cbut [mbutton new $wcan -type $direction -x $strw2 -y $strw2 -fillnormal $Options(-fillnormal) -fillenter "##" -fillpress "##" -strokewidth $Options(-strokewidth) -stroke $Options(-stroke) \
		-command "$Options(-command)" -tongue "$Options(-tongue)" -text "" -width [expr {$wx + $bx0 }] -height [expr {$hy + $by0 + $m3}]]
#puts "cmenu finish: wcan=$wcan cbut=$cbut IDOR=[$wcan find withtag IDOR]"

	    set wmax [expr {$wx + $bx0 }]
#puts "Place wx=$wx bx0=$bx0 m2=$m2 wmax=$wmax tongue=\"$Options(-tongue)\""
#Длина разделителя - separator
	    set wstr [winfo fpixels $wcan $Options(-strokewidth)]
	    foreach {obj} $listmenu {
		set hs [$obj config -text]
		if {$hs == "separator"} {
		    $obj config -width $wmax -text ""
		} else {
		    set tp [$obj type]
		    if {$tp != "check" && $tp != "radio"} {
			$obj config -width [expr {$wx - abs($bx0) - $wstr * 1 }]
		    }
#подвески строк в меню Цвет - #3584e4 синий
#Создание прямоугольника над строкой меню
		    set bcol "#3584e4"
		    set otag "canvasb[string range $obj 6 end]"
		    foreach {x0 y0 x1 y1} [$wcan bbox "canvasb[string range $obj 6 end]"] {break}
			$wcan raise $otag
		    if {[$obj config -fillenter] != "##"} {
			set brect [[$obj canvas] create prect 0 [expr {$y0 + 2}] $wmax [expr {$y1 - 2}] -fill {} -fillopacity 0.2 -strokeopacity 0.2 -stroke {} -strokewidth 0]
#Курсор на строке, вне ее, щелчек по кнопке
			if {$tp != "check" && $tp != "radio"} {
			    eval "[$obj canvas] bind [set brect] <Enter> {[$obj canvas] itemconfigure [set brect] -fill [set bcol] -stroke [set bcol];[set obj] enter}"
			    eval "[$obj canvas] bind [set brect] <Leave> {[$obj canvas] itemconfigure [set brect] -fill {} -stroke {};[set obj] leave}"
			} else {
			    eval "[$obj canvas] bind [set brect] <Enter> {[$obj canvas] itemconfigure [set brect] -fill [set bcol] -stroke [set bcol]}"
			    eval "[$obj canvas] bind [set brect] <Leave> {[$obj canvas] itemconfigure [set brect] -fill {} -stroke {}}"
			}
			eval "[$obj canvas] bind [set brect] <ButtonPress-1> {[set obj] press}"
			eval "[$obj canvas] bind [set brect] <ButtonRelease-1> {[set obj] release %X %Y]}"
		    }
		}
	    }
	    set idr $cbut
	    lappend listmenu $cbut
	    set lmenu  $cbut
	    append lmenu " $listmenu"
	    set listmenu $lmenu
#puts "CMENU place wcan=$wcan listmenu=$listmenu"

#Устанавливаем размеры холста
	    set wx [expr {[$cbut config -width] + $strw}]
#puts "PLACE wx=$wx hy=$hy canvas=[$erlib canvas] htongue=$htongue direction=$direction"
	    if {$direction == "right" || $direction == "left"} {
		set wx [expr {$wx + $htongue}]
	    }
	    if {$direction == "left" } {
		$wcan move 0 $htongue 0
	    }

	    set hy [expr {[$cbut config -height] + $strw}]
#puts "PLACE wx=$wx hy=$hy canvas=[$erlib canvas]"
	    $wcan configure -width $wx -height $hy
	    set erlib $cbut
	}
	default {
	    error "cmanu: bad type=$type for add"
	}
    }
    $wcan delete $srect
    if {$cbut == ""} {
	return $cbut
    }
    if {$type != "separator" } {
	foreach {x0 y0 x1 y1} [[$cbut canvas] bbox all] {break}
	set yc [expr {$yc + [winfo fpixels $wcan [$cbut config -height]]}]

    } else {
	set yc [expr {$yc + [winfo fpixels $wcan [$cbut config -height]] + $m1 }]
    }
    
    return $cbut
  }

  method class {} {
    return $wclass
  }

  method menulist {} {
    return $listmenu
  }


  method invoke {} {
    if {[winfo manager $wcan] != ""} {
	if {[my config -command] != ""} {
	    eval [my config -command]
	}
    }
  }

  method config args {
    variable Options
#    set svgtype [list circle ellipse group path  pline polyline ppolygon prect ptext]
#pimage - это делается отдельно
    if {[llength $args] == 1} {
	set args [lindex "$args" 0]
    }
#puts "Config args=$args length=[llength $args]"
    if {[llength $args] == 0} {
	return [array get Options]
    }
    if {[llength $args] % 2 != 0} {
#Чтение значения аттрибута
	if {[llength $args] == 1} {
#puts "config $args : $Options($args)"
	    return $Options($args)
	}
#puts "cframe Error args length: $args"
      error "use is: <object> config ?-option value?...\nargs=$args" 
    }
    foreach {option value} $args {
        switch $option {
    	    -lockwindow {
    		set Options($option) $value
    	    }
    	    -height -
    	    -width {
    		set Options($option) $value
    	    }
	    -pad -
	    -strokewidth {
    		set Options($option) $value
    	    }
    	    -direction -
    	    -tongue {
    		set Options($option) $value
    	    }
    	    -menu {
    		set Options($option) $value
    	    }
    	    -command {
    		set Options($option) $value
		if {[winfo manager $wcan] != ""} {
		    $erlib config $option $value
		}
    	    }
	    -stroke -
    	    -fillnormal {
    		set Options($option) $value
		if {[winfo manager $wcan] != ""} {
		    $erlib config $option "$value"
		}
    	    }
    	    default {
    		puts "cmenu: Bad option $option args=$args"
    	    }
	}
    }
  }    

  destructor {
    foreach objmenu $listmenu {
	catch {$objmenu destroy}
    }
    [self] destroy
    destroy $wcan
  }
}

oo::class create cframe {
  variable wcan
  variable Options
  variable listmenu
  variable xc
  variable yc
  variable canvasb
  variable btag
  variable tbut
  variable idr
  variable idt
  variable bidt
  variable idtb
  variable geotop 
  variable wclass
#fr = 0 кнопки создаются на внешнем холсте
#fr - 1 кнопки создаются на внутреннем холсте для внешнего фрейма
  variable fr
  variable relwdt

  constructor {w {args ""}} {
    set wcan $w
    set fr 0
    set wclass "cframe"
    set xc0 0
    set yc0 0
    set type "frame"
    set ind [lsearch $args "-type"]
    if {$ind > -1} {
	incr ind
	set type [lindex $args $ind]
    }

    if {![winfo exists $wcan]} {
	tkp::canvas $wcan -bd 0 -highlightthickness 0
	$wcan configure -bg [[winfo parent $wcan] cget -bg]
	set fr 1
    } else {
	set ind [lsearch $args "-x"]
	if {$ind > -1} {
	    incr ind
	    set xc0 [lindex $args $ind]
	}
	set ind [lsearch $args "-y"]
	if {$ind > -1} {
	    incr ind
	    set yc0 [lindex $args $ind]
	}
	set xc0 [winfo fpixels $wcan $xc0]
	set yc0 [winfo fpixels $wcan $yc0]
    }
#Запоминаем геометрию главного окна
    set topw [winfo toplevel $wcan]
#    set geotop [lindex [split [wm geometry $topw] +] 0]
#    set geotop [wm geometry $topw]
    set geotop ""
#Вставить проверку wcan на canvas!!

    catch {unset Options}
    set tbut $type
#puts "CFRAME: type=$type tbut=$tbut args=$args fr=$fr "
    set Options(-strokewidth) 	0.5m
    set Options(-rx) 		2m
    set Options(-fillnormal) 	""
    set Options(-stroke)	cyan
#    set Options(-width)		10c
#    set Options(-height)	7c
    set Options(-width)		10m
    set Options(-height)	7m
    switch -- $::tcl_platform(platform) {
	"windows"        {
		set svgFont "Arial Narrow"
	    }
	"unix" - default {
		set svgFont "Nimbus Sans Narrow"
	    }
    }
    switch $type {
	clframe {
	    set Options(-fontfamily) "$svgFont"
	    set Options(-text) "label frame"
	    set Options(-fontsize) 3m
	    set Options(-filltext) "black"
	    set Options(-stroketext) "black"
	    set Options(-strokewidthtext) 0
	    set Options(-width)		10m
	    set Options(-height)	7m
	}
	ccombo -
	centry {
	    set Options(-rx)	1.5m
	    set Options(-text) ""
	    set  Options(-fontsize) 3m
	    set  Options(-values) ""
	}
	default {
	    set Options(-text) ""
	    set  Options(-fontsize) 0
	}
    }
    my config $args
    if {![info exists Options(-fillbox)]} {
	set Options(-fillbox) $Options(-fillnormal)
    }
    set strwidth [winfo fpixels $wcan $Options(-strokewidth)]
    if {$fr == 1} {
	set entwidth [winfo fpixels $wcan $Options(-width)]
	$wcan configure -width [expr {$strwidth + $entwidth}]
    }
    switch $type {
	clframe {
	    set fontsize [winfo fpixels $wcan $Options(-fontsize)]
	    set idt [$wcan create ptext 0 0 -textanchor nw -text $Options(-text) -fontsize $fontsize -fontfamily $Options(-fontfamily) ]
	    foreach {xy0 yt0 xt1 yt1} [$wcan bbox $idt] {break}
	    $wcan delete $idt
	    set ycoords [expr {($yt1 - $yt0) / 2.0 + $strwidth}]	
	}
	centry {
	    set fonte "Helvetica [winfo pixels $wcan $Options(-fontsize)]"
#puts "CENTRY font=$fonte="
	    set ycoords $strwidth
	    if {[info exists Options(-textvariable)]} {
		set cent [entry $wcan.entry -background snow -bd 0 -highlightthickness 0 -font "$fonte" -highlightbackground gray85 -highlightcolor skyblue -justify left -relief sunken -readonlybackground snow -textvariable $Options(-textvariable)]
	    } else {
		set cent [entry $wcan.entry -background snow -bd 0 -highlightthickness 0 -font "$fonte" -highlightbackground gray85 -highlightcolor skyblue -justify left -relief sunken -readonlybackground snow ]
	    }
	    pack $wcan.entry -in $wcan -fill x -expand 1 -padx 1.0m  -pady 1.0m
	    raise $wcan.entry
	}
	ccombo {
	    set fonte "Helvetica [winfo pixels $wcan $Options(-fontsize)]"
#puts "CENTRY font=$fonte="
	    set ycoords $strwidth
	    ttk::style configure My.TCombobox -borderwidth 0 -fieldbackground white -selectbackground white -selectborderwidth 0 -selectforeground black -padding 0 -arrowsize 5m -background white
	    ttk::style map My.TCombobox -fieldbackground { readonly white}
	    ttk::style map My.TCombobox -selectbackground {readonly white}
	    ttk::style map My.TCombobox -selectforeground {readonly black}
	    ttk::style map My.TCombobox -background {readonly white}
	    ttk::style map My.TCombobox -foreground {readonly black}
	    ttk::style map My.TCombobox -fieldbackground [list "readonly" "white"]
#Для Windows -focusfill == -fieldbackground
	    ttk::style map My.TCombobox -focusfill [list "readonly focus" "white"]

	    if {[info exists Options(-textvariable)]} {
		set cent [ttk::combobox $wcan.entry -style My.TCombobox -values "$Options(-values)" -font "$fonte" -textvariable $Options(-textvariable)]
	    } else {
		set cent [ttk::combobox $wcan.entry -style My.TCombobox -values "$Options(-values)" -font "$fonte"]
	    }
	    pack $wcan.entry -in $wcan -fill x -expand 1 -padx 1.0m  -pady 1.0m
	    raise $wcan.entry
	}
	default {
	    set ycoords $strwidth
	}
    }
    set crx [winfo fpixels $wcan $Options(-rx)]
    set canvasb "canvasb"

    if {$fr} {    
	set ch [$wcan cget -height]
	set cw [$wcan cget -width]
    } else {
	set ch [winfo fpixels $wcan $Options(-height)]
	set cw [winfo fpixels $wcan $Options(-width)]
    }
#puts "ch=$ch cw=$cw ycoords=$ycoords xc0=$xc0 yc0=$yc0 strwidth=$strwidth"
    set idr [$wcan create prect [expr {$xc0 + $strwidth * 0}] [expr {$yc0 + $ycoords}] [expr {$xc0 + $cw - $strwidth * 0}] [expr {$yc0 + $ch - $ycoords}]] 

    set btag "canvasb[string range [self] [string first Obj [self]] end]"
    $wcan itemconfigure $idr -fill $Options(-fillnormal) -stroke $Options(-stroke) -rx $crx -tags [list Rectangle obj $canvasb $btag [linsert $btag end frame] utag$idr]
    my changestrwidth $strwidth
    if {$tbut == "centry" || $tbut == "ccombo"} {
	set bg [$wcan.entry cget -background]
	$wcan itemconfigure $idr -fill $bg
    }
    set idr "utag$idr"
#Заголовок
    if {$tbut == "clframe"} {
	set idt [$wcan create ptext [expr {$xc0 + ($cw - $strwidth * 2) / 2.0}] [expr {$yc0 + 1}] -textanchor n -text $Options(-text) -fontsize $fontsize -fontfamily $Options(-fontfamily) -tags "$btag"]
    }
    if {$fr == 1} {
	eval "bind $wcan  <Configure> {[self] resize %w %h 0}"
    }

#puts "[self]"

    return self
  }
  method entry {} {
	if {$tbut != "centry" && $tbut != "ccombo"} {
	    return ""
	}
	return "$wcan.entry"
  }

  method resize {wx hy {from 1}} {
#puts "cframe resize: fr=$fr wx=$wx hy=$hy"
    set topw [winfo toplevel $wcan]
    set geotek [wm geometry $topw]
    set geotop $geotek
    
    if {$fr == 1} {
	set wx1 [winfo width $wcan]
#Два справа???
	set hy1 [winfo height $wcan]
    } else {
	set wx1 [winfo fpixels $wcan $Options(-width)]
	set hy1 [winfo fpixels $wcan $Options(-height)]
    }
#puts "cframe resize: fr=$fr wx=$wx hy=$hy wx1=$wx1 hy1=$hy1  idr=$idr"

    foreach {x0 y0 x1 y1} [$wcan coords $idr] {break}
#puts "x0=$x0 y0=$y0 x1=$x1 y1=$y1"
    set swidth [$wcan itemcget $idr -strokewidth]
    if {$fr == 1} {
	set x1 [expr {$wx - $swidth}]
	set y1 [expr {$hy - $swidth}]
#puts "NEW x0=$x0 y0=$y0 x1=$x1 y1=$y1"
    } else {
	set x1 [expr {$x0 + $wx - $swidth}]
	set y1 [expr {$y0 + $hy - $swidth}]
    }

    $wcan coords $idr $x0 $y0 $x1 $y1
    if {[info exists idr] && $tbut == "clframe"} {
	foreach {xc yc } [$wcan coords $idt] {break}
	if {$fr == 1} {
	    $wcan coords $idt [expr {($wx - $swidth * 2) / 2.0 }]   $yc
	} else {
	    $wcan coords $idt [expr {($x0 + $wx - $swidth * 2) / 2.0 }]   $yc
	}
    }
    if {[info exists bidt]} {
	my boxtext
    }
    
#    puts "1 WX=$wx HY=$hy"
    if {$from && $fr} {
	foreach {x1 y1 x2 y2} [$wcan bbox $btag] {break}
	$wcan configure -width [expr {$x2 + $x1}] -height [expr {$y2 + $y1}]
    }

  }

  method canvas {} {
    return $wcan
  }
  method boxtext {} {
    if {$tbut != "clframe"} {
	return
    }
    if {[info exists bidt]} {
	$wcan delete $bidt
    }

    foreach {xt0 yt0 xt1 yt1} [$wcan bbox $idt] {break}
    set bidt [$wcan create prect $xt0 $yt0 $xt1 $yt1 -strokewidth 0 -fill $Options(-fillbox) -tags $btag -stroke ""] 
    $wcan lower $bidt $idt
  }

  method type {} {
    return "$tbut"
  }
  method config args {
    variable Options
#    set svgtype [list circle ellipse group path  pline polyline ppolygon prect ptext]
#pimage - это делается отдельно
    if {[llength $args] == 1} {
	set args [lindex "$args" 0]
    }
#puts "Config args=$args length=[llength $args]"
    if {[llength $args] == 0} {
	return [array get Options]
    }
    if {[llength $args] % 2 != 0} {
#Чтение значения аттрибута
	if {[llength $args] == 1} {
#puts "config $args : $Options($args)"
	    return $Options($args)
	}
#puts "cframe Error args length: $args"
      error "use is: <object> config ?-option value?...\nargs=$args" 
    }
    foreach {option value} $args {
        switch $option {
	    -background -
	    -bg {
		if {$fr} {
		    set  Options($option) $value
		    $wcan configure -background $value
		}
	    }
	    -x -
	    -y {
    		if {[info exists idr] || $fr} {
    		    continue
    		}
		set  Options($option) $value
	    }
	    -type {
    		if {[info exists idr]} {
    		    continue
    		}
		set  Options($option) $value
	    }
	    -strokeopacity -
    	    -fillopacity {
    		if {$tbut == "clframe"} {
    		    set Options($option) $value
		    if {[info exists idr]} {
			$wcan itemconfigure $idr $option $value
		    }
		}
    	    }
    	    -relwidth {
    		    set Options($option) $value
    		    if {$value > 0 && $value <= 1.0} {
    			set relwdt $value
    		    } else {
    			set relwdt [winfo pixels $wcan $value]
    			set Options($option) $relwdt
    		    }
	    }
    	    -width -
    	    -height {
    		set Options($option) $value
		if {[info exists idr]} {
		    my resize [winfo pixels $wcan $Options(-width)] [winfo pixels $wcan $Options(-height)]
#		    my resize $Options(-width) $Options(-height)
		}
    	    }
        
    	    -fontsize {
    		if {$tbut == "clframe"} {
    		    set Options($option) $value
		    if {[info exists idt]} {
			$wcan itemconfigure $idt -fontsize [winfo fpixels $wcan $value]
			if {[info exists bidt]} {
			    my boxtext
			}
		    }
		} elseif {$tbut == "centry" || $tbut == "ccombo"} {
    		    set Options($option) $value
		}
    	    }
    	    -stroke {
    		set Options($option) $value
		if {[info exists idr]} {
		    $wcan itemconfigure $idr -stroke $value
		}
    	    }
    	    -text {
    		if {$tbut == "clframe"} {
    		    set Options($option) $value
		    if {[info exists idt]} {
			$wcan itemconfigure $idt -text $value
		    }
		    if {[info exists bidt]} {
			my boxtext
		    }
		}
    	    }
    	    -values {
    		if {$tbut != "ccombo"} {
    		    return
    		}
    		set Options($option) $value
    	    }
    	    -fillnormal {
    		set Options($option) $value
		if {[info exists idr]} {
		    $wcan itemconfigure $idr -fill $value
#????
		    if {$tbut != "clframe"} {
			[my canvas] configure -background $value
		    }
		}
    	    }
    	    -fillbox {
    		if {$tbut == "clframe"} {
    		    set Options($option) $value
		    if {[info exists bidt]} {
			$wcan itemconfigure $bidt -fill $value
		    }
		}
    	    }
	    -strokewidth {
    		set Options($option) $value
		if {[info exists idr]} {
		    my changestrwidth [winfo fpixels $wcan $value]
		}
    	    }
	    -textvariable {
		variable $value
    		set Options($option) $value
    		if {![info exists $value]} {
    		    set $value ""
    		}
#puts "VALUE textvariable ($value) -variable: [subst $$value]"
	    }
	    -rx {
		    set Options($option) $value
		    if {[info exists idr]} {
			$wcan itemconfigure $idr $option [winfo fpixels $wcan $value]
		    }
	    }
    	    default {
    		puts "cframe: Bad option $option"
    	    }
	}
    }	

  }
  method move {dx dy} {
    if {$fr == 0} {
	$wcan move $btag $dx $dy
    }
    return $btag
  }

  destructor {
    if {[winfo exist $wcan]} {
	$wcan delete $btag
	if {$fr == 1} {
	    bind $wcan  <Configure> {}
	    destroy $wcan
	}
    }
  }

}

oo::define mbutton {
    eval $methodman
}
oo::define cframe {
    eval $methodman
}
oo::define cmenu {
    eval $methodman
}

package provide svgwidgets 0.3.3
