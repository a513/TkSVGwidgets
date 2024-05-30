proc id2coordscenter {wcan id} {
#Координаты прямоугольника вокруг объекта
    foreach {x0 y0 x1 y1} [$wcan bbox $id] {break}
#точка вращения - центр
    set xc [expr {($x1 - $x0) / 2.0 + $x0 }]
    set yc [expr {($y1 - $y0) / 2.0 + $y0 }]
    return [list $xc $yc]
}

proc scaleGroup {win w h x y} {
#puts "scaleGroup: w=$w h=$h x=$x y=$y"
    global Canv BBox
#set wcan ".test.c"
    set wcan $win
    set onemm2px [winfo fpixels $wcan 1m]
    set x [$wcan canvasx $x]
    set y [$wcan canvasx $y]
#    if {$Canv(W) == 1 || $Canv(H) == 1} {}
    if {![info exist Canv(W)]} {
	set Canv(W) [winfo width $wcan]
	set Canv(H) [winfo height $wcan]
	set Canv(X) [winfo rootx $wcan]
	set Canv(Y) [winfo rooty $wcan]
	set Canv(X1) [expr {$Canv(X) + $Canv(W)}]
	set Canv(Y1) [expr {$Canv(Y) + $Canv(H)}]
set bbox [$wcan bbox "canvasb"]
set BBox(x1) [lindex $bbox 0]
set BBox(y1) [lindex $bbox 1]
set BBox(x2) [lindex $bbox 2]
set BBox(y2) [lindex $bbox 3]
set BBox(xscale) 1
set BBox(action) none
	return
    }
#	set Canv(X1) [expr {$Canv(X) + $Canv(W)}]
#	set Canv(Y1) [expr {$Canv(Y) + $Canv(H)}]
    if {[$wcan bbox "canvasb"] == "" } {
	return
    }
#Ловим перемещение
if {$Canv(X) != [winfo rootx $wcan] && $Canv(Y) != [winfo rooty $wcan] && $Canv(X1) != [expr {[winfo rootx $wcan] + [winfo width $wcan]}] && $Canv(Y1) != [expr {[winfo rooty $wcan] + [winfo height $wcan]}]} {
	set Canv(X) [winfo rootx $wcan]
	set Canv(Y) [winfo rooty $wcan]
	set Canv(W) [winfo width $wcan]
	set Canv(H) [winfo height $wcan]
	set Canv(X1) [expr {$Canv(X) + $Canv(W)}]
	set Canv(Y1) [expr {$Canv(Y) + $Canv(H)}]
	return
}

set xScaleW [expr {$w * 1.0 / $Canv(W)}]
if {$xScaleW == 0} {
    set xScaleW 0.01
}
set yScaleW [expr {$h * 1.0 / $Canv(H)}]
if {$xScaleW == 0} {
    set yScaleW 0.01
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
if {$xScaleW == 0} {
    set xScaleW 0.01
}
set yScaleW [expr {($BBox(y2) - $BBox(y1) + $dh) * 1.0 / ($BBox(y2) - $BBox(y1))}]
if {$xScaleW == 0} {
    set yScaleW 0.01
}
############################


set x1 [winfo width $wcan]
set y1 [winfo height $wcan]
set x [winfo rootx $wcan]
set y [winfo rooty $wcan]
#set x1 $x
#set y1 $y

    if {$Canv(W) == $w && $Canv(H) == $h} {
#	set Canv(X) [winfo rootx $wcan]
#	set Canv(Y) [winfo rooty $wcan]
	set Canv(X) $x
	set Canv(Y) $y
	set Canv(X) [winfo rootx $wcan]
	set Canv(Y) [winfo rooty $wcan]
	set Canv(X1) [expr {$Canv(X) + $Canv(W)}]
	set Canv(Y1) [expr {$Canv(Y) + $Canv(H)}]
	set BBox(action) none
    } elseif {$Canv(W) == $w} {
        if {abs($h - $Canv(H)) < 2} {return}
	set Canv(H) $h
#	set x [expr {}]
	if {$y == $Canv(Y)} {
	    set BBox(action) s
	} else {
	    set Canv(Y) $y
	    set BBox(action) n
	}
    } elseif {$Canv(H) == $h} {
        if {abs($w - $Canv(W)) < 2} {return}
	set Canv(W) $w
	if {$x == $Canv(X)} {
	    set BBox(action) e
	} else {
	    set Canv(X) $x
	    set BBox(action) w
	}
    } elseif {$x == $Canv(X) && $y == $Canv(Y)} {
#	if {($Canv(W) < $w && $Canv(H) < $h) || ($Canv(W) > $w && $Canv(H) > $h)} {}
#    	    if {abs(($x + $w) - $Canv(X1)) < 2 || abs(($y + $h) - $Canv(Y1)) < 2 } {return}

	    set Canv(H) $h
	    set Canv(W) $w
	    set Canv(X1) [expr {$w + $x}]
	    set Canv(Y1) [expr {$y + $h}]
	    set BBox(action) se
#	{}
    } elseif {[expr {$w + $x}] == $Canv(X1) && [expr {$y + $h}] == $Canv(Y1)} {
#    	    if {abs($x - $Canv(X)) < 2 || abs($y - $Canv(Y)) < 2 } {return}

	    set Canv(H) $h
	    set Canv(W) $w
	    set Canv(X) $x
	    set Canv(Y) $y
#	    set Canv(X1) [expr {$w + $x}]
#	    set Canv(Y1) [expr {$y + $h}]
	    set BBox(action) nw
    } elseif {$x == $Canv(X) && [expr {$y + $h}] == $Canv(Y1)} {
#puts "Action=NE"
#    	    if {abs(($x + $w) - $Canv(X1)) < 2 || abs(($y + $h) - $Canv(Y1)) < 2 } {return}
#puts "Action=NE1"

	    set Canv(H) $h
	    set Canv(W) $w
#	    set Canv(X) $x
	    set Canv(Y) $y
	    set Canv(X1) [expr {$w + $x}]
#	    set Canv(Y1) [expr {$y + $h}]
	    set BBox(action) ne
    } elseif {[expr {$w + $x}] == $Canv(X1) && $y == $Canv(Y)} {
#    	    if {abs($x - $Canv(X)) < 2 || abs(($y + $h) - $Canv(Y1)) < 2 } {return}

	    set Canv(H) $h
	    set Canv(W) $w
	    set Canv(X) $x
#	    set Canv(Y) $y
#	    set Canv(X1) [expr {$w + $x}]
	    set Canv(Y1) [expr {$y + $h}]
	    set BBox(action) sw
    
    } else {
#puts "Разобраться!!!"
	return
    }
   global BBox lastX1 lastY1 lastX2 lastY2

   set lastX1 $BBox(x1)
   set lastY1 $BBox(y1)
   set lastX2 $BBox(x2)
   set lastY2 $BBox(y2)
   switch -exact -- $BBox(action) {
      none  { return }
      n    { 
	     set BBox(y1) [expr {$BBox(y1) * $yScaleW}]
             set xOrigin $BBox(x1)
             set yOrigin $BBox(y2)
             set xScale  1.0
             set yScale $yScaleW
      }
      s    { 
	     set BBox(y2) [expr {$BBox(y1) + ($BBox(y2) - $BBox(y1)) * $yScaleW}]
             set xOrigin $BBox(x1)
             set yOrigin $BBox(y1)
             set xScale  1.0
             set yScale $yScaleW
      }
      w    { 
	     set BBox(x1) [expr {$BBox(x1) * $xScaleW}]
             set xOrigin $BBox(x1)
             set yOrigin $BBox(y1)
             set xScale $xScaleW
             set yScale  1.0
      }
      e    { 
	     set BBox(x2) [expr {$BBox(x1) + ($BBox(x2) - $BBox(x1)) * $xScaleW}]
             set xOrigin $BBox(x1)
             set yOrigin $BBox(y1)
             set xScale $xScaleW
             set yScale  1.0
      }
      ne   { 
	     set BBox(y1) [expr {$BBox(y1) * $yScaleW }]
             set xOrigin $BBox(x1)
             set yOrigin $BBox(y2)

             set xScale $xScaleW
             set yScale $yScaleW
      }
      nw   {
	     set BBox(y1) [expr {$BBox(y1) * $yScaleW }]
             set xOrigin $BBox(x2)
             set yOrigin $BBox(y2)
	     set BBox(x1) [expr {$BBox(x1) * $xScaleW }]
             set xScale $xScaleW
             set yScale $yScaleW
      }
      se   {
	     set BBox(x2) [expr {$BBox(x1) + ($BBox(x2) - $BBox(x1)) * $xScaleW}]
	     set BBox(y2) [expr {$BBox(y1) + ($BBox(y2) - $BBox(y1)) * $yScaleW}]
             set xOrigin $BBox(x1)
             set yOrigin $BBox(y1)
             set xScale $xScaleW
             set yScale $yScaleW
      }
      sw   {
	     set BBox(y2) [expr {$BBox(y1) + ($BBox(y2) - $BBox(y1)) * $yScaleW}]
	     set BBox(x1) [expr {$BBox(x1) * $xScaleW}]
             set xOrigin $BBox(x2)
             set yOrigin $BBox(y1)
             set xScale $xScaleW
             set yScale $yScaleW
      }
      default {
	puts "Default: action=$BBox(action)"      
      }
   }
 
   set BBox(xscale) [expr {$xScale * $BBox(xscale)}]
   foreach id "[$wcan find withtag canvasb] [$wcan find withtag canvasi]" {
      set type [$wcan type $id]
#puts "Canvasb id=$id type=$type  xScale=$xScale yScale=$yScale"
      if {$type == "group"} {
	continue
      }
      
      if {[catch {$wcan itemcget $id -strokewidth} result]==0} {
	set stw [$wcan itemcget $id -strokewidth]
        $wcan itemconfig $id -strokewidth [expr {$stw * $yScale * $xScale}]
      }

      if {$type != "pimage" && $type != "polyline" && $type != "path"} {
	    $wcan scale $id $xOrigin $yOrigin $xScale $yScale
if {$type == "ptext"} {
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
      if {$type == "prect"} {
	set rx [$wcan itemcget $id -rx]
	set ry [$wcan itemcget $id -ry]
	$wcan itemconfigure $id -rx [expr {$rx * $xScale}] -ry [expr {$ry * $yScale}]
#Сюда вставим обработку entry
	set tagr [$wcan itemcget $id -tags]
	set centry [lsearch $tagr "centry"]
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
      if {$type == "pimage"} {
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
#puts "PIMAGE 1 id=$id"
	set iheight [expr {$height * $yScale * $yScaleLast}]
#puts "PIMAGE xScale=$xScale yScale=$yScale xScaleLast=$xScaleLast  yScaleLast=$yScaleLast action=$BBox(action) width=$width height=$height iwidth=$iwidth iheight=$iheight"

	foreach {mx0  my0 mx1 my1} [$wcan bbox $id] {break}
	foreach {xc  yc} [id2coordscenter $wcan $id] {break}
	$wcan itemconfigure $id  -width $iwidth -height $iheight -srcregion [list 0  0  $width $height]

	set tags "[$wcan itemcget $id -tags]"
	set ind [lsearch -regexp "$tags" {^canvasbObj}]
	if {$ind == -1} {
	    set ind [lsearch -regexp "$tags" {^canvasb::}]
	}
	set oid [lindex "$tags" $ind]
	if {[$wcan type "$oid image"] != ""} {
	    foreach {xr yr} [id2coordscenter $wcan "$oid rect"] {break}
	    foreach {xi yi} [id2coordscenter $wcan $id] {break}
	    $wcan move "$oid image" [expr {$xr - $xi }] [expr {$yr - $yi }]
	} else {
#puts "PIMAGE=$oid tags=$tags"
	    foreach {xi yi} [$wcan coords "$oid pimage"] {break}
	    foreach {x1 y1 x2 y2} [$wcan coords "$oid rect"] {break}

#Плясать от ipad и side
	    foreach {xr yr} [id2coordscenter $wcan "$oid rect"] {break}
	    foreach {xi yi} [id2coordscenter $wcan $id] {break}
	    foreach {xr yr xr1 yr1} [$wcan coords "$oid rect"] {break}
	    foreach {xi yi xi1 yi1} [$wcan bbox "$oid pimage"] {break}

	    $wcan move "$oid pimage" [expr {$xr - $xi * $xScale}] [expr {$yr - $yi * $yScale }]
	    
#	    $wcan move "$oid pimage" [expr {($xi - $xr) * $xScale}] [expr {$yr - $yi } * $yScale]
	    
	} 
    }

      if {[catch {$wcan itemcget $id -font} result]==0} {
        set u [Utag find $id]
        set fsize [expr round($BBox($u,fontsize)*$BBox(xscale))]
        if {$fsize != [lindex $result 1]} {
            $wcan itemconfig $id -font [lreplace $result 1 1 $fsize]
        }
      } elseif {[catch {$wcan itemcget $id -fontsize} result]==0} {
#LISSI
if {0} {
        set u [Utag find $id]
        set fsize [expr round($BBox($u,fontsize)*$BBox(xscale))]
        if {$fsize != $result} {
            $wcan itemconfig $id -fontsize $fsize
        }
}
      }
   }
}
