#Моя добавка
package require Tk
. configure -bg cyan
# -width [winfo screenwidth .] -height [winfo screenheight .]
catch {package require wm}
update
toplevel .train -width 160  -height 160
#wm withdraw .
#Ниже оригинальный код

set g(interval) 30
set g(speed) 4

proc wheel {c x y r args} {
    global g
    array set opt {-color red -spokes 24 -pivot 0 -tag {}}
    array set opt $args
    set y0 [expr {$y-$r}]
    $c create oval [expr {$x-$r}] [expr {$y0-$r}] \
	    [expr {$x+$r}] [expr {$y0+$r}]  -outline white
    set r1 [expr {$r-2}]
    set col $opt(-color)
    set it [$c create oval [expr {$x-$r1}] [expr {$y0-$r1}] \
	    [expr {$x+$r1}] [expr {$y0+$r1}]  -outline $col  -width 2]
    lappend g(wheels) $it
    set g($it,spokes) $opt(-spokes)
    set g($it,r) $r1
    set g($it,x) $x
    set g($it,y) $y0
    set g(alpha) 0.
    set g(-color) $opt(-color)
    drawSpokes $c $it
    if $opt(-pivot) {
        set deg2arc [expr {atan(1.0)*8/360.}]
        set rp [expr {$r1*$opt(-pivot)}]
        set xp [expr {$x-$rp*cos($deg2arc*$g(alpha))}]
        set yp [expr {$y0-$rp*sin($deg2arc*$g(alpha))}]
        set pivot [$c create rect $xp $yp \
		[expr {$xp+1}] [expr {$yp+1}] -fill $opt(-color) \
		-tag  [list $opt(-tag) pivot]]
        set g($it,pivot) [list $pivot $opt(-pivot)]
        $c create arc [expr {$x-$r1}] [expr {$y0-$r1}]\
		[expr {$x+$r1}] [expr {$y0+$r1}] \
		-style chord -fill $g(-color) -start 310\
		-extent 80 -tag counterweight
    }
    set rh [expr {$r/12.}]
    $c create oval [expr {$x-$rh}] [expr {$y0-$rh}] \
	    [expr {$x+$rh}] [expr {$y0+$rh}]  -fill white  -tag hub
}
proc movesmoke {c} {
    global g
    foreach i [$c find withtag smoke] {
        if {[lindex [$c bbox $i] 3]<0} {
            $c delete $i
        } elseif {$g(speed) == 0} {
            $c move $i [expr {(rand()-.5)*2.}] [expr {rand()*2-2}]
	} else {
            $c move $i [expr {rand()*$g(speed)/3.}] [expr {rand()*2-2}]
        }
    }
    foreach {a1 a2 a3 a4} [$c bbox chimney] {}
    set t [$c create oval $a1 $a2 $a3 $a4 \
	    -fill white  -outline white  -tag smoke]
    $c move $t 0 -10
    $c lower smoke
}
proc turn {c deg} {
    if {![winfo exist $c]}  {
	return
    } 
    global g
    set g(alpha) [expr {round($g(alpha)+360-$deg)%360}]
    foreach i [$c find withtag counterweight] {
        $c itemconfig $i -start [expr {310-$g(alpha)}]
    }
    $c delete spoke
    foreach i $g(wheels) {
        drawSpokes $c $i
    }
    $c raise hub
    set xp0 [expr {105+15*sin(($g(alpha)-90)*atan(1.0)*8/360)}]
    set foobar($xp0) foobar
    $c delete piston
    $c coords p0 $xp0 120 [expr {$xp0+2}] 122
    $c create line 90 121 $xp0 121 -width 2 -fill white -tag piston
    drawRod $c p0 p1 p2 p3
    $c raise p0
    movesmoke $c
}
proc drawSpokes {c item} {
    global g
    set nspokes $g($item,spokes)
    set delta [expr {360./$nspokes}]
    set alpha $g(alpha)
    set r $g($item,r)
    set x $g($item,x)
    set y $g($item,y)
    set deg2arc [expr {atan(1.0)*8/360.}]
    for {set i 0} {$i<$nspokes} {incr i} {
        set x1 [expr {$x+cos($deg2arc*$alpha)*$r}]
        set y1 [expr {$y+sin($deg2arc*$alpha)*$r}]
        $c create line $x $y $x1 $y1 -fill $g(-color) -tag spoke
        set alpha [expr {$alpha+$delta}]
    }
    if [info exists g($item,pivot)] {
        foreach {item perc} $g($item,pivot) break
        set rp [expr {$r*$perc}]
        set xp [expr {$x-$rp*cos($deg2arc*$g(alpha))}]
        set yp [expr {$y-$rp*sin($deg2arc*$g(alpha))}]
        $c coords $item $xp $yp [expr {$xp+1}] [expr {$yp+1}]
    }
}

proc drawRod {c p0 p1 p2 p3} {
    $c delete rod
    foreach {l1 l2 l3 l4} [$c bbox $p1 $p3] {}
    $c create rect $l1 $l2 $l3 $l4 -fill white -tag rod
    foreach {l1 l2 ? ?} [$c bbox $p0] {}
    foreach {l3 l4 ? ?} [$c bbox $p2] {}
    $c create line $l1 $l2 $l3 $l4 -width 3 -fill white -tag rod
    $c raise rod
    $c raise pivot
} 

proc speed {c} {
    global g
    turn $c $g(speed)
    after cancel $g(movement)
    set g(movement) [after $g(interval) speed $c]
}
proc smokin' {c} {
    global g
    movesmoke $c
    after cancel $g(movement)
    set g(movement) [after $g(interval) smokin' $c]
}

#Моя правка
#set c [canvas .c -width 600 -height 160 -background lightblue]
set c [canvas .train.c -width 600 -height 160 -background lightblue]

pack $c
bind $c <1> {incr g(speed) 6; speed   $c} ;# throttle
bind $c <3> {set  g(speed) 0; smokin' $c} ;# emergency brake
bind $c <q> {exit}

proc gradientRect {canv x1 y1 x2 y2 c1 c2 {tags ""} {dir vertical}} {
    foreach {r1 g1 b1} [winfo rgb $canv $c1] {}
    foreach {r2 g2 b2} [winfo rgb $canv $c2] {}
    set dr [expr {$r2-$r1}]
    set dg [expr {$g2-$g1}]
    set db [expr {$b2-$b1}]
    switch $dir {
	vertical {
	    set dy [expr {$y2-$y1}]
	    set steps [expr {int(abs($dy))}]
	    if {$steps>255} {set steps 255}
	    for {set i 0} {$i<$steps} {incr i} {
		set p [expr {double($i)/$steps}]
		set y [expr {$y1+$dy*$p}]
		set r [expr {int($r1+$dr*$p)}]
		set g [expr {int($g1+$dg*$p)}]
		set b [expr {int($b1+$db*$p)}]
		$canv create rect $x1 $y $x2 $y2 -outline {} -tags $tags \
			-fill [format "#%02x%02x%02x" $r $g $b]
	    }
	}
	horizontal {
	    set dx [expr {$x2-$x1}]
	    set steps [expr {int(abs($dx))}]
	    if {$steps>255} {set steps 255}
	    for {set i 0} {$i<$steps} {incr i} {
		set p [expr {double($i)/$steps}]
		set x [expr {$x1+$dx*$p}]
		set r [expr {int($r1+$dr*$p)}]
		set g [expr {int($g1+$dg*$p)}]
		set b [expr {int($b1+$db*$p)}]
		$canv create rect $x $y1 $x2 $y2 -outline {} -tags $tags \
			-fill [format "#%02x%02x%02x" $r $g $b]
	    }
	}
	default {
	    return -code error "unknown direction \"$dir\":\
		    must be one of horizontal or vertical"
	}
    }
}

$c delete all
$c create rect 32 115 360 125 -fill black		;# frame
gradientRect $c 22 118 32 122 grey50 black		;# buffer
$c create line 22 115 22 125
$c create poly 60 95 40 115 50 115 70 95 -fill black

gradientRect $c 60 45 310 95 grey50 black		;# boiler

$c create oval 55 50 65 90 -fill black			;# smokebox
$c create rect 70 32 85 50 -fill black -tag chimney
$c create rect 40 52 90 75 -fill black			;# wind diverter
$c create oval 130 36 150 52 -fill black		;# dome
$c create rect 195 35 215 50 -fill black		;# sandbox
$c create oval 260 36 280 52 -fill black		;# dome
$c create rect 65 100 90 135 -fill black		;# cylinder
$c create rect 90 120 92 122 -fill red -tag p0		;# crossbar
$c create rect 72 87 82 100 -fill black			;# steam tube
$c create rect 310 40 370 115 -fill black		;# cab
gradientRect $c 310 32 390 42 grey70 grey40		;# cab roof
$c create text 338 82 -text "01 234" -fill gold -font {Times 7}
$c create rect 318 48 333 66 -fill white		;# cab window #1
$c create rect 338 48 355 66 -fill white		;# cab window #2
wheel $c 50  150 13 -spokes 12
wheel $c 105 150 13 -spokes 12
wheel $c 150 150 30 -pivot 0.5 -tag p1
wheel $c 215 150 30 -pivot 0.5 -tag p2
wheel $c 280 150 30 -pivot 0.5 -tag p3
drawRod $c p0 p1 p2 p3
wheel $c 340 150 16 -spokes 12
$c create rect 360 110 380 118 -fill black

$c create rect 380 65 560 125 -fill black -tag tender
gradientRect $c 560 118 570 122 grey50 black		;# buffer
$c create line 571 116 571 125
$c create rect 390 45 525 65 -fill black -tag tender
wheel $c 395  150 13 -spokes 12
wheel $c 440  150 13 -spokes 12
$c create rect 380 132 456 142 -fill red
wheel $c 495  150 13 -spokes 12
wheel $c 540  150 13 -spokes 12
$c create rect 480 132 556 142 -fill red -outline red
$c create rect 0 150 600 160 -fill brown		;# earth
$c create line 0 150 600 150 -fill grey -width 2	;# rail

set g(movement) {}
focus $c
speed $c
lower .