set ix [lsearch $argv -display]
if {$ix >= 0} {
    incr ix
    set env(DISPLAY) [lindex $argv $ix]
    set argc 0
    set argv {}
#lappend  auto_path [pwd]/modadd_Lin64
    set tekdir [pwd]
lappend  auto_path [set tekdir]/modadd_Lin64
source [set tekdir]/Tk/Train/train.tcl

#source [pwd]/Tk/Train/train.tcl
#source /home/a513/TkCloud/CLOUDTk/TCLKIT/Tk/Train/train.tcl
}

