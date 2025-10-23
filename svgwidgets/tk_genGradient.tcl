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
    foreach {wdclass} $wsclass {
	set listoo -1
	catch {set listoo [info class instances $wdclass]}
	if {$listoo == -1} {
    	    error "svgwidget::cleargengrad: Unknown class=$wdclass: must be \"\[cbutton\] \[ibutton\] \[mbutton\] \[cmenu\] \[cframe\]\""
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
	set erlib [mbutton create mesend "$t1.message" -type yesno  -fillnormal white -text [mc "Are you sure you\nwant to quit?"] -textanchor n -strokewidth 3]
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
  package require msgcat
  namespace import ::msgcat::mc
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
  set tg [mc "gradient generation"]
  wm title .tpgradient "SVGWIDGETS: $tg"
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

  label .tpgradient.frameFirst.frame0.label1 -background "#d6d2d0" -foreground "#221f1e" -relief {flat} -text "[mc {Gradient type}]"

  pack .tpgradient.frameFirst.frame0.label1 -anchor n -expand 0 -fill none -padx 0 -pady 0 -side top

  set arraydir {"Top to Bottom" "Top-Right to Bottom-Left" "Right to Left" "Bottom-Right to Top-Left" "Bottom to Top" "Bottom-Left to Top-Right" "Left to Right" "Top-Left to Bottom-Right"}

#Заготовки для градиента linear
  frame .tpgradient.frameFirst.frame0.linear -borderwidth {2} -relief {flat} -background yellow
  label .tpgradient.frameFirst.frame0.linear.lab -background "#d6d2d0" -foreground "#221f1e" -relief {flat} -text "Направление: "

  set ::lmenu [cbutton create mlin .tpgradient.frameFirst.frame0.linear.direction -type rect -text [mc "Direction patterns"] -fontsize 3.5m -compound left]

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
label .tpgradient.frameFirst.frame0.radial.lab -background "#d6d2d0" -foreground "#221f1e" -relief {flat} -text "[mc Position]: "

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
        
    set tg [mc "Gradient components"]
    label $cf.label5 -background snow -foreground "#221f1e" -relief {flat} -text "$tg"
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
    eval "cbutton create addst $buts.butadd -type round -command {global Gradient; ::gengrad::createstop $cf \$Gradient(i)} -text \"[mc {Add layer}]\" -strokenormal skyblue -strokewidth 0.5m -fontsize 4m -fontfamily \"$svgFont\""

    cbutton create view $buts.butview -rx 2m -command {::gengrad::viewgradient ".tpgradient.frameFirst.canvas18"}  -text "[mc {Gradient preview}]" -strokenormal skyblue -strokewidth 0.5m -fontsize 4m -fontfamily "$svgFont"
    cbutton create ok $buts.butok -type ellipse -command {::gengrad::okgradient} -text [mc "Accept"] -strokenormal skyblue -strokewidth 0.5m -fontsize 4m -fontfamily "$svgFont"
    cbutton create canc $buts.butcan -type round -command {::gengrad::cancelgradient} -text [mc "Cancel"] -strokenormal skyblue -strokewidth 0.5m -fontsize 4m -fontfamily "$svgFont"
    eval "cbutton create delst $buts.butdel -command {::gengrad::deletestop $cf} -text \"[mc {Remove last layer}]\" -strokenormal skyblue -strokewidth 0.5m -fontsize 4m -fontfamily \"$svgFont\""

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
    wm title $wgrad [mc "Gradient code generation"]
    wm withdraw $wgrad
    wm protocol $wgrad WM_DELETE_WINDOW [subst "after 0 wm withdraw $wgrad"]
    wm iconphoto $wgrad "$::gengrad::icongrad"
    wm iconphoto .tpgradient "$::gengrad::icongrad"

    wm geometry $wgrad 600x430+100+50
    set ::vgrad [cframe create "Obj[incr ::gengrad::i]" $wgrad.can -type clframe -text "[mc {Gradient preview}]" -fontsize 5m -fillnormal yellow -bg snow -strokewidth 1m -stroke cyan]
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
