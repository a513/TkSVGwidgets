encoding system utf-8
set dd [file dirname [info script]]
source [file join $dd sampleSVGmenu.tcl]
if {[winfo exist .dsvg]} {
    tk busy hold .dsvg
}
