lappend auto_path PackageAdd
    package require tkpath
source "can2svg.tcl"
set can ".c"
destroy $can
tkp::canvas $can -bg gray80
pack $can -fill both -expand 1
wm geometry . 800x600
file delete -force test1.svg
file delete -force test2.svg
file delete -force test3.svg

set grad1 [$can gradient create linear -method pad -units bbox -stops { { 0.00 red 1.00} { 0.50 "#dbebc3" 1.00} { 1.00 "#08ce20" 1.00}} -lineartransition {0.00 0.00 1.00 0.00} ]
set grad2 [$can gradient create linear -method pad -units bbox -stops { { 0.00 red 0.50} { 1.00 "#00f000" 0.80}} -lineartransition {0.00 0.00 1.00 0.00} ]

set obj1 [$can create ppolygon {172.0 295.0 172.0 295.0 258.0 228.0 279.0 318.0 198.0 399.0 170.0 294.0} -fill "#00CD00" -strokelinejoin miter ]
set obj2 [$can create path {M 204.0 203.85 Q 204.0 186.0 221.85 186.0 L 543.15 186.0 Q 561.0 186.0 561.0 203.85 L 561.0 271.11 Q 561.0 288.96000000000004 543.15 288.96000000000004 \
     L 489.6 288.96000000000004 L 418.2 342.0 L 382.5 288.96000000000004 L 221.85 288.96000000000004 Q 204.0 288.96000000000004 204.0 271.11 Z} -strokewidth 8.0 -fill $grad1]
set obj3 [$can create circle {521.0 361.0} -fill "#FF7256" -rx 95.0 ]
set obj4 [$can create circle {656.0 68.0} -stroke "#FF0000" -strokewidth 4.0 -rx 56.0 -fill $grad2]

can2svg::can2xmlfile $can test1.svg all
set allobj [$can find all]
can2svg::can2xmlfile $can test2.svg [list $obj1 $obj2]
can2svg::can2xmlfile $can test3.svg [list $obj3 $obj4]
set xmldata [can2svg::can2xmlfile $can "xmldata" [list $obj3 $obj4]]
puts "xmldata: $xmldata"



set win1 ".win1"
destroy $win1
toplevel $win1 -bg gray80
wm geometry $win1 800x600
lappend auto_path PackageAdd
package require svg2can
#source "svg2can.tcl"
set can2 "$win1$can"
tkp::canvas $can2 -bg snow
pack $can2  -fill both -expand 1
svg2can::SVGFileToCanvas $can2 test1.svg 
svg2can::SVGFileToCanvas $can2 test2.svg 
#svg2can::SVGFileToCanvas $can2 test3.svg 
set cmdtkpath [svg2can::SVGFileToCmds $can2 test3.svg ]
svg2can::SVGXmlToCanvas $can2 $xmldata 
puts "CMDtkpath: $cmdtkpath"
