set ix [lsearch $argv -display]
if {$ix >= 0} {
    incr ix
    set env(DISPLAY) [lindex $argv $ix]
    set argc 0
    set argv {}
lappend  auto_path [pwd]/modadd_Lin64
source [pwd]/Tk/wsvgGame/demoGridSVGboard.tcl
#source /home/a513/TkCloud/CLOUDTk/TCLKIT/Tk/SvgGame/demoGridSVGboard.tcl
}

