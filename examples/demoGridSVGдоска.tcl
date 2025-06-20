package require svgwidgets
wm state . withdraw
wm state . normal
set ::bgold [. cget -bg]
set ::geo [wm geometry .]
set ::min [wm minsize .]

. configure -bg yellow
. configure -bg snow
wm state . withdraw
wm state . normal
wm protocol . WM_DELETE_WINDOW {exitarm . {Вы действительно\nхотите выйти?}}

proc exitarm {t mestok} {
	if {$t == "."} {
	    set t1 ""
	} else {
	    set t1 $t
	}
	set erlib [mbutton new "$t1.message" -type yesno  -fillnormal white -text "$mestok" -textanchor n]
	set herlib [expr {int([winfo fpixels "$t1.message" [$erlib config -height]])}]
	set werlib [expr {int([winfo fpixels "$t1.message" [$erlib config -width]])}]

#Главное окно неизменяемое
	wm resizable $t 0 0
	tk busy hold $t
	set werlib [expr {[winfo width $t] / 2 - $werlib / 2}]
	set herlib [expr {[winfo height $t] / 4 }]
	eval bind . <Configure> \{raise $t1.message $t1._Busy\}
	set rr [$erlib place -in $t -x $werlib -y $herlib]
	if {[tk busy status $t]} {
	    tk busy forget $t
	}
	bind . <Configure> {}
	if {$rr != "yes"} {
	    wm resizable $t 1 1
	    return
	}
#Убураем за собой!!!
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
	destroy .b
	wm resizable $t 1 1
	wm geometry $t $::geo
	eval wm minsize $t $::min
	. configure -bg $::bgold
	wm title . "Следующий пример"
	if {$::argc > -1} {
	    exit
	}
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
puts "Проблемы с ходом: Сейчас не ваш ход"
	return
    }
    if {$::tstep == "snow" && "$filln" != $::wcolor && $::fstep == ""} {
puts "Проблемы с ходом 2: Сейчас не ваш ход"
	return
    }
    if {$::tstep == "red" && "$filln" != $::bcolor && $::fstep == ""} {
puts "Проблемы с ходом 3: Сейчас не ваш ход"
	return
    }
    if {$::fstep == $bstart} {
	set ::fstep ""
puts "Проблемы с ходом 4"
	return
    }
    if {$::fstep == ""} {
#set ::fstep $bstart
	set ::fstep $oo
puts "Вы выбрали фигуру для хода: [$oo canvas] $oo"
	return
    }
if {[$oo config -fillnormal] != "" } {
puts "Проблемы с ходом: сюда ходить нельзя, клетка занята"
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
		set bred [cbutton new .cb$id -type circle -width 10m -height 10m -text "" -strokewidth 1 -stroke "" -fillenter orangered -fillpress red1 -relcom 1 -bg black]
		set grad1 [[$bred canvas] gradient create radial -stops {{0 gray95} {1 gray70}} -radialtransition {0.6 0.4 0.5 0.7 0.3}]
		set grad2 [[$bred canvas] gradient create radial -stops {{0 snow} {1 red}}]
		$bred config -fillnormal $grad2
#Цвет черных шашек
		set ::bcolor [$bred config -fillpress ]
	    } elseif {$image ==  "checkerWhite"} {
		set bred [cbutton new .cb$id -type circle -width 10m -height 10m -text "" -strokewidth 1 -stroke ""  -fillenter gray84 -fillpress snow -relcom 1 -bg black]
		set grad1 [[$bred canvas] gradient create radial -stops {{0 gray95} {1 gray70}} -radialtransition {0.6 0.4 0.5 0.7 0.3}]
		set grad2 [[$bred canvas] gradient create radial -stops {{0 snow} {1 red}}]
		$bred config -fillnormal $grad1
#Цвет белых шашек
		set ::wcolor [$bred config -fillpress ]
	    } else {
		set bred [cbutton new .cb$id -type circle -width 10m -height 10m -text "" -strokewidth 1 -stroke ""  -fillnormal "" -fillenter "" -fillpress "" -relcom 1 -bg black]
		set grad1 [[$bred canvas] gradient create radial -stops {{0 gray95} {1 gray70}} -radialtransition {0.6 0.4 0.5 0.7 0.3}]
		set grad2 [[$bred canvas] gradient create radial -stops {{0 snow} {1 red}}]
	    }
		$bred config  -command [subst {step $bred  .cb$id  \[winfo containing \$x \$y \]}] -relcom 0
	} else {
	    return "x"
	}
    
    return .cb$id
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
    cbutton new .fr$id -type rect -width 5m -height 5m -text "$text" -rotate $grad  -fontweight bold
    return .fr$id
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
    set abut [cbutton new .fr$id -type rect -width 5m -height 5m -rotate $grad -text $text -fontweight bold]
    if {$id == "E"} {
	$abut config -command {exitarm . "Вы действительно\nхотите выйти?"}
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

    return .fr$id
}
proc initPos {} {
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
    
    set j 1
    for {set i 8} {$i > 0} {incr i -1} {
	grid x [ci a$i] [ci b$i] [ci c$i] [ci d$i] [ci e$i] [ci f$i] [ci g$i] [ci h$i]  -sticky nwse -row $j
	incr j
#    grid [n $i] x x x x x x x x [n 1$i] -sticky nws
    }
    set ::tstep snow
    setcyan
}

. configure -height 450 -width 450
grid propagate . 0

#Шапка доски
grid [a nw] [a A1] [a B1] [a C1] [a D1] [a E1] [a F1] [a G1] [a H1] [a ne] -sticky ne
grid configure .frnw -sticky nw
grid configure .frne -sticky nw
for {set i 8} {$i > 0} {incr i -1} {
    grid [n $i] x x x x x x x x [n 1$i] -sticky nws
}
#Низ доски
grid [a sw] [a A] [a B] [a C] [a D] [a E] [a F] [a G] [a H] [a se] -sticky ne
grid configure .frsw -sticky nw
grid configure .frse -sticky nw

grid columnconfigure . "0 1 2 3 4 5 6 7 8 9" -weight 3 -uniform a
grid columnconfigure . "0 9" -weight 1
grid rowconfigure . "1 2 3 4 5 6 7 8 " -weight 1 -uniform b

initPos
update

wm minsize . 450 450
wm iconphoto . checkerWhite
wm title . "Шашки с svg-фигурами"
wm geometry . +200+100
setcyan

