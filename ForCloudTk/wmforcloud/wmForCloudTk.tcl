# A simple window manager in Tcl/Tk for use with CloudTk
# Copyright (c) Schelte Bron.  Freely redistributable.
# Copyright (c) Vladimir Orlov.  Freely redistributable.

package provide wm 1.0

namespace eval winfo {
    package require Tk
    if {[namespace which winfo] eq "::winfo"} {
        rename winfo winfo
    }
    # Create a new winfo command
    namespace ensemble create -unknown ::winfo::unknown -subcommands {
	width height
    }
    variable map {}

}
proc winfo::width {window} {
     tailcall winfo width [wm::window $window]
}

proc winfo::height {window } {
    tailcall winfo height [wm::window $window]
}
# winfo command implementation
proc winfo::unknown {cmd sub args} {
    # Forward any unknown subcommands to the original wm command
    return [list winfo::winfo $sub]
}


namespace eval wm {
    package require Tk

    # Move the original toplevel and wm commands into the wm namespace
    if {[namespace which toplevel] eq "::toplevel"} {
        rename toplevel toplevel
    }
    if {[namespace which wm] eq "::wm"} {
        rename wm wm
    }
    if {[namespace which lower] eq "::lower"} {
        rename lower lower
    }
    if {[namespace which raise] eq "::raise"} {
        rename raise raise
    }
    # Get rid of the tk::toplevel command
    catch {rename ::tk::toplevel {}}

    # Create a new wm command
    namespace ensemble create -unknown ::wm::unknown -subcommands {
        deiconify geometry iconphoto minsize maxsize
        overrideredirect stackorder title withdraw
        resizable state
    }

    namespace export toplvl
    namespace export lowerwm
    namespace export raisewm

    variable map {}
    variable State 
    set State(pressed) 0
    set State(arrow) {}
    set State(cursor) "top_left_arrow"
    # A default icon
    variable icon [image create photo -data {
        iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAABy0lEQVQ4y42TzWvT
        cBjHv8kvMUvS6nBrY23pVhCEefLgkIEd7KB0h122m3p2HgQd/gdzd8d69OBfIAju
        INSefIHpYC+ttbPsfUZsFtKmaWaa7OfFw+hSkuf2vH2+38PzEAQHc/FSdHpwIPo4
        nRoca1l/t1zXMxE2YrHLM/mXz9T3b57S10vTNDYgPz/b54KWF+Zn87dGiNJuqrjA
        MfC8U+bsDNtrWZbFyYUXT/JjN/uVanUXHZfi08q+qhv22zAAOTs++ih7O62UNkow
        Gg7cjodSVfsK4CgQIMnixMP7uQlT30Plp46hpIjNH/VWuaq/AmAFApJXlTs3rscj
        5e874AjA88ByoVbUjo1i96wf4Eoul50SeQflioprw1FsVuqtb2tH59R7AYgk8rKm
        aTAtF2Ifi+VC7YPRsIp+brsBDCEkEYlI5PefNgTeRW1HP/m8sv0OoFYYgJBKJR7c
        vZeN7f7qgOc5SJJAWJYdAdDnByBdudtoNNfb7ZNRz6PDHbuJvUPz4+ra/twppYYf
        wO8SM4XCFzGZVEyOMDg4rIuu52UAqGHPvx9AQhCExXg8vggg8b+GsA4MAAal1LRt
        G0HKPZ/JcZyS4zjpILv/AO1ascYM+PVRAAAAAElFTkSuQmCC
    }]
    variable iclose [image create photo -data {
	iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAQAAABKfvVzAAABK0lEQVQ4y5XUMU5C
	QRAG4O+BiR2JPSaUwPMShnN4ARV7Y0M0ofYMngJIfOgFsDIWSuMBLDUSNmsBEh/i
	4/lvsZnd/Dvzz8wONV1TscSa6qolzlwKXkXFSDQkLhJTe87clyAcuvZG9GBfGex7
	ECuIW19fIIpU/BPrhKrdnL2rWkSo6uhpr+xUT2edEk3UV+/1vcuk4MDYh/7KZ91E
	zBNoycwMtbSMzGRaq7uNBFJDQSYTDH6E9yeBprEgyDRz53WTRR1+1/R7TzaXI+/h
	wEhwKxMMl/ILQmobmxloahpuF71I6+1Sairzvp7WnVx4c3cSN57Ao1NH7syLNBS1
	xgYPBCFnf25rvlLd+ke+N9QnYcdUw6FxiS/a0fCS6LoqPQQqzqk58VJqzDw7VvsC
	yiOQMwD0a10AAAAASUVORK5CYII=
    }]
}

# Create a new toplevel command
proc wm::toplvl {name args} {
    variable toplvl
    variable map
    variable icon
    variable iclose
    variable State
    if {[dict exists $args -class]} {
        if {[dict get $args -class] in {ComboboxPopdown}} {
            tailcall toplevel $name {*}$args
        }
    }
    # Create a temporary frame to do all of the error checking and be able
    # to use the winfo command to obtain useful bits of information
    frame $name
    set parent [winfo parent $name]
    set child [winfo name $name]
    destroy $name
    set w [toplevel $parent.toplvl-[incr toplvl]]
    label $w.icon -image $icon
    label $w.title -text $child -font TkCaptionFont
    label $w.close -text "" -image $iclose
    frame $w.frame -container 1
    decorate $w
    toplevel $name {*}$args -use [winfo id $w.frame]
    frame $name.__wm__canary -class WmCanary
    wm overrideredirect $w 1
    bindtags $w.title [list $w.title WmTitlebar $w all]
    bindtags $w.close [list $w.close WmClose $w all]
    dict set map $name $w
    set State(geom) ""
    set State(pressed) 0
    return $name
}

namespace import wm::toplvl
rename toplvl toplevel

proc wm::lowerwm {window {below ""}} {
    set win [window $window]
    if {$below == ""} {
	lower $win
    } else {
	lower $win [window $below]
    }
}
proc wm::raisewm {window {above ""}} {
    set win [window $window]
    if {$above == ""} {
	raise $win
    } else {
	raise $win [window $above]
    }
}
namespace import wm::lowerwm
rename lowerwm lower
namespace import wm::raisewm
rename raisewm raise

proc wm::window {window} {
    variable map
    if {[dict exists $map $window]} {
        return [dict get $map $window]
    } else {
        return $window
    }
}

proc wm::unmanage {win} {
    # Grid
    set slaves [grid slaves $win]
    if {[llength $slaves]} {grid forget {*}$slaves}
    lassign [grid size $win] cols rows
    for {set i 0} {$i < $rows} {incr i} {
        grid rowconfigure $win $i -minsize 0 -pad 0 -uniform {} -weight 0
    }
    for {set i 0} {$i < $rows} {incr i} {
        grid columnconfigure $win $i -minsize 0 -pad 0 -uniform {} -weight 0
    }
    grid propagate $win 1
    # Pack
    set slaves [pack slaves $win]
    if {[llength $slaves]} {pack forget {*}$slaves}
    pack propagate $win 1
    # Place
    set slaves [place slaves $win]
    if {[llength $slaves]} {place forget {*}$slaves}
}

proc wm::decorate {win} {
    unmanage $win
    grid $win.icon $win.title $win.close -sticky ew
    grid $win.icon $win.close -padx 4 -pady 4
    grid $win.frame - - -padx 4 -pady {0 4} -sticky nsew
    grid rowconfigure $win $win.frame -weight 1
    grid columnconfigure $win $win.title -weight 1
}

proc wm::strip {win} {
    unmanage $win
    grid $win.frame -sticky nsew
    grid rowconfigure $win $win.frame -weight 1
    grid columnconfigure $win $win.frame -weight 1
}

# wm command implementation
proc wm::unknown {cmd sub args} {
    # Forward any unknown subcommands to the original wm command
    return [list wm::wm $sub]
}

proc wm::deiconify {window} {
    wm deiconify [window $window]
}

proc wm::state {window {status ""}} {
    set win [window $window]
    if {$status == ""} {
	return [wm state $win]
    } else {
	return [wm state $win $status]
    }
}

proc wm::geometry {window {geometry ""}} {
    if {[llength [info level 0]] > 2} {
	lassign [split $geometry "+"] wxh xw yw
	lassign [split $wxh "x"] w h

	lassign [wm::resizable $window] rw rh
	if {$rw == 0 && $rh == 0} {
	    return
	}
	lassign [wm minsize $window] minw minh
	lassign [wm maxsize $window] maxw maxh
	set swin ""
	if {$w != "" &&  $h != ""} {
	    if {$minw > $w} {
		set w $minw
	    } elseif {$w > $maxw} {
		set w $maxw
	    }
	    if {$minh > $h} {
		set h $minh
	    } elseif {$h > $maxh} {
		set h $maxh
	    }
	    set swin "[set w]x[set h]"
	}
	set wcoord ""
	if {$xw != "" && $yw != ""} {
	    set wcoord "+[set xw]+[set yw]"
	}
        tailcall wm geometry [window $window] "[set swin][set wcoord]"
    } else {
        tailcall wm geometry [window $window]
    }
}

proc wm::resizable {window args} {
    if {[llength [info level 0]] > 2} {
#        tailcall wm resizable [window $window] [set args]
	set com [subst "tailcall wm resizable [window $window] [set args]"]
	eval $com
    } else {
        tailcall wm resizable [window $window]
    }
}
  #Увеличить/уменьшить картинку (отрицательное значение - уменьшение)
proc wm::scaleImage {im xfactor {yfactor 0}} {
    set mode -subsample
    if {0} {
      if {abs($xfactor) < 1} {
        set xfactor [expr round(1./$xfactor)]
      } elseif {$xfactor>=0 && $yfactor>=0} {
        set mode -zoom
      }
    }
    if {$xfactor>=0 && $yfactor>=0} {
      set mode -zoom
    } else {
      set xfactor [expr $xfactor * -1]
    }

    if {$yfactor == 0} {set yfactor $xfactor}
    set t [image create photo]
    $t copy $im
    $im blank
    $im copy $t -shrink $mode $xfactor $yfactor
    image delete $t
}


proc wm::iconphoto {window args} {
    if {[lindex $args 0] eq "-default"} {
        variable icon
        set args [lrange $args 1 end]
    } else {
        set icon ""
    }
    # Find the first matching icon
    set scl 0
    foreach img $args {
        if {[image width $img] <= 24 && [image height $img] <= 24} {
            set icon $img
            set scl 1
            break
        }
    }
    if {$scl == 0} {
	scaleImage $img [expr {[image width $img] / 24 * -1}] [expr {[image height $img] / 24 }] 
        set icon $img
    }

    set win [window $window]
    if {$win ne $window} {
        $win.icon configure -image $icon
    } else {
        tailcall wm {*}[info level 0]
    }
}

proc wm::maxsize {window {width ""} {height ""}} {
    set com [info level 0]
    if {[llength $com] > 1} {
	set com "[lindex $com 0] [wm::window [lindex $com 1]] [lrange $com 2 end]"
    }
    tailcall wm {*}[set com]
}

proc wm::minsize {window {width ""} {height ""}} {
    set com [info level 0]
    if {[llength $com] > 1} {
	set com "[lindex $com 0] [wm::window [lindex $com 1]] [lrange $com 2 end]"
    }
    tailcall wm {*}[set com]
}

proc wm::overrideredirect {window {boolean ""}} {
    set win [window $window]
    if {$win ne $window} {
        if {$boolean eq ""} {
            lassign [grid size $win] cols rows
            return [expr {$cols == 1 && $rows == 1}]
        } elseif {$boolean} {
            strip $win
        } else {
            decorate $win
        }
    } else {
        tailcall wm {*}[info level 0]
    }
}

proc wm::stackorder {window args} {
    variable map
    set revmap {}
    dict for {k v} $map {dict set revmap $v $k}
    return [lmap w [wm stackorder $window {*}$args] {
        if {[dict exists $revmap $w]} {dict get $revmap $w} else {set w}
    }]
}

proc wm::title {window {string ""}} {
    variable map
    if {[dict exists $map $window]} {
        set w [dict get $map $window]
        if {[llength [info level 0]] > 2} {
            $w.title configure -text $string
        } else {
            return [$w.title cget -text]
        }
    } else {
        tailcall wm {*}[info level 0]
    }
}

proc wm::withdraw {window} {
    wm withdraw [window $window]
}

# Bindings
proc wm::Select {w x y} {
    variable State
    set top [winfo toplevel $w]
    raise $top
    set State(toplevel) $top
    set State(pressX) $x
    set State(pressY) $y
    set State(x) [winfo rootx $top]
    set State(y) [winfo rooty $top]
    set State(pressed) 1
    set State(cursor) [$w cget -cursor]
    set State(id) [after 100 [list $w configure -cursor fleur]]
    focus -force $top.frame
    update
}

proc wm::Drag {w x y} {
    variable State
    if {!$State(pressed)} return

    $w configure -cursor fleur
    set dx [expr {$x - $State(pressX)}]
    set dy [expr {$y - $State(pressY)}]
    set State(pressX) $x
    set State(pressY) $y
    set x [incr State(x) $dx]
    set y [incr State(y) $dy]
    wm geometry $State(toplevel) [format +%d+%d $x $y]
}

proc wm::Release {w x y} {
    variable State
    after cancel $State(id)
    $w configure -cursor $State(cursor)
    set State(pressed) 0
}

proc wm::Close {w} {
    variable map
    set top [winfo toplevel $w]
#Проверяем wm protokol $w WM_DELETE_WINDOW
    if {[wm protocol $top WM_DELETE_WINDOW] != ""} {
	eval [wm protocol $top WM_DELETE_WINDOW]
	return
    }
#Ищем и проверяем родное окно
    set ind [lsearch $map $top]
    if {$ind != -1} {
	incr ind -1
	set owin [lindex $map $ind]
	if {[wm protocol $owin WM_DELETE_WINDOW] != ""} {
	    eval [wm protocol $owin WM_DELETE_WINDOW]
	    return
	}
    }
    destroy $top
}

proc wm::Destroy {w} {
    variable map
    set top [winfo toplevel $w]
    if {[dict exists $map $top]} {
        set win [dict get $map $top]
        dict unset map $top
        # Destroying immediately causes a BadWindow X error
        after idle [list destroy $win]
    }
}
proc wm::pressBut {win x y} {
    if {[string first "toplvl-" $win] != -1} {
	variable State
	set top [winfo toplevel $win]
	raise $top
	set State(toplevel) $top
	set State(pressX) $x
	set State(pressY) $y
	set State(x) [winfo rootx $top]
	set State(y) [winfo rooty $top]
	set State(pressed) 1
	set State(geom) "[wm geometry $win]"
    }
}
proc wm::enterBut {win x y} {
    variable State
  if {$State(pressed) == 0} {
    if {[string first "toplvl-" $win] != -1} {
	set State(cursor) [$win cget -cursor]
	if {"[winfo containing $x $y]" == "$win"} {
	    set x0 [winfo x $win]
	    set y0 [winfo y $win]
	    set w0 [winfo width $win]
	    set h0 [winfo height $win]
	    set x0l [expr {$x0 + 10}]
	    set dg [winfo pixels $win 2.5m]
	    set x0r [expr {$x0 + $w0 - $dg}]
	    set y0t [expr {$y0 + $dg}]
	    set y0b [expr {$y0 + $h0 - $dg}]
	    if {$x > $x0l && $x < $x0r && $y < $y0t} {
		$win configure -cursor "top_side"
		set  State(arrow) "n"
	    } elseif {$x > $x0l && $x < $x0r && $y > $y0b} {
		$win configure -cursor "bottom_side"
		set  State(arrow) "s"
	    } elseif {$x > $x0r && $y < $y0b && $y > $y0t} {
		$win configure -cursor "right_side"
		set  State(arrow) "e"
	    } elseif {$x <= $x0l && $y < $y0b && $y > $y0t} {
		$win configure -cursor "left_side"
		set  State(arrow) "w"
	    } elseif {$x >= $x0r && $y <= $y0t} {
		$win configure -cursor "top_right_corner"
		set  State(arrow) "ne"
	    } elseif {$x <= $x0l && $y <= $y0t} {
		$win configure -cursor "top_left_corner"
		set  State(arrow) "nw"
	    } elseif {$x <= $x0l && $y >= $y0b} {
		$win configure -cursor "bottom_left_corner"
		set  State(arrow) "sw"
	    } elseif {$x >= $x0r && $y >= $y0b} {
		$win configure -cursor "bottom_right_corner"
		set  State(arrow) "se"
	    } else {
		$win configure -cursor ""
		set  State(arrow) ""
	    
	    }
	}
    }
  }
}
proc wm::leaveBut {win x y} {
    variable State
  if {$State(pressed) == 0} {
    if {[string first "toplvl-" $win] != -1 && [info exist State(cursor)]} {
	$win configure -cursor $State(cursor)
    }
  }
}

proc wm::relBut {win x y} {
    variable State
    if {$State(pressed) == 1} {
	set dx [expr {$x - $State(pressX)}]
	set dy [expr {$y - $State(pressY)}]
	lassign [split $State(geom) "x"] w ost
	lassign [split $ost "+"] h xw yw
	
	lassign [wm::resizable $win] rw rh
	if {$rw == 0 && $rh == 0} {
	    set State(arrow) ""
	}
	set geom $State(geom)	
	switch $State(arrow) {
	    "nw" {
		set geom [expr {$w + $dx * -1}]x[expr {$h + $dy * -1}]
		append geom "+[expr {$xw + $dx}]+[expr {$yw + $dy}]"
	    }
	    "n" {
		set dx 0
		set geom [expr {$w + $dx}]x[expr {$h + $dy * -1}]		
		append geom "+[expr {$xw + $dx}]+[expr {$yw + $dy}]"
	    }
	    "ne" {
		set geom [expr {$w + $dx}]x[expr {$h + $dy * -1}]
		append geom "+[expr {$xw + $dx * 0}]+[expr {$yw + $dy}]"
	    }
	    "w" {
		set dy 0
		set geom [expr {$w + $dx * -1}]x[expr {$h + $dy}]		
		append geom "+[expr {$xw + $dx}]+$yw"
	    }
	    "e" {
		set dy 0
		set geom [expr {$w + $dx}]x[expr {$h + $dy}]	
	    }
	    "sw" {
		set geom [expr {$w + $dx * -1}]x[expr {$h + $dy}]
		append geom "+[expr {$xw + $dx}]+[expr {$yw + $dy * 0}]"
	    }
	    "s" {
		set dx 0
		set geom [expr {$w + $dx}]x[expr {$h + $dy}]
	    }
	    "se" {
		set geom [expr {$w + $dx}]x[expr {$h + $dy}]
	    }
	}

	$win configure -cursor $State(cursor)
	wm geometry $win "$geom"
	set State(geom) ""
	set State(pressed) 0
update
    }
}

bind Toplevel <Button-1> {wm::pressBut %W %X %Y}
bind Toplevel <ButtonRelease-1> {wm::relBut %W %X %Y}
bind Toplevel <Leave> {wm::leaveBut %W %X %Y}
bind Toplevel <Motion> {wm::enterBut %W %X %Y}

bind WmTitlebar <Button-1> {wm::Select %W %X %Y}
bind WmTitlebar <B1-Motion> {wm::Drag %W %X %Y}
bind WmTitlebar <ButtonRelease-1> {wm::Release %W %X %Y}
bind WmClose <Button-1> {wm::Close %W}
bind WmCanary <Destroy> {wm::Destroy %W}

