#  Copyright (c) 2023-2025  Orlov Vladimir
#  
#  This file is distributed under BSD style license.
#
if {[catch {package require tko}]} {
    package require tkpath
}

package require treectrl

namespace eval ::svgwidget {
    set treemenu [list ]
    image create photo ::svgwidget::tpblank \
	-data {R0lGODlhFAAUAIAAAAAAAP///yH5BAkAAAAALAAAAAAUABQAAAIRhI+py+0Po5y02ouz3rz7rxUAOw==} \
	-gamma {1.0} -height {0}  -width {0}

    if {[catch {package present tko}]}  {
	set matrix "::tkp::matrix"
	set tkpath "::tkp::canvas"
    } {
#Используется пакет tko
	set matrix "::tko::matrix"
	set tkpath "::tko::path"
    }

proc clearclass {{wsclass "cbutton ibutton mbutton cmenu cframe"}}  {
    foreach {wclass} $wsclass {
	set listoo -1
	catch {set listoo [info class instances $wclass]}
	if {$listoo == -1} {
    	    error "svgwidget::clearclass: Unknown class=$wclass: must be \"\[cbutton\] \[ibutton\] \[mbutton\] \[cmenu\] \[cframe\]\""
    	    return
	}
	foreach {oo} $listoo {
	    $oo destroy
	}
    }
}
proc destroyclass {{wsclass "cbutton ibutton mbutton cmenu cframe"}}  {
    foreach {wclass} $wsclass {
	if {[catch {$wclass destroy}] == 1} {
    		error "svgwidget::destroyclass: Unknown class=$wclass: must be \"\[cbutton\] \[ibutton\] \[mbutton\] \[cmenu\] \[cframe\]\""
    		return
	}
    }
}

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
    if { [set [namespace current]::matrix] == "::tkp::matrix"} {
	set m [list {1.0 0.0} {-0.0 1.0} {0.0 0.0}]
    } else {
	set m [list 1.0 0.0 -0.0 1.0 0.0 0.0]
    }
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
#    set m1 [::tkp::matrix rotate $phi $xr $yr]
    set m1 [[set [namespace current]::matrix] rotate $phi $xr $yr]
	if {$retm != 0} {
	    return $m1
	}
#Читаем что было
    set mOrig [$w itemcget $id -m]
    if {$mOrig != ""} {
#	    set m1 [::tkp::matrix mult $mOrig $m1]
	    set m1 [[set [namespace current]::matrix] mult $mOrig $m1]
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
#    set m1 [::tkp::matrix rotate $phi $xr $yr]
    if {$::svgwidget::tkpath == "::tkp::canvas"} {
	set m1 [[set [namespace current]::matrix] rotate $phi $xr $yr]
    } else {
	set m1 [[set [namespace current]::matrix] rotate $deg $xr $yr]    
    }
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
  variable tkpath
  variable ptext
  variable pline
  variable prect
  variable ppolygon
  variable pimage
  variable matrix
  variable Canv
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
    if {[catch {package present tko}]}  {
#Используется пакет tkpath
	set tkpath "::tkp::canvas"
	set ptext "ptext"
	set pline "pline"
	set prect "prect"
	set ppolygon "ppolygon"
	set pimage "pimage"
	set matrix "::tkp::matrix"
    } else {
#Используется пакет tko
	set tkpath "::tko::path"
	set ptext "text"
	set pline "line"
	set prect "rect"
	set ppolygon "polygon"
	set pimage "image"
	set matrix "::tko::matrix"
    }
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
#    set  Options(-compound) "left"
    set  Options(-compound) "none"
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
	[set tkpath] $wcan -bd 0 -highlightthickness 0
#	tkp::canvas $wcan -bd 0 -highlightthickness 0

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
	    if {$fr == 1} {
		destroy $wcan
	    }
    	    error "Unknown type=$type: must be rect, round. ellipse, square, circle, check, radio, frame"
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
		set idt [$w create [set ptext] 3 3 -text "$Options(-text)" -fontfamily $Options(-fontfamily) -fontsize $fontsize -fill $Options(-textfill) -fontweight $Options(-fontweight)]
		set ww [winfo fpixels $wcan $Options(-width)]
		set hw [winfo fpixels $wcan $Options(-height)]

		if {[info exists idt] && $Options(-text) != ""} {
		    ::svgwidget::idrotate2angle $wcan $idt $Options(-rotate)
		}

		foreach {xt1 yt1 xt2 yt2} "0 0 0 0" {break}
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
    set idr [$wcan create [set prect] $x1 $y1 [expr {$x1 + $cw}] [expr {$y1 + $ch}] -stroke {} -strokewidth 0] 
    my changestrwidth
    foreach {xr1 yr1 wrr hrr} [$wcan coords $idr] {break}
    set xr2 [expr {$x1 + $wrr}]
    set yr2 [expr {$y1 + $hrr}]

#puts "cbutton type=$type x1=$x1 y1=$y1"
    set btag "canvasb[string range [self] [expr {[string last "::" [self]] + 2}] end]"

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
	set idm [$wcan create [set prect] [expr {$xr1 + $wrr / 4}] [expr {$yr1 + $wrr / 4}] [expr {$xr2 - $wrr / 4}] [expr {$yr2 - $wrr / 4}]  -strokewidth 0 -stroke ""]
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
    set idt [$w create [set ptext] $x $y -textanchor $anc -text "$Options(-text)" -fontfamily $Options(-fontfamily) -fontsize $fontsize -fill $Options(-textfill) -fontweight $Options(-fontweight)]
    $wcan itemconfigure $idt -tags [list text obj $canvasb $btag [linsert $btag end text] utag$idt]

    set idt utag$idt

    set idor [$wcan create [set prect] [$wcan coords $idr] -strokewidth 0 -stroke {} -rx $Options(-rx) -fillopacity 0 -strokeopacity 0 -fill red -tags [list idor obj $canvasb $btag [linsert $btag end idor]]]

    eval "$wcan bind $idor <Enter> {[self] enter}"
    eval "$wcan bind $idor <Leave> {[self] leave}"
    eval "$wcan bind $idor <ButtonPress-1> {[self] press}"
    eval "$wcan bind $idor <ButtonRelease-1> {[self] release %X %Y}"

    if {$tbut == "square" || $tbut == "citcle" || $tbut == "check" || $tbut == "radio"} {
	eval "$wcan bind $idt <Enter> {[self] enter}"
	eval "$wcan bind $idt <Leave> {[self] leave}"
    }
    $wcan itemconfigure $idr -fill $Options(-fillnormal) -stroke $Options(-stroke) -strokewidth [winfo fpixels $wcan $Options(-strokewidth)]
    if {$tbut == "ellipse"} {
	set ry [expr {[winfo fpixels $wcan $Options(-height)] / 2.0}]
	$wcan itemconfigure $idr -ry $ry
    }
#    puts "[self]"
#puts "COORDS 0: idr=$idr [$wcan coords $idr]  strokewidth=[$wcan itemcget $idr -strokewidth]"
set coordsidr [$wcan coords $idr]
    my config [array get Options]
    if {$tbut == "check"} {
	if {[info exists Options(-variable)] && [info exists $Options(-variable)]} {
	    set $Options(-variable) [set $Options(-variable)]
	}
    }

    if {$fr == 1} {
	eval "bind $wcan  <Configure> {[self] resize %w %h 0}"
#	eval "bind $wcan  <ButtonRelease> {[self] fon}"
    }
$wcan coords $idr "$coordsidr"
#puts "COORDS 1: SELF=[self]: idr=$idr= [$wcan coords $idr] strokewidth=[$wcan itemcget $idr -strokewidth]"
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
	disabled -
	hidden {
	    $wcan itemconfigure $btag -state $stat
	}
	default {
	    error "Bad state=$stat: must be normal, disabled, hidden"
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
	    if {$Options(-displaymenu) != "enter" && $Options(-displaymenu) != "enterhidden"} {
		return
	    }
	    if {$Options(-displaymenu) == "enter"} {
		foreach {xm ym } [my showmenu] {break}
	    } else {
		set objm [my config -menu]
		set teks [$objm config -state]
		if {$teks == "normal"} {
		    $objm config -state hidden
		} elseif {$teks == "hidden"} {
		    $objm config -state normal
		}
	    }
#	    puts "Method enter -> showmenu: Кнопка=[self] xm=$xm ym=$ym Options(-menu)=$Options(-menu)"
	} 
	if {$Options(-fillenter) == "##"} {
	    return
	}

	set strwidth [winfo fpixels $wcan $Options(-strokewidth)]
	my changestrwidth [expr {$strwidth + $strwidth / 2.0}]

	catch {$wcan itemconfigure $idr -fill $Options(-fillenter) -stroke $Options(-strokeenter)}
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
	if {$Options(-displaymenu) != "release" && $Options(-displaymenu) != "releasehidden"} {
	    return
	}
	if {$Options(-displaymenu) == "release"} {
	    foreach {xm ym } [my showmenu] {break}
	    if {$xm == -1 && $ym == -1} {
		puts "Method release -> sgowmenu: Кнопка=[self] xm=$xm ym=$ym Options(-menu)=$Options(-menu)"
		catch {$wcan itemconfigure $idr -fill $Options(-fillenter) -stroke $Options(-strokeenter)}
		return
	    }
	} else {
		set objm [my config -menu]
		set teks [$objm config -state]
		if {$teks == "normal"} {
		    $objm config -state hidden
		} elseif {$teks == "hidden"} {
		    $objm config -state normal
		}
	    }
#	puts "Method release -> sgowmenu: Кнопка=[self] xm=$xm ym=$ym Options(-menu)=$Options(-menu)"
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
#puts "SELF=[self] TBUT=$tbut wx=$wx hy=$hy W=[winfo width $wcan] H=[winfo height $wcan]"
    if {$tbut == "frame"}  {
	foreach {x0 y0 x1 y1} [$wcan coords $idr] {break}
#puts "x0=$x0 y0=$y0 x1=$x1 y1=$y1"
	set swidth [$wcan itemcget $idr -strokewidth]
	if {$fr == 1} {
	    set x1 [winfo width $wcan]
	    set y1 [winfo height $wcan]
	} else {
	    set wx [winfo fpixels $wcan $wx]
	    set hy [winfo fpixels $wcan $hy]
	    set x1 [expr {$x0 + $wx}]
	    set y1 [expr {$y0 + $hy}]
	}
	my config -width $x1 -height $y1
	return
    }
    if {$fr == 0} {
	return
    }
    set wx [winfo width $wcan]
    set hy [winfo height $wcan]

set swidth [winfo fpixels $wcan [my config -strokewidth]]
if {$hy <= [expr {$swidth * 2.0}] || $wx <= [expr {$swidth * 2.0}]} {
	    return
}

    if {![info exist Canv(W)]} {
	set Canv(W) [winfo pixels $wcan [my config -width]]
	set Canv(H) [winfo pixels $wcan [my config -height]]
	set Canv(X) [winfo rootx $wcan]
	set Canv(Y) [winfo rooty $wcan]
	set Canv(X1) [expr {$Canv(X) + $Canv(W)}]
	set Canv(Y1) [expr {$Canv(Y) + $Canv(H)}]
	set Canv(xscale) 1
    }
if {$Options(-text) != ""} {
      if {[catch {$wcan itemcget $idt -fontsize} result] == 0} {
	    set u $idt
            set FontS($u,fontsize) $result
      }
}
if {0} {
   foreach id "[$wcan find withtag canvasb] [$wcan find withtag canvasi] [$wcan find withtag boxText]" {
      set type [$wcan type $id]
#puts "Canvasb id=$id type=$type"
      if {$type == "group"} {
	continue
      }
      if {[catch {$wcan itemcget $id -fontsize} result]==0} {
	    set u $id
            set FontS($u,fontsize) $result
      }
    }
}
#Ловим перемещение
    if {$Canv(X) != [winfo rootx $wcan] && $Canv(Y) != [winfo rooty $wcan] && $Canv(X1) != [expr {[winfo rootx $wcan] + [winfo width $wcan]}] && $Canv(Y1) != [expr {[winfo rooty $wcan] + [winfo height $wcan]}]} {
	if {$Canv(H) == $hy && $Canv(W) == $wx} {
	    set Canv(X) [winfo rootx $wcan]
	    set Canv(Y) [winfo rooty $wcan]
	    set Canv(W) [winfo width $wcan]
	    set Canv(H) [winfo height $wcan]
	    set Canv(X1) [expr {$Canv(X) + $Canv(W)}]
	    set Canv(Y1) [expr {$Canv(Y) + $Canv(H)}]
	    return
	}
    }
    if {$fr } {
	set bbox [$wcan bbox "canvasbfr"]
    } else {
	set bbox [$wcan bbox "canvasb"]
    }

    set BBox(x1) [lindex $bbox 0]
    set BBox(y1) [lindex $bbox 1]
    set BBox(x2) [lindex $bbox 2]
    set BBox(y2) [lindex $bbox 3]
#Scale через canvasb
    set dw [expr {$wx - $Canv(W)}]
    set dh [expr {$hy - $Canv(H)}]
    set xScale [expr {($BBox(x2) - $BBox(x1) + $dw) * 1.0 / ($BBox(x2) - $BBox(x1))}]
    set yScale [expr {($BBox(y2) - $BBox(y1) + $dh) * 1.0 / ($BBox(y2) - $BBox(y1))}]

    set Canv(H) $hy
    set Canv(W) $wx
    set Canv(X) [winfo rootx $wcan]
    set Canv(Y) [winfo rooty $wcan]
    set Canv(X1) [expr {$Canv(X) + $Canv(W)}]
    set Canv(Y1) [expr {$Canv(Y) + $Canv(H)}]

   set Canv(xscale) $xScale

##########################
    set wx [winfo fpixels $wcan $wx]
    set hy [winfo fpixels $wcan $hy]
    if {$wx < $onemm2px || $hy < $onemm2px} {
	return
    }

    if {$tbut == "radio" || $tbut == "circle" || $tbut == "check" || $tbut == "square" } {
	set yold [expr {[winfo fpixels $wcan $hy] / [winfo fpixels $wcan [my config -height] ]}]
	set wold [expr {([winfo fpixels $wcan $wx] - [winfo fpixels $wcan $hy]) / [winfo fpixels $wcan [my config -width]]}]
	if {$hy < $wx} {
	    set wx $hy
	}
    } else {
	set wold [expr {[winfo fpixels $wcan $wx] / [winfo fpixels $wcan [my config -width] ]}]
	set yold [expr {[winfo fpixels $wcan $hy] / [winfo fpixels $wcan [my config -height] ]}]
    }
    set strwidth [winfo fpixels $wcan [my config -strokewidth]]
    my config -width $wx  -height $hy

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
#    foreach {x1 xh y1 y2} [my config -ipad] {break} 
    lassign [my config -ipad] x1 xh y1 y2
if {1} {
    if {$tbut == "square" } {
	set wold $yold
	set ipad [expr {[winfo fpixels $wcan $x1] * $wold}]
    } else {
	set ipad [expr {[winfo fpixels $wcan $x1]}]
    }
}
    set ipad [expr {[winfo fpixels $wcan $x1] * $wold}]
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
#Пока отложим масштабирование шрифта
if {0} {
    if {$fr} {
#Масштабирования шрифта
	if {$Options(-text) != ""} {
    	    if {[catch {$wcan itemcget $idt -fontsize} result]==0} {
		set u $idt
    		set fsize [expr {$result * $Canv(xscale)}]
    		if {$fsize != $result} {
        	    $wcan itemconfigure $idt -fontsize $fsize
    		}
    	    }
	    catch {unset FontS}
	}
    }
}

  }

  method config args {
    if {$tkpath == "::tkp::canvas"} {
	set svgtype [list circle ellipse group path pline polyline ppolygon prect ptext]
    } else {
	set svgtype [list circle ellipse group path line polyline polygon rect text]    
    }

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
    		if {[lsearch [list "release" "enter" "releasehidden" "enterhidden"] $value] == -1} {
    		    error "Error for displaymenu ($value): -displaymenu \[ release | enter | releasehidden | enterhidden\]"
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
		
    		if {[info exists idr]} {
		    if { $tbut == "rect" && $Options(-isvg) == "" &&  $Options(-image) == "" && $Options(-text) != ""} {
    			my config -text $Options(-text)
    		    }
		    if {$Options(-isvg) != ""} {
    			my config -image "$wcan $Options(-isvg)"
		    } elseif {[info exists idi]} {
    			my config -image $Options(-image)
		    }
    		}
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
#		    foreach {xt1 yt1 xt2 yt2} [$wcan bbox $idt] {break}
		    
    		    if {[info exists idr] && ![info exists idi]} {
#Учесть координаты для compound - left и т.д.
    			foreach {x1 y1 x2 y2} [$wcan bbox $idr] {break}
    			set x2 [expr {$x1 + $x2}]
    			set y2 [expr {$y1 + $y2}]

#Создаём image!!!
			if {$tbut != "square"} {
			    set idi [$wcan create [set pimage] [expr {$x1 + $pxl}] [expr {$y1 + $pyl}] -image $Options(-image) -tintcolor $Options(-tintcolor) -tintamount 0.0  \
				-width $pwidth -height $pheight -anchor nw]
			} else {
			    set idi [$wcan create [set pimage] [expr {$x1 + $pxl}] [expr {$y1 + $pyl}] -image $Options(-image) -tintcolor $Options(-tintcolor) -tintamount 0.0  \
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
			$wcan coords $idi [expr {$x1 + $pxl}] [expr {$y1 + $pyl}]
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
#				    set y [expr { ($y1 + $y2) / 2.0}]
				    set y [expr { $y2 / 2.0}]
				    set tanchor  "w"
				}
				right {
#				    set y [expr { ($y1 + $y2) / 2.0}]
				    set y [expr { $y2 / 2.0}]
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
				    $wcan raise $idt $idr
    				    $wcan raise $idor
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
				foreach {tx1 ty1 tx2 ty2} "0 0 0 0" {break}
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
    			    set Options(-isvg) ""
#    			    unset Options(-isvg)
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
    		    foreach {rx1 ry1 rx2 ry2} [$wcan coords $idr] {break}
#		    set value [my copyItem $canv $item 0 0]
		    set value [my copyItem $canv $item $rx1 $ry1]

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
#		    $wcan itemconfigure $isvg -tags [list isvg obj $canvasb $btag [linsert $btag end isvg] utag$idt]
		    $wcan itemconfigure $isvg -tags [list isvg obj $canvasb [set btag]Group [linsert $btag end isvg] utag$idt]
		}
if {[$wcan bbox $isvg] != ""} {
    		foreach {sx1 sy1 sx2 sy2} [$wcan bbox $isvg] {break}
    		if {$tbut == "rect" } {
    		    foreach {rx1 ry1 rx2 ry2} [$wcan bbox $idr] {break}
    		    set rx2 [expr {$rx1 + $rx2}]
    		    set ry2 [expr {$ry1 + $ry2}]
    		} else {
    		    foreach {rx1 ry1 rx2 ry2} [$wcan bbox "$btag rect"] {break}
if {$fr == 1} {
    		    set rx2 [expr {$rx1 + $rx2}]
    		    set ry2 [expr {$ry1 + $ry2}]    		    
}
    		}
    		
		foreach {pxl pxr pyl pyr} [my config -ipad] {break}
		set pxl [winfo fpixels $wcan $pxl]
		set pxr [winfo fpixels $wcan $pxr]
		set pwidth $pxr
		set pyl [winfo fpixels $wcan $pyl]
    		set pyr [winfo fpixels $wcan $pyr]
		set pheight $pyr
if {[$wcan bbox $isvg] != ""} {
    		if {$tbut == "rect" } {
    		    set scalex [expr {$pwidth  / ($sx2 - $sx1 )}]
    		    set scaley [expr {$pheight / ($sy2 - $sy1 )}]
		} else {
    			set scalex [expr {($rx2 - $rx1 - ($pxr + $pxl)) / ($sx2 - $sx1 )}]
    			set scaley [expr {($ry2 - $ry1 - ($pyr + $pyl)) / ($sy2 - $sy1 )}]
		}
}
#puts "scalex=$scalex scaley=$scaley"
#Изменение размеров - ширины и высоты
		if {[$wcan itemcget $isvg -matrix] == ""} {
		    if {$tkpath == "::tkp::canvas"} {
			$wcan itemconfigure $isvg -matrix "{1 0} {0 1} {0 0}"
		    } else {
			$wcan itemconfigure $isvg -matrix "1 0 0 1 0 0"
		    }
		}
		lassign [$wcan itemcget $isvg -matrix]  w1 w0 h0 h1 x y
		set typec 0
		if {$h1 == ""} {
		    lassign "$h0" x y 
		    lassign "$w0" h0 h1 
		    lassign "$w1" w1 w0 
    		    set typec 1
		} 
		set w1 [expr {$w1 * $scalex}]
		set h1 [expr {$h1 * $scaley}]
		if {$typec == 1} {
		    $wcan itemconfigure $isvg -matrix [list "$w1 $w0" "$h0 $h1" "$x $y"]
		} else {
		    $wcan itemconfigure $isvg -matrix "$w1 $w0 $h0 $h1 $x $y"		
		}
if {[$wcan bbox $isvg] != ""} {
    		foreach {snx1 sny1 snx2 sny2} [$wcan bbox $isvg] {break}

#Перемещение по x и y
		if {[$wcan itemcget $isvg -matrix] == ""} {
		    if {$tkpath == "::tkp::canvas"} {
			$wcan itemconfigure $isvg -matrix "{1 0} {0 1} {0 0}"
		    } else {
			$wcan itemconfigure $isvg -matrix "1 0 0 1 0 0"
		    }
		}
		lassign [$wcan itemcget $isvg -matrix]  w1 w0 h0 h1 x y
		set typec 0
		if {$h1 == ""} {
		    lassign "$h0" x y 
		    lassign "$w0" h0 h1 
		    lassign "$w1" w1 w0 
    		    set typec 1
		} 
		set x [expr {$x + $rx1 - $snx1 + $pxl }]
		set y [expr {$y + $ry1 - $sny1 + $pyl}]
		if {$typec == 1} {
		    $wcan itemconfigure $isvg -matrix [list "$w1 $w0" "$h0 $h1" "$x $y"]
		} else {
		    $wcan itemconfigure $isvg -matrix "$w1 $w0 $h0 $h1 $x $y"		
		}

}
}
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
				    foreach {x1 y1 x2 y2} [$wcan bbox $idr] {break}
				    lassign [$wcan itemcget $isvg -matrix]  w1 w0 h0 h1 dxi dyi
				    set typec 0
				    if {$h1 == ""} {
					lassign "$h0" dxi dyi
					lassign "$w0" h0 h1 
					lassign "$w1" w1 w0 
    					set typec 1
				    } 
				    set dxi [expr {$x1 + $pxl + 2}]

				    if {$typec == 1} {
					$wcan itemconfigure $isvg -matrix [list "$w1 $w0" "$h0 $h1" "$dxi $dyi"]
				    } else {
					$wcan itemconfigure $isvg -matrix "$w1 $w0 $h0 $h1 $dxi $dyi"		
				    }

				    set x [expr {$ix2 + $pxl}]
				    set y [expr { ($y1 + $y2) / 2.0}]

				    set tanchor  "w"
				    set dy 0
				    set dx 0
				}
				right {
				    lassign [$wcan itemcget $isvg -matrix]  w1 w0 h0 h1 dxi dyi
				    set typec 0
				    if {$h1 == ""} {
					lassign "$h0" dxi dyi
					lassign "$w0" h0 h1 
					lassign "$w1" w1 w0 
    					set typec 1
				    } 

				    foreach {x1 y1 x2 y2} [$wcan bbox $idr] {break}
				    set dxi [expr {$x2 - $x1 - ($pxl + $pxr)}]
				    if {$typec == 1} {
					$wcan itemconfigure $isvg -matrix [list "$w1 $w0" "$h0 $h1" "$dxi $dyi"]
				    } else {
					$wcan itemconfigure $isvg -matrix "$w1 $w0 $h0 $h1 $dxi $dyi"		
				    }

				    foreach {ix1 iy1 ix2 iy2} [$wcan bbox $Options(-isvg)] {break}
				    set x [expr {$ix1 - $pxl}]
				    set y [expr { ($y1 + $y2) / 2.0}]
				    set tanchor  "e"
				    set dy 0
				    set dx 0
				}
				top {
				    set x [expr { ($rx1 + $rx2) / 2.0}]
				    set y [expr { $iy2 + $pyl * 0  }]
				    set tanchor  "n"
				    set dx 0 
				}
				bottom {
				    set x [expr { ($rx1 + $rx2) / 2.0}]
				    set y [expr { 0 + $pyl * 1.0 }]
				    set tanchor  "n"
				}
				none {
				    foreach {x1 y1 x2 y2} [$wcan bbox $idr] {break}
				    set x [expr { ($x1 + $x2) / 2.0}]
				    set y [expr { ($y1 + $y2) / 2.0}]
				    $wcan coords $idt "$x $y "
				    $wcan itemconfigure  $idt -textanchor c
				    $wcan raise $idt
				    $wcan raise $idor
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
				    foreach {xt1 yt1 xt2 yt2} "0 0 0 0" {break}
				    foreach {xt1 yt1 xt2 yt2} [$wcan bbox $idt] {break}
				    ::svgwidget::id2angleZero $wcan $idt
				    set dx 0
				    set dy [expr {$iy2 + $pyl - $yt1}]
				    $wcan move $idt $dx $dy
				    ::svgwidget::idrotate2angle $wcan $idt $Options(-rotate)
				}
				if {$Options(-compound) == "bottom"} {
				    lassign [$wcan bbox $idr] x1 y1 x2 y2
				    set dxi [expr {$x2 - $x1 - ($pxl + $pxr)}]
				    lassign   [$wcan bbox $idt] xt1 yt1 xt2 yt2				    
				    set dyi [expr {$yt2 - $yt1 + $pyl}]
				    if {$typec == 1} {
					$wcan itemconfigure $isvg -matrix [list "$w1 $w0" "$h0 $h1" "$dxi $dyi"]
				    } else {
					$wcan itemconfigure $isvg -matrix "$w1 $w0 $h0 $h1 $dxi $dyi"		
				    }
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
			    $wcan itemconfigure $btag -state $value
			}
		    }
		    default {
			error "Bad state=$value: must be normal, disabled, hidden"
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
			$wcan coords $idr $x1 $y1 [expr {$x2 - $strwidth / 2}]  [expr {$y2 - $strwidth }]
		    }
    		    continue
		} 
		if { $tbut == "rect" || $tbut == "round" || $tbut == "ellipse"} {
		    if {[info exists idr]} {
			foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
			set x2 [expr {$x1 + $val}]
#			$wcan coords $idr "$x1 $y1 [expr {$x2 - $strwidth / 2}]  [expr {$y2 - $strwidth}]"
			$wcan coords $idr $x1 $y1  [expr {$x2 - $strwidth / 2}]  [expr {$y2 - $strwidth }]
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
			my config -compound $Options(-compound)
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
#puts "WIDTH - COORDS 0: idr=$idr [$wcan coords $idr]  strokewidth=[$wcan itemcget $idr -strokewidth]"
			foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
			set x2 [expr {$x1 + $val}]
			set y2n [expr {$y1 + $val}]
			$wcan coords $idr "$x1 $y1 [expr {$x2 - $strwidth}] [expr {$y2n - $strwidth}]"
#puts "WIDTH 1 - COORDS 0: idr=$idr [$wcan coords $idr]  strokewidth=[$wcan itemcget $idr -strokewidth]"
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
			$wcan coords $idr $x1 $y1 [expr {$x2 - $strwidth / 2.0}]  [expr {$y2 - $strwidth}]
		    }
		    continue
		} 
		set scalexy [expr {$val / $valold}]
		if { $tbut == "rect" || $tbut == "ellipse" ||  $tbut == "round" } {
		    if {[info exists idr]} {
			foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
			set y2 [expr {$y1 + $val}]
#			$wcan coords $idr "$x1 $y1 [expr {$x2 - $strwidth / 2}]  [expr {$y2 - $strwidth}]"
			$wcan coords $idr $x1 $y1  [expr {$x2 - $strwidth / 2.0}]  [expr {$y2 - $strwidth}]
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
			    my config -compound $Options(-compound)
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
#puts "HEIGHT - COORDS 0: idr=$idr [$wcan coords $idr]  strokewidth=[$wcan itemcget $idr -strokewidth]"
			set x2 [expr {$x1 + $val}]
			set y2n [expr {$y1 + $val}]
			$wcan coords $idr "$x1 $y1 [expr {$x2 - $strwidth}] [expr {$y2n - $strwidth}]"
#puts "HEIGHT 1 - COORDS 0: idr=$idr [$wcan coords $idr]  strokewidth=[$wcan itemcget $idr -strokewidth]"
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
		    trace add variable $value write ::svgwidget::trace_rb
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
#$wcan itemconfigure  $idt -text $value
			foreach {xe0 ye0 xe1 ye1} "0 0 0 0" {break}
			foreach {xe0 ye0 xe1 ye1} [$wcan bbox $idt] {break}
			$wcan itemconfigure $idt $option $value
    			$wcan raise $idt $idr
			set xx [winfo pixels $wcan $Options(-width)]
			if {[$wcan bbox $idt] == ""} {
			    continue
			}
			foreach {xt0 yt0 xt1 yt1} "0 0 0 0" {break}
			foreach {xt0 yt0 xt1 yt1} [$wcan bbox $idt] { break}
		    
			if {$fr && $tbut != "round" && $tbut != "rect" && $tbut != "ellipse"} {
			    set xx [expr {$xx + ($xt1 - $xt0)}]
			    $wcan configure -width $xx
			} else {
			    set xx1 [expr {$xt1 - $xt0}]
			    if {$xx1 > $xx}  {
			    }
			}
###  COMPOUND ###########
			if { $tbut == "rect" && $Options(-isvg) == "" &&  $Options(-image) == "" } {
			    foreach {pxl pxr pyl pyr} $Options(-ipad) {break}
			    set pxl [winfo fpixels $wcan $pxl]
			    set pxr [winfo fpixels $wcan $pxr]
			    set pyl [winfo fpixels $wcan $pyl]
			    set pyr [winfo fpixels $wcan $pyr]
    			    foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
    			    set x2 [expr {$x1 + $x2}]
    			    set y2 [expr {$y1 + $y2}]
#Посчитать с учётом -ipad
#    			    foreach {xi1 yi1 xi2 yi2} [$wcan bbox $idr] {break}
    			    foreach {xi1 yi1 xi2 yi2} [$wcan coords $idr] {break}
#puts "COORDS IDR: xi1=$xi1 yi1=$yi1 xi2=$xi2 yi2=$xi2"
			    set x [expr {$xi2 + $pxl}]
			    set y [expr { ($y1 + $y2) / 2.0}]
			    set tanchor  "w"
			    switch $Options(-compound)  {
				left {
				    set x [expr {$xi1 + $pxl}]
				    set y [expr { $y2 / 2.0}]
				    set tanchor  "w"
				}
				right {
#				    set x [expr {$xi2 - $pxr - ($xt1 - $xt0) / 2}]
				    set x [expr {$xi2 - $pxl}]
				    set y [expr { $y2 / 2.0}]
				    set tanchor  "e"
#puts "COORDS IDR Right: x=$x y=$y tanchor=$tanchor pxl=$pxl xi2=$xi2"
				
				}
				top {
				    set x [expr { $x2 / 2.0}]
				    set y [expr { $yi1 + $pyl * 1 }]
				    set tanchor  "n"
				}
				bottom {
				    set x [expr { $x2 / 2.0}]
#				    set y [expr { $yi2 - $pyl - ($yt1 - $yt0)}]
#				    set tanchor  "n"
				    set y [expr { $yi2 - $pyl}]
				    set tanchor  "s"
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
				    set dy [expr {$yi1 + $pyl - $yt1}]
				    $wcan move $idt $dx $dy
				    ::svgwidget::idrotate2angle $wcan $idt $Options(-rotate)
				}
    				$wcan raise $idt $idr
			    }
    			    $wcan raise $idor
			}
################
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
	catch {$wcan delete $idi}
	
	if {$fr} {
    	    bind $wcan  <Configure> {}
	    destroy $wcan
	}
    }
  }
}

oo::class create ibutton {
  variable tkpath
  variable ptext
  variable pline
  variable prect
  variable ppolygon
  variable pimage
  variable matrix

#iidt - текст
#idr - прямоугольник вокруг картинки
#idor - прозрачный прямоугольник вокруг картинки
#idi - картинка
#idh - подсказка
  variable wcan
  variable Canv
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
  variable wpad
  
  constructor {w args} {
    if {[catch {package present tko}]}  {
#Используется пакет tkpath
	set tkpath "::tkp::canvas"
	set ptext "ptext"
	set pline "pline"
	set prect "prect"
	set ppolygon "ppolygon"
	set pimage "pimage"
	set matrix "::tkp::matrix"
    } else {
#Используется пакет tko
	set tkpath "::tko::path"
	set ptext "text"
	set pline "line"
	set prect "rect"
	set ppolygon "polygon"
	set pimage "image"
	set matrix "::tko::matrix"
    }

    catch {unset Options}
    set wpad 0
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
#	tkp::canvas $wcan -bd 0 -highlightthickness 0 
	[set tkpath] $wcan -bd 0 -highlightthickness 0 

	set strwidth [winfo fpixels $wcan $Options(-strokewidth)]
	set cwidth [winfo fpixels $wcan $Options(-width)]
	set cheight [winfo fpixels $wcan $Options(-height)] 
#	$wcan configure -width [expr {$strwidth * 2.0 + $cwidth}] -height [expr {$strwidth * 2.0 + $cheight}]
	$wcan configure -width $cwidth -height $cheight
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
        set x0 0
        set y0 0

        set fr 1
        append canvasb "fr"
    } else {
	set ind [lsearch $args "-x"]
	if {$ind > -1} {
	    incr ind
	    set x0 [winfo fpixels $wcan [lindex $args $ind]]
	}
	set ind [lsearch $args "-y"]
	if {$ind > -1} {
	    incr ind
	    set y0 [winfo fpixels $wcan [lindex $args $ind]]
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
    set wr [winfo fpixels $wcan $Options(-width)]
    set hr [winfo fpixels $wcan $Options(-height)]

    set x2 [expr {$x1 + $wr }]
    set y2 [expr {$y1 + $hr }]

    set idr [$wcan create [set prect] $x1 $y1 $x2 $y2 -strokelinecap butt -stroke {} -strokewidth 0]
    my changestrwidth

    foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
    set btag "canvasb[string range [self] [expr {[string last "::" [self]] + 2}] end]"

    $wcan itemconfigure $idr -fill $Options(-fillnormal) -strokelinejoin $Options(-strokelinejoin) -stroke $Options(-stroke)  -rx $Options(-rx) -tags [list Rectangle obj $canvasb $btag [linsert $btag end rect] utag$idr] -fill {}

    set idr "utag$idr"
#Метка кнопки
    set x [expr {$x2 + $onemm2px}]
    set y [expr { ($y1 + $y2) / 2.0}]
    set anc w 

    set imageOrig $Options(-image)
    set idi [$wcan create [set pimage] [expr {$x1 + $pxl }] [expr {$y1 + $pyl }] -image "::svgwidget::tpblank" -tintcolor $Options(-tintcolor) -tintamount 0.0  \
	-width [expr {$wr - ($pxl + $pxr) }] -height [expr {$hr - ($pyl + $pyr) }] -anchor nw]

    $wcan itemconfigure $idi -tags [list image obj canvasi $btag [linsert $btag end image] utag$idi]
    set idi "utag$idi"

    set ibox [$wcan bbox $idi]
#Если не менять размеры и координаты прямоугольника, то закомментировать
#    $wcan coords $idr $ibox
    
#    foreach {x1 y1 x2 y2} $ibox {break}
    foreach {x1 y1 x2 y2} [$wcan coords $idr] {break}
    set x [expr {$x2 + $onemm2px}]
    set y [expr { ($y1 + $y2) / 2.0}]

    
    set idt [$w create [set ptext] $x $y -textanchor $anc -text $Options(-text) -fontfamily $Options(-fontfamily) -fontsize [winfo fpixels $wcan $Options(-fontsize)]]
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

#    set $Options(-image) $imageOrig
#    my config -image $Options(-image)

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
	    if {$Options(-displaymenu) != "enter" && $Options(-displaymenu) != "enterhidden"} {
		return
	    }
	    if {$Options(-displaymenu) == "enter"} {
		foreach {xm ym } [my showmenu] {break}
		if {$xm == -1 && $ym == -1} {
		    puts "Method ibutton enter -> sgowmenu: Кнопка=[self] xm=$xm ym=$ym Options(-menu)=$Options(-menu)"
		    catch {$wcan itemconfigure $idr -fill $Options(-fillenter) -stroke $Options(-strokeenter)}
		    return
		}
	    } else {
		set objm [my config -menu]
		set teks [$objm config -state]
		if {$teks == "normal"} {
		    $objm config -state hidden
		} elseif {$teks == "hidden"} {
		    $objm config -state normal
		}
	    }
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
	    set idh [$wcan create [set ptext] $x0r [expr {$y0r - $twomm2px * 2}] -textanchor nw -text $Options(-help)]
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
    if {$fr == 0} {
	return
    }
#puts "RESIZE WIDTH=[winfo width $wcan] wx=$wx hy=$hy -width=$Options(-width)"
    set wxc [winfo fpixels $wcan $wx]
    set hyc [winfo fpixels $wcan $hy]
    if {$wxc < $onemm2px || $hyc < $onemm2px} {
	return
    }

    set strwidth [winfo fpixels $wcan [my config -strokewidth]]

    set wold [expr {$wxc / $wlast}]
#puts "WXC=$wxc WLAST=$wlast HYC=$hyc"
    set wlast $wxc
    set nfont [expr {[winfo fpixels $wcan $Options(-fontsize)] * $wold}]

    foreach {x1t y1t x2t y2t} [$wcan bbox "$btag text"] {break}
    if {![info exists x1t]} {
	foreach {x1t y1t x2t y2t} "0 0 0 0" {break}
    }
    if {[expr {$wxc - ($x2t - $x1t) }] < [expr {$strwidth * 2.0}] || $hyc < [expr {$strwidth * 2.0}] } {
	return
    }
    set yold [expr {$hyc / $hlast}] 
    set hlast $hyc
    set nwidth [expr {[winfo fpixels $wcan $wx] - ($x2t - $x1t)}]

    set nheight [winfo fpixels $wcan $hy]

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
	if {$Options(-displaymenu) != "release" && $Options(-displaymenu) != "releasehidden"} {
	    return
	}
	if {$Options(-displaymenu) == "release"} {
	    foreach {xm ym } [my showmenu] {break}
	    if {$xm == -1 && $ym == -1} {
		puts "Method ibutton release -> sgowmenu: Кнопка=[self] xm=$xm ym=$ym Options(-menu)=$Options(-menu)"
		catch {$wcan itemconfigure $idr -fill $Options(-fillenter) -stroke $Options(-strokeenter)}
		return
	    }
	} else {
		set objm [my config -menu]
		set teks [$objm config -state]
		if {$teks == "normal"} {
		    $objm config -state hidden
		} elseif {$teks == "hidden"} {
		    $objm config -state normal
		}
	}
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
    if {$tkpath == "::tkp::canvas"} {
	set svgtype [list circle ellipse group path pline polyline ppolygon prect ptext]
    } else {
	set svgtype [list circle ellipse group path line polyline polygon rect text]    
    }

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
    		if {[lsearch [list "release" "enter" "releasehidden" "enterhidden"] $value] == -1} {
    		    error "Error for ibutton displaymenu ($value): -displaymenu \[ release | enter | releasehidden | enterhidden\]"
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
				$wcan itemconfigure $btag -state $value
			}
		    }
		    default {
			error "Bad value=$value: must be normal, disabled, hidden"
		    }
		}
	    }
	    -isvg -
	    -image {
    		if {$value == ""} {
		    set value "::svgwidget::tpblank"
    		}
		set itype [catch {image type $value}]
		if {$itype == 0} {
    		    set Options($option) $value
    		    if {[info exists Options(-isvg)]} {
			$wcan delete $Options(-isvg)
    			set Options(-isvg) ""
#			catch {unset Options(-isvg)}
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
		set Options(-image) "$value"
		if {![info exists idr]} {
    		    puts "Not idr: -isvg Options(-isvg)=\"$value\""
    		    set Options($option) "$value"
		    continue
		}
		foreach {canv item} $value {break}
    		foreach {rx1 ry1 rx2 ry2} [$wcan coords $idr] {break}
#		set value [my copyItem $canv $item 0 0]
		set value [my copyItem $canv $item $rx1 $ry1]
		
    		set itype [$wcan type $value]
    		if {[lsearch $svgtype $itype] == -1} {
			error "ibutton: Bad svg image=$itype, value=$value"
    		}
    		set isvgold ""
    		if {[info exists Options(-isvg)]} {
    		    set isvgold $Options(-isvg)
    		    $wcan delete $isvgold 
    		}
		set  Options(-isvg) $value
    		set isvg $Options(-isvg)
#		$wcan itemconfigure $isvg -tags [list isvg obj $canvasb $btag [linsert $btag end isvg]]
		$wcan itemconfigure $isvg -tags [list isvg obj $canvasb [set btag]Group [linsert $btag end isvg]]

		my config -pad "$Options(-pad)"
		if {$idor > 0} {
		    $wcan delete $idor
		}
#Плюха в винде: тодщина строки в svg и обрамления вместо нуля остается фактически равной одному, поэтому далается пустая заливка
#		set idor [$wcan create prect [$wcan bbox $value] -strokewidth 0 -stroke {} -fillopacity 0 -strokeopacity 0 -fill red -tags [list isvg obj $canvasb $btag [linsert $btag end isvg]]]
		set idor [$wcan create [set prect] [$wcan coords $idr] -strokewidth 0 -stroke {} -fillopacity 0 -strokeopacity 0 -fill red -tags [list isvg obj $canvasb $btag [linsert $btag end isvg]]]
		eval "$wcan bind $idor <Enter> {[self] enter}"
		eval "$wcan bind $idor <Leave> {[self] leave}"
		eval "$wcan bind $idor <ButtonPress-1> {[self] press}"
		eval "$wcan bind $idor <ButtonRelease-1> {[self] release %X %Y}"

    		$wcan itemconfigure $idi -state hidden
#    		$wcan raise $isvg $idr
    		$wcan raise $idor
    		$wcan lower $isvg $idor

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
			set isvg $Options(-isvg)
			if {[$wcan bbox $isvg] != ""} {
			    set strwidth [winfo fpixels $wcan $Options(-strokewidth)]
    			    set isvg $Options(-isvg)
#puts "ibutton: -isvg ok isvg=$isvg idr=$idr"
    			    foreach {sx1 sy1 sx2 sy2} [$wcan bbox $isvg] {break}
    			    foreach {rx1 ry1 rx2 ry2} [$wcan bbox "$btag rect"] {break}
if {0} {
    			    foreach {rx1 ry1 rx2 ry2} [$wcan coords $idr] {break}
}
			    foreach {pxl pxr pyl pyr} $Options(-pad) {break}
			    set pxl [winfo fpixels $wcan $pxl]
			    set pxr [winfo fpixels $wcan $pxr]
			    set pyl [winfo fpixels $wcan $pyl]
    			    set pyr [winfo fpixels $wcan $pyr]

    			    set scalex [expr {($rx2 - $rx1 - ($pxr + $pxl) ) / ($sx2 - $sx1)}]
    			    set scaley [expr {($ry2 - $ry1 - ($pyr + $pyl) ) / ($sy2 - $sy1)}]
#Изменение размеров - ширины и высоты
#    			$wcan scale $isvg 0 0 $scalex $scaley
			    if {[$wcan itemcget $isvg -matrix] == ""} {
				if {$tkpath == "::tkp::canvas"} {
				    $wcan itemconfigure $isvg -matrix "{1 0} {0 1} {0 0}"
				} else {
				    $wcan itemconfigure $isvg -matrix "1 0 0 1 0 0"
				}
			    }
			    lassign [$wcan itemcget $isvg -matrix]  w1 w0 h0 h1 x y
			    set typec 0
			    if {$h1 == ""} {
				lassign "$h0" x y 
				lassign "$w0" h0 h1 
				lassign "$w1" w1 w0 
    				set typec 1
			    } 
			    set w1 [expr {$w1 * $scalex}]
			    set h1 [expr {$h1 * $scaley}]
			    if {$typec == 1} {
				$wcan itemconfigure $isvg -matrix [list "$w1 $w0" "$h0 $h1" "$x $y"]
			    } else {
				$wcan itemconfigure $isvg -matrix "$w1 $w0 $h0 $h1 $x $y"		
			    }

if {0} {
			    foreach {width height xy} [$wcan itemcget $isvg -matrix] {
				foreach {w1 w0} $width {
				    set w1 [expr {$w1 * $scalex}]
				}
				foreach {h0 h1} $height {
				    set h1 [expr {$h1 * $scaley}]
				}
				$wcan itemconfigure $isvg -matrix [list "$w1 $w0" "$h0 $h1" "$xy"]
			    }
}			    
			    if {[$wcan bbox $isvg] != ""} {
    				foreach {snx1 sny1 snx2 sny2} [$wcan bbox $isvg] {break}
#Перемещение по x и y
				if {[$wcan itemcget $isvg -matrix] == ""} {
				    if {$tkpath == "::tkp::canvas"} {
					$wcan itemconfigure $isvg -matrix "{1 0} {0 1} {0 0}"
				    } else {
					$wcan itemconfigure $isvg -matrix "1 0 0 1 0 0"
				    }
				}
				lassign [$wcan itemcget $isvg -matrix]  w1 w0 h0 h1 x y
				set typec 0
				if {$h1 == ""} {
				    lassign "$h0" x y 
				    lassign "$w0" h0 h1 
				    lassign "$w1" w1 w0 
    				    set typec 1
				} 
				set x [expr {$x + $rx1 - $snx1 + $pxl }]
				set y [expr {$y + $ry1 - $sny1 + $pyl }]
				if {$typec == 1} {
				    $wcan itemconfigure $isvg -matrix [list "$w1 $w0" "$h0 $h1" "$x $y"]
				} else {
				    $wcan itemconfigure $isvg -matrix "$w1 $w0 $h0 $h1 $x $y"		
				}
if {0} {
				foreach {width height xy} [$wcan itemcget $isvg -matrix] {
				    foreach {x y} $xy {
					set x [expr {$x + $rx1 - $snx1 + $pxl }]
					set y [expr {$y + $ry1 - $sny1 + $pyl }]
				    }
			
				    $wcan itemconfigure $isvg -matrix [list "$width" "$height" "$x $y"]
				}
}
			    }
			}
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
		    set x2 [expr {$x1 + $val}]
		    $wcan coords $idr $x1 $y1 [expr {$x2 - $strwidth / 2}] $y2
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
		    set y2 [expr {$y1 + $val}]
		    $wcan coords $idr $x1 $y1 $x2 [expr {$y2 - $strwidth / 2}]
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
set ::copycanitem {
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
#Добавить tags
    set btag "canvasb[string range [self] [expr {[string last "::" [self]] + 2}] end]"

    $wcan itemconfigure $copytag -tags [list $type obj $canvasb $btag [linsert $btag end frame] utag$copytag]
    $wcan itemconfigure $copytag -parent $grnew
    foreach {x1 y1 x2 y2} [$wcan bbox $grnew] {break}
    
    set dx [expr { [winfo fpixels $wcan $x0] - $x1}] 
    set dy [expr { [winfo fpixels $wcan $y0] - $y1}]

    $wcan move $copytag $dx $dy

    foreach {x1 y1 x2 y2} [$wcan bbox $grnew] {break}
    set dx0 [expr {$x0 - $x1 }]
    set dy0 [expr {$y0 - $y1 }]
    if {$tkpath == "::tkp::canvas"} {
	$wcan itemconfigure $copytag -m [list {1 0} {0 1} "[set dx0] [set dy0]"]
    } else {
	$wcan itemconfigure $copytag -m "1 0 0 1 [set dx0] [set dy0]"
    }


#    $wcan itemconfigure $copytag -m [list {1 0} {0 1} "[set dx0] [set dy0]"]
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
#	    if {[lindex $conf 0] == "-matrix"} {continue}
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
	append command [subst " $options  -parent $grnew"]
#Создаем объект
	set copytag [eval $command]
	if {$copytag == ""} {return -1}
#Добавить tags
	set btag "canvasb[string range [self] [expr {[string last "::" [self]] + 2}] end]"

	$wcan itemconfigure $copytag -tags [list $type obj $canvasb $btag [linsert $btag end frame] utag$copytag]
    }
#Ставим группу в нужное место
    foreach {x1 y1 x2 y2} [$wcan bbox $grnew] {break}
    set dx [expr { [winfo fpixels $wcan $x0] - $x1}] 
    set dy [expr { [winfo fpixels $wcan $y0] - $y1}]

    foreach {x1 y1 x2 y2} [$wcan bbox $grnew] {break}
    set dx0 [expr {$x0 - $x1 }]
    set dy0 [expr {$y0 - $y1 }]
    if {$tkpath == "::tkp::canvas"} {
	$wcan itemconfigure $grnew -m [list {1 0} {0 1} "[set dx0] [set dy0]"]
    } else {
	$wcan itemconfigure $grnew -m "1 0 0 1 [set dx0] [set dy0]"
    }

    return $grnew
  }

}
oo::define ibutton {
    eval $::copycanitem
}
oo::define cbutton {
    eval $::copycanitem
}

set ::methodman {
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
    if {$wclass == "mbutton"} {
	return
    }
#puts "changestrwidth tsw=$tsw nst=$nst"
    if {$tsw == $nst} {
	return
    }
#Восстанавливаем начальные координаты прямоугольника
    foreach {x0 y0 x1 y1} [$wcan coords $idr] {break}
    set wtstr [$wcan itemcget $idr -strokewidth]
#puts "changestrwidth nst=$nst x0=$x0 y0=$y0 x1=$x1 y1=$y1 wtstr=$wtstr"
    set wtstr [expr {$wtstr / 2.0}]

    set x0 [expr {$x0 - $wtstr}]
    set y0 [expr {$y0 - $wtstr}]
    set x1 [expr {$x1 + $wtstr}]
    set y1 [expr {$y1 + $wtstr}]
#Вычисляем новые координаты
    set nst1 [expr {$nst / 2.0}]
    set x0 [expr {$x0 + $nst1}]
    set y0 [expr {$y0 + $nst1}]
    set x1 [expr {$x1 - $nst1}]
    set y1 [expr {$y1 - $nst1}]
#Выставляем прямоугольник
    $wcan coords $idr $x0 $y0 $x1 $y1
    if {[winfo manager $wcan] != "UXTY"} {
	if {!$Options(press)} {
	    $wcan itemconfigure $idr -strokewidth $nst
	}
    }
  }
 
  method manager {type args} {
#puts "MANAGER wcan=$wcan fr=$fr type=$type args=$args"
    if {$fr == 0} {
	return
    }
    if {$wclass == "mbutton" || $wclass == "cmenu"} {
	foreach {x0 y0 x1 y1} [$wcan bbox 0] {break}
#	$wcan configure -width [expr {$x1 + $x0}] -height [expr {$y1 + $y0}]
	$wcan configure -width $x1  -height $y1
    }

    if {[winfo manager $wcan] == ""} {
	    eval $type $wcan [lindex $args 0]
	    lower $wcan
	    update
    }
############################
    if {$wclass == "cbutton"} {
	set strw [$wcan itemcget $idr -strokewidth]
	set ww [expr {[winfo width $wcan] - $strw}]
	set hh [expr {[winfo height $wcan] - $strw}]
	if {$ww > 0 && $hh > 0} {
	    my config -width $ww -height $hh
	    update
	}
    }
    $wcan delete fon
    my fon

  }
#Какие svg-щбъекты размещены в окне текущего svg-щбъекта
  method slavesoo {} {
    set man [winfo manager $wcan]
    if { $man == ""} {
	return ""
    }
#    return [$man slaves $wcan]
#Возврат дочерних объектов
#Дочерние окна
    set slaves [$man slaves $wcan]
#Все svg-объекты
    set allobj ""
    foreach {wclass} "cbutton ibutton mbutton cmenu cframe" {
	set listoo -1
	set listoo [info class instances $wclass]
	foreach {oo} $listoo {
	    foreach ww $slaves {
		if {[$oo canvas] == $ww } {
		    lappend allobj $oo
		}
	    }
	}
    }
    return $allobj
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
    set pars [$man info $wcan]
    set lwin ""
    set ind [lsearch $pars "-in"]
    if {$ind > -1} {
	incr ind
	set lwin [lindex $pars $ind]
    }
    return $lwin
  }

 method fon {} {
    $wcan delete fon
    update
    set rx [winfo rootx $wcan]
    set ry [winfo rooty $wcan]

    set wb [winfo width $wcan]
    set hb [winfo height $wcan]

#set hb [expr {$hb - 1}]
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
	raise $wcan 
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
    eval $::methodman
}
oo::define cbutton {
    eval $::methodman
}

set ::methshowmenu {

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
	    wm geometry $tlm +$rootx+$rooty
#	    set tlb [[my config -menu] config -lockwindow]
	    set tlb [winfo toplevel $wcan]

	    set ptlb [winfo toplevel $tlb]
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
		set bconf [bind [set ptlb]_Busy <Configure>]
		set bfoc [bind [set ptlb]_Busy <FocusOut>]
	    } else {
		set brel [bind [set ptlb]._Busy <ButtonRelease>]
		set bconf [bind [set ptlb]._Busy <Configure>]
		set bfoc [bind [set ptlb]._Busy <FocussOut>]
	    }
	    if { $sttlb } {
		if {$ptlbw != $ptlb ||  $ptlb == "."} {
		    eval "bind [set ptlb]_Busy <ButtonRelease> {bind [set ptlb]_Busy <ButtonRelease> {$brel}; tk busy forget $ptlb; wm state $tlm withdraw}"
		    eval "bind [set ptlb]_Busy <Configure> {bind [set ptlb] <Configure> {$bconf};catch {tk busy forget $ptlb}; wm state $tlm withdraw}"
		    eval "bind [set ptlb] <FocusOut> {bind [set ptlb] <FocusOut> {$bfoc};catch {tk busy forget $ptlb}; wm state $tlm withdraw}"
		} else {
		    eval "bind [set ptlb]._Busy <ButtonRelease> {bind [set ptlb]._Busy <ButtonRelease> {$brel}; wm state $tlm withdraw;}"
		    eval "bind [set ptlb]._Busy <Configure> {bind [set ptlb] <Configure> {$bconf};catch {tk busy forget $ptlb}; wm state $tlm withdraw}"
		    eval "bind [set ptlb] <FocusOut> {bind [set ptlb] <FocusOut> {$bfoc};catch {tk busy forget $ptlb}; wm state $tlm withdraw}"
		}
	    } else {
		if {$ptlbw != $ptlb ||  $ptlb == "."} {
		    eval "bind [set ptlb]_Busy <ButtonRelease> {bind [set ptlb]_Busy <ButtonRelease> {$brel}; tk busy forget $ptlb; wm state $tlm withdraw};"
		    eval "bind [set ptlb]_Busy <Configure> {bind [set ptlb] <Configure> {$bconf};catch {tk busy forget $ptlb}; wm state $tlm withdraw}"
		    eval "bind [set ptlb] <FocusOut> {bind [set ptlb] <FocusOut> {$bfoc};catch {tk busy forget $ptlb}; wm state $tlm withdraw}"
		} else {
		    eval "bind [set ptlb]._Busy <ButtonRelease> {bind [set ptlb]._Busy <ButtonRelease> {$brel}; tk busy forget $ptlb; wm state $tlm withdraw};"
		    eval "bind [set ptlb]._Busy <Configure> {bind [set ptlb] <Configure> {$bconf};catch {tk busy forget $ptlb}; wm state $tlm withdraw}"
		    eval "bind [set ptlb] <FocusOut> {bind [set ptlb] <FocusOut> {$bfoc};catch {tk busy forget $ptlb}; wm state $tlm withdraw}"
		}
	    }
	    wm state $tlm normal
	  }
	    return "$rootx $rooty"
	} else {
		if {[my config -displaymenu] == "enter"} {
		    set tbind "<Enter>"
		} else {
		    set tbind "<ButtonRelease>"		
		}

	    if {[tk busy status $tlb]} {
		set sttlb 1
		set tlbw [winfo toplevel $tlb]
		if {$tlbw != $tlb ||  $tlb == "."} {
		    set brel "[bind [set tlb]_Busy $tbind]"
		} else {
		    set brel "[bind [set tlb]._Busy $tbind]"
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
		lappend ::svgwidget::treemenu $winm
		if {[my config -displaymenu] == "enter"} {
		    set tbind "<Enter>"
		} else {
		    set tbind "<ButtonRelease>"		
		}
		if { $sttlb } {
		    if {$tlbw != $tlb ||  $tlb == "."} {
#puts "STTLB 1 tlb=$tlb tlbw=$tlbw winm=$winm self=[self]"
			lower [set tlb]_Busy $winm
			eval "bind [set tlb]_Busy <ButtonRelease> {bind [set tlb]_Busy $tbind {$brel};place forget $winm;set ::svgwidget::treemenu \"[lreplace $::svgwidget::treemenu end end]\"; eval lower [set tlb]_Busy \[lindex \$::svgwidget::treemenu end]}"
		    } else {
#puts "STTLB 2 tlb=$tlb tlbw=$tlbw winm=$winm self=[self] displaymenu=[my config -displaymenu]"
			eval "bind [set tlb]._Busy $tbind {bind [set tlb]._Busy $tbind {$brel};place forget $winm}"
		    }
		} else {
		    if {$tlbw != $tlb ||  $tlb == "."} {
#puts "STTLB  No 1 tlb=$tlb tlbw=$tlbw winm=$winm self=[self]"

			eval "bind [set tlb]_Busy <ButtonRelease> {bind [set tlb]_Busy $tbind {$brel};tk busy forget $tlb; place forget $winm}"
		    } else {
#puts "STTLB No 2 tlb=$tlb tlbw=$tlbw winm=$winm self=[self]"
#Меню в своем окне
			eval "bind [set tlb] <Configure> {lower [set tlb]._Busy $winm}"
			eval "bind [set tlb]._Busy $tbind {bind [set tlb]._Busy $tbind {$brel};tk busy forget $tlb; place forget $winm;set ::svgwidget::treemenu \"[lreplace $::svgwidget::treemenu end end]\";bind [set tlb] <Configure> {}}"
		    }    
		}
	    }
	    return "$x $y"
	}
  }
  
}
set ::methscaleGroup {
  method scaleGroup {w h} {
    if {![info exist Canv(W)]} {
	set Canv(W) [winfo width $wcan]
	set Canv(H) [winfo height $wcan]
	set Canv(X) [winfo rootx $wcan]
	set Canv(Y) [winfo rooty $wcan]
	set Canv(X1) [expr {$Canv(X) + $Canv(W)}]
	set Canv(Y1) [expr {$Canv(Y) + $Canv(H)}]
	set Canv(xscale) 1
	return
    }
    if {[$wcan bbox "canvasb"] == "" } {
	return
    }
    set onemm2px [winfo fpixels $wcan 1m]
   foreach id "[$wcan find withtag canvasb] [$wcan find withtag canvasi] [$wcan find withtag boxText]" {
      set type [$wcan type $id]
#puts "Canvasb id=$id type=$type"
      if {$type == "group"} {
	continue
      }
      if {[catch {$wcan itemcget $id -fontsize} result]==0} {
	    set u $id
            set FontS($u,fontsize) $result
      }
    }
#Ловим перемещение
    if {$Canv(X) != [winfo rootx $wcan] && $Canv(Y) != [winfo rooty $wcan] && $Canv(X1) != [expr {[winfo rootx $wcan] + [winfo width $wcan]}] && $Canv(Y1) != [expr {[winfo rooty $wcan] + [winfo height $wcan]}]} {
	if {$Canv(H) == $h && $Canv(W) == $w} {
	    set Canv(X) [winfo rootx $wcan]
	    set Canv(Y) [winfo rooty $wcan]
	    set Canv(W) [winfo width $wcan]
	    set Canv(H) [winfo height $wcan]
	    set Canv(X1) [expr {$Canv(X) + $Canv(W)}]
	    set Canv(Y1) [expr {$Canv(Y) + $Canv(H)}]
	    return
	}
    }

    set bbox [$wcan bbox "canvasb"]
    set BBox(x1) [lindex $bbox 0]
    set BBox(y1) [lindex $bbox 1]
    set BBox(x2) [lindex $bbox 2]
    set BBox(y2) [lindex $bbox 3]
    set BBox(action) ""
#Scale через canvasb
    set dw [expr {$w - $Canv(W)}]
    set dh [expr {$h - $Canv(H)}]
    set xScaleW [expr {($BBox(x2) - $BBox(x1) + $dw) * 1.0 / ($BBox(x2) - $BBox(x1))}]
    set yScaleW [expr {($BBox(y2) - $BBox(y1) + $dh) * 1.0 / ($BBox(y2) - $BBox(y1))}]

    set x1 [winfo width $wcan]
    set y1 [winfo height $wcan]
    set x [winfo rootx $wcan]
    set y [winfo rooty $wcan]

    set Canv(H) $h
    set Canv(W) $w
    set Canv(X) [winfo rootx $wcan]
    set Canv(Y) [winfo rooty $wcan]
    set Canv(X1) [expr {$Canv(X) + $Canv(W)}]
    set Canv(Y1) [expr {$Canv(Y) + $Canv(H)}]
    set BBox(action) se

    set xOrigin $BBox(x1)
    set yOrigin $BBox(y1)
    set xScale $xScaleW
    set yScale $yScaleW

   set Canv(xscale) $xScale

   foreach id "[$wcan find withtag canvasb] [$wcan find withtag canvasi] [$wcan find withtag boxText]" {
        set type [$wcan type $id]
#puts "Canvasb id=$id type=$type  xScale=$xScale yScale=$yScale"
	set idgr [$wcan itemcget $id -parent]
	if {[lindex [$wcan itemcget $idgr -tag] 0] == "isvg"} {
		continue
	}

      if {$type == "group"} {
    	    set taggr [$wcan itemcget $id -tag]
    	    if {[lindex $taggr  0] != "isvg"} {
    		continue
    	    }
    	    set objgr "::oo::[string range [lindex $taggr  3] 7 end-5]"
    	    if {[$objgr type] == "ibutton"} {
    		set padgr [$objgr config -pad]
    	    } else {
    		set padgr [$objgr config -ipad]
    	    }
	    foreach {pxl pxr pyl pyr} $padgr {break}
	    set pxl [expr {[winfo fpixels $wcan $pxl] * $xScale }]
	    set pxr [expr {[winfo fpixels $wcan $pxr] * $xScale }]
	    set pyl [expr {[winfo fpixels $wcan $pyl] * $yScale }]
	    set pyr [expr {[winfo fpixels $wcan $pyr] * $yScale }]
    	    if {[$objgr type] == "ibutton"} {
		$objgr config -pad "$pxl $pxr $pyl $pyr"
    	    } else {
;
#		$objgr config -ipad "$pxl $pxr $pyl $pyr"
    	    }

    	    set gtag [lindex [lindex  [$wcan itemcget $id -tag] 4] 0]
    	    foreach {rx1 ry1 rx2 ry2} [$wcan bbox "$gtag rect"] {break}
    	    set scalex $xScale
    	    set scaley $yScale
#Изменение размеров - ширины и высоты
#Используется пакет tkpath
	if {$tkpath == "::tkp::canvas"} {
	    foreach {width height xy} [$wcan itemcget $id -matrix] {
		foreach {w1 w0} $width {
		    set w1 [expr {$w1 * $scalex}]
		}
		foreach {h0 h1} $height {
		    set h1 [expr {$h1 * $scaley}]
		}
		$wcan itemconfigure $id -matrix [list "$w1 $w0" "$h0 $h1" "$xy"]
	    }
	    if {[$wcan bbox $id] != ""} {
    		foreach {snx1 sny1 snx2 sny2} [$wcan bbox $id] {break}
#Перемещение по x и y
		foreach {width height xy} [$wcan itemcget $id -matrix] {
		    foreach {x y} $xy {
			set x [expr {$x + $rx1 - $snx1 + $pxl }]
			set y [expr {$y + $ry1 - $sny1 + $pyl}]
		    }
		    $wcan itemconfigure $id -matrix [list "$width" "$height" "$x $y"]
		}
	    }
	} else {
#Для пакета tko
	    if {[$wcan bbox $id] != ""} {
    		foreach {snx1 sny1 snx2 sny2} [$wcan bbox $id] {break}
		lassign [$wcan itemcget $id -matrix]  w1 w0 h0 h1 x y
		set w1 [expr {$w1 * $scalex}]
		set h1 [expr {$h1 * $scaley}]
		set x [expr {$x + $rx1 - $snx1 + $pxl }]
		set y [expr {$y + $ry1 - $sny1 + $pyl}]
		$wcan itemconfigure $id -matrix "$w1 $w0 $h0 $h1 $x $y"		
	    }
	}
	
	continue
      }
      
      if {[catch {$wcan itemcget $id -strokewidth} result]==0} {
	set stw [$wcan itemcget $id -strokewidth]
        $wcan itemconfigure $id -strokewidth [expr {$stw * $yScale * $xScale}]
      }

#      if {$type != "pimage" && $type != "polyline" && $type != "path"} { }
      if {$type != [set pimage] && $type != "polyline" && $type != "path"} {
	    $wcan scale $id $xOrigin $yOrigin $xScale $yScale
#	    if {$type == "ptext"} { }
	    if {$type == [set ptext]} {
    		$wcan coords $id [$wcan coords $id]
    	    }
      } elseif {$type == "polyline" || $type == "path"} {
	    set st [$wcan itemcget $id -startarrow]
	    set et [$wcan itemcget $id -endarrow]
	    set aw [$wcan itemcget $id -startarrowwidth]
	    set al [$wcan itemcget $id -startarrowlength]
	    set af [$wcan itemcget $id -startarrowfill]
	
	    $wcan itemconfigure $id -startarrow 0
	    $wcan itemconfigure $id -endarrow 0
	    $wcan scale $id $xOrigin $yOrigin $xScale $yScale
	    $wcan itemconfigure $id  -startarrow $st -startarrowlength [expr {$al * $xScale}] -startarrowwidth [expr {$aw * $yScale}] 
	    $wcan itemconfigure $id -endarrow $et -endarrowlength [expr {$al * $xScale}] -endarrowwidth [expr {$aw * $yScale}]
      }
#Добавить в tksvgpaint
#      if {$type == "prect"} { }
      if {$type == [set prect]} {
	set rx [$wcan itemcget $id -rx]
	set ry [$wcan itemcget $id -ry]
	$wcan itemconfigure $id -rx [expr {$rx * $xScale}] -ry [expr {$ry * $yScale}]
#Сюда вставим обработку entry
	set tagr [$wcan itemcget $id -tags]
	set centry [lsearch $tagr "centry"]
	if {$centry == -1} {
	    set centry [lsearch $tagr "cspin"]
	}
	if {$centry == -1} {
	    set centry [lsearch $tagr "ccombo"]
	}
	if {$centry > -1} {
	    set obj [string range [lindex $tagr 3] 7 end]
	    set sto [$wcan itemcget [lindex $tagr 5] -state]
	    if {$sto != "hidden"} {
		foreach {rx0 ry0 rx1 ry1} [$wcan coords [lindex $tagr 5]] {
#			puts "TAGS=$tagr obj=$obj"
		    place configure $wcan.entry$obj -width [expr {$rx1 - $rx0 - $onemm2px * 4}] -height [expr {$ry1 - $ry0 - $onemm2px * 2 }] -y [expr {$ry0 + $onemm2px  }] -x [expr {$rx0 + $onemm2px * 2 }]
		}
	    }
	}
      }
#      if {$type == "pimage"} { }
      if {$type == [set pimage]} {
#puts "PIMAGE id=$id"
	set name [$wcan itemcget $id  -image]
	set anch [$wcan itemcget $id  -anchor]
	set width [image width $name]
	set height [image height $name]
	set reg [$wcan itemcget $id  -srcregion]
	if {$reg == ""} {
	   set yScaleLast 1
	   set xScaleLast 1
	} else {
	    set wreg [lindex $reg 2]
	    set hreg [lindex $reg 3]
	    set wimg [$wcan itemcget $id  -width]
	    set himg [$wcan itemcget $id  -height]
	    if {$wimg == 0} {
		set xScaleLast 1.0
	    } else {
		set xScaleLast [expr {$wimg * 1.0 / $wreg}]
	    }
	    if {$himg == 0} {
		set yScaleLast 1.0
	    } else {
		set yScaleLast [expr {(1.0 * $himg) / (1.0 * $hreg)}]
	    }
	}
	set iwidth [expr {$width * $xScale * $xScaleLast}]
	set iheight [expr {$height * $yScale * $yScaleLast}]
#puts "PIMAGE xScale=$xScale yScale=$yScale xScaleLast=$xScaleLast  yScaleLast=$yScaleLast action=$BBox(action) width=$width height=$height iwidth=$iwidth iheight=$iheight"

	foreach {mx0  my0 mx1 my1} [$wcan bbox $id] {break}
	foreach {xc  yc} [::svgwidget::id2center $wcan $id] {break}

	$wcan itemconfigure $id  -width $iwidth -height $iheight -srcregion [list 0  0  $width $height]

	set tags "[$wcan itemcget $id -tags]"
	set ind [lsearch -regexp "$tags" {^canvasbObj}]
	if {$ind == -1} {
#	    set ind [lsearch -regexp "$tags" {^canvasb::}]
	    set ind [lsearch -regexp "$tags" {^canvasb.}]
	}
	set oid [lindex "$tags" $ind]
	if {[$wcan type "$oid image"] != ""} {
	    foreach {xr yr} [::svgwidget::id2center $wcan "$oid rect"] {break}
	    foreach {xi yi} [::svgwidget::id2center $wcan $id] {break}
	    $wcan move "$oid image" [expr {$xr - $xi }] [expr {$yr - $yi }]
	} else {
#puts "PIMAGE=$oid tags=$tags"
	    foreach {xi yi} [$wcan coords "$oid pimage"] {break}
	    foreach {x1 y1 x2 y2} [$wcan coords "$oid rect"] {break}

#Плясать от ipad и side
	    foreach {xr yr} [::svgwidget::id2center $wcan "$oid rect"] {break}
	    foreach {xi yi} [::svgwidget::id2center $wcan $id] {break}
	    foreach {xr yr xr1 yr1} [$wcan coords "$oid rect"] {break}
	    foreach {xi yi xi1 yi1} [$wcan bbox "$oid pimage"] {break}

	    $wcan move "$oid pimage" [expr {$xr - $xi * $xScale}] [expr {$yr - $yi * $yScale }]
	} 
    }
#Масштабирования шрифта
    if {[catch {$wcan itemcget $id -fontsize} result]==0} {
	set u $id
        set fsize [expr {$FontS($u,fontsize)*$Canv(xscale)}]
        if {$fsize != $result} {
            $wcan itemconfigure $id -fontsize $fsize
        }
      }
   }
    catch {unset FontS}
  }
  method resizeGroup {} {
    eval "bind $wcan <Configure> {[self] scaleGroup %w %h}"
  }
}
oo::define ibutton {
    eval $::methshowmenu
    eval $::methscaleGroup
}
oo::define cbutton {
    eval $::methshowmenu
    eval $::methscaleGroup
}
oo::class create mbutton {
  variable tkpath
  variable ptext
  variable pline
  variable prect
  variable ppolygon
  variable matrix
  variable pimage
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
    if {[catch {package present tko}]}  {
#Используется пакет tkpath
	set tkpath "::tkp::canvas"
	set ptext "ptext"
	set pline "pline"
	set prect "prect"
	set ppolygon "ppolygon"
	set matrix "::tkp::matrix"
	set pimage "pimage"
    } else {
#Используется пакет tko
	set tkpath "::tko::path"
	set ptext "text"
	set pline "line"
	set prect "rect"
	set ppolygon "polygon"
	set matrix "::tko::matrix"
	set pimage "image"
    }

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
#	tkp::canvas $wcan -bd 0 -highlightt 0
	[set tkpath] $wcan -bd 0 -highlightthickness 0
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
	    if {$fr == 1} {
		destroy $wcan
	    }
    	    error "mbutton: Unknown type=$type: must be msg, yesno, left, right, down, up"
	}
    
    } 

    set Options(-command) {}
    set btag "canvasb[string range [self] [expr {[string last "::" [self]] + 2}] end]"

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
#		set y2 [expr {$y1 + [winfo fpixels $wcan $Options(-height)] + 30}]
		set y2 [expr {$y1 + [winfo fpixels $wcan $Options(-height)] + 0}]
		set rx [winfo fpixels $wcan $Options(-rx)]
#Метка кнопки
#set testfont "sans-serif 12 normal"
		foreach {p1x p2x p3x theight } $Options(-tongue) {break}
		set htongue [winfo fpixels $wcan $theight]
		set xt [expr { $x1 + $rx }]
		set yt [expr { $y1 + $rx + $htongue}]
	    }
	default {
	    if {$fr == 1} {
		destroy $wcan
	    }
    	    error "mbutton 1: Unknown type=$type: must be msg, yesno, left, right, down, up"
	} 
    }   
#puts "TYPE=$type x1=$x1 y1=$y1 x2=$x2 y2=$y2"
    set d [my coordspath "$x1 $y1" "$x2 $y2" $rx "$Options(-tongue)" $type]
#puts "TYPE=$type path=$d"
    set idr [$wcan create path  "$d" -stroke {} -strokewidth 0] 
#$wcan lower $idr
    set strwidth [winfo fpixels $wcan $Options(-strokewidth)]
    $wcan itemconfigure $idr -fill white -stroke black -strokewidth $strwidth  -tags [list Rectangle obj $canvasb $btag [linsert $btag end frame] utag$idr]
    set idr "utag$idr"
#puts "MBUTTON: btag=$btag"
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
	if {$fr == 1} {
	    set yr2 [winfo pixels $wcan [my config -height]]
	}

	set idtyn [$w create [set ptext] $xr1 [expr {$yr2 - ( $hyesno / 2)}] -textanchor c -text "Нет" -fontfamily $Options(-fontfamily) -fontsize $fontsize]
	set boxyn [$wcan bbox $idtyn]
	foreach {tx1 ty1 tx2 ty2} $boxyn {break}
	$wcan delete $idtyn
#puts "hyesno=$hyesno wyesno=$wyesno boxyn=$boxyn btag=$btag"
	set dx [expr {($xr2 - $xr1 - ($tx2 - $tx1) * 2) / 3.0}]
	if {$fr == 0} {
	    set cbut [cbutton new "$wcan" -type round -x [expr {$xr1 + $dx}] -y [expr {$yr2 -  $hyesno }] -text "Да"  -fontfamily $Options(-fontfamily) -fontsize $fontsize]
	    set cbut1 [cbutton new "$wcan" -type round -x [expr {$xr1 + $dx * 2 + ($tx2 - $tx1)}] -y [expr {$yr2 - $hyesno }] -text " Нет"  -fontfamily $Options(-fontfamily) -fontsize $fontsize]
	} else {
	    set cbut [cbutton new "$wcan" -type round -x [expr {$xr1 + $dx}] -y [expr {$yr2 - $hyesno / 2}] -text "Да"  -fontfamily $Options(-fontfamily) -fontsize $fontsize]
	    set cbut1 [cbutton new "$wcan" -type round -x [expr {$xr1 + $dx * 2 + ($tx2 - $tx1)}] -y [expr {$yr2 - $hyesno / 2 }] -text " Нет"  -fontfamily $Options(-fontfamily) -fontsize $fontsize]
	}

	$cbut config -width [expr {$tx2 - $tx1 + 4}] -height [expr {$ty2 - $ty1 - $onemm2px}] -rx 4 -command "variable $Options(-variable);[set cbut] destroy;[set cbut1] destroy;[self] destroy;set $Options(-variable) yes"
	$cbut1 config -width [expr {$tx2 - $tx1 + 4}] -height [expr {$ty2 - $ty1 - $onemm2px}] -rx 4 -command "variable $Options(-variable);[set cbut] destroy;[set cbut1] destroy;[self] destroy;set $Options(-variable) no"

	my config -state disabled
	$cbut config -state normal
	$cbut1 config -state normal
#puts "hyesno=$hyesno self=[self] Yes=$cbut No=$cbut1 btag=$btag"
    } elseif {$type == "msg"} {
	set wyesno [expr {$x2 - $x1}]
#puts "hyesno=$hyesno wyesno=$wyesno y2=$y2 yt=$yt self=[self]"
	set fontsize [winfo fpixels $wcan 3.5m]
	foreach {xr1 yr1 xr2 yr2} [$wcan bbox $idr] {break}
#puts "xr1=$xr1 yr1=$yr1 xr2=$xr2 yr2=$yr2 idr=$idr height=[my config -height]"
	if {$fr == 1} {
	    set yr2 [winfo pixels $wcan [my config -height]]
	}

	set idtyn [$w create [set ptext] $xr1 [expr {$yr2 - ( $hyesno / 2)}] -textanchor c -text "Нет" -fontfamily $Options(-fontfamily) -fontsize $fontsize]
	set boxyn [$wcan bbox $idtyn]
	foreach {tx1 ty1 tx2 ty2} $boxyn {break}
	$wcan delete $idtyn
#	puts "hyesno=$hyesno wyesno=$wyesno boxyn=$boxyn"
	set dx [expr {($xr2 - $xr1 - ($tx2 - $tx1) * 1) / 2.0}]
	if {$fr == 0} {
	    set cbut [cbutton new "$wcan" -type round -x [expr {$xr1 + $dx}] -y [expr {$yr2 - $hyesno }] -text "Да"  -fontfamily $Options(-fontfamily) -fontsize $fontsize]
	} else {
	    set cbut [cbutton new "$wcan" -type round -x [expr {$xr1 + $dx}] -y [expr {$yr2 - $hyesno / 2}] -text "Да"  -fontfamily $Options(-fontfamily) -fontsize $fontsize]
	}
	$cbut config -width [expr {$tx2 - $tx1 + 4}] -height [expr {$ty2 - $ty1 - $onemm2px}] -rx 4


#Переменная erm для ожидания ответа от пользователя (нажатия кнрпки Ок)
#	$cbut config -command "global erm; [self] destroy; [set cbut] destroy; set erm 1"
	$cbut config  -command "variable $Options(-variable); [set cbut] destroy;[self] destroy;set $Options(-variable) yes"
	my config -state disabled
	$cbut config -state normal
#puts "hyesno=$hyesno self=[self] Yes=$cbut"
    }
#puts "hyesno=$hyesno self=[self] Yes=$cbut No=$cbut1 OK"

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
    } else {
	$wcan delete IDOR
    }
    if {$Options(-command) != ""} {
#	set cmd [my config -command]
	set cmd "variable $Options(-variable);$Options(-command);set $Options(-variable) yes"
	my config -command $cmd
    }
    if {$::svgwidget::tkpath == "::tkp::canvas"} {
	$wcan raise $idor $idt
    }
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
	down {
	    set y2 [expr {$y2 + $p1y}]
	    ;
	}
	up {
	    set y2 [expr {$y2 + 2 * $p1y}]
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
	    my config -state $stat
	}
	default {
	    error "Bad state=$stat: must be normal, disabled, hidden"
	}
    }
  }
  
  method move {dx dy} {
#    $wcan move $idr  $dx $dy
#    $wcan move $idt  $dx $dy
#    $wcan move "boxText"  $dx $dy
    $wcan move $btag  $dx $dy

    if {$tbut == "yesno"} {
	$cbut move $dx $dy
	$cbut1 move $dx $dy
    } elseif {$tbut == "msg"} {
	$cbut move $dx $dy
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
    $can delete "boxText $btag" 
    set i 0
    foreach {txt}  "$ltext" {
	set tekb [$can create [set ptext] $xt $ystr -text "$txt" -fontfamily $Options(-fontfamily) -fontweight $Options(-fontweight) -fontsize $sfont -fontslant $Options(-fontslant) -textanchor $textanchor  -tag "boxText$i" -parent $grt -textanchor nw]

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
		$can itemconfigure $id  -tag [list "boxText" "boxText $btag"]
#		$can itemconfigure $id  -tag [list $btag boxText]
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
	   		    $wcan itemconfigure $btag -state $value
			    $wcan itemconfigure "boxText $btag" -state $value
			    if {$tbut ==  "yesno" || $tbut == "msg"} {
				if {[info class instances cbutton $cbut] != ""} {
				    $cbut config -state $value
				} 
			    }
			    if {$tbut ==  "yesno" } {
				if {[info class instances cbutton $cbut1] != ""} {
				    $cbut1 config -state $value
				}
			    }
			}
		    }
		    default {
			error "Bad state=$value: must be normal, disabled, hidden"
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
		    if {$option == "-fontsize"} {
		    	$wcan itemconfigure $idt $option [winfo pixels $wcan $Options(-fontsize)]
		    } else {
		    	$wcan itemconfigure $idt $option $value
		    }
		    if {$fr == 1} {
			foreach {x1 y1 x2 y2} [$wcan bbox $canvasb] {break}
			$wcan configure -width $x2 -height $y2
		    }
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
        $wcan delete $idt $idr IDOR "boxText $btag" $btag
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
  variable tkpath
  variable ptext
  variable pline
  variable prect
  variable ppolygon
  variable pimage
  variable matrix

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
    if {[catch {package present tko}]}  {
#Используется пакет tkpath
	set tkpath "::tkp::canvas"
	set ptext "ptext"
	set pline "pline"
	set prect "prect"
	set ppolygon "ppolygon"
	set pimage "pimage"
	set matrix "::tkp::matrix"
    } {
#Используется пакет tko
	set tkpath "::tko::path"
	set ptext "text"
	set pline "line"
	set prect "rect"
	set ppolygon "polygon"
	set pimage "image"
	set matrix "::tko::matrix"
    }
    set tpmenu "canvas"
    set ind [lsearch $args "-type"]
    if {$ind > -1} {
	incr ind
	set tpmenu [lindex $args $ind]
    }
    if {$tpmenu != "canvas" && $tpmenu != "window"} {
	error "cmanu: bad type=$tpmenu: must be canvas or window (default canvas)"
    }
    if {$tpmenu == "window"} {
	set pwin [split $w "."]
	if {[llength $pwin] != 3 || [lindex $pwin 0] != ""} {
	    error "cmanu: bad path=$win: must be .<window>.<canvas>"
	}
	set fmWin ".[lindex $pwin 1]"
	destroy $fmWin
	toplevel $fmWin -class femenu
	wm overrideredirect $fmWin 1
	wm state $fmWin withdraw
    }
    if {[winfo exists $w]} {
	if {[winfo class $w] != "PathCanvas" && [winfo class $w] != "TkoPath"} {
#	error "cmenu cmenu $w already exist"
	    puts "class create cmenu: cmenu $w already exist"
	    destroy $w
	}
    }

    set erlib ""
    set wcan $w
    set fr 0
    if {![winfo exists $wcan]} {
	set fr 1
#	tkp::canvas $wcan -bd 0 -highlightt 0
	[set tkpath] $wcan -bd 0 -highlightthickness 0
    }
    set wclass "cmenu"
    catch {unset Options}
    set  Options(-height) 5m
    set  Options(-fillnormal) white
    set  Options(-fontsize) 3m
    set Options(-strokewidth) 1
    set Options(-stroke) ""
    set Options(-command) ""
    set Options(-state) "normal"
    set Options(-pad) 1m
    set Options(-ipad) [list 1m 5m 1m 5m]
    set Options(-direction) "up"
#Блокирукмое окно при отображении меню
    set Options(-lockwindow) ""
    set Options(-tongue) [list 0.45 0.5 0.55 5m]
    set xc [winfo fpixels $wcan $Options(-strokewidth)]
    set m3 [winfo fpixels $wcan 3m]
    set yc $m3
    set listmenu [list]
    if {$fr == 0} {
	set Options(-x) 0
	set Options(-y) 0
    }
    my config $args
#puts "cmenu constructor: Options(-strokewidth)=$Options(-strokewidth)"
    set xc [expr {$xc + [winfo fpixels $wcan $Options(-strokewidth)] / 2.0}]
    set yc [expr {$yc + [winfo fpixels $wcan $Options(-strokewidth)] / 1.0}]
if {0} {
    if {$fr == 0} {
	set xc	[expr {$xc + $Options(-x)}]
	set yc [expr {$yc + $Options(-y)}]
    }
}
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
    set srect [$wcan create [set prect] 0 0 10 10 -stroke ""]
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
#    	    set cbut [eval "cbutton new $wcan -type rect -x $xc -y $yc -ipad \"$Options(-ipad)\" -stroke \"$Options(-stroke)\" $args -fontsize $Options(-fontsize)"]
    	    set cbut [eval "cbutton new $wcan -type rect -x $xc -y $yc -ipad \"$Options(-ipad)\" -stroke \"$Options(-stroke)\" $args"]
	    if {[$cbut config -image] == ""} {
#    		$cbut config -image "$wcan $srect"
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
#puts "FINISH: listtag=$listtag"

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
	    if {$fr == 1} {
		foreach {bx0 by0 bx1 by1} [$wcan bbox all] { 
		    break 
		}
	    } else {
		foreach {bx0 by0 bx1 by1} [eval $wcan bbox $listtag] {break }
	    }
#puts "Смещение bx0=$bx0 by0=$by0 bx1=$bx1 by1=$by1 old=$old"
	    set direction $Options(-direction)
	    switch $direction {
		down {
;
#		    set hy [expr {$hy + $htongue + 20}]
		}
		up {
#		    set hy [expr {$hy + $htongue +20}]
#		    $wcan move 0 0 $htongue
    foreach objmenu $listtag {
		    $wcan move $objmenu 0 $htongue
    }
#puts "place up htongue=$htongue"
		}
		right {
		    set wx [expr {$wx + $htongue}]
		}
		left {
		    set wx [expr {$wx + $htongue}]
		    if {$old == 1} {
			$wcan move 0 [expr {$htongue * -1}] 0
    foreach objmenu $listtag {
		    $wcan move $objmenu [expr {$htongue * -1}] 0
    }
		    } else {
#			$wcan move 0 $htongue 0
    foreach objmenu $listmenu {
		    $wcan move $objmenu $htongue 0
    }
		    }
		}

		default {
puts "cmenu finish: uuncnown direction=$direction"
		}
	    }
	    set  strw2 [expr {$strw / 2.0}]
#  -fillnormal $Options(-fillnormal)
	    set cbut [mbutton new $wcan -type $direction -x $strw2 -y $strw2 -fillnormal $Options(-fillnormal) -fillenter "##" -fillpress "##" -strokewidth $Options(-strokewidth) -stroke $Options(-stroke) \
		-command "$Options(-command)" -tongue "$Options(-tongue)" -text "" -width [expr {$wx + $bx0 + 2}] -height [expr {$hy + $by0 + $m3}]]
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
			if {$tp == "rect" && [$obj config -image] != ""} {
			    $obj config -image [$obj config -image]
			}
		    }
#подвески строк в меню Цвет - #3584e4 синий
#Создание прямоугольника над строкой меню
		    set bcol "#3584e4"
		    set otag "canvasb[string range $obj 6 end]"
		    if {[$obj type] == "rect"} {
			foreach {x0 y0 x1 y1} [$wcan bbox "$otag rect"] {break}
		    } else {
			foreach {x0 y0 x1 y1} [$wcan bbox "canvasb[string range $obj 6 end]"] {break}
		    }
		    $wcan raise $otag
		    $wcan lower "$otag isvg" "$otag idor"
		    if {[$obj config -fillenter] != "##"} {
			set btago "canvasb[string range [set obj] [expr {[string last "::" [set obj]] + 2}] end]"

			set brect [[$obj canvas] create [set prect] 0 [expr {$y0 + 2}] $wmax [expr {$y1 - 2}] -fill {} -fillopacity 0.2 -strokeopacity 0.2 -stroke {} -strokewidth 0 -tags $btago]
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
if {$fr == 1}  {
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
} else {
#puts "MOVE self=[self]  -x=$Options(-x) -y=$Options(-y)"
;
		my move $Options(-x) $Options(-y)
}
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

  method move {dx dy} {
    if {$fr == 1} {
	return
    }
    set i 0
    foreach objmenu $listmenu {
#puts "CMENU move: objmenu=$objmenu"
	if {$i == 0} {
	    set i 1
	    continue
	}
	$objmenu move $dx $dy
    }
    return
  }
  method move {dx dy} {
    if {$fr == 1} {
	return
    }
    set i 0
    foreach objmenu $listmenu {
#puts "CMENU move: objmenu=$objmenu"
	if {$i == 0} {
	    set i 1
	    continue
	}
	$objmenu move $dx $dy
    }
    return
  }
  method state {stat} {
    my config -state $stat
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
	    -type {
	    }
    	    -lockwindow {
    		set Options($option) $value
    	    }
    	    -height -
    	    -width {
    		set Options($option) $value
    	    }
	    -pad -
	    -ipad -
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
		if {$fr == 1 && [winfo manager $wcan] != ""} {
		    $erlib config $option $value
		}
    	    }
	    -stroke -
    	    -fillnormal {
    		set Options($option) $value
		if {$fr == 1 && [winfo manager $wcan] != ""} {
		    $erlib config $option "$value"
		}
    	    }
	    -x -
	    -y {
    		if {$fr == 1} {
    		    continue
    		}
		set  Options($option) [winfo fpixels $wcan $value]
	    }
	    -state {
		if {$fr == 1} {
		    return
		}
		switch $value {
		    normal -
		    disabled -
		    hidden {
			set  Options($option) $value
#puts "CMENU STAT listmenu=$listmenu erlib=$erlib"
			if {$erlib != ""} {
			    set i 0
			    foreach objmenu $listmenu {
#puts "CMENU state: objmenu=$objmenu"
				if {$i == 0} {
				    set i 1
				    continue
				}
				$objmenu config -state $value
			    }
			}
		    }
		    default {
			error "Bad state=$value: must be normal, disabled, hidden"
		    }
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
    if {$fr == 1} {
	destroy $wcan
    }
  }
}

oo::class create cframe {
  variable tkpath
  variable ptext
  variable pline
  variable prect
  variable ppolygon
  variable pimage
  variable matrix

  variable wcan
  variable wentry
  variable Options
  variable Canv
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
  variable onemm2px
#fr = 0 кнопки создаются на внешнем холсте
#fr - 1 кнопки создаются на внутреннем холсте для внешнего фрейма
  variable fr
  variable relwdt

  constructor {w {args ""}} {
    if {[catch {package present tko}]}  {
#Используется пакет tkpath
	set tkpath "::tkp::canvas"
	set ptext "ptext"
	set pline "pline"
	set prect "prect"
	set ppolygon "ppolygon"
	set pimage "pimage"
	set matrix "::tkp::matrix"
    } {
#Используется пакет tko
	set tkpath "::tko::path"
	set ptext "text"
	set pline "line"
	set prect "rect"
	set ppolygon "polygon"
	set pimage "image"
	set matrix "::tko::matrix"
    }

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
#	tkp::canvas $wcan -bd 0 -highlightthickness 0
	[set tkpath] $wcan -bd 0 -highlightthickness 0
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
    set onemm2px [winfo fpixels $w 1m]
#Запоминаем геометрию главного окна
    set topw [winfo toplevel $wcan]
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
    set Options(-state) "normal"
    set Options(press) 0
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
	cspin -
	centry {
	    set Options(-rx)	1.5m
	    set Options(-text) ""
	    set  Options(-values) ""
	    if {[string range $::tcl_platform(machine) 0 2] != "arm"} {
		set  Options(-fontsize) 3m
	    } else {
		set  Options(-fontsize) 1m
	    }
	}
	roundframe -
	frame {
	    set Options(-text) ""
	    set  Options(-fontsize) 0
	}
	default {
	    if {$fr == 1} {
		destroy $wcan
	    }
    	    error "mbutton: Unknown type=$type: must be clframe, ccombo, cspin, centry, frame"
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
#    set obje [string range [self] [string first "Obj" [self]] end]
    set obje [string range [self] [expr {[string last "::" [self]] + 2}] end]
    set wentry "$wcan.entry$obje"
    switch $type {
	clframe {
	    set fontsize [winfo fpixels $wcan $Options(-fontsize)]
	    set idt [$wcan create [set ptext] 0 0 -textanchor nw -text $Options(-text) -fontsize $fontsize -fontfamily $Options(-fontfamily) ]
	    foreach {xy0 yt0 xt1 yt1} [$wcan bbox $idt] {break}
	    $wcan delete $idt
	    if {[info exist yt1]} {
		set ycoords [expr {($yt1 - $yt0) / 2.0 + $strwidth}]
	    } else {
		set ycoords $strwidth
	    }
	}
	centry {
	    set fonte "Helvetica [winfo pixels $wcan $Options(-fontsize)]"
#puts "CENTRY font=$fonte="
	    set ycoords $strwidth
	    if {[info exists Options(-textvariable)]} {
		set cent [entry $wentry -background snow -bd 0 -highlightthickness 0 -font "$fonte" -highlightbackground gray85 -highlightcolor skyblue -justify left -relief sunken -readonlybackground snow -textvariable $Options(-textvariable)]
	    } else {
		set cent [entry $wentry -background snow -bd 0 -highlightthickness 0 -font "$fonte" -highlightbackground gray85 -highlightcolor skyblue -justify left -relief sunken -readonlybackground snow ]
	    }
	    if {$fr == 1 } {
		pack $wentry -in $wcan -fill x -expand 1 -padx $Options(-rx)  -pady 1.0m
	    } else {
		set entwidth [winfo fpixels $wcan $Options(-width)]
		set entheight [winfo fpixels $wcan $Options(-height)]
		place $wentry -in $wcan -x [expr {$xc0 + $onemm2px }] -y [expr {$yc0 + $ycoords}] -width [expr {$entwidth - $onemm2px * 2}] -height [expr {$entheight - $ycoords * 2}]
	    }
	    raise $wentry
	}
	cspin {
	    set fonte "Helvetica [winfo pixels $wcan $Options(-fontsize)]"
#puts "CSPIN font=$fonte="
	    set ycoords $strwidth
	    if {[info exists Options(-textvariable)]} {
		set cent [spinbox $wentry -background snow -bd 0 -highlightthickness 0 -font "$fonte" -highlightbackground gray85 -highlightcolor skyblue -justify left -relief sunken -readonlybackground snow -textvariable $Options(-textvariable)]
	    } else {
		set cent [spinbox $wentry -background snow -bd 0 -highlightthickness 0 -font "$fonte" -highlightbackground gray85 -highlightcolor skyblue -justify left -relief sunken -readonlybackground snow ]
	    }
	    if {$fr == 1 } {
		pack $wentry -in $wcan -fill x -expand 1 -padx $Options(-rx)  -pady 1.0m
	    } else {
		set entwidth [winfo fpixels $wcan $Options(-width)]
		set entheight [winfo fpixels $wcan $Options(-height)]
		place $wentry -in $wcan -x [expr {$xc0 + $onemm2px }] -y [expr {$yc0 + $ycoords}] -width [expr {$entwidth - $onemm2px * 2}] -height [expr {$entheight - $ycoords * 2}]
	    }
	    raise $wentry
	}
	ccombo {
	    set fonte "Helvetica [winfo pixels $wcan $Options(-fontsize)]"
#puts "CCOMBO font=$fonte="
	    set ycoords $strwidth
	    ttk::style configure My.TCombobox -borderwidth 0 -fieldbackground white -focuscolor white -selectbackground white -selectborderwidth 0 -selectforeground black -padding 0 -arrowsize 5m -background white
	    ttk::style map My.TCombobox -fieldbackground { readonly white}
	    ttk::style map My.TCombobox -selectbackground {readonly white}
	    ttk::style map My.TCombobox -selectforeground {readonly black}
	    ttk::style map My.TCombobox -background {readonly white}
	    ttk::style map My.TCombobox -foreground {readonly black}
	    ttk::style map My.TCombobox -fieldbackground [list "readonly" "white"]
#Для Windows -focusfill == -fieldbackground
	    ttk::style map My.TCombobox -focusfill [list "readonly focus" "white"]

	    if {[info exists Options(-textvariable)]} {
		set cent [ttk::combobox $wentry -style My.TCombobox -values "$Options(-values)" -font "$fonte" -textvariable $Options(-textvariable)]
	    } else {
		set cent [ttk::combobox $wentry -style My.TCombobox -values "$Options(-values)" -font "$fonte"]
	    }
	    if {$fr == 1 } {
		pack $wentry -in $wcan -fill x -expand 1 -padx $Options(-rx)  -pady 1.0m
	    } else {
		set entwidth [winfo fpixels $wcan $Options(-width)]
		set entheight [winfo fpixels $wcan $Options(-height)]
		place $wentry -in $wcan -x [expr {$xc0 + $onemm2px }] -y [expr {$yc0 + $ycoords}] -width [expr {$entwidth - $onemm2px * 2}] -height [expr {$entheight - $ycoords}]
	    }
	    raise $wentry
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
    if {$fr == 1 || $tbut == "clframe" } {
#	set idr [$wcan create [set prect] [expr {$xc0 + $strwidth * 0}] [expr {$yc0 + $ycoords}] [expr {$xc0 + $cw - $strwidth * 0}] [expr {$yc0 + $ch - $ycoords}]] 
	set idr [$wcan create [set prect] $xc0 [expr {$yc0 + $ycoords}] [expr {$xc0 + $cw}] [expr {$yc0 + $ch - $ycoords}] -stroke {} -strokewidth 0] 
    } else {
#	set idr [$wcan create [set prect] [expr {$xc0 + $strwidth * 0}] [expr {$yc0 - $ycoords}] [expr {$xc0 + $cw - $strwidth * 0}] [expr {$yc0 + $ch + $ycoords}]] 
	set idr [$wcan create [set prect] $xc0 $yc0 [expr {$xc0 + $cw}] [expr {$yc0 + $ch + $ycoords}] -stroke {} -strokewidth 0] 
    }
    my changestrwidth

    set btag "canvasb[string range [self] [expr {[string last "::" [self]] + 2}] end]"

    $wcan itemconfigure $idr -fill $Options(-fillnormal) -stroke $Options(-stroke) -rx $crx -tags [list Rectangle obj $canvasb $btag $tbut [linsert $btag end $tbut] utag$idr]
    my changestrwidth $strwidth
    if {$tbut == "centry" || $tbut == "cspin" || $tbut == "ccombo"} {
	set bg [$wentry cget -background]
	if {$bg == ""} {
	    set bg "white"
	}
	$wcan itemconfigure $idr -fill $bg
    }
    set idr "utag$idr"
#Заголовок
    if {$tbut == "clframe"} {
	set idt [$wcan create [set ptext] [expr {$xc0 + ($cw - $strwidth * 2) / 2.0}] [expr {$yc0 + 1}] -textanchor n -text $Options(-text) -fontsize $fontsize -fontfamily $Options(-fontfamily) -tags [list Text obj $canvasb "$btag"]]
    }
    if {$fr == 1} {
	if {$tbut == "frame"} {
	    eval "bind $wcan  <Configure> {[self] scaleGroup %w %h;[self] resize %w %h 0}"
	} else {
	    eval "bind $wcan  <Configure> {[self] resize %w %h 0}"
	}
    }
#puts "[self]"

    return self
  }
  method entry {} {
	if {$tbut != "centry" && $tbut != "cspin" && $tbut != "ccombo"} {
	    return ""
	}
	return "$wentry"
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
	if {$hy1 <= [expr {$swidth * 2.0}] || $wx1 <= [expr {$swidth * 2.0}]} {
	    return
	}
	set x1 [expr {$wx - $swidth}]
	set y1 [expr {$hy - $swidth}]
    } else {
	set x1 [expr {$x0 + $wx - $swidth * 0}]
	set y1 [expr {$y0 + $hy - $swidth * 0}]
    }

    $wcan coords $idr $x0 $y0 $x1 $y1
    if {$fr == 0 && ($tbut == "centry" || $tbut == "cspin" || $tbut == "ccombo")} {
	place configure $wentry -width [expr {$wx - $onemm2px * 2}] -height [expr {$hy - $onemm2px * 2 }]
	return
    }
    
    if {[info exists idr] && $tbut == "clframe"} {
	foreach {xc yc } [$wcan coords $idt] {break}
	if {$fr == 1} {
	    $wcan coords $idt [expr {($wx - $swidth * 2) / 2.0 }]   $yc
	} else {
	    $wcan coords $idt [expr {($x0 + $wx - $swidth * 2 * 0) / 2.0 }]   $yc
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
    if {[info exist yt1]} {
	set bidt [$wcan create [set prect] $xt0 $yt0 $xt1 $yt1 -strokewidth 0 -fill $Options(-fillbox) -tags [list Rectangle boxtext $canvasb $btag] -stroke ""] 
	$wcan lower $bidt $idt
    }
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
    		if {$tbut == "clframe" || $tbut == "frame"} {
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
		} elseif {$tbut == "centry" || $tbut == "cspin" || $tbut == "ccombo"} {
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
		    if {$tbut != "clframe" && $fr == 1} {
			set type [catch "$wcan gradient type $value"]
			if {$type == 1} {
			    [my canvas] configure -background $value
			}
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
	    -state {
    		if {$tbut == "clframe"} {
		    switch $value {
			normal -
			disabled -
			hidden {
			    set  Options($option) $value
			    if {[info exists idr]} {
	   			$wcan itemconfigure $btag -state $value
			    }
			}
			default {
			    error "Bad state=$value: must be normal, disabled, hidden"
			}
		    }
		} else {
		    switch $value {
			normal {
			    if {[info exists idr]} {
	   			$wcan itemconfigure $btag -state $value
	   			$wentry configure -state $value
				if {$Options($option) == "hidden"} {
				    foreach {rx0 ry0 rx1 ry1} [$wcan coords $idr] {
					place configure $wentry -width [expr {$rx1 - $rx0 - $onemm2px * 4}] -height [expr {$ry1 - $ry0 - $onemm2px * 2 }] -y [expr {$ry0 + $onemm2px  }] -x [expr {$rx0 + $onemm2px * 2 }]
				    }
				}
			    }
			    set  Options($option) $value
			}
			disabled {
			    set  Options($option) $value
			    if {[info exists idr]} {
	   			$wcan itemconfigure $btag -state $value
	   			$wentry configure -state $value
			    }			
			}
			hidden {
			    set  Options($option) $value
			    if {[info exists idr]} {
	   			$wcan itemconfigure $btag -state $value
	   			place forget $wentry 
			    }
			}
			default {
			    error "Bad state=$value: must be normal, disabled, hidden"
			}
		    }
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
	} else {
	    if {$fr == 0 && ($tbut == "centry" || $tbut == "cspin" || $tbut == "ccombo")} {
		destroy $wentry
	    }
	}
    }
  }

}

oo::define mbutton {
    eval $::methodman
}
oo::define cframe {
    eval $::methodman
    eval $::methscaleGroup
}
oo::define cmenu {
    eval $::methodman
}

namespace eval ::gengrad {
  set i 0
  set icongrad [image create photo -data {
    iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAIAAAD8GO2jAAAEwElEQVRIx11WW5IkuQ0DQPWsb+xj+AA+6XYSgD+U1TNeRUWFIiNTpEjiwf/899/7pf119tf46+w5+9f4
    6+v7X18+k1+zv772nP06OQOyIlPZ59nz/Xw9y7+X9l/fO0/m7+/z/Zwn+n5+/b18fNq2BdoWKQAAbZke127dqMc1AwoFGrnjMpWrgAFSpkzv5+8hwGmtalveSC1S1vIp
    o4dShguAPVArwhlbu2erDW1tkLZlwZTNjYT0sGisKMV89k2b1q2qeB4UmxSiSKSKtZFXn8TZMv7kV6IEhBylBVgoQSxTblRMgXDIJafi0U2fRAuHNlIkSNGOrVTxFAqU
    ymZx5NZVXLOsVMXHtANonhRohT63wxBvuccdRxu5cG9XZj+R3CmYHsUxuQRDkozEcM9zGtz2cxIREsmSbZW8p7ja1NGGG/r+W2mdcc+tGlqlcCMjUgobgQtALMJWJQnx
    zpvSE3CjDWu0ipl3TO4LaM/dcUOsSAXjBVWg4viAgkASGnwWG7Z06chmyuc5t2j3Nt46TM9xFzv6IhvmAKCAoOmwXWQ4LFCFZFAWAKbgRrFSpMfVE21mI/tTvT3zLHCw
    m55g3QMsKqTY6WmUDAtVJHlBBECx3NsJ1NqMc55oV5vZ1WNtDh1xReHNHaUOBQ+mrTS0VQYAxLdGqQDFb5UK2NpofesDh96THiQoGNArCICodubwAjslEIglmPcG7P1F
    /jDEPnL5LFN66SipcxTXEQ6AFsAKp6doKSXUToYFSAIMoVuld5YsFy28cmfDmH6vot1zdtlZLHHApkAeRSY4jZiJlqXwxvisGK1ctizqjHe23CiR92y0OdoAKJkuOASA
    WQTchkcnYYkygP6YogDQO+9mWviC7jgXYuPSPXhMZxyes1/tDttfq+cYYmmGJQGQv3Hw6YTpskV6AthoYZ+9dBtuzjzBkVmyQDxEAPWUFavGhG6M/IRpK+RHA9Rq01ap
    cgnqJY9zdhPSxylmdFoSGk7LiSARZKUXw3deAaZomNIVwA3qF3G7F2Vsj3Yl5oKgTUgdqAjLjBixnP6cy99QYDvND/MwRc0PkuXl5mhdSXg1jWJVkFMByJBimN/nVm/+
    rQK2sgGMryBa7sRy5gmao8eY5q3qk1scUWFFGNAMk/d8AX53l83z8r6atnAUX6mgg/TMLkz56KuRomKnYoclKYApoZdK/TNIKhAT0O3BvUFWrtrZwKv0nCcdlcYDTCFB
    ZegyxOFELO/g/wNruekjVUHvR5Az+4o223P2u54sNRNxZyhB4iBAx7oq9kNz6M8UsWCrQMBlf6bTHBsbZJEebKienoWFOXCKtpMKSgjRBKl/BLhIZiGXHyuFenw7Ubp1
    ztdjiFGP6QlEHZdzR94GyNEUwf8vfi6h12z5Qlofe8G9Tf5+oNE0QzodNSz3CiTFUj8g+MfSFQZfcvWLZL/G4pqao5R1GloUk2BZMUqJ4VQp/w8BP7r2+rgbJm6vuvX6
    otvwg9wCM7hMwhAgqUIMA71iphq4dgB56egzQoXyuls2b9tbFucPo9AWSIcsO9f/6So8fxDwpyS8ZrSXwH/bZ/4xCeemxE9NryW+n10RDtDL1jcUgffJq8yvJxc/Rv19
    iWTR/wE5KW53Qusm+AAAAABJRU5ErkJggg==
  }]
  if {[string range $::tcl_platform(machine) 0 2] != "arm"} {
    array set Imy []
    set Imy(arrow-down-prelight) [image create photo  -data {
	iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAABmJLR0QA/wD/AP+gvaeTAAAAk0lEQVQokc2PsQ3CMBRE/32WwF2moDJgsUFSIBgxCGImQBaiYop0RlkB
	4aMCWQkCGiSuPL13+l/kP+N8LL5l4HwsbtQzkZan0oRXsPXRgboZIU00lKaloAK1njWXRR+e77spqDWEq1CaFs+VprMQ7iBcH6vx4QGnxG3eIV/LJahe+/BAyO8VEXn3
	10CyPrqP4E9yB2s4SU1wZK6JAAAAAElFTkSuQmCC
    }]
    set Imy(arrow-down-insens) [image create photo  -data {
	iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAABmJLR0QA/wD/AP+gvaeTAAAAqUlEQVQokc2QsQrCMBiErybBoaMmBgriE/yQtXZy8cWl4OLQ9gkUoSmW
	Tjq0JjiJWoW6CN78fcdxwH+GiMJvGUZEoefjtZaL2trD+TMcK8+DlZbTPbPWdpGenRxziZrMm6o6vkjGGOmYS9DyNM93DQOAsiwvkda15375LBljZBcECVqRFsXWAkDQ
	b7sDQrS+D78Jj71dAgCjq9hkWVoNHQKiWBHFahD8SW5gekeBcxjv0wAAAABJRU5ErkJggg==
    }]
    set Imy(arrow-down) [image create photo  -data {
	iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAABmJLR0QA/wD/AP+gvaeTAAAApElEQVQokc2PTQqCUBSFz9Vd9Axdghi8HvgEVxG4Ra0tRIPIn4G2g8AU
	GzaPvE0fGdUk6Iy/73AO8J/xlfK+ZchXyqPRrtii1bHY717DOqaRU7bu0r503VU4bg7mbCbm9dCfTyYcyDACIyNw0pR5YwPA0LetcNyCgdSUAhlGDKwJnNTVYQsAZLYt
	llqPzBsCJwDdnuGJYO4FgHe/JpKvdPwR/Eke6FFKPMIYKegAAAAASUVORK5CYII=
    }]
    set Imy(scrollbar-slider-horiz) [image create photo  -data {
	iVBORw0KGgoAAAANSUhEUgAAAB4AAAAUCAYAAACaq43EAAAABmJLR0QA/wD/AP+gvaeTAAAAfElEQVRIie3NsRHCMBAAwXtZQwFICW6BmgxdmMzMQCnK6IcWHFlUIHgH
	DFSAlPCbXHhgjPkR2d/um20XrwgDsKv8mwVSLsvkg48XhbHy8KNXOAUfcQqHRtMvhaN7ty2BpxNIrccvNPlclin4iMIA9JWfs0B6lHyu/DHmn6xkVh1tCWue8gAAAABJ
	RU5ErkJggg==
    }]
    set Imy(scrollbar-slider-vert) [image create photo  -data {
	iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAYAAAAsEj5rAAAABmJLR0QA/wD/AP+gvaeTAAAAmElEQVRIie3WsQ3CMBCF4d9gMQB2ATNkH7rAFkAVJBglHftkBKgSBogs
	jsoSCslJQHuvuye9z60dSoprs1jO4wVHCYiDuktt1WyKfmrjNTD4eBbY51vgEHwEOE5tZhoosB3pdtpGBYH1SLf6B/w6BhpooIEGGmhgzn1YOLj9DDqoh90T+ejeo/5t
	utRWwUcEyvzAI3UnbfMCMEIfS/u3nUUAAAAASUVORK5CYII=
    }]
    set Imy(scrollbar-trough-horiz-active) [image create photo  -data {
	iVBORw0KGgoAAAANSUhEUgAAADgAAAAUCAYAAADY6P5TAAAABmJLR0QA/wD/AP+gvaeTAAAAy0lEQVRYhe3TuwrCQBAF0DsTQxQNsfHV24mSD7CwzT9bWPgBabRKaaGC
	jyCCGDdro5IoFkI0BuZ0O9PcyzKAEEII8RY9D1x3VEfp1INhOFrHnEeoTxFxDKVCXMoz35/skzsj+eh6nmWej0MQVQH9Uv5/aQJRBYbq2IP+YhsE6r5J/ZC9DNsAzJ/n
	y47prA+t5CBVkJn1b/N8X6pg2LRXAKKcsmQhunV4SN3gNghUp9HdEKsaMVtFuUMijknrHUWWP5+Oj3nnEUIIURhXog40I5tPlhsAAAAASUVORK5CYII=
    }]
    set Imy(scrollbar-slider-horiz-active) [image create photo  -data {
	iVBORw0KGgoAAAANSUhEUgAAAB4AAAAUCAYAAACaq43EAAAABmJLR0QA/wD/AP+gvaeTAAAAeUlEQVRIie3SMRKCMBBA0b8ZBvqYRu6G3kI7dOAoORNXoEL6OOMsDXoC
	k4Z9F/jNB2PMn8hzmurTO4woHXDO3JsV4tosfeVTGIBb5uBXK3D3KeAELoWiPwJXB2jpMPBxCrF8V2O1NkvvU0CgA9rMxX2u1yNzx5gj2QA2vRzmr3lMjwAAAABJRU5E
	rkJggg==
    }]
    set Imy(scrollbar-trough-vert-active) [image create photo  -data {
	iVBORw0KGgoAAAANSUhEUgAAABQAAAA4CAYAAAD959hAAAAABmJLR0QA/wD/AP+gvaeTAAAAsUlEQVRYhe3XoQ7CMBQF0NuNUgzZFPwACswcFrsvnsXiZkDxA6BYMJSy
	DoNYUtYtDYbsPnn77kntA0Y3om9hlecqud6XAFAt5pdzUehgMMt2aTPVWwDyExnxVIey3N+6OpH3e5PHpoUBgITUa1/FD8Zx4jaiNBhsGuu8f8sGgyFDkCBBggQJEiRI
	kCBBgn8FChHZIdlgEHVdOZm1nZdoP/iaHQGYVmJg1MlX+fkBPsJ5A6faL2J/SI4TAAAAAElFTkSuQmCC
    }]
    set Imy(scrollbar-slider-vert-active) [image create photo  -data {
	iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAYAAAAsEj5rAAAABmJLR0QA/wD/AP+gvaeTAAAAkElEQVRIie3WsQ3CMBCF4d8I4d64gBkyU2ALoAoRjJKZMgJUwb3TmMqi
	uZwEtPe6e9L73NqhpB/HzXaOdwotUAoMyU9d3zTz0matgSHHG3Cqt4NzyBHgsrRZaaCDg9AdtY0KAnuh2/0Dfh0DDTTQQAMNNLDmKXSPn8ECg9AK3Sfq3yb5qQs54qCt
	DyT/umqbN9ezHkQrVDt+AAAAAElFTkSuQmCC
    }]
    set Imy(scrollbar-slider-insens) [image create photo  -data {
	iVBORw0KGgoAAAANSUhEUgAAAAYAAAAeCAYAAAAPSW++AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAANUlEQVQoz2NkYGBgsFnz8j8DEjgS
	Is7IiC4IA0wMOMBQk2DCoZrpHxaJf8PJ58NdghFXogYAqmYNCjdUXn0AAAAASUVORK5CYII=
    }]
#Начиная с tk8.6.16 пересоздать элемент нельзя
#Поэтому пересоздаем layout - макет
        ttk::style element create My.downarrow \
            image [list $Imy(arrow-down) \
                        active    $Imy(arrow-down-prelight) \
                        pressed   $Imy(arrow-down-prelight) \
                        disabled  $Imy(arrow-down-insens) \
          ]  -border 4 -sticky {} 
    ttk::style layout My.TCombobox {
	Combobox.field -sticky nswe -children {
	    My.downarrow -side right -sticky ns
		Combobox.padding -expand 1 -sticky nswe -children {
		    Combobox.textarea -sticky nswe
		}
	}
    }

#Вид scrollbar-ов: 0 - оригинальный, 1 - типа breeze
        ttk::style element create HorizontalMY.Scrollbar.trough image $Imy(scrollbar-trough-horiz-active) \
        -border {4 0 4 0} -sticky ew
        ttk::style element create HorizontalMY.Scrollbar.thumb \
             image [list $Imy(scrollbar-slider-horiz) \
                        {active !disabled}  $Imy(scrollbar-slider-horiz-active) \
                        disabled            $Imy(scrollbar-slider-insens) \
            ] -border {6 0 6 0} -sticky ew

        ttk::style element create VerticalMY.Scrollbar.trough image $Imy(scrollbar-trough-vert-active) \
            -border {0 4 0 4} -sticky ns
        ttk::style element create VerticalMY.Scrollbar.thumb \
            image [list $Imy(scrollbar-slider-vert) \
                        {active !disabled}  $Imy(scrollbar-slider-vert-active) \
                        disabled            $Imy(scrollbar-slider-insens) \
            ] -border {0 6 0 6} -sticky ns

        ttk::style layout My.Vertical.TScrollbar {
            VerticalMY.Scrollbar.trough -sticky ns -children {
                VerticalMY.Scrollbar.thumb -expand true
            }
        }

        ttk::style layout My.Horizontal.TScrollbar {
            HorizontalMY.Scrollbar.trough -sticky ew -children {
                HorizontalMY.Scrollbar.thumb -expand true
            }
        }
  }

  proc cleargengrad {{wsclass "cbutton ibutton mbutton cmenu cframe"}}  {
    foreach {wclass} $wsclass {
	set listoo -1
	catch {set listoo [info class instances $wclass]}
	if {$listoo == -1} {
    	    error "svgwidget::cleargengrad: Unknown class=$wclass: must be \"\[cbutton\] \[ibutton\] \[mbutton\] \[cmenu\] \[cframe\]\""
    	    return
	}
	foreach {oo} $listoo {
	    if {[string range $oo 0 10] == "::gengrad::"} {
		$oo destroy
	    }
	}
    }
  }

  proc exitarm {t} {
    global Gradient
	wm withdraw .viewrad
	if {$t == "."} {
	    set t1 ""
	} else {
	    set t1 $t
	}
	set erlib [mbutton create mesend "$t1.message" -type yesno  -fillnormal white -text "Вы действительно\nхотите выйти?" -textanchor n -strokewidth 3]
	set g4 [$t1.message gradient create linear -method pad -units bbox -stops { { 0.00 "#ffffff" 1} { 1.00 "#dbdbdb" 1}} -lineartransition {0.00 0.00 0.00 1.00} ]
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
#Удаляем все объекты
	gengrad::cleargengrad
	destroy .viewrad
	destroy $t
	puts "Утилита генерации градиента завершена."
	return
  }

  proc setRadial {ind wcan} {
    global Gradient
    if {$ind > 8 || $Gradient(type) != "radial"} {
	puts "setRadial: Bad index=$ind"
	return
    }
    switch $ind {
	0 {
#Centre
	    set Gradient(cx) 0.50
	    set Gradient(cy) 0.50
#	    set Gradient(r) 1.00
	    set Gradient(r) 0.50
	    set Gradient(fx) 0.50
	    set Gradient(fy) 0.50
	}
	1 {
#Top
	    set Gradient(cx) 0.50
	    set Gradient(cy) 0.00
	    set Gradient(r) 1.00
	    set Gradient(fx) 0.50
	    set Gradient(fy) 0.00
	}
	2 {
#Top-Right
	    set Gradient(cx) 1.00
	    set Gradient(cy) 0.00
	    set Gradient(r) 1.00
	    set Gradient(fx) 1.00
	    set Gradient(fy) 0.00
	}
	3 {
#Right
	    set Gradient(cx) 1.00
	    set Gradient(cy) 0.50
	    set Gradient(r) 1.00
	    set Gradient(fx) 1.00
	    set Gradient(fy) 0.50
	}
	4 {
#Bottom-Right
	    set Gradient(cx) 1.00
	    set Gradient(cy) 1.00
	    set Gradient(r) 1.00
	    set Gradient(fx) 1.00
	    set Gradient(fy) 1.00
	}
	5 {
#Bottom
	    set Gradient(cx) 0.50
	    set Gradient(cy) 1.00
	    set Gradient(r) 1.00
	    set Gradient(fx) 0.50
	    set Gradient(fy) 1.00
	}
	6 {
#Bottom-Left
	    set Gradient(cx) 0.00
	    set Gradient(cy) 1.00
	    set Gradient(r) 1.00
	    set Gradient(fx) 0.00
	    set Gradient(fy) 1.00
	}
	7 {
#Left
	    set Gradient(cx) 0.00
	    set Gradient(cy) 0.50
	    set Gradient(r) 1.00
	    set Gradient(fx) 0.00
	    set Gradient(fy) 0.50
	}
	8 {
#Top-Left
	    set Gradient(cx) 0.00
	    set Gradient(cy) 0.00
	    set Gradient(r) 1.00
	    set Gradient(fx) 0.00
	    set Gradient(fy) 0.00
	}
	default {
	    puts "setRadial=$ind"
	}
    }
    ::gengrad::changetransition .tpgradient.frameFirst.canvas18
  }

  proc setLinear {ind wcan} {
    global Gradient
    if {$ind > 7} {
	puts "Bad index=$ind"
	return
    }
    if {$Gradient(type) == "linear" } {
      switch $ind {
	0 {
#Top to Button
	    set Gradient(x0) 0.00
	    set Gradient(y0) 0.00
	    set Gradient(x1) 0.00
	    set Gradient(y1) 1.00
	}
	1 {
#Top-Right to Bottom-Left
	    set Gradient(x0) 1.00
	    set Gradient(y0) 0.00
	    set Gradient(x1) 0.00
	    set Gradient(y1) 1.00
	}
	2 {
#Right to Left
	    set Gradient(x0) 1.00
	    set Gradient(y0) 0.00
	    set Gradient(x1) 0.00
	    set Gradient(y1) 0.00
	}
	3 {
#Bottom-Right to Top-Left
	    set Gradient(x0) 1.00
	    set Gradient(y0) 1.00
	    set Gradient(x1) 0.00
	    set Gradient(y1) 0.00
	}
	4 {
#Button to Top
	    set Gradient(x0) 0.00
	    set Gradient(y0) 1.00
	    set Gradient(x1) 0.00
	    set Gradient(y1) 0.00
	}
	5 {
#Bottom-Left to Top-Right
	    set Gradient(x0) 0.00
	    set Gradient(y0) 1.00
	    set Gradient(x1) 1.00
	    set Gradient(y1) 0.00
	}
	6 {
#Left to Right 
	    set Gradient(x0) 0.00
	    set Gradient(y0) 0.00
	    set Gradient(x1) 1.00
	    set Gradient(y1) 0.00
	}
	7 {
#Top-Left to Bottom-Right
	    set Gradient(x0) 0.00
	    set Gradient(y0) 0.00
	    set Gradient(x1) 1.00
	    set Gradient(y1) 1.00
	}
	default {
	    puts "setLinear=$ind"
	}
      }
      ::gengrad::changetransition .tpgradient.frameFirst.canvas18
    }
  }

  proc TP_selcolorgr {but ind} {
    global Gradient
    set tekbg [$but cget -background]
    set color [tk_chooseColor -title "Color" -initialcolor $tekbg -parent .tpgradient]
    if {$color == ""} {
	set color $tekbg
    }
    $but configure -background $color
    set Gradient(color$ind) $color
    ::gengrad::changestops .tpgradient.frameFirst.canvas18
  }
  proc updategradient {} {
    global Gradient
    catch {    .tpgradient.frameFirst.canvas18 gradient delete $Gradient(newgr)}
    set newgr [creategradient .tpgradient.frameFirst.canvas18]
    set Gradient(newgr) $newgr
    .tpgradient.frameFirst.canvas18 itemconfigure $Gradient(viewgr) -fill $Gradient(newgr)
  }

  proc viewgradient {can } {
    set xx [cloneGradients]
    if {[info exist ::vgrad]} {
	if {[winfo exist [$::vgrad canvas]]} {
	    wm state .viewrad normal
	    eval "set zxzx $xx"
	    $::vgrad config -fillnormal $zxzx
#Вставляем шаблон команды для создания градиента
	    .viewrad.cmd delete 0.0 end
	    set ind1 [string first "gradient create" $xx]
	    set ind2 [string first "]" $xx]
	    incr ind2 -1
	    .viewrad.cmd insert 0.0 [string range $xx $ind1 $ind2]	    
	}
    }
    ::gengrad::changetransition $can
    ::gengrad::changestops $can
  }

  proc okgradient {} {
    global Gradient
    set xx [cloneGradients]
#puts "viewgradients=$xx"
    set Gradient(ret) ""
    if {[info exist ::vgrad]} {
	if {[winfo exist [$::vgrad canvas]]} {
	    wm state .viewrad normal
	    eval "set zxzx $xx"
	    $::vgrad config -fillnormal $zxzx
#Вставляем шаблон команды для создания градиента
	    .viewrad.cmd delete 0.0 end
	    set ind1 [string first "gradient create" $xx]
	    set ind2 [string first "]" $xx]
	    incr ind2 -1
	    set Gradient(ret) [string range $xx $ind1 $ind2]	    
#puts "Gradient(ret)=$Gradient(ret)"
	}
    }
    if {[info exist ::vgrad]} {
	$::vgrad destroy
	unset ::vgrad
    }
    exitarm .tpgradient
  }

  proc cancelgradient {} {
    global Gradient
#puts "cancelgradient: Cancel"
    set Gradient(ret) ""
    if {[info exist ::vgrad]} {
	$::vgrad destroy
	unset ::vgrad
    }
    exitarm .tpgradient
  }

  proc deletestop {w} {
    global Gradient
#    puts "Delete last stop";
    if {$Gradient(i) < 3} {
	return
    }
    set i $Gradient(i)
    incr i -1
    unset Gradient(offset$i)
    gengrad::spin1r$i destroy
    ::gengrad::spin2r$i destroy
    destroy $w.frame$i
    unset Gradient(color$i)
    unset Gradient(opacity$i)
    set Gradient(i) $i
    incr i -1
    [gengrad::spin1r$i entry] configure -to 1.0
    ::gengrad::updategradient
  }

  proc settransition {} {
    global Gradient
    if {$Gradient(type) == "linear"} {
	pack forget .tpgradient.frameFirst.frame0.frame4
	pack forget .tpgradient.frameFirst.frame0.fbboxr
	pack forget .tpgradient.frameFirst.frame0.radial
	if {$Gradient(unitssel) == 1} {
	    pack forget .tpgradient.frameFirst.frame0.fbboxl
	    pack .tpgradient.frameFirst.frame0.frame3 -anchor n -expand 1 -fill x -pady 0 -side top
	    pack .tpgradient.frameFirst.frame0.label1 .tpgradient.frameFirst.frame0.frame2 .tpgradient.frameFirst.frame0.frame3 .tpgradient.frameFirst.frame0.linear -in .tpgradient.frameFirst.frame0 -anchor w
	    pack configure  .tpgradient.frameFirst.frame0.linear -anchor center
	} else {
	    pack forget .tpgradient.frameFirst.frame0.frame3
	    pack .tpgradient.frameFirst.frame0.fbboxl -anchor n -expand 1 -fill x -pady 0 -side top
	    pack .tpgradient.frameFirst.frame0.label1 .tpgradient.frameFirst.frame0.frame2 .tpgradient.frameFirst.frame0.fbboxl .tpgradient.frameFirst.frame0.linear -in .tpgradient.frameFirst.frame0 -anchor w
	    pack configure  .tpgradient.frameFirst.frame0.linear -anchor center
	}
    } else {
	pack forget .tpgradient.frameFirst.frame0.fbboxl
	pack forget .tpgradient.frameFirst.frame0.frame3
	pack forget .tpgradient.frameFirst.frame0.linear
	if {$Gradient(unitssel) == 1} {
	    pack forget .tpgradient.frameFirst.frame0.fbboxr
	    pack .tpgradient.frameFirst.frame0.frame4 -anchor n -expand 1 -fill x -pady 0 -side top
	    pack .tpgradient.frameFirst.frame0.label1 .tpgradient.frameFirst.frame0.frame2 .tpgradient.frameFirst.frame0.frame4 .tpgradient.frameFirst.frame0.radial -in .tpgradient.frameFirst.frame0 -anchor w
	    pack configure .tpgradient.frameFirst.frame0.radial -anchor center -pady "0 0.5"
	} else {
	    pack forget .tpgradient.frameFirst.frame0.frame4
	    pack .tpgradient.frameFirst.frame0.fbboxr -anchor n -expand 1 -fill x -pady 0 -side top
	    pack .tpgradient.frameFirst.frame0.label1 .tpgradient.frameFirst.frame0.frame2 .tpgradient.frameFirst.frame0.fbboxr .tpgradient.frameFirst.frame0.radial -in .tpgradient.frameFirst.frame0 -anchor w
	    pack configure .tpgradient.frameFirst.frame0.radial -anchor center -pady "0 0.5"
	}
    }
  }

  proc setuserspace {} {
    global Gradient
    if {$Gradient(unitssel) == 1} {
	set Gradient(units) "userspace"
    } else {
	set Gradient(units) "bbox"
    }
    ::gengrad::settransition
  }

  proc createstop {wfr i} {
    global Gradient
#puts "createstop: wfr=$wfr i=$i"
    frame $wfr.frame$i -borderwidth {2} -relief {flat} -height {30} -width {30} -background  gray95
    if {![info exists  Gradient(color$i)]} {
	set Gradient(color$i) skyblue
	set Gradient(offset$i) 1.0
	set Gradient(opacity$i) 1.0
    }

    set w $wfr.frame$i
    eval [subst "button $w.button1 -activebackground {#d6d2d0} -background gray95 -command {::gengrad::TP_selcolorgr $w.button1 $i} -padx {2} -pady {0} -width {4} -bg  $Gradient(color$i)"]

    pack $w.button1 -anchor center -expand 0 -fill none -padx 4 -pady 0 -side left

    label $w.label1 -background gray95 -borderwidth {0} -foreground "#221f1e" -padx {0} -pady {0} -text {Offset:}

    pack $w.label1 -anchor center -expand 0 -fill none -padx 0 -pady 0 -side left

    label $w.label2 -background gray95 -borderwidth {0} -foreground "#221f1e" -padx {0} -pady {0} -relief {flat} -text {Color:}

    pack $w.label2 -anchor center -expand 0 -fill none -padx 0 -pady 0 -side left

    label $w.label3 -background gray95 -borderwidth {0} -foreground "#221f1e" -relief {flat} -text {Opacity:}

    pack $w.label3 -anchor center -expand 0 -fill none -padx 0 -pady 0 -side left

    eval [subst "label $w.label4 -background gray95 -borderwidth {0} -foreground {#221f1e} -padx {0} -pady {0} -text {Stop $i:}"]

    pack $w.label4 -anchor center -expand 0 -fill none -padx 5 -pady 0 -side left
    if {$i == 0} {
	set j 0
	set min 0
    } else {
	set j [expr {$i - 1}]
	set min $Gradient(offset$j)
    }
    if {$i < [expr {$Gradient(i) - 1}]} {
	set l [expr {$i + 1}]
	set max $Gradient(offset$l)
    } else {
	set max 1.0
    }
    eval [subst "cframe create ::gengrad::spin1r$i $w.spinbox1 -type cspin -background gray95 -stroke orange -strokewidth 0.5m"]
    eval [subst {[::gengrad::spin1r$i entry] configure  -from $min  -increment {0.01} -to $max  -width {4} -textvariable Gradient(offset$i) -command {::gengrad::changestops .tpgradient.frameFirst.canvas18 $i $wfr.frame}}]
    pack $w.spinbox1 -anchor center -expand 0 -fill none -padx 4 -pady 0 -side left
    eval [subst "cframe create ::gengrad::spin2r$i $w.spinbox2 -type cspin -background gray95 -stroke gray70"]
    eval [subst {[::gengrad::spin2r$i entry] configure  -from {0.0}  -increment {0.01} -to {1.0}  -width {4} -textvariable Gradient(opacity$i) -command {::gengrad::changestops .tpgradient.frameFirst.canvas18}}]

    pack $w.spinbox2 -anchor center -expand 0 -fill none -padx 0 -pady 0 -side left

    pack $w.label4 $w.label1 $w.spinbox1 $w.label2 $w.button1 $w.label3 $w.spinbox2 -in $w

    pack $w -anchor center -expand 0 -fill x -padx 2m -pady 0 -side top
#puts "createstop: i=$i Gradient(i)=$Gradient(i)"
    if {$i >= $Gradient(i)} {
	incr Gradient(i)
    }
  }
  proc creategradient {can} {
    global Gradient
    if {$Gradient(type) == "linear"} {
	set tran " -lineartransition \{$Gradient(x0) $Gradient(y0) $Gradient(x1) $Gradient(y1)\} "
    } else {
	set tran " -radialtransition \{$Gradient(cx) $Gradient(cy) $Gradient(r) $Gradient(fx) $Gradient(fy)\} "
    }
    set cmd "$can gradient create $Gradient(type) $tran -units $Gradient(units) -stops \{"
    set i 0
    for {set i 0} {$i < $Gradient(i)} {incr i} {
	append cmd " \{ $Gradient(offset$i) $Gradient(color$i) $Gradient(opacity$i)\}"
    }
    append cmd "\}"
#puts "creategradient can=$can: cmd=$cmd"
    return [eval $cmd]
  }
  proc changetransition {can} {
    global Gradient
    if {$Gradient(type) == "linear"} {
	set tran " -lineartransition \{$Gradient(x0) $Gradient(y0) $Gradient(x1) $Gradient(y1)\} "
    } else {
	set tran " -radialtransition \{$Gradient(cx) $Gradient(cy) $Gradient(r) $Gradient(fx) $Gradient(fy)\} "
    }
    set cmd "$can gradient configure $Gradient(newgr) $tran"
    eval $cmd
  }
  proc changestops {can {ind -1} {w ""} } {
    global Gradient
    set cmd "$can gradient configure $Gradient(newgr)  -stops \{"
    set i 0
    for {set i 0} {$i < $Gradient(i)} {incr i} {
	append cmd " \{ $Gradient(offset$i) $Gradient(color$i) $Gradient(opacity$i)\}"
    }
    append cmd "\}"
    eval $cmd
    if {$ind > -1} {
	set i [expr {$ind - 1}]
	if {$i >= 0} {
	    [::gengrad::spin1r$i entry] configure -to $Gradient(offset$ind)
	}
	set i [expr {$ind + 1}]
	if {$i < $Gradient(i)} {
	    [::gengrad::spin1r$i entry] configure -from $Gradient(offset$ind)
	}
    }
  }

  proc parsegradient {can grad} {
    array set Gradient []
    set Gradient(type) [$can gradient type $grad]
    set Gradient(units) [$can gradient cget $grad -units]
    if {$Gradient(type) == "linear"} {
	foreach {Gradient(x0) Gradient(y0) Gradient(x1) Gradient(y1)} [$can gradient cget $grad -lineartransition] {break}
    } else {
	foreach {Gradient(cx) Gradient(cy) Gradient(r) Gradient(fx) Gradient(fy)} [$can gradient cget $grad -radialtransition] {break}
    }
    set i 0
    foreach stop [$can gradient cget $grad -stops] {
	foreach {offset color opacity} $stop {
	    set Gradient(offset$i) $offset
	    set Gradient(color$i) $color
	    if {$opacity == ""} {
		set Gradient(opacity$i) 1.00
	    } else {
		set Gradient(opacity$i) $opacity
	    }
	}
	incr i
    }
    if {$Gradient(units) == "bbox"} {
	set Gradient(unitssel) 0
    } else {
	set Gradient(unitssel) 1
    }
    set Gradient(i) $i

    return [array get Gradient]
  }

  proc cloneGradients { } {
# Generate and return image loading code
    set wcan ".tpgradient.frameFirst.canvas18"
    set rtnval {}
    set rtnvalWin {}
    foreach grad [$wcan gradient names] {
	if {[$wcan gradient inuse $grad] == 0}  {
	    continue
	}
	    set type [$wcan gradient type $grad]
	    set cmd ".c gradient create $type "
	    set cmdWin ".viewrad.can gradient create $type "

	    foreach option [$wcan gradient configure $grad] {
		  set optval [lindex $option 4]
		  if {$optval != {}} {
		      lappend cmd [lindex $option 0] $optval
		      lappend cmdWin [lindex $option 0] $optval
		    } 
	    }
	set cm1 "set $grad \["
	append cm1 "$cmd \]"
	    append rtnval $cm1\n
	set cm1 " \["
	append cm1 "$cmdWin \]"
	    append rtnvalWin $cm1\n
    }

    append rtnval "\n"
    append rtnvalWin "\n"
    return $rtnvalWin
  }
  proc setmatrixstart {w id } {
    if { [set ::svgwidget::matrix] == "::tkp::matrix"} {
	set m [list {1.0 0.0} {-0.0 1.0} {0.0 0.0}]
    } else {
	set m [list 1.0 0.0 -0.0 1.0 0.0 0.0]
    }
    $w itemconfigure $id -m $m
  }

  proc createConfigMenu { oow fm direct {mtype 0}} {
    set arraydir {"Top to Bottom" "Top-Right to Bottom-Left" "Right to Left" "Bottom-Right to Top-Left" "Bottom to Top" "Bottom-Left to Top-Right" "Left to Right" "Top-Left to Bottom-Right"}
# oow - кнопка, для которой создаем меню
# fm - короткое имя виджета 
#direct - направление язычка
# mtype - 0 меню создается в окне кнопки; 1 - меню создается в отдельном окне 
#set mtype 0
    variable t
    if {$::cmenubut != ""}  {
	$::cmenubut destroy
    }

    set mm2px [winfo pixels [$oow canvas] 1m]
    set win [winfo toplevel [$oow canvas]]
    if {$mtype == 1} {
#Меню в отдельном окне
	set ::cmenubut [cmenu create "Obj[incr ::gengrad::i]" "$fm" -tongue "0.45 0.5 0.55 2m" -direction $direct -strokewidth 2 -pad 1m -command "" -fillnormal GhostWhite  -stroke gray70 -height 6m -type window ]
    } else {
#Меню во фрейме
	set ::cmenubut [cmenu create "Obj[incr ::gengrad::i]" "$fm" -tongue "0.45 0.5 0.55 2m" -direction $direct -strokewidth 2 -pad 1m -command "" -fillnormal GhostWhite  -stroke gray70 -height 6m -type canvas ]
    }

    for {set i 0} {$i < 8 } {incr i} {
	set gr [$fm create group]
	setmatrixstart $fm $gr
	[lindex [lindex $arraydir $i] 0 ] $fm $gr
	
	eval "$::cmenubut add command  -text \"[lindex $arraydir $i]\" -command {::gengrad::setLinear [set i] .tpgradient.frameFirst.canvas18} -image \"$fm $gr\" -compound left -ipad {1m 6m 1m 6m}"
    }
    $::cmenubut add separator
    eval "$oow config -command {update;$fm delete $gr}"

    set mbut [$::cmenubut add finish]
#    $mbut config -command ""
    $oow config -menu $::cmenubut -displaymenu release
    return $::cmenubut
  }

#set arraydir {"Top to Bottom" "Top-Right to Bottom-Left" "Right to Left" "Bottom-Right to Top-Left" "Bottom to Top" "Bottom-Left to Top-Right" "Left to Right" "Top-Left to Bottom-Right"}
  proc Top {fm gr} {
    return [$fm create polyline {18.89763779527559 3.779527560055118 18.89763779527559 32.340730136005725} -stroke "#FF6347" -strokewidth 6.0 -startarrowwidth 11.0 -startarrowfill 0.4 -endarrow 1 -endarrowwidth 11.0 -endarrowfill 0.4 -parent $gr]
  }
  proc Top-Right {fm gr} {
    return [$fm create polyline {30.236220472440944 3.779527560055118 5.575449216878349 31.96326613684094} -stroke "#FF6347" -strokewidth 6.0 -startarrowwidth 11.0 -startarrowfill 0.4 -endarrow 1 -endarrowwidth 11.0 -endarrowfill 0.4 -parent $gr]
  }
  proc Right {fm gr} {
    return [$fm create polyline {6.506800286327845 18.89763779527559 34.01574803149606 18.89763779527559} -stroke "#FF6347" -strokewidth 6.0 -startarrow 1 -startarrowwidth 11.0 -startarrowfill 0.4 -endarrowwidth 11.0 -endarrowfill 0.4 -parent $gr]
  }
  proc Bottom-Right {fm gr} {
    return [$fm create polyline {9.354976775933467 5.832009453710239 32.21982637367283 31.96326613684094} -stroke "#FF6347" -strokewidth 6.0 -startarrow 1 -startarrowwidth 11.0 -startarrowfill 0.4 -endarrowwidth 11.0 -endarrowfill 0.4 -parent $gr]
  }
  proc Bottom {fm gr} {
    return [$fm create polyline {18.89763779527559 6.506800286327845 18.89763779527559 35.06800286327845} -stroke "#FF6347" -strokewidth 6.0 -startarrow 1 -startarrowwidth 11.0 -startarrowfill 0.4 -endarrowwidth 11.0 -endarrowfill 0.4 -parent $gr]
  }
  proc Bottom-Left {fm gr} {
    return [$fm create polyline {28.440298814617712 5.8320094537102385 3.779527560055118 34.01574803149606} -stroke "#FF6347" -strokewidth 6.0 -startarrow 1 -startarrowwidth 11.0 -startarrowfill 0.4 -endarrowwidth 11.0 -endarrowfill 0.4 -parent $gr]
  }
  proc Left {fm gr} {
    return [$fm create polyline {3.779527560055118 18.89763779527559 31.288475304223333 18.89763779527559} -stroke "#FF6347" -strokewidth 6.0 -startarrowwidth 11.0 -startarrowfill 0.4 -endarrow 1 -endarrowwidth 11.0 -endarrowfill 0.4 -parent $gr]
  }
  proc Top-Left {fm gr} {
    return [$fm create polyline {7.560055118110236 3.779527560055118 32.21982637367283 31.96326613684094} -stroke "#FF6347" -strokewidth 6.0 -startarrowwidth 11.0 -startarrowfill 0.4 -endarrow 1 -endarrowwidth 11.0 -endarrowfill 0.4 -parent $gr]
  }

 proc generateGradient { {args ""}} {
  package require scrollutil_tile
  global Gradient
  catch "destroy .tpgradient"
  catch {unset Gradient}
  if {$args == "" || [llength $args] != 2} {
    set Gradient(type) linear
    set Gradient(color0) "#57f1b3"
    set Gradient(color1) "#c63e31"
    set Gradient(offset0) 0.0
    set Gradient(offset1) 1.0
    set Gradient(opacity0) 1.0
    set Gradient(opacity1) 1.0
    set Gradient(x0) 0
    set Gradient(x1) 1
    set Gradient(y0) 0
    set Gradient(y1) 0
    set Gradient(cx) 0.5
    set Gradient(cy) 0.5
#    set Gradient(r) 0.5
    set Gradient(r) 1.00
#    set Gradient(fx) 0.25
#    set Gradient(fy) 0.25
    set Gradient(fx) 0.50
    set Gradient(fy) 0.50
    set Gradient(units) "bbox"
    set Gradient(unitssel) 0
    set Gradient(i) 2
  } else {
    array set Gradient [parsegradient [lindex $args 0]  [lindex $args 1]]
    if {$Gradient(type) == "linear"} {
	set Gradient(cx) 0.5
	set Gradient(cy) 0.5
#	set Gradient(r) 0.5
	set Gradient(r) 1.00
#	set Gradient(fx) 0.25
#	set Gradient(fy) 0.25
	set Gradient(fx) 0.50
	set Gradient(fy) 0.50
    } else {
	set Gradient(x0) 0
	set Gradient(x1) 1
	set Gradient(y0) 0
	set Gradient(y1) 0
    }

#    puts "ShowWindow.tpgradient: Gradient(i)=$Gradient(i)"
  }
    switch -- $::tcl_platform(platform) {
	"windows"        {
		set svgFont "Arial Narrow"
	    }
	"unix" - default {
		set svgFont "Nimbus Sans Narrow"
	    }
    }

  toplevel .tpgradient -background "#dcdcdc"  -highlightbackground "#dcdcdc"

  # Window manager configurations
  wm positionfrom .tpgradient ""
  wm sizefrom .tpgradient ""
  wm maxsize .tpgradient 660 640
  wm minsize .tpgradient 600 430
  wm geometry .tpgradient 600x430+500+300
  wm title .tpgradient {SVGWIDGETS: генерация градиента}
  wm protocol .tpgradient WM_DELETE_WINDOW {gengrad::cancelgradient}

  variable Gradienttype

  frame .tpgradient.frameFirst -borderwidth {1} -relief {raised} -background "#d6d2d0" -height {30} -width {30}

  $::svgwidget::tkpath .tpgradient.frameFirst.canvas18 -background "#FFE4C4" -height {87} -highlightthickness 0 -selectborderwidth {0} -width {100}

  pack .tpgradient.frameFirst.canvas18 -anchor n -expand 0 -fill none -padx "0 1m" -pady "2m 0" -side right

  frame .tpgradient.frameFirst.frame0 -borderwidth {2} -relief {flat} -background "#d6d2d0" -height {30} -width {30}

  frame .tpgradient.frameFirst.frame0.frame2 -borderwidth {2} -relief {flat} -background "#d6d2d0" -height {30} -width {30}

  set blin [cbutton create "Obj[incr ::gengrad::i]" .tpgradient.radiobutton3 -background "#d6d2d0" -type radio -text {Linear} -command {::gengrad::settransition;::gengrad::updategradient}  -value linear -variable Gradient(type)]

  set brad [cbutton create "Obj[incr ::gengrad::i]" .tpgradient.radiobutton4 -background "#d6d2d0" -type radio -text {Radial} -command {::gengrad::settransition;::gengrad::updategradient}  -value radial -variable Gradient(type)]

  cbutton create "Obj[incr ::gengrad::i]"  .tpgradient.frameFirst.frame0.frame2.checkunits -type check -variable {Gradient(unitssel)}  -text {userspace:} -command {::gengrad::setuserspace} -state disabled

  $blin pack -anchor center -expand 1 -fill none -padx 2.5m -pady 0 -side left -in .tpgradient.frameFirst.frame0.frame2
#pack .tpgradient.frameFirst.frame0.frame2.radiobutton4 -anchor center -expand 1 -fill none -padx 10 -pady 0 -side left
  $brad pack -anchor center -expand 1 -fill none -padx 2.5m -pady 0 -side left -in .tpgradient.frameFirst.frame0.frame2

  pack .tpgradient.frameFirst.frame0.frame2.checkunits -anchor center -expand 1 -fill none -padx 10 -pady 0 -side left
  pack .tpgradient.frameFirst.frame0.frame2 -anchor n -expand 0 -fill x -padx 40 -pady 0 -side top
#For userspace
#Linear transition
    set wtrl ".tpgradient.frameFirst.frame0.frame3"
    frame $wtrl -borderwidth {2} -relief {flat} -background "#d6d2d0" -height {10} 
    label $wtrl.l1 -text {Transition:} 
    pack $wtrl.l1 -side left
    label $wtrl.l2 -background "#d6d2d0" -borderwidth {0} -foreground "#221f1e" -relief {flat} -text {x0:}
    pack $wtrl.l2 -anchor center -expand 0 -side left
    entry $wtrl.e2 -background {white} -textvariable Gradient(x0) -borderwidth {0} -foreground "#221f1e"  -width 5 -highlightthickness {0} 
    pack $wtrl.e2 -anchor center -expand 0 -padx 1 -side left -fill none -padx 0 -pady 0 
    label $wtrl.l4 -background "#d6d2d0" -borderwidth {0} -foreground "#221f1e" -relief {flat} -text {y0:}
    pack $wtrl.l4 -anchor center -expand 0 -side left
    entry $wtrl.e4 -background {white} -textvariable Gradient(y0) -borderwidth {0} -relief {flat} -foreground "#221f1e"  -width {5} -highlightthickness {0}
    pack $wtrl.e4 -anchor center -expand 0 -padx 1 -side left
    label $wtrl.l3 -background "#d6d2d0" -borderwidth {0} -foreground "#221f1e" -relief {flat} -text {x1:}
    pack $wtrl.l3 -anchor center -expand 0 -side left
    entry $wtrl.e3 -background {white} -textvariable Gradient(x1) -borderwidth {0} -relief {flat} -foreground "#221f1e"  -width {5} -highlightthickness {0}
    pack $wtrl.e3 -anchor center -expand 0 -padx 1 -side left
    label $wtrl.l5 -background "#d6d2d0" -borderwidth {0} -foreground "#221f1e" -relief {flat} -text {y1:}
    pack $wtrl.l5 -anchor center -expand 0 -side left
    entry $wtrl.e5 -background {white} -textvariable Gradient(y1) -borderwidth {0} -relief {flat} -foreground "#221f1e"  -width {5} -highlightthickness {0}
    pack $wtrl.e5 -anchor center -expand 0 -padx 1 -side left
#Radial transition
    set wtrr ".tpgradient.frameFirst.frame0.frame4"
    frame $wtrr -borderwidth {2} -relief {flat} -background "#d6d2d0" -height {10} 
    label $wtrr.l1 -text {Transition:} 
    pack $wtrr.l1 -side left
    label $wtrr.l2 -background "#d6d2d0" -borderwidth {0} -foreground "#221f1e" -relief {flat} -text {cx:}
    pack $wtrr.l2 -anchor center -expand 0 -side left
    entry $wtrr.e2 -background {white} -textvariable Gradient(cx) -borderwidth {0} -relief {flat} -foreground {#221f1e}  -width {4} -highlightthickness {0} -highlightthickness {0}
    pack $wtrr.e2 -anchor center -expand 0 -padx 1 -side left
    label $wtrr.l3 -background {#d6d2d0} -borderwidth {0} -foreground {#221f1e} -relief {flat} -text {cy:}
    pack $wtrr.l3 -anchor center -expand 0 -side left
    entry $wtrr.e3 -background {white} -textvariable Gradient(cy) -borderwidth {0} -relief {flat} -foreground {#221f1e}  -width {4} -highlightthickness {0}
    pack $wtrr.e3 -anchor center -expand 0 -padx 1 -side left
    label $wtrr.l4 -background {#d6d2d0} -borderwidth {0} -foreground {#221f1e} -relief {flat} -text {r:}
    pack $wtrr.l4 -anchor center -expand 0 -side left
    entry $wtrr.e4 -background {white} -textvariable Gradient(r) -borderwidth {0} -relief {flat} -foreground {#221f1e}  -width {4} -highlightthickness {0}
    pack $wtrr.e4 -anchor center -expand 0 -padx 1 -side left
    label $wtrr.l5 -background {#d6d2d0} -borderwidth {0} -foreground {#221f1e} -relief {flat} -text {fx:}
    pack $wtrr.l5 -anchor center -expand 0 -side left
    entry $wtrr.e5 -background {white} -textvariable Gradient(fx) -borderwidth {0} -relief {flat} -foreground {#221f1e}  -width {4} -highlightthickness {0}
    pack $wtrr.e5 -anchor center -expand 0 -padx 1 -side left
    label $wtrr.l6 -background {#d6d2d0} -borderwidth {0} -foreground {#221f1e} -relief {flat} -text {fy:}
    pack $wtrr.l6 -anchor center -expand 0 -side left
    entry $wtrr.e6 -background {white} -textvariable Gradient(fy) -borderwidth {0} -relief {flat} -foreground {#221f1e}  -width {4} -highlightthickness {0}
    pack $wtrr.e6 -anchor center -expand 0 -padx 1 -side left
    pack $wtrr -anchor n -expand 1 -fill x -pady 0 -side top
#For bbox
#Linear transition
    set wtrlb ".tpgradient.frameFirst.frame0.fbboxl"
    frame $wtrlb -borderwidth {2} -relief {flat} -background "#d6d2d0" -height {10} 
    label $wtrlb.l1 -text {Transition:} 
    pack $wtrlb.l1 -side left
    label $wtrlb.l2 -background "#d6d2d0" -borderwidth {0} -foreground "#221f1e" -relief {flat} -text {x0:}
    pack $wtrlb.l2 -anchor center -expand 0 -side left
    spinbox $wtrlb.e2 -background {white} -textvariable Gradient(x0) -borderwidth 0 -highlightthickness 0 -buttonbackground "#d6d2d0" -foreground "#221f1e" -increment {0.01} -to {1.0} -width {5} -command {::gengrad::changetransition .tpgradient.frameFirst.canvas18}
    pack $wtrlb.e2 -anchor center -expand 0 -padx 1 -side left -fill none -padx 0 -pady 0 
    label $wtrlb.l4 -background "#d6d2d0" -borderwidth {0} -foreground "#221f1e" -relief {flat} -text {y0:}
    pack $wtrlb.l4 -anchor center -expand 0 -side left
    spinbox $wtrlb.e4 -background {white} -textvariable Gradient(y0) -borderwidth 0 -highlightthickness 0 -buttonbackground "#d6d2d0" -foreground "#221f1e" -increment {0.01} -to {1.0} -width {5} -command {::gengrad::changetransition .tpgradient.frameFirst.canvas18}
    pack $wtrlb.e4 -anchor center -expand 0 -padx 1 -side left
    label $wtrlb.l3 -background "#d6d2d0" -borderwidth {0} -foreground "#221f1e" -relief {flat} -text {x1:}
    pack $wtrlb.l3 -anchor center -expand 0 -side left
    spinbox $wtrlb.e3 -background {white} -textvariable Gradient(x1) -borderwidth 0 -highlightthickness 0 -buttonbackground "#d6d2d0" -foreground "#221f1e" -increment {0.01} -to {1.0} -width {5} -command {::gengrad::changetransition .tpgradient.frameFirst.canvas18}
    pack $wtrlb.e3 -anchor center -expand 0 -padx 1 -side left
    label $wtrlb.l5 -background "#d6d2d0" -borderwidth {0} -foreground "#221f1e" -relief {flat} -text {y1:}
    pack $wtrlb.l5 -anchor center -expand 0 -side left
    spinbox $wtrlb.e5 -background {white} -textvariable Gradient(y1) -borderwidth 0 -highlightthickness 0 -buttonbackground "#d6d2d0" -foreground "#221f1e" -increment {0.01} -to {1.0} -width {5} -command {::gengrad::changetransition .tpgradient.frameFirst.canvas18}
    pack $wtrlb.e5 -anchor center -expand 0 -padx 1 -side left
#Radial transition
    set wtrrb ".tpgradient.frameFirst.frame0.fbboxr"
    frame $wtrrb -borderwidth {2} -relief {flat} -background {#d6d2d0} -height {10} 
    label $wtrrb.l1 -text {Transition:} 
    pack $wtrrb.l1 -side left
    label $wtrrb.l2 -background {#d6d2d0} -borderwidth {0} -foreground {#221f1e} -relief {flat} -text {cx:}
    pack $wtrrb.l2 -anchor center -expand 0 -side left
    spinbox $wtrrb.e2 -background {white} -textvariable Gradient(cx) -borderwidth 0 -highlightthickness 0 -buttonbackground "#d6d2d0" -foreground "#221f1e" -increment {0.01} -to {1.0} -width {4} -command {::gengrad::changetransition .tpgradient.frameFirst.canvas18}
    pack $wtrrb.e2 -anchor center -expand 0 -padx 1 -side left
    label $wtrrb.l3 -background {#d6d2d0} -borderwidth {0} -foreground {#221f1e} -relief {flat} -text {cy:}
    pack $wtrrb.l3 -anchor center -expand 0 -side left
    spinbox $wtrrb.e3 -background {white} -textvariable Gradient(cy) -borderwidth 0 -highlightthickness 0 -buttonbackground "#d6d2d0" -foreground "#221f1e" -increment {0.01} -to {1.0} -width {4} -command {::gengrad::changetransition .tpgradient.frameFirst.canvas18}
    pack $wtrrb.e3 -anchor center -expand 0 -padx 1 -side left
    label $wtrrb.l4 -background {#d6d2d0} -borderwidth {0} -foreground {#221f1e} -relief {flat} -text {r:}
    pack $wtrrb.l4 -anchor center -expand 0 -side left
    spinbox $wtrrb.e4 -background {white} -textvariable Gradient(r) -borderwidth 0 -highlightthickness 0 -buttonbackground "#d6d2d0" -foreground "#221f1e" -increment {0.01} -to {1.0} -width {4} -command {::gengrad::changetransition .tpgradient.frameFirst.canvas18}
    pack $wtrrb.e4 -anchor center -expand 0 -padx 1 -side left
    label $wtrrb.l5 -background {#d6d2d0} -borderwidth {0} -foreground {#221f1e} -relief {flat} -text {fx:}
    pack $wtrrb.l5 -anchor center -expand 0 -side left
    spinbox $wtrrb.e5 -background {white} -textvariable Gradient(fx) -borderwidth 0 -highlightthickness 0 -buttonbackground "#d6d2d0" -foreground "#221f1e" -increment {0.01} -to {1.0} -width {4} -command {::gengrad::changetransition .tpgradient.frameFirst.canvas18}
    pack $wtrrb.e5 -anchor center -expand 0 -padx 1 -side left
    label $wtrrb.l6 -background {#d6d2d0} -borderwidth {0} -foreground {#221f1e} -relief {flat} -text {fy:}
    pack $wtrrb.l6 -anchor center -expand 0 -side left
    spinbox $wtrrb.e6 -background {white} -textvariable Gradient(fy) -borderwidth 0 -highlightthickness 0 -buttonbackground "#d6d2d0" -foreground "#221f1e" -increment {0.01} -to {1.0} -width {4} -command {::gengrad::changetransition .tpgradient.frameFirst.canvas18}
    pack $wtrrb.e6 -anchor center -expand 0 -padx 1 -side left

  label .tpgradient.frameFirst.frame0.label1 -background "#d6d2d0" -foreground "#221f1e" -relief {flat} -text {Тип градиента}

  pack .tpgradient.frameFirst.frame0.label1 -anchor n -expand 0 -fill none -padx 0 -pady 0 -side top

  set arraydir {"Top to Bottom" "Top-Right to Bottom-Left" "Right to Left" "Bottom-Right to Top-Left" "Bottom to Top" "Bottom-Left to Top-Right" "Left to Right" "Top-Left to Bottom-Right"}

#Заготовки для градиента linear
  frame .tpgradient.frameFirst.frame0.linear -borderwidth {2} -relief {flat} -background yellow
  label .tpgradient.frameFirst.frame0.linear.lab -background "#d6d2d0" -foreground "#221f1e" -relief {flat} -text "Направление: "

  set ::lmenu [cbutton create mlin .tpgradient.frameFirst.frame0.linear.direction -type rect -text " Шаблоны направлений" -fontsize 3.5m -compound left]

  set w ".tpgradient.frameFirst.frame0.linear.direction"
  set gr [$w create group]
if {1} {
  $w create path {M 0 511.874 V 341.069 l 53.101 53.101 l 92.948 -91.948 c 7.661 13.198 16.904 25.254 27.627 35.977 c 10.84 10.84 22.866 20.112 35.903 27.686 l -91.875 91.89 l 53.101 54.101 H 0 V 511.874 z} \
    -fill "#7986E8" -stroke {} -parent $gr
  $w create path {M 341.195 511.874 l 53.101 -54.101 l -91.948 -91.948 c 13.198 -7.661 25.239 -16.89 35.962 -27.612 c 10.811 -10.781 20.068 -22.822 27.686 -35.947 L 458.9 394.17 l 53.1 -53.101 v 170.805 H 341.195 z} \
    -fill "#4C5CE1" -stroke {} -parent $gr
  $w create path {M 458.899 118.828 l -92.948 91.948 c -7.661 -13.198 -16.904 -25.254 -27.627 -35.977 c -10.84 -10.84 -22.866 -20.112 -35.903 -27.686 l 91.875 -93.89 L 341.195 0.124 H 512 v 171.805 L 458.899 118.828 z} \
    -fill "#4C5CE1" -stroke {} -parent $gr
  $w create path {M 0 0.124 h 170.805 l -53.101 53.101 l 91.948 93.948 c -13.198 7.661 -25.254 16.904 -35.977 27.627 c -10.84 10.84 -20.098 22.852 -27.686 35.903 l -92.89 -91.875 L 0 171.929 V 0.124 z} \
    -fill "#7986E8" -stroke {} -parent $gr
  $w create path {M 380.263 203.345 c -6.636 -16.069 -16.304 -30.527 -28.755 -42.979 s -26.909 -22.119 -42.729 -28.652 c -33.516 -14.546 -71.997 -14.59 -105.308 -0.103 c -16.069 6.636 -30.527 16.304 -42.979 28.755 s -22.119 26.909 -28.652 42.729 c -14.561 33.545 -14.561 72.012 -0.103 105.308 c 6.636 16.069 16.304 30.527 28.755 42.979 s 26.909 22.119 42.729 28.652 c 16.802 7.295 34.834 10.928 52.852 10.928 c 17.93 0 35.845 -3.604 52.456 -10.825 c 16.069 -6.636 30.527 -16.304 42.979 -28.755 c 12.422 -12.407 22.075 -26.836 28.711 -42.861 C 394.721 275.02 394.706 236.597 380.263 203.345 z} \
    -fill "#FF3333" -stroke {} -parent $gr
  $w create path {M 351.508 160.366 c -12.451 -12.451 -26.909 -22.119 -42.729 -28.652 c -16.772 -7.28 -34.788 -10.922 -52.778 -10.933 v 270.174 c 0.024 0 0.049 0.007 0.073 0.007 c 17.93 0 35.845 -3.604 52.456 -10.825 c 16.069 -6.636 30.527 -16.304 42.979 -28.755 c 12.422 -12.407 22.075 -26.836 28.711 -42.861 c 14.502 -33.501 14.487 -71.924 0.044 -105.176 C 373.627 187.275 363.959 172.817 351.508 160.366 z} \
    -fill "#FD3018" -stroke {} -parent $gr
  $w create path {M 256 330.405 c -20.039 0 -39.36 -7.837 -53.027 -21.504 c -14.165 -14.15 -21.958 -32.988 -21.958 -53.027 s 7.793 -38.877 21.958 -53.027 c 14.15 -14.165 32.988 -21.958 53.027 -21.958 s 38.877 7.793 53.027 21.958 c 14.165 14.15 21.958 32.988 21.958 53.027 s -7.793 38.877 -21.958 53.027 C 295.36 322.568 276.039 330.405 256 330.405 z} \
    -fill "#FEDB41" -stroke {} -parent $gr
  $w create path {M 309.027 308.901 c 14.165 -14.15 21.958 -32.988 21.958 -53.027 s -7.793 -38.877 -21.958 -53.027 c -14.15 -14.165 -32.988 -21.958 -53.027 -21.958 v 149.517 C 276.039 330.405 295.36 322.568 309.027 308.901 z} \
    -fill "#FCBF29" -stroke {} -parent $gr
  $::lmenu config -isvg "$w $gr"
  $w delete $gr
}

set ::cmenubut ""

#Меню в отдельном окне .grad
set mmlin [createConfigMenu ::gengrad::mlin ".grad.gmenu"  up 1]
#Меню как фркйм в основном окне .tpgradient

$::lmenu config -menu $mmlin -displaymenu release
pack .tpgradient.frameFirst.frame0.linear.direction -expand 0 -fill none  -padx "0 0"  -side top -anchor e

#Заготовки для градиента radial
set arraypos {"Center" "Top" "Top-Right" "Right" "Bottom-Right" "Bottom" "Bottom-Left" "Left" "Top-Left" }
frame .tpgradient.frameFirst.frame0.radial -borderwidth {0} -relief {flat} -background yellow
label .tpgradient.frameFirst.frame0.radial.lab -background "#d6d2d0" -foreground "#221f1e" -relief {flat} -text "Позиция: "

variable varpos
set  varpos [lindex $arraypos 0]
set ::ltsp [cframe create "Obj[incr ::gengrad::i]" .tpgradient.frameFirst.frame0.radial.position -type ccombo -stroke orange -strokewidth 0.5m -fontsize 3.5m -rx 1m -textvariable "::gengrad::varpos" -values $arraypos ]
[$::ltsp entry] configure -font {helvetica 12}

set  varpos [lindex $arraypos 0]
bind [$::ltsp entry] <<ComboboxSelected>> {::gengrad::setRadial [[$::ltsp entry] current] .tpgradient.frameFirst.canvas18}
pack .tpgradient.frameFirst.frame0.radial.lab  -expand 0 -fill none  -padx 0.5m -pady 0 -side left
pack .tpgradient.frameFirst.frame0.radial.position -expand 0 -fill none  -padx "0 0" -pady 0  -side top -anchor e

pack .tpgradient.frameFirst.frame0 -anchor nw -expand  1 -fill x -padx 0 -pady 0 -side left

pack .tpgradient.frameFirst -anchor ne -expand 1 -fill both -padx 0 -pady 0 -side right
pack .tpgradient.frameFirst.frame0 .tpgradient.frameFirst.canvas18 -in .tpgradient.frameFirst


    frame .tpgradient.frameStops -borderwidth {1} -relief {raised}  -borderwidth 2 -background "#d6d2d0" 
    
    set f [frame .tpgradient.frame6 -borderwidth {0} -relief {flat} -background lightblue] 
    set sa [scrollutil::scrollarea $f.sa]
    set sf [scrollutil::scrollableframe $sa.sf]
    $sa setwidget $sf
    scrollutil::createWheelEventBindings all   
    set cf [$sf contentframe]
        
    label $cf.label5 -background snow -foreground "#221f1e" -relief {flat} -text {Компоненты градиента}
    pack $cf.label5 -expand 0 -fill none -padx 0 -pady 1m -side top -anchor center

    set i 0
    createstop "$cf" $i
    incr i
    createstop "$cf" $i

    set Gradient(newgr) [creategradient .tpgradient.frameFirst.canvas18]
    if {$::svgwidget::tkpath == "::tkp::canvas"} {
	set Gradient(viewgr) [.tpgradient.frameFirst.canvas18 create prect 0 0 100 87 -fill $Gradient(newgr) -tags {viewgr} -stroke "" -strokewidth 0]
    } else {
	set Gradient(viewgr) [.tpgradient.frameFirst.canvas18 create rect 0 0 100 87 -fill $Gradient(newgr) -tags {viewgr} -stroke "" -strokewidth 0]
    }

    incr i
    set buts ".tpgradient.frameStops.buts"
    frame $buts -borderwidth {2} -relief {flat} -background "#d6d2d0"
    eval "cbutton create addst $buts.butadd -type round -command {global Gradient; ::gengrad::createstop $cf \$Gradient(i)} -text {Добавить слой} -strokenormal skyblue -strokewidth 0.5m -fontsize 4m -fontfamily \"$svgFont\""

    cbutton create view $buts.butview -rx 2m -command {::gengrad::viewgradient ".tpgradient.frameFirst.canvas18"}  -text "Просмотр градиента" -strokenormal skyblue -strokewidth 0.5m -fontsize 4m -fontfamily "$svgFont"
    cbutton create ok $buts.butok -type ellipse -command {::gengrad::okgradient} -text "Готово" -strokenormal skyblue -strokewidth 0.5m -fontsize 4m -fontfamily "$svgFont"
    cbutton create canc $buts.butcan -type round -command {::gengrad::cancelgradient} -text "Cancel" -strokenormal skyblue -strokewidth 0.5m -fontsize 4m -fontfamily "$svgFont"
    eval "cbutton create delst $buts.butdel -command {::gengrad::deletestop $cf} -text {Удалить последний слой} -strokenormal skyblue -strokewidth 0.5m -fontsize 4m -fontfamily \"$svgFont\""

    pack $buts.butview -anchor ne -expand 0 -fill x -padx 1m -pady "3m 1m" -side top
    pack $buts.butadd -anchor ne -expand 0 -fill x -padx 1m -pady 1m -side top
    pack $buts.butdel -anchor ne -expand 0 -fill x -padx 1m -pady 1m -side top
    pack $buts.butcan -anchor ne -expand 0 -fill none -padx 1m -pady 1m -side top -anchor center
    pack $buts.butok -anchor ne -expand 0 -fill none -padx 1m -pady 1m -side top -anchor center

    pack $buts -anchor center -expand 1 -fill both -side right -in .tpgradient.frameStops
    pack .tpgradient.frameStops -anchor center -expand 1 -fill both -side bottom
    $f.sa.vsb configure -style My.Vertical.TScrollbar
    $f.sa.hsb configure -style My.Horizontal.TScrollbar
    pack $sa -fill both -expand 1 -padx 2m -pady 2m
    pack .tpgradient.frame6 -anchor center -expand 1 -fill both -padx "0 0" -pady 0 -side left -in .tpgradient.frameStops
    pack .tpgradient.frameStops .tpgradient.frameFirst -in .tpgradient

    if {$args != ""} {
	if {$Gradient(i) > 2} {
	    set i [expr {$Gradient(i) - 2}]
	    set j 2
	    while {$i > 0 } {
		createstop "$cf" $j
		incr i -1
		incr j
	    }
	}
    }
    ::gengrad::settransition
    set newgr [::gengrad::creategradient .tpgradient.frameFirst.canvas18]
#    puts "newgr=$newgr"
    ::gengrad::setLinear 0 ""

    set wgrad ".viewrad"
    toplevel $wgrad -bg snow
    wm title $wgrad "Кодогенерация градиента"
    wm withdraw $wgrad
    wm protocol $wgrad WM_DELETE_WINDOW [subst "wm withdraw $wgrad"]
    wm iconphoto $wgrad "$::gengrad::icongrad"
    wm iconphoto .tpgradient "$::gengrad::icongrad"

    wm geometry $wgrad 600x430+100+50
    set ::vgrad [cframe create "Obj[incr ::gengrad::i]" $wgrad.can -type clframe -text "Просмотр градиента" -fontsize 5m -fillnormal yellow -bg snow -strokewidth 1m -stroke cyan]
    $::vgrad boxtext
    pack $wgrad.can -fill both -expand 1 -padx 1m -pady {1m 0m}
    update
#Форма для команды генерации градиента
    text $wgrad.cmd -yscrollcommand [list $wgrad.scroll set] -setgrid 1 -height 5 -undo 1 -autosep 1 -highlightcolor cyan -highlightbackground cyan -highlightthickness 2
    ttk::scrollbar $wgrad.scroll -command [list $wgrad.cmd yview] -style My.Vertical.TScrollbar
    pack $wgrad.scroll -side right -fill y -pady 1m -padx {0 1m}
    pack $wgrad.cmd -expand 0 -fill both -pady 1m -padx {1m 0}
    update 
    set Gradient(type) $Gradient(type)
    tkwait window .tpgradient
    set ret $Gradient(ret)
    array unset Gradient
#puts "okgradients=$ret"
    return $ret
 }

}

package provide svgwidgets 0.3.3
