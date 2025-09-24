 #!/bin/sh
 # Next line restarts with Tcl \
 exec tclsh "$0" ${1+"$@"}
 
 # TkPool --
 #
 #   A "simple" simulation of the game of Pool using Tcl/Tk. Based on the ideas
 #   and code from Colliding Balls: http://wiki.tcl.tk/8573 by David Easton.
 
 package require Tcl 8.4
 package require Tk 8.4
 
 # bgerror handler
 proc bgerror {args} {
     global errorInfo
     puts "=== ERROR ==="
     puts "$args"
     catch { puts $errorInfo }
     tkpool::dump
 }
 
 namespace eval tkpool {
     # VERSION
     variable version "0.7.1"
 
     # List of created balls
     variable balls {}
     # Unique id for creating balls
     variable uniqueid 0
     # Mapping from id to name
     variable id2name
 
     variable radius 9
     variable mass   10
     # The friction coefficient of the surface
     variable fcoefficient 0.015
 
     # Flag to say if any balls are in motion - if not, then don't bother
     # updating them.
     variable inMotion 0
 
     # The dimensions of the main window - reduce this number to reduce size of
     # the table and balls
     variable scale 1.0
 
     set radius [expr {$radius * $scale}]
 
     namespace export ball
 }
 
 # Representation of state associated with a ball
 proc tkpool::ball {canvas xpos ypos mass colour} {
     variable balls
     variable uniqueid
     variable radius
     variable id2name
 
     # Create a unique name for this ball
     set name "ball[incr uniqueid]"
     lappend balls $name
     # And a command to access it from
     interp alias {} ::$name {} ::tkpool::ball_cmd $name
 
     # Create the state of this ball
     variable $name
     upvar 0 $name state
     set state(pos) [list $xpos $ypos]
     set state(vel) [list 0.0 0.0]
     set state(mass) $mass
     set state(colour) $colour
 
     set x1 [expr {$xpos - $radius}]
     set x2 [expr {$xpos + $radius}]
     set y1 [expr {$ypos - $radius}]
     set y2 [expr {$ypos + $radius}]
 
     set state(id) [$canvas create oval $x1 $y1 $x2 $y2 \
         -outline black -fill $colour -tags [list $name ball]]
 
     set id $state(id)
     set id2name($id) $name
 }
 
 proc tkpool::ball_cmd {name cmd args} {
     variable balls
     variable $name
     upvar 0 $name state
 
     switch $cmd {
         set    {
             if {[llength $args] == 1} {
                 return $state([lindex $args 0])
             } elseif {[llength $args] == 2} {
                 set state([lindex $args 0]) [lindex $args 1]
             } else {
                 return -code error "wrong # args"
             }
         }
         unset   {
             unset state([lindex $args 0])
         }
         delete {
             set idx [lsearch $balls $name]
             catch {
                 set balls [lreplace $balls $idx $idx]
             }
             .c delete $state(id)
             unset state
         }
         default {
             return -code error "unknown command \"$cmd\""
         }
     }
 }
 
 proc tkpool::dump {} {
     variable balls
     variable version
     variable radius
     variable mass
     variable scale
 
     catch {console show}
 
     puts "=== BEGIN DUMP ==="
 
     puts "Version:    $version"
     puts "Radius:     $radius"
     puts "Mass:       $mass"
     puts "Scale:      $scale"
     puts ""
 
     foreach ball $balls {
         puts "Ball $ball"
         upvar 0 ::tkpool::$ball state
         parray state
         puts ""
     }
 
     puts "=== END DUMP ==="
 }
 
 #
 # Given the initial velocities and masses calculates the velocities following
 # a collision.
 proc tkpool::postColVels {u1 u2 m1 m2} {
     # No collision if velocity of ball2 > velocity of ball1
     if {$u2 > $u1} {
         return [list $u1 $u2]
     }
 
     set u1 [expr {1.0 * $u1}]
     set u2 [expr {1.0 * $u2}]
     set m1 [expr {1.0 * $m1}]
     set m2 [expr {1.0 * $m2}]
 
     set M [expr {$m1 / $m2}]
 
     set b [expr {($M * $u1) + $u2}]
     set c [expr {($M * $u1 * $u1) + ($u2 * $u2)}]
 
     set q [expr {2 * $M * $b}]
     set p [expr {4 * $M * $M * $b * $b}]
     set r [expr {4 * ($M + ($M * $M)) * (($b * $b) - $c)}]
     set s [expr {2 * ($M + ($M * $M))}]
 
     if {$r > $p} {
         return -code error "no solution"
     } else {
         set root [expr {sqrt($p-$r)}]
 
         set v1 [expr {($q - $root) / $s}]
         set v2 [expr {$b - ($M * $v1)}]
 
         return [list $v1 $v2]
     }
 }
 
 proc tkpool::checkForCollisions {canvas ball} {
     variable radius
     variable id2name
     global State
 
     set didCollide 0
     set potted 0
     set overlapList [list]
 
     foreach {ourX ourY} [$ball set pos] {break}
 
     set searched [list [$ball set id]]
     set id [$canvas find closest $ourX $ourY $radius [$ball set id]]
 
     while {[lsearch $searched $id] == -1} {
         if {[lsearch -glob [$canvas gettags $id] "ball*"] > -1} {
             set didCollide 1
             lappend overlapList $id
         } elseif {[lsearch [$canvas gettags $id] "pocket"] > -1} {
             # Ball has been potted
             set potted 1
             break
         }
         lappend searched $id
         set id [$canvas find closest $ourX $ourY $radius $id]
     }
     if {$potted} {
         pot $canvas $ball
     } elseif {[llength $overlapList] > 0} {
         foreach id $overlapList {
             collide $ball $id2name($id)
         }
     }
 
     return $didCollide
 }
 
 proc tkpool::checkForCushionCollisions {canvas ball} {
     variable radius
 
     set didCollide 0
 
     foreach {ourX ourY} [$ball set pos] {break}
 
     set searched [list [$ball set id]]
     set id [$canvas find closest $ourX $ourY $radius [$ball set id]]
 
     while {[lsearch $searched $id] == -1} {
         if {[lsearch [$canvas gettags $id] "cushion"] > -1} {
             set didCollide 1
             break
         }
         lappend searched $id
         set id [$canvas find closest $ourX $ourY $radius $id]
     }
 
     return $didCollide
 }
 
 # Called when a ball is potted.
 proc tkpool::pot {canvas ball} {
     global State
     # See which ball has been potted.
     set colour [$ball set colour]
     set player "player$State(currentp)"
     set other "player[expr {3 - $State(currentp)}]"
 
     if {$ball eq $::cue} {
         puts "Potted the cue ball!"
         set State(state) start
     } else {
         puts "$colour ball potted!"
     }
     $ball delete
 }
 
 proc tkpool::move {canvas} {
     variable balls
     variable fcoefficient
     variable scale
     variable inMotion
 
     set canvasHeight [winfo height $canvas]
     set canvasWidth  [winfo width $canvas]
 
     if {$inMotion} {
         set moving 0
         foreach ball $balls {
 
             foreach {xpos ypos} [$ball set pos] {break}
             foreach {xvel yvel} [$ball set vel] {break}
 
             if {$xvel == 0.0 && $yvel == 0.0} {
                 # Not moving
                 continue
             } else {
                 incr moving
             }
 
             # Take friction into account
             set mass [$ball set mass]
             set decel [expr {$fcoefficient * $mass * $scale}]
 
             if {$xvel != 0.0} {
                 set phi [expr {atan(abs($yvel / $xvel))}]
 
                 set vel [expr {sqrt(pow($xvel,2) + pow($yvel,2))}]
                 set vel [expr {$vel - $decel}]
 
                 if {$vel < 0.0} {
                     set vel 0.0
                 }
 
                 if {$xvel < 0.0} {
                     set xvel [expr {-1.0 * $vel * cos($phi)}]
                 } else {
                     set xvel [expr {$vel * cos($phi)}]
                 }
                 if {$yvel < 0.0} {
                     set yvel [expr {-1.0 * $vel * sin($phi)}]
                 } else {
                     set yvel [expr {$vel * sin($phi)}]
                 }
             } else {
                 # No horizontal component
                 if {$yvel > 0.0} {
                     set yvel [expr {$yvel - $decel}]
                     if {$yvel < 0.0} {
                         set yvel 0.0
                     }
                 } elseif {$yvel < 0.0} {
                     set yvel [expr {$yvel + $decel}]
                     if {$yvel > 0.0} {
                         set yvel 0.0
                     }
                 }
             }
 
             set xpos [expr {$xpos + ($xvel / 2.0)}]
             set ypos [expr {$ypos + ($yvel / 2.0)}]
 
             $canvas move $ball [expr {$xvel/2.0}] [expr {$yvel/2.0}]
 
             # Bounce off edges
             foreach {x1 y1 x2 y2} [$canvas bbox $ball] {break}
 
             # Work out if the ball is overlapping a cushion
             if {[checkForCushionCollisions $canvas $ball]} {
                 if {$x1 < (10 * $scale) && $xvel < 0} {
                     set xvel [expr {-1.0 * $xvel}]
                 } 
                 if {$x2 > ($canvasWidth - (10 * $scale)) && $xvel > 0} {
                     set xvel [expr {-1.0 * $xvel}]
                 }
                 if {$y1 < (10 * $scale) && $yvel < 0} {
                     set yvel [expr {-1.0 * $yvel}]
                 } 
                 if {$y2 > ($canvasHeight - (10 * $scale)) && $yvel > 0} {
                     set yvel [expr {-1.0 * $yvel}]
                 }
             }
 
 
             set ret [checkForCollisions $canvas $ball]
             if {$ret == 2} {
                 # Potted the cue ball
             } elseif {$ret == 1} {
                 # Collided
                 $ball set pos [list $xpos $ypos]
             } else {
                 $ball set pos [list $xpos $ypos]
                 $ball set vel [list $xvel $yvel]
             }
 
         }
 
         if {$moving == 0} {
             # No balls were moving this round
             set inMotion 0
         }
     }
 
     after 25 [list ::tkpool::move $canvas]
 }
 
 proc tkpool::collide {ball1 ball2} {
 
     foreach {x1 y1} [$ball1 set pos] {break}
     foreach {x2 y2} [$ball2 set pos] {break}
 
     # Always call ball on right (2) and one on left (1)
     if {$x1 > $x2} {
         set temp $ball2
         set ball2 $ball1
         set ball1 $temp
 
         foreach {x1 y1} [$ball1 set pos] {break}
         foreach {x2 y2} [$ball2 set pos] {break}
     }
 
     # Get velocity of each ball
     foreach {ux1 uy1} [$ball1 set vel] {break}
     foreach {ux2 uy2} [$ball2 set vel] {break}
 
     # Work out angle of collision
     set diffX [expr {1.0 * ($x2 - $x1)}]
     set diffY [expr {1.0 * ($y2 - $y1)}]
 
     if {$diffX == 0.0} {
         set phi 1.57079632579
     } else {
         set phi [expr {atan($diffY / $diffX)}]
     }
 
     # Work out velocity parallel and perpendicular
     set uparr1 [expr {($ux1 * cos($phi)) + ($uy1 * sin($phi))}]
     set uperp1 [expr {($ux1 * sin($phi)) - ($uy1 * cos($phi))}]
 
     set uparr2 [expr {($ux2 * cos($phi)) + ($uy2 * sin($phi))}]
     set uperp2 [expr {($ux2 * sin($phi)) - ($uy2 * cos($phi))}]
 
     # If they are not going towards each other, then they will not collide
     if {$uparr2 > $uparr1} {
         return
     }
 
     set mass1 [$ball1 set mass]
     set mass2 [$ball2 set mass]
 
     foreach {vparr1 vparr2} [postColVels $uparr1 $uparr2 $mass1 $mass2] \
         {break}
 
     # Perpendicular velocities are unchanged
     set vperp1 $uperp1
     set vperp2 $uperp2
 
     # Convert back into x and y movements
     set vx1 [expr {($vparr1 * cos($phi)) + ($vperp1 * sin($phi))}]
     set vy1 [expr {($vparr1 * sin($phi)) - ($vperp1 * cos($phi))}]
     
     set vx2 [expr {($vparr2 * cos($phi)) + ($vperp2 * sin($phi))}]
     set vy2 [expr {($vparr2 * sin($phi)) - ($vperp2 * cos($phi))}]
 
     # Update new velocities
     $ball1 set vel [list $vx1 $vy1]
     $ball2 set vel [list $vx2 $vy2]
 }
 
 #
 # Racks the balls on the table, using the positions indicated. The positions
 # argument should be a list of lists, where each element is a letter or x
 # (meaning no ball in this position). The rows go from the back to the front.
 # Here is English pool setup:
 # {
 #  {y r y y r}
 #  { r y r y }
 #  {x y b r x}
 #  { x r y x }
 #  {x x r x x}
 # }
 proc tkpool::rack {canvas mass positions} {
     variable radius
     variable balls
     variable numred
     variable numyellow
     global cue
 
     foreach ball $balls {
         $ball delete
     }
 
     set w [winfo width $canvas]
     set h [winfo height $canvas]
 
     set x0 [expr {($w /2.0) - (4 * $radius)}]
     set y0 [expr {int(($h / 4) - ($radius * 4))}]
 
     for {set i 0} {$i < 5} {incr i} {
         # Calculate row offset
         if {($i % 2) != 0} {
             set offset [expr {int($radius)}]
         } else {
             set offset 0
         }
         foreach item [lindex $positions $i] {
             switch $item {
                 x   { }
                 y   { ball $canvas [expr {$x0 + $offset}] \
                                    $y0 $mass yellow
                 }
                 r   { ball $canvas [expr {$x0 + $offset}] \
                                     $y0 $mass red
                 }
                 b   { ball $canvas [expr {$x0 + $offset}] \
                                     $y0 $mass black
                 }
                 default { return -code error "unknown identifier \"$item\""}
             }
             incr offset [expr {int($radius * 2.0)}]
         }
         incr y0 [expr {int($radius * 2.0)}]
     }
     set ::State(state) start
     set ::State(red) 7
     set ::State(yellow) 7
 }
 
 #
 # If taking a shot, start a timer to determine the power of the shot
 proc tkpool::mousedown {} {
     variable timer
     variable power 0
     variable inMotion
 
     if {$inMotion} {return}
 
     global State
     if {$State(state) ne "start"} {
         set timer [after 20 [list tkpool::powerup]]
     }
 }
 
 proc tkpool::powerup {} {
     # Show a visual display of the power
     variable power
     variable timer
     variable segments
 
     incr power
 
     # Update power display
     set p [expr {$power / 2}]
     set colour green
     if {$p > 12} {
         set colour red
     } elseif {$p > 7} {
         set colour yellow
     }
     if {($power % 2) == 1} {
         .info.power.p itemconfigure [lindex $segments [expr {$power/2}]] \
             -fill $colour
     }
 
     if {$power >= 30} {
         set timer [after 20 [list tkpool::powerdown]]
     } else {
         set timer [after 20 [list tkpool::powerup]]
     }
 }
 
 proc tkpool::powerdown {} {
     variable power
     variable timer
     variable segments
 
     incr power -1
 
     set p [expr {$power/2}]
     set colour green
     if {$p > 12} {
         set colour red
     } elseif {$p > 7} {
         set colour yellow
     }
     if {($power % 2) == 1} {
         .info.power.p itemconfigure [lindex $segments [expr {$power/2}]] \
             -fill #404040
     }
 
     if {$power <= 0} {
         set timer [after 20 [list tkpool::powerup]]
     } else {
         set timer [after 20 [list tkpool::powerdown]]
     }
 }
 
 
 
 proc tkpool::mouseup {canvas x y} {
     global cue
     global State
     variable timer
     variable power
     variable scale
     variable mass
     variable inMotion
     variable segments
 
     if {$inMotion} {return}
 
     if {$State(state) eq "start"} {
         # Must be behind the line
         if {$y < (480 * $scale)} {
             puts "Must start from behind the line"
             return
         }
         set cue [tkpool::ball $canvas $x $y [expr {$mass * 1.2}] white]
         set State(state) "game"
     } else {
         after cancel $timer
         foreach segment $segments {
             .info.power.p itemconfigure $segment -fill #404040
         }
 
         $canvas delete cueline
 
         # Work out component velocities.
         foreach {oldx oldy} [$cue set pos] {break}
         set diffX [expr {1.0 * ($x - $oldx)}]
         set diffY [expr {1.0 * ($y - $oldy)}]
 
         set power [expr {$power * 1.5 * $scale}]
 
         if {$diffX != 0.0} {
             set phi [expr {atan(abs($diffY / $diffX))}]
 
             if {$diffX < 0.0} {
                 set xvel [expr {-1.0 * $power * cos($phi)}]
             } else {
                 set xvel [expr {$power * cos($phi)}]
             }
             if {$diffY < 0.0} {
                 set yvel [expr {-1.0 * $power * sin($phi)}]
             } else {
                 set yvel [expr {$power * sin($phi)}]
             }
         } else {
             # No horizontal component
             if {$diffY > 0.0} {
                 set yvel $power
             } elseif {$yvel < 0.0} {
                 set yvel [expr {-1.0 * $power}]
             }
         }
 
         $cue set vel [list $xvel $yvel]
         set inMotion 1
     }
 }
 
 # Draw some pockets onto the canvas
 proc tkpool::drawpockets {canvas} {
     variable radius
     variable scale
 
     set r [expr {$radius + 5}]
 
     set w [winfo width $canvas]
     set h [winfo height $canvas]
 
     set inset [expr {10 * $scale}]
 
     #$canvas create rectangle 0 0 $inset $h -fill SeaGreen
     #$canvas create rectangle 0 0 $w $inset -fill SeaGreen
     #$canvas create rectangle [expr {$w - $inset}] 0 $w $h -fill SeaGreen
     #$canvas create rectangle 0 [expr {$h - $inset}] $w $h -fill SeaGreen
 
     foreach size {1.0 0.7} tags {{} {pocket}} color {saddlebrown black} {
 
         $canvas create oval [expr {0 - 1.5 * $size * $r}] [expr {0 - 1.5 * $size * $r}] \
             [expr {1.5 * $size * $r}] [expr {1.5 * $size * $r}] -fill $color \
             -tags $tags
         $canvas create oval [expr {$w - 1.5 * $size * $r}] \
             [expr {0 - 1.5 * $size * $r}] \
             [expr {$w + 1.5 * $size * $r}] [expr {1.5 * $size * $r}] -fill $color \
             -tags $tags
         $canvas create oval [expr {0 - 1.5 * $size * $r}] \
             [expr {$h - 1.5 * $size * $r}] \
             [expr {1.5 * $size * $r}] [expr {$h + 1.5 * $size * $r}] -fill $color \
             -tags $tags
         $canvas create oval [expr {$w - 1.5 * $size * $r}] \
             [expr {$h - 1.5 * $size * $r}] \
             [expr {$w + 1.5 * $size * $r}] [expr {$h + 1.5 * $size * $r}] -fill $color \
             -tags $tags
 
         set mid [expr {$h / 2}]
         $canvas create oval [expr {0 - $size * $r}] [expr {$mid - $size * $r}] \
             [expr {$size * $r}] [expr {$mid + $size * $r}] \
             -fill $color -tags $tags
         $canvas create oval [expr {$w - $size * $r}] \
             [expr {$mid - $size * $r}] \
             [expr {$w + $size * $r}] [expr {$mid + $size * $r}] -fill $color \
             -tags $tags
     }
     # Draw the cushions
     $canvas create rectangle 0 [expr {1.5 * $r + $inset}] $inset \
         [expr {$h/2 - $r - $inset}] \
         -fill SeaGreen -tags cushion -outline SeaGreen
 
     $canvas create rectangle 0 [expr {$h/2 + $r + $inset}] $inset \
         [expr {$h - 1.5 * $r - $inset}] \
         -fill SeaGreen -tags cushion -outline SeaGreen
 
     $canvas create rectangle [expr {1.5 * $r + $inset}] 0 \
         [expr {$w - 1.5 * $r - $inset}] $inset \
         -fill SeaGreen -tags cushion -outline SeaGreen
 
     $canvas create rectangle [expr {$w - $inset}] [expr {1.5 * $r + $inset}] $w \
         [expr {$h/2 - $r - $inset}] -fill SeaGreen -tags cushion -outline SeaGreen
 
     $canvas create rectangle [expr {$w - $inset}] [expr {$h/2 + $r + $inset}] $w \
         [expr {$h - 1.5 * $r - $inset}] -fill SeaGreen -tags cushion -outline SeaGreen
 
     $canvas create rectangle [expr {1.5 * $r + $inset}] [expr {$h - $inset}] \
         [expr {$w - 1.5 * $r - $inset}] $h -fill SeaGreen -tags cushion -outline SeaGreen
 
     # Draw the rounded edges of the cushions
     foreach x [list 0 $w] {
         set i [expr {$x - $inset}]
         set j [expr {$x + $inset}]
         $canvas create oval $i [expr {1.5 * $r}] \
             $j [expr {1.5 * $r + 2 * $inset}] -fill SeaGreen -tags cushion \
             -outline SeaGreen
         $canvas create oval $i [expr {$h/2 - $r}] \
             $j [expr {$h/2 -$r - 2* $inset}] -fill SeaGreen -tags cushion \
             -outline SeaGreen
         $canvas create oval $i [expr {$h/2 + $r}] \
             $j [expr {$h/2 + $r + 2 * $inset}] -fill SeaGreen -tags cushion \
             -outline SeaGreen
         $canvas create oval $i [expr {$h - 1.5 * $r}] $j\
             [expr {$h - 1.5 * $r - 2 * $inset}] -fill SeaGreen -tags cushion \
             -outline SeaGreen
     }
 
     foreach y [list 0 $h] {
         set i [expr {$y - $inset}]
         set j [expr {$y + $inset}]
         $canvas create oval [expr {1.5 * $r}] $i \
             [expr {1.5 * $r + 2 * $inset}] $j -fill SeaGreen -tags cushion \
             -outline SeaGreen
         $canvas create oval [expr {$w - 1.5 * $r}] $i \
             [expr {$w - 1.5 * $r - 2 * $inset}] $j \
             -fill SeaGreen -tags cushion -outline SeaGreen
     }
         
 }
 
 proc tkpool::drawline {canvas x y} {
     global cue
 
     if {[catch {$cue set pos} pos]} {
         # No cue ball
         return
     }
     foreach {x1 y1} $pos {break}
 
     $canvas delete cueline
 
     $canvas create line $x $y $x1 $y1 -tags cueline -fill white
 
     bind $canvas <Motion> [list tkpool::drawline $canvas %x %y]
 }
 
 proc tkpool::endline {canvas} {
     $canvas delete cueline
 
     bind $canvas <Motion> {}
 }
 
 
 
 proc tkpool::about {} {
     variable version
     # Popup an about box
     tk_messageBox -title "About TkPool V$version" -icon info \
         -message "A simple Tcl/Tk pool game\nBy Neil Madden\nhttp://wiki.tcl.tk/TkPool\nPublic Domain"
 }
 
 
 
 proc tkpool::main {argv} {
     variable scale
     variable radius
     variable version
     variable segments
     global State cue
 
     if {[llength $argv] > 0} {
         if {[llength $argv] > 1 || ![string is double [lindex $argv 0]]} {
             puts "Usage: $::argv0 ?scale?"
             exit 1
         } else {
             set scale [lindex $argv 0]
             set radius [expr {$radius * $scale}]
         }
     }
     
     # Create a frame to show the players' scores
     frame .info
 
     labelframe .info.p1 -text "Player 1"
     label .info.p1.colour -text "Colour:"
     label .info.p1.col -textvariable State(player1,colour)
     label .info.p1.score -text "Score:"
     label .info.p1.scr -textvariable State(player1,score)
 
     labelframe .info.p2 -text "Player 2"
     label .info.p2.colour -text "Colour:"
     label .info.p2.col -textvariable State(player2,colour)
     label .info.p2.score -text "Score:"
     label .info.p2.scr -textvariable State(player2,score)
 
     labelframe .info.turn -text "Turn"
     label .info.turn.t -textvariable State(currentplayer)
 
     labelframe .info.power -text "Power"
     canvas .info.power.p -bg black -width 100 -height 10
 
     array set State {
         player1,colour      ""
         player1,score       0
         player2,colour      ""
         player2,score       0
         currentplayer       "Player 1"
         currentp            1
         state               start
         red                 7
         yellow              7
     }
 
     pack .info.p1.colour .info.p1.col -anchor w
     pack .info.p1.score .info.p1.scr -anchor w
     pack .info.p2.colour .info.p2.col -anchor w
     pack .info.p2.score .info.p2.scr -anchor w
 
     pack .info.p1 -anchor n -fill x
     pack .info.p2 -anchor n -fill x
 
     pack .info.turn.t -fill both
     pack .info.turn -anchor n -fill x
 
     pack .info.power.p -fill both
     pack .info.power -anchor n -fill x
 
 
     pack .info -side right -fill y
 
     set canvas [canvas .c -bg darkgreen -width [expr {300 * $scale}] \
         -height [expr {600 * $scale}]]
     pack $canvas
 
     set layout {
           {y r y y r}
           { r y r y }
           {x y b r x}
           { x r y x }
           {x x r x x}
     }
 
     button .info.rerack -text "Re-Rack" -command \
         [list tkpool::rack $canvas $tkpool::mass $layout] -width 15
 
     button .info.quit -text "Quit" -command exit -width 15
     button .info.about -text "About" -command tkpool::about -width 15
 
     pack .info.quit -side bottom -padx 5 -pady 5
     pack .info.rerack -side bottom -padx 5 -pady 5
     pack .info.about -side bottom -padx 5 -pady 5
 
 
     wm resizable . 0 0
     wm title . "TkPool V$version"
 
     update
     # Create the segments in the power display
     set r [expr {[winfo width .info.power.p] / 15.0}]
     for {set i 0} {$i < 15} {incr i} {
         lappend segments [.info.power.p create rect [expr {$i * $r}] 0 \
             [expr {$i * $r + $r -1}] 10 -fill #404040]
     }
 
     # Draw the spot and line
     set p [expr {[winfo width $canvas]/2.0}]
     $canvas create oval [expr $p-3] [expr $p-3] [expr $p+3] [expr $p+3]\
         -fill white -outline white
 
     set p [expr {[winfo height $canvas] * 0.8}]
     $canvas create line 0 $p [winfo width $canvas] $p -fill white 
 
     $canvas configure -cursor tcross
 
     drawpockets $canvas
 
     # Create some balls
     rack $canvas $tkpool::mass $layout
 
     # Create the cue ball - with a slightly larger mass
     bind $canvas <ButtonPress-1> [list tkpool::mousedown]
     bind $canvas <ButtonRelease-1> [list tkpool::mouseup $canvas %x %y]
 
     bind $canvas <ButtonPress-3> [list tkpool::drawline $canvas %x %y]
     bind $canvas <ButtonRelease-3> [list tkpool::endline $canvas]
 
     bind . <d> tkpool::dump
 
     move $canvas
 }
 
 tkpool::main $argv
