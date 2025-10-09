package require svgwidgets
wm state . withdraw
wm state . normal
set ::bgold [. cget -bg]
set ::geo [wm geometry .]
set ::min [wm minsize .]
catch {package require wm}

#. configure -bg yellow
wm state . withdraw
wm state . normal
wm protocol . WM_DELETE_WINDOW {exitarm . [mc {Вы действительно\nхотите выйти?}]}
set ::bgold [. cget -bg]
set ::geo [wm geometry .]
. configure -bg chocolate


proc exitarm {t mestok} {
	variable ::erm
	set t1 $t
	if {$t == "."} {
	    set t ""
	} else {
	    set t $t
	}

	set erlib [mbutton new "$t.message" -type yesno  -fillnormal white -text "$mestok" ]
	set herlib [expr {int([winfo fpixels "$t.message" [$erlib config -height]])}]
	set werlib [expr {int([winfo fpixels "$t.message" [$erlib config -width]])}]
	tk busy hold .dsvg
	set werlib [expr {[winfo width $t.game] / 2 - $werlib / 2}]
	set herlib [expr {[winfo height $t.game] / 4 }]
	set rr [$erlib place -in $t1 -x $werlib -y $herlib]
	wm resizable $t1 0 0
	if {$rr != "yes"} {
	    return
	}
	set allo "[info class instances cbutton] [info class instances ibutton] [info class instances mbutton] [info class instances cmenu]  [info class instances cframe]"
	foreach {oo} $allo {
	    set ind 0
	    foreach omain $::listO {
		if {"$oo" != "$omain"} {
		    continue
		}
		set ind 1
		break
	    }
	    if {$ind == 0} {
		$oo destroy
	    }
	}
#	destroy $t1
	puts "Пример demoPackSVGwithImageMesFromMenu.tcl завершен."
	tk busy forget .dsvg
	destroy .game
	wm resizable $t1 1 1
	wm geometry $t1 $::geo
	. configure -bg $::bgold
	wm state . withdraw
	return
}

proc badmove {t wd mestok} {
#t - главное окно
#wd - нажатый виджет
#mestok - сообщение об ошибке
	set wcb [winfo width $wd]
	set hcb [winfo height $wd]
	set xcb [winfo x $wd]
	set ycb [winfo y $wd]
	set wd1 $wd
	set ind [string first ".cb" $wd]
	if {$ind != -1} {
	    set wd [string range $wd $ind end]
	}
	set numwd [string range $wd 4 4]
	set ltrwd [string range $wd 3 3]
#puts "badmove: wd=$wd numwd=$numwd lettre=$ltrwd"

	if {$t == "."} {
	    set t1 ""
	} else {
	    set t1 $t
	}
	set typewd "up"
	if {$numwd < 2} {
	    set typewd "down"
	}
	set erlib [mbutton new "$t1.message" -type $typewd -tongue "0.45 0.5 0.55 5m" -bg white -fillnormal yellow -fillenter "#b6f6f6" -text "$mestok" -textanchor n]
	set herlib [expr {int([winfo fpixels "$t1.message" [$erlib config -height]])}]
	$erlib config -background [. cget -bg]

#Главное окно неизменяемое
	wm resizable $t 0 0
	tk busy hold $t
	set wmes [expr {int([winfo fpixels "$t1.message" [$erlib config -width]])}]
	set werlib [expr {$xcb + $wcb / 2 - $wmes / 2}]
	if {$numwd > 1} {
	    set herlib [expr {$ycb + $hcb / 2}]
	} else {
	    set herlib [expr {$ycb - $herlib / 1}]	
	}
	if {$ltrwd == "a"} {
	    set werlib [expr {$xcb}]
	    $erlib config -tongue "0.45 0.15 0.55 5m"
	} elseif {$ltrwd == "h"} {
	    set werlib [expr {$xcb + $wcb - $wmes }]
	    $erlib config -tongue "0.45 0.90 0.55 5m"
	}
	eval bind $t <Configure> \{raise $t1.message $t1._Busy\}
#puts "erlib=$erlib"
	set rr [$erlib place -in [winfo parent $wd1] -x $werlib -y $herlib]
	if {[tk busy status $t]} {
	    tk busy forget $t
	}
	bind $t <Configure> {}
	wm resizable $t 1 1
}


set mydir [file dirname [info script]]

image create photo checkerWhite -file [file join $mydir "шашкаБелая_50x50.png"]
image create photo checkerRed -file [file join $mydir "шашкаКрасная_50x50.png"]

#Чей ход: булые - snow, черные - red
set ::tstep snow
#widget, выбранная для хода
set ::fstep ""
#Цвет белых шашек
set ::wcolor ""
#Цвет черных шашек
set ::bcolor ""

set dim 40

proc step {oo bstart {bend ""}} {
    puts "Step $oo: from $bstart "
    set filln "[$oo config -fillpress]"
    if {$filln == "" && $::fstep == ""} {
	badmove . $bstart "Проблемы с ходом: \nКлетка без фигуры"
	return
    }
    if {$::tstep == "snow" && "$filln" != $::wcolor && $::fstep == ""} {
	badmove . $bstart "Проблемы с ходом 2: \nСейчас не ваш ход"
	return
    }
    if {$::tstep == "red" && "$filln" != $::bcolor && $::fstep == ""} {
	badmove . $bstart "Проблемы с ходом 3: \nСейчас не ваш ход"
	return
    }
    if {$::fstep == $bstart} {
	set ::fstep ""
	badmove . $bstart "Проблемы с ходом 4"
	return
    }
    if {$::fstep == ""} {
	set ::fstep $oo
	badmove . $bstart "Вы выбрали фигуру для хода: \n[$oo canvas] $oo\nщёлкните по мне, а затем\nпо клетке для перехода"
	return
    }
    if {[$oo config -fillnormal] != "" } {
	badmove . $bstart "Проблемы с ходом: \nсюда ходить нельзя, клетка занята"
	return
    }
#Делаем ход и
#Переход хода
    set oldstep $::tstep
    if {$::tstep == "snow" } {
	set ::tstep "red"
	$::ared  config -fillnormal cyan
	if {$svgwidget::tkpath != "::tko::path"} {
	    $::asnow config -fillnormal gradient1
	} else {
	    $::asnow config -fillnormal ::tko::gradient1
	}
    } else {
	set ::tstep "snow"
	if {$svgwidget::tkpath != "::tko::path"} {
	    $::ared  config -fillnormal gradient1
	} else {
	    $::ared  config -fillnormal ::tko::gradient1
	}
	$::asnow config -fillnormal cyan
    }
    setcyan

    $oo config -fillnormal [$::fstep config -fillnormal] -fillenter [$::fstep config -fillenter] -fillpress [$::fstep config -fillpress]
    $::fstep config -fillnormal "" -fillpress "" -fillenter "##"

    set sl1 [string range $bstart 3 3]
    set sl2 [string range $bstart 4 4]
#Получаем код буквы в snl1
    binary scan $sl1 "c" snl1
#Получаем код следующей буквы в snl1next
    set snl1next [expr {$snl1 + 1}]
#Получаем букву из кода следующей буквы в tsnl1next
    set tsnl1next [format "%c" $snl1next]
puts "sl1=$sl1 snl1=$snl1 snl1next=$snl1next tsnl1next=$tsnl1next"
puts "Вы ($oldstep) сделали ход [string range [$::fstep canvas] 3 4] - [string range [$oo canvas] 3 4]"
	set ::fstep ""
}

proc setcyan {} {
    set ared [string range $::ared 9 end]
    set asnow [string range $::asnow 9 end]
    for {set i 0} {$i < 8} {incr i} {
	if {$::tstep == "red" } {
	    ::oo::Obj$ared  config -fillnormal cyan
	    if {$svgwidget::tkpath != "::tko::path"} {
		::oo::Obj$asnow config -fillnormal gradient1
	    } else {
		::oo::Obj$asnow config -fillnormal ::tko::gradient1
	    }
	} else {
	    if {$svgwidget::tkpath != "::tko::path"} {
		::oo::Obj$ared  config -fillnormal gradient1
	    } else {
		::oo::Obj$ared  config -fillnormal ::tko::gradient1
	    }
	    ::oo::Obj$asnow config -fillnormal cyan
	}
	incr ared
	incr asnow
	if {$svgwidget::tkpath == "::tko::path"} {
	    incr ared
	    incr asnow
	}
    }
}

proc ci {id} {
#Белые шашки
    set cw [list a c e g]
#Черные шашки
    set cb [list b d f h]
#Буква клетки/
    set l [string range [string tolower $id] 0 0]
#Номер клетки/
    set n [string range [string tolower $id] 1 1]
	if {[expr {$n % 2}] == 1} {
	    set cwb "$cw"
	} else {
	    set cwb "$cb"	
	}
    if {$n < 4} {
	set image checkerWhite
    } elseif {$n > 5} {
	set image checkerRed    
    } else {
	set image ""
    }
	if {[lsearch $cwb $l] != -1} {
	    if {$image ==  "checkerRed"} {
		set bred [cbutton new .game.cb$id -type circle -width 10m -height 10m -text "" -strokewidth 1 -stroke "" -fillenter orangered -fillpress red1 -relcom 1 -bg black]
		set grad1 [[$bred canvas] gradient create radial -stops {{0 gray95} {1 gray70}} -radialtransition {0.6 0.4 0.5 0.7 0.3}]
		set grad2 [[$bred canvas] gradient create radial -stops {{0 snow} {1 red}}]
		$bred config -fillnormal $grad2
#Цвет черных шашек
		set ::bcolor [$bred config -fillpress ]
	    } elseif {$image ==  "checkerWhite"} {
		set bred [cbutton new .game.cb$id -type circle -width 10m -height 10m -text "" -strokewidth 1 -stroke ""  -fillenter gray84 -fillpress snow -relcom 1 -bg black]
		set grad1 [[$bred canvas] gradient create radial -stops {{0 gray95} {1 gray70}} -radialtransition {0.6 0.4 0.5 0.7 0.3}]
		set grad2 [[$bred canvas] gradient create radial -stops {{0 snow} {1 red}}]
		$bred config -fillnormal $grad1
#Цвет белых шашек
		set ::wcolor [$bred config -fillpress ]
	    } else {
		set bred [cbutton new .game.cb$id -type circle -width 10m -height 10m -text "" -strokewidth 1 -stroke ""  -fillnormal "" -fillenter "" -fillpress "" -relcom 1 -bg black]
		set grad1 [[$bred canvas] gradient create radial -stops {{0 gray95} {1 gray70}} -radialtransition {0.6 0.4 0.5 0.7 0.3}]
		set grad2 [[$bred canvas] gradient create radial -stops {{0 snow} {1 red}}]
	    }
		$bred config  -command [subst {step $bred  .game.cb$id  \[winfo containing \$x \$y \]}] -relcom 0
	} else {
	    return "x"
	}
    
    return .game.cb$id
}
#n - number
proc n {id} {
    if {$id > 10} {
	set text [expr {$id - 10}]
	set grad 180
    } else {
	set text $id
	set grad 0
    }
    cbutton new .game.fr$id -type rect -width 5m -height 5m -text "$text" -rotate $grad  -fontweight bold
    return .game.fr$id
}
#a - angle
proc a {id} {
    set len [string length $id]
    set text [string range $id 0 0]
    if {$len > 1} {
	set grad 180    
    } else {
	set grad 0
    }
    set abut [cbutton new .game.fr$id -type rect -width 5m -height 5m -rotate $grad -text $text -fontweight bold]
    if {$id == "E"} {
	$abut config -command {exitarm . [mc "Вы действительно\nхотите выйти?"]}
    }
    if {$id == "A"} {
	set ::asnow $abut
    }
    if {$id == "A1"} {
	set ::ared $abut
    }
    if {$id == "nw" || $id == "ne" || $id == "sw" || $id == "se" } {
	$abut config -command {initPos}  -fillnormal "#02ffa2"
    }

    return .game.fr$id
}
proc initPos {} {
if {0} {
    foreach b [info class instances cbutton] {
	if {[$b config -text] == ""} {
	    $b destroy    
	}
    }
    foreach b [info class instances ibutton] {
	if {[$b config -text] == ""} {
	    $b destroy    
	}
    }
}
    set allo "[info class instances cbutton] [info class instances ibutton] [info class instances mbutton] [info class instances cmenu]  [info class instances cframe]"
	foreach {oo} $allo {
	    set ind 0
	    foreach omain $::listO {
		if {"$oo" != "$omain"} {
		    continue
		}
		set ind 1
		break
	    }
	    if {$ind == 0} {
		if {[$oo config -text] == ""} {
		    $oo destroy
		}
	    }
    }

    
    set j 1
    for {set i 8} {$i > 0} {incr i -1} {
	grid x [ci a$i] [ci b$i] [ci c$i] [ci d$i] [ci e$i] [ci f$i] [ci g$i] [ci h$i]  -sticky nwse -row $j
	incr j
#    grid [n $i] x x x x x x x x [n 1$i] -sticky nws
    }
    set ::tstep snow
    setcyan
}

#. configure -height 450 -width 450
frame .game -height 450 -width 450 -bg snow -bd 2
pack .game -pady 50 -padx 50 -anchor w
# -anchor center
grid propagate . 0

#Шапка доски
grid [a nw] [a A1] [a B1] [a C1] [a D1] [a E1] [a F1] [a G1] [a H1] [a ne] -sticky nwe
grid configure .game.frnw -sticky nw
grid configure .game.frne -sticky nw
for {set i 8} {$i > 0} {incr i -1} {
    grid [n $i] x x x x x x x x [n 1$i] -sticky nws
}
#Низ доски
grid [a sw] [a A] [a B] [a C] [a D] [a E] [a F] [a G] [a H] [a se] -sticky nwe
grid configure .game.frsw -sticky nw
grid configure .game.frse -sticky nw

grid columnconfigure . "0 1 2 3 4 5 6 7 8 9" -weight 3 -uniform a
grid columnconfigure . "0 9" -weight 1
grid rowconfigure . "1 2 3 4 5 6 7 8 " -weight 1 -uniform b

initPos
update

#wm minsize . 450 450
wm iconphoto . checkerWhite
wm title . "Шашки_с_SVG-виджетами [pwd]"
wm geometry . 450x450+200+100
setcyan
