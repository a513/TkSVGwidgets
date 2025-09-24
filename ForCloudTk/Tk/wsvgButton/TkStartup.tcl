set ix [lsearch $argv -display]
if {$ix >= 0} {
    incr ix
    set env(DISPLAY) [lindex $argv $ix]
    set argc 0
    set argv {}
    set tekdir [pwd]
lappend  auto_path [set tekdir]/modadd_Lin64
source [set tekdir]/Tk/wsvgButton/demoPackSVGwithImageMesFromMenu.tcl
}

