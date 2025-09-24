set ix [lsearch $argv -display]
if {$ix >= 0} {
    incr ix
    set env(DISPLAY) [lindex $argv $ix]
    set argc 0
    set argv {}
#lappend  auto_path /home/a513/TkCloud/CLOUDTk/TCLKIT/modadd_Lin64
lappend  auto_path [pwd]/modadd_Lin64
source [pwd]/Tk/wsvgCanvas/скрипт_button_Холст.tcl
#source /home/a513/TkCloud/CLOUDTk/TCLKIT/Tk/ATrain/train.tcl
}


