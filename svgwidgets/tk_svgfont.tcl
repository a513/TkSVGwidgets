namespace eval ::svgfont {
  set i 0
  set iconfont [image create photo -data {
    iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAAD5klEQVRIx62Wf0yUdRzHX89zhwmIAUbERbOgtcnUubK2XLm5uWmsUUxW
    ayNztWotW+sP/cdyS1stJQnTtpZzWYol80eRSwpnGzBJWzXBMEW5Qoi7Q447uOOOe+5598fBjgPULXlvn30/z/v7PJ/39/vd9/P5PIYkAfgDAfZ9d4oDp34lPBrFlXkb
    c5wO0g0D0wAn4DBIwOFAJlhAzIJw1MI3PEJcULH8QdauWUX+HTkAGJJU33CS39v/oKK8gpKi+dwK3N29HDt6mKzcQl6qLAfPNb/er/5IM43qnTXquNglNuzYI7fHk5xp
    uygdbpTCoZtHGYkodKJZsT8vTZnyDw1rwZo3BPc8lWTPnJfIk/Z9LoF6eiJqt6S/LKkzKnX6pE5PYrzSE9c5HtKlzVvUBPq75tAUEUBQUJZkPqyVDhwcn9Vrmy6J0xIt
    Eo0SLw+I8j5R2S8ev6zTIIWj6t/boGYWTS9w9+LnkkzAL0HC1jwx5YNWScfH7JikE7yjn0GNoGDD2WkFnFnpzuQVmJuN+0KAz/Zf5YOtJQAEhvxYkQiGAec9EfrjNnMy
    53BvcT7B0BZWZ66g95cish65zu1b8ujaFNXmkMTYYoZCg2PnONUOev2qsyRe98vvn/4OADKdRqqgYQOjCd+UQemyQiTxbe1e2LiTIwNRuG8lpm1g2kDYBvv6eeE0JzM2
    EE+4GZlzOd7SnRAzHYBBbs4sjrf9xKzZMGgBsbE9XQfmtOw0K5IEo3HiQHom2A6I2YBl3Cg+piYd0eTncQSDAbjcy/AoRJWwiACcxG4kYKelRowbJCrbBMRGhqh89U2o
    38bJ1svEgezBKEYUcGZgmTcQsHCkEBkRYCB102npWfj7+/jqipeFC4tJFzzWtYJ17xr07Hfiqi+DjjqwhieFL8CMOSbsYCDI0jwDlZlgrE95NXtePml5eQyb0DEElORA
    KbgWAC/Uw+ZnwNc5SSALipa/OKEEHpK210ihEcVB2967KFqlh1ukgh8lKgbFA37hisjdvk4KIf2AlIn0zcpp8mCxmLfk+STT9FuiTGzaJ4EGLlxTX1TyRCRvWPL6JK9H
    8nglhWulYaQA0vdIK5HcZyYJLBK4nkyVrfpaYoXU2n6TWn1OCrok1UuhVdIRpGVIA/9MELhLkLHqf7YUW1LfmO+TgrlSPVJXU2o1Xb91l3yBwRnoYSFJV5K9yJJY/Zbo
    7vHo4127Z7xl7tj9pc62dcosdN1Jxu0FbK/5hG6vj1uFLxCm+tM9DNmzWLqwOPFXAeC++i8bq76grubtsWI0H8gAjAlmArMBx4RxPO3DgE3pK09TteFZFtxfCMB/UpaV
    dh5zlWAAAAAASUVORK5CYII=  }]
    set fontsvg(-fontfamily) "Helvetika"
#    set fontsvg(-fontsize) "3m"
    set fontsvg(-fontsize) "15"
    set fontsvg(-fontweight) "normal"
    set fontsvg(-fontslant) "normal"
    set fontsvg(-filloverstroke) 0
    if {[tk windowingsystem] != "win32"} {
	set fontsvg(-stroke) ""
    } else {
	set fontsvg(-stroke) "#3bc654"
    }
    set fontsvg(-strokewidth) 0
    set fontsvg(-strokeopacity) 1.0
    set fontsvg(-fillopacity) 1.0
    set fontsvg(-fill) "black"

    proc fontsvg_sample { par {scale ""}} {
	variable fontsvg
	set w .__tk_fontsvg
	$w.fr3 coords "sample" [expr {5 + $fontsvg(-strokewidth)}] [expr {20 + $fontsvg(-strokewidth)}]
	if {$par != "all"} {
	    eval $w.fr3 itemconfigure "sample"  $par $fontsvg([set par])
	} else {
	    eval $w.fr3 itemconfigure "sample"  [array get fontsvg]
	}
    }
    proc clearobj {} {
	set wsclass "cbutton ibutton mbutton cmenu cframe"
	foreach {wdclass} $wsclass {
	    set listoo -1
	    catch {set listoo [info class instances $wdclass]}
	    if {$listoo == -1} {
    		return
	    }
	    foreach {oo} $listoo {
		if {[string first "::svgFont1" $oo] != -1} {
		    $oo destroy
		}
	    }
	}
    }
    proc cancel {w} {
	clearobj
	destroy [winfo toplevel $w]
	set ::svgfont::fontsvg(ret) "Cancel"
	return ""
    }
    proc done {w} {
	clearobj
	destroy [winfo toplevel $w]
	set ::svgfont::fontsvg(ret) "Accept"
	return ""
    }

}
proc tk_fontsvg { args} {
    ::svgfont::clearobj
    catch {unset ::svgfont::fontsvg(ret)}
    set isvg 99
    set ::fontFam 0
    set largs [llength $args]
    if {$largs != 0 && $largs != 2} {
	error "bad params: must be <name canvas> <id/tag item text>"
    }
    if {$largs == 2} {
	set w [lindex $args 0]
	set id [lindex $args 1]
	if {[winfo exists $w]} {
	    if {[winfo class $w] != "PathCanvas" && [winfo class $w] != "TkoPath"} {
#	error "tk_fontsvg: widget $w not class PathCanvas and TkoPath"
		puts "tk_fontsvg: widget $w not class PathCanvas and TkoPath"
		set w ""
	    } else { 
		set type [$w type $id]
		if {$type == "ptext" || ($type == "text" && [winfo class $w] == "TkoPath")} {
		    foreach key [array names ::svgfont::fontsvg] {
			set ::svgfont::fontsvg([set key]) [$w itemcget $id [set key]]
		    }
		} else {
		    set w ""
		}
	    }
	}
    }

    package require msgcat
    namespace import ::msgcat::mc

    package require svgwidgets
    if {$::svgwidget::tkpath == "::tkp::canvas"} {
	set fptext "ptext"
    } else {
	set fptext "text"
    }
    set ::lang "ru"

    set tfont ".__tk_fontsvg"
    catch "destroy $tfont"
    toplevel $tfont   -relief {raised}  -background {gray86}  -highlightbackground {gray86}

    wm geometry $tfont 600x550+50+50
    wm minsize $tfont 550 500
    set tt [mc "svg-font select"]
    wm title $tfont "SVG-widgets: $tt"
    wm iconphoto $tfont "$::svgfont::iconfont"
    wm protocol ".__tk_fontsvg" WM_DELETE_WINDOW {::svgfont::cancel ".__tk_fontsvg" }

    set rfr [cbutton create svgFont[incr isvg] $tfont.c -type frame -rx 0  -fillnormal yellow -bg yellow -strokewidth 0 -stroke {}]

    pack $tfont.c -in $tfont -fill both -expand 1 -padx 3m -pady 3m

    set fr2 [cframe create svgFont[incr isvg] $tfont.fr2 -type clframe -rx 2m -text [mc "Font family and its properties"]  -fillnormal gray90 -bg yellow -strokewidth 0.5m -stroke {chocolate}  -fontsize 3.5m]
    $fr2 boxtext -ipadx 2c -strokewidth 0.5m -stroke chocolate -fill cyan -ipady 1m -rx 1m
    pack $tfont.fr2 -in $tfont.c -fill both -expand 1 -padx 3m -pady "2m 0"
#Выбор имени шрифта
    frame $tfont.frame1  -borderwidth {2}  -background {gray86}  -height {224}  -highlightbackground {gray86}  -width {166}

    label $tfont.frame1.label3  -activebackground {gray86}  -background {gray86}  -borderwidth {0}  -font {Helvetica 10 bold}  -highlightbackground {gray86}  -text {Font:}

    entry $tfont.frame1.entry4  -background {gray94}  -disabledbackground {white}  -disabledforeground {black}  -font {Helvetica 10}  -highlightbackground {white}  -selectbackground "#7783bd"  -selectforeground {white}  -state {normal}  -textvariable ::svgfont::fontsvg(-fontfamily)

    frame $tfont.frame1.frame  -background {gray86}  -highlightbackground {gray86}

    ttk::scrollbar $tfont.frame1.frame.scrollbar2 -command "[set tfont].frame1.frame.listbox1 yview"

    listbox $tfont.frame1.frame.listbox1  -background {gray94}  -font {Helvetica 10}  -height {6}  -highlightbackground white  -selectbackground "#7783bd"  -selectforeground white  -width {28}  -yscrollcommand "[set tfont].frame1.frame.scrollbar2 set"
    $tfont.frame1.frame.listbox1 delete 0 end
  # bindings
    bind $tfont.frame1.frame.listbox1 <<ListboxSelect>> {
	set TPtemp [%W curselection]
	if {$TPtemp ne {}} {
	    set ::svgfont::fontsvg(-fontfamily) [%W get $TPtemp]
	    [winfo toplevel %W].frame1.frame.listbox1 itemconfigure $::fontFam -bg {}
	    [winfo toplevel %W].frame1.frame.listbox1 itemconfigure $TPtemp -bg cyan
	    set ::fontFam $TPtemp
	}
	[winfo toplevel %W].fr3 coords $::vsamp [expr {5 + $::svgfont::fontsvg(-strokewidth)}] [expr {20 + $::svgfont::fontsvg(-strokewidth)}]

	eval [winfo toplevel %W].fr3 itemconfigure $vsamp -tags {sample} -text {ABCabcXYZxyz0123456789АБВабвЭЮЯэюя} [array get ::svgfont::fontsvg]
    }
    $tfont.frame1.frame.listbox1 selection set 0 0
    pack $tfont.frame1.label3  -anchor w
    pack $tfont.frame1.entry4  -fill x
    pack $tfont.frame1.frame  -expand 1  -fill both
    pack $tfont.frame1.frame.scrollbar2  -fill y  -side right
    pack $tfont.frame1.frame.listbox1  -expand 1  -fill both
    pack $tfont.frame1 -in $tfont.fr2  -anchor nw  -fill y  -ipady 3  -padx 3m -pady "7m 2m" -side left -expand 0
    set fr1 [cframe create svgFont[incr isvg] $tfont.fr1 -type clframe -rx 2m -text [mc "Font effects"]  -fillnormal cyan -bg yellow -strokewidth 0.5m -stroke "#b3b3b3"  -fontsize 3.5m]
    $fr1 boxtext -ipadx 2m -strokewidth 0.5m -ipady 0.5m -fill "#99ff77"
    set bbold [cbutton create svgFont[incr isvg] $tfont.bbold -type check -text [mc "bold"] -variable  vbold  -bg yellow]
    $bbold config -command {if {$vbold == 1} {set ::svgfont::fontsvg(-fontweight) bold} else {set ::svgfont::fontsvg(-fontweight) normal}; ::svgfont::fontsvg_sample {-fontweight}}
    grid [$bbold canvas] -in $tfont.fr1  -row 0 -column 0 -padx "2m 5m" -pady "4m 0m" -sticky nw
    set bdone [cbutton create svgFont[incr isvg] $tfont.bdone -type rect -rx 1m -text [mc Accept] -command "svgfont::done .__tk_fontsvg" -fontweight normal -fontsize 4.0m]
    set grdone [[$bdone canvas] gradient create radial -stops {{0 "#00bcd4"} {1 "#c0faff"}} -radialtransition {0.50 0.50 0.50 0.5 0.5}]

    $bdone config -fillnormal $grdone

    grid [$bdone canvas] -in $tfont.fr1  -row 0 -column 1 -padx "0 1m" -pady "4m 0m" -sticky ne

    set bover [cbutton create svgFont[incr isvg] $tfont.bover -type check -text [mc "fill over stroke"] -variable ::svgfont::fontsvg(-filloverstroke)  -fillopacity 1.0  ] 
    $bover config -command {::svgfont::fontsvg_sample {-filloverstroke}}
    grid [$bover canvas] -in $tfont.fr1 -row 1 -column 0 -columnspan 2 -padx "2m" -pady "1m 0m" -sticky nw
    set bcancel [cbutton create svgFont[incr isvg] $tfont.bcancel -type rect -rx 1m -text [mc Cancel] -command "svgfont::cancel .__tk_fontsvg"  -fontweight bold -fontsize 3.5m]
    grid [$bcancel canvas] -in $tfont.fr1  -row 1 -column 1 -padx "0 1m" -pady "1m 0m" -sticky ne

    set bslant [cbutton create svgFont[incr isvg] $tfont.bslant -type check -text [mc "slant"] -variable vslant -bg yellow]
    $bslant config -command {if {$vslant == 1} {set ::svgfont::fontsvg(-fontslant) italic} else {set ::svgfont::fontsvg(-fontslant) normal}; ::svgfont::fontsvg_sample {-fontslant}}

    grid [$bslant canvas] -in $tfont.fr1  -row 2 -column 0 -columnspan 2 -padx "2m 5m" -pady "1m 0m"  -sticky nw

    scale $tfont.scalsize -from 0.00 -to 100.00 -digits 5 -resolution {0.1} -tickinterval 0 -label [mc "Font size"] -orient horizontal -variable ::svgfont::fontsvg(-fontsize) -showvalue true -width 8  -bg "#aaffff" -highlightthickness 0 -bd 0 -font {Helvetica 10 bold}
    $tfont.scalsize configure -command {::svgfont::fontsvg_sample {-fontsize}}

    grid $tfont.scalsize -in $tfont.fr1 -row 3 -column 0 -columnspan 2 -padx "2m 2m" -pady "1m 1m" -sticky nwe

    set bfill [cbutton create svgFont[incr isvg] $tfont.bfill -type square -text [mc "fill"] ]
    $bfill config -fillnormal $::svgfont::fontsvg(-fill)
    set cmd "set tcol \[tk_chooseColor -initialcolor \$::svgfont::fontsvg(-fill)]; if {\$tcol != {} } { 
	    set ::svgfont::fontsvg(-fill) \$tcol;  
	    [set bfill] config -fillnormal \$tcol
	    ::svgfont::fontsvg_sample  -fill
	}"
    $bfill config -command "[set cmd]"

    grid [$bfill canvas] -in $tfont.fr1 -row 4 -column 0 -columnspan 1 -padx "2m 0m" -pady "1m 0m" -sticky w
    scale $tfont.scal1 -from 0.00 -to 1.00 -digits 3 -resolution {0.01} -tickinterval 0 -label [mc {Opacity fill}] -orient horizontal -variable ::svgfont::fontsvg(-fillopacity) -showvalue true -width 8  -bg snow -highlightthickness 0 -bd 0
    $tfont.scal1 configure -command {::svgfont::fontsvg_sample {-fillopacity}}
    grid $tfont.scal1 -in $tfont.fr1 -row 4 -column 1 -columnspan 1 -padx "0m 2m" -pady "0m 0m" -sticky nwe

    scale $tfont.scalwidth -from 0.00 -to 60.00 -digits 4 -resolution {0.01} -tickinterval 0 -label [mc "Stroke width"] -orient horizontal -variable ::svgfont::fontsvg(-strokewidth) -showvalue true -width 8  -bg "#aaffff" -highlightthickness 0 -bd 0 -font {{} 10 bold}
    $tfont.scalwidth configure -command {::svgfont::fontsvg_sample {-strokewidth}}
    grid $tfont.scalwidth -in $tfont.fr1 -row 5 -column 0 -columnspan 2 -padx "2m 2m" -pady "1m 0m" -sticky nwe

    set bstr [cbutton create svgFont[incr isvg] $tfont.bstr -type square -text [mc "stroke"] ]

    set cmd "set tcol \[tk_chooseColor -initialcolor \$::svgfont::fontsvg(-stroke)];
	if {\$tcol != {}} { 
	    set ::svgfont::fontsvg(-stroke) \$tcol;  
	    [set bstr] config -fillnormal \$tcol
	    ::svgfont::fontsvg_sample  {-stroke}
	}"
    $bstr config -command "[set cmd]"

    $bstr grid -in $tfont.fr1 -row 6 -column 0 -padx "2m 0m" -pady "1m 2m" -sticky w
    scale $tfont.scal2 -from 0.00 -to 1.00 -digits 3 -resolution {0.01}  -orient horizontal -variable ::svgfont::fontsvg(-strokeopacity) -showvalue true -width 8  -bg snow -highlightthickness 0 -bd 0 -label [mc "Opacity stroke"]
    $tfont.scal2 configure -command {::svgfont::fontsvg_sample {-strokeopacity}}

    grid $tfont.scal2 -in $tfont.fr1 -row 6 -column 1 -columnspan 1 -padx "0m 2m" -pady "1m 2m" -sticky nwe

    grid columnconfigure $tfont.fr1 1 -weight 1
    grid rowconfigure $tfont.fr1 3 -weight 1

    pack $tfont.fr1 -in $tfont.fr2 -fill both -expand 1 -padx "0c 2m" -pady "7m 2m" -side left -anchor nw

    set fr3 [cframe create svgFont[incr isvg] $tfont.fr3 -type clframe -rx 2m -text [mc "How it will look"]  -fillnormal snow -bg yellow -strokewidth 0.5m -stroke {cyan} -fontsize 3.5m]
    $fr3 boxtext -ipadx 1c -ipady 0.5m -rx 1m

    pack $tfont.fr3 -in $tfont.c -fill both -expand 1 -padx 3m -pady 2m
    set ::vsamp [$tfont.fr3 create [set fptext] [expr {5 + $::svgfont::fontsvg(-strokewidth)}] [expr {20 + $::svgfont::fontsvg(-strokewidth)}] -textanchor nw]

    eval $tfont.fr3 itemconfigure $::vsamp -tags {sample} -text {ABCabcXYZxyz0123456789АБВабвЭЮЯэюя} [array get ::svgfont::fontsvg]

    $tfont.frame1.frame.listbox1 delete 0 end
    set ff [lsort [font families]]
    set df ""
    set lff [list]
    lappend lff "Helvetica"
    foreach f1 $ff {
	if {$df == $f1} {continue}
	set df $f1
	lappend lff $f1
    } 
    eval "$tfont.frame1.frame.listbox1 insert end $lff"
    set ind [lsearch [.__tk_fontsvg.frame1.frame.listbox1 get 0 end] "Nimbus Sans Narrow"]
    update
    if {$ind == -1} {
	set ::svgfont::fontsvg(-fontfamily) [lindex [$tfont.frame1.frame.listbox1 get 0 0] 0]
	$tfont.frame1.frame.listbox1 selection set 0 0
    } elseif {$largs == 2 && $w == "" || $largs == 0} {
	$tfont.frame1.frame.listbox1 selection set $ind $ind
	set ::svgfont::fontsvg(-fontfamily) [lindex [$tfont.frame1.frame.listbox1 get $ind $ind] 0]
	$tfont.frame1.frame.listbox1 see $ind
	set ::svgfont::fontsvg(-stroke) "#3bc654"
	[set bstr] config -fillnormal "#3bc654"
	set ::svgfont::fontsvg(-fill) black
	[set bfill] config -fillnormal black
	set ::svgfont::fontsvg(-fontsize) 21.0
	set ::svgfont::fontsvg(-strokewidth) 5.0
	set ::svgfont::fontsvg(-filloverstroke) 1
	
    } else {
	[set bstr] config -fillnormal $::svgfont::fontsvg(-stroke)
	[set bfill] config -fillnormal $::svgfont::fontsvg(-fill)
	set ::svgfont::fontsvg(-fontweight) $::svgfont::fontsvg(-fontweight)
	set ::svgfont::fontsvg(-fontslant) $::svgfont::fontsvg(-fontslant)
	set ::svgfont::fontsvg(-filloverstroke) $::svgfont::fontsvg(-filloverstroke)
    }
    ::svgfont::fontsvg_sample {all}
    tkwait window $tfont
    if {$::svgfont::fontsvg(ret) == "Cancel"} {
	unset ::svgfont::fontsvg(ret)
	return ""
    }
    unset ::svgfont::fontsvg(ret)
    return [array get ::svgfont::fontsvg]
}
