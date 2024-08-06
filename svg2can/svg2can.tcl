#  svg2can.tcl ---
#  
#      This file provides translation from canvas commands to XML/SVG format.
#      
#  Copyright (c) 2004-2007  Mats Bengtsson
#  Copyright (c) 2021-2024  Orlov Vladimir
#  
#  This file is distributed under BSD style license.
#
# $Id: svg2can.tcl,v 1.42 2008-02-06 13:57:24 matben Exp $
# 
# ########################### USAGE ############################################
#
#   NAME
#      svg2can - translate XML/SVG to canvas command.
#      
#   SYNOPSIS
#      svg2can::parsesvgdocument xmllist
#      svg2can::parseelement xmllist
#      
#
# ########################### CHANGES ##########################################
#
#   0.1      first release
#   0.2      starting support for tkpath package
#
# ########################### TODO #############################################
#
#       A lot...
#
# ########################### INTERNALS ########################################
# 
# The whole parse tree is stored as a hierarchy of lists as:
# 
#       xmllist = {tag attrlist isempty cdata {child1 child2 ...}}

# We need URN decoding for the file path in images. From my whiteboard code.

package require tkpath 
package require uriencode
package require tinydom

package provide svg2can 2.0

namespace eval svg2can {

    variable confopts
    array set confopts {
	-foreignobjecthandler ""
	-httphandler          ""
	-imagehandler         ""
	-imagehandlerex       ""
    }

    variable textAnchorMap
    array set textAnchorMap {
	start   w
	middle  c
	end     e
    }
    
    variable fontWeightMap 
    array set fontWeightMap {
	normal    normal
	bold      bold
	bolder    bold
	lighter   normal
	100       normal
	200       normal
	300       normal
	400       normal
	500       normal
	600       bold
	700       bold
	800       bold
	900       bold
    }
    
    # We need to have a temporary tag for doing transformations.
    variable tmptag _tmp_transform
    variable pi 3.14159265359
    variable degrees2Radians [expr {2*$pi/360.0}]
    variable systemFont

    switch -- $::tcl_platform(platform) {
	unix {
	    set systemFont {Helvetica 10}
	    if {[package vcompare [info tclversion] 8.3] == 1} {	
		if {[string equal [tk windowingsystem] "aqua"]} {
		    set systemFont system
		}
	    }
	}
	windows {
	    set systemFont system
	}
    }
    
    variable priv
    set priv(havetkpath) 0
    if {![catch {package require tkpath 0.3.3}]} {
	set priv(havetkpath) 1
    } else {
	puts "Cannot load package svg2cam"
	return -code error "Cannot load package tkpath 0.3.3"
    }

    # We don't want it now.
#    set priv(havetkpath) 0

    variable chache
    variable cache_key ""
#Переменная для currentColor
    variable curColor
}

# svg2can::config --
# 
#       Processes the configuration options.

proc svg2can::config {args} {
    variable confopts
    
    set options [lsort [array names confopts -*]]
    set usage [join $options ", "]
    if {[llength $args] == 0} {
	set result {}
	foreach name $options {
	    lappend result $name $confopts($name)
	}
	return $result
    }
    regsub -all -- - $options {} options
    set pat ^-([join $options |])$
    if {[llength $args] == 1} {
	set flag [lindex $args 0]
	if {[regexp -- $pat $flag]} {
	    return $confopts($flag)
	} else {
	    return -code error "Unknown option $flag, must be: $usage"
	}
    } else {
	foreach {flag value} $args {
	    if {[regexp -- $pat $flag]} {
		set confopts($flag) $value
	    } else {
		return -code error "Unknown option $flag, must be: $usage"
	    }
	}
    }
}

# svg2can::cache_* --
# 
#       A few routines to handle the caching of images and gradients.
#       Useful for garbage collection. Cache stuff per key which is typically
#       a widget path, and then do:
#       svg2can::cache_set_key $w
#       bind $w <Destroy> +[list svg2can::cache_free $w]
#       This works only if parsing svg docs in one shot.

proc svg2can::cache_set_key {key} {
    variable cache_key
    set cache_key $key
}

proc svg2can::cache_get_key {} {
    variable cache_key
    return $cache_key
}

proc svg2can::cache_get {$key} {
    variable cache
    if {[info exists cache($key)]} {
	return $cache($key)
    } else {
	return [list]
    }
}

proc svg2can::cache_add {type token} {
    variable cache
    variable cache_key
    lappend cache($cache_key) [list $type $token]
}

proc svg2can::cache_free {key} {
    variable cache
    
    if {![info exists cache($key)]} {
	return
    }
    foreach spec $cache($key) {
	set type [lindex $spec 0]
	set token [lindex $spec 1]
	switch -- $type {
	    image {
		image delete $token
	    }
	    gradient {
#		::tkp::gradient delete $token
		${svg2can::priv(wcan)} gradient delete $token

	    }
	}
    }
    set cache($key) [list]
}

proc svg2can::cache_reset {key} {
    variable cache
    set cache($key) [list]
}

# svg2can::parsesvgdocument --
# 
# 
# Arguments:
#       xmllist     the parsed document as a xml list
#       args        configuration options
#          -httphandler
#    	   -imagehandler            
#       
# Results:
#       a list of canvas commands without the widgetPath

proc svg2can::parsesvgdocument {xmllist args} {
    variable confopts
    variable priv

    array set argsA [array get confopts]
    array set argsA $args
    set paropts [array get argsA]
        
    set ans {}
#ORLOV
#GRADIENT сначало делаем без ссылок
    foreach c [getchildren $xmllist] {
	set tag [gettag $c]
	if {$tag == "linearGradient" || $tag == "radialGradient"} {
	    set attr [getattr $c]
	    set idx [lsearch -exact $attr xlink:href]
	    if {$idx == -1} {
		if {$tag == "linearGradient"} {
		    CreateLinearGradient $c
		} else {
		    CreateRadialGradient $c
		}
	    }
	}
    }
#GRADIENT END
    foreach c [getchildren $xmllist] {
	set tag [gettag $c]
#Без ссылок градиенты уже сделаны
	if {$tag == "linearGradient" || $tag == "radialGradient" } {
	    set attr [getattr $c]
	    set idx [lsearch -exact $attr xlink:href]
	    if {$idx == -1} {
		continue
	    }
	}
#puts "svg2can::parsesvgdocument -> c=$c"
#puts "svg2can::parsesvgdocument -> ParseElemRecursiveEx"
	set ans [concat $ans [ParseElemRecursiveEx $c $paropts {}]]
    }
    return $ans
}

# svg2can::parseelement --
# 
#       External interface for parsing a single element.
# 
# Arguments:
#       xmllist     the elements xml list
#       args        configuration options
#          -httphandler
#    	   -imagehandler            
#    	   -imagehandlerex            
#       
# Results:
#       a list of canvas commands without the widgetPath

proc svg2can::parseelement {xmllist args} {
    variable confopts
    variable priv

    array set argsA [array get confopts]
    array set argsA $args
    set paropts [array get argsA]
    return [ParseElemRecursiveEx $xmllist $paropts {}]
}

# svg2can::ParseElemRecursiveEx --
# 
#       Same for tkpath...
#       
# Arguments:
#       transAttr   this is a list of transform attributes

proc svg2can::ParseElemRecursiveEx {xmllist paropts transAttr args} {

    set cmdList [list]
    set tag [gettag $xmllist]
#puts "ParseElemRecursiveEx: START tag=$tag"
    switch -- $tag {
	style {
		CreateCurrentColor $xmllist
	}
	circle - ellipse - image - line - polyline - polygon - rect - path - text {
	    set func [string totitle $tag]
#ORLOV		
#puts "ParseElemRecursiveEx func=$func"
	    if {$func == "Path"} {
		array set attrA1 $args
		array set attrA1 [getattr $xmllist]

		foreach {key value} [array get attrA1] {
#puts "ParseElemRecursiveEx key=$key"
		    switch -- $key {
			x - y - width - height {
			    set func "Rect"
			}
			rx - ry {
			    set func "Ellipse"
			}
			r {
			    set func "Circle"
			}
			points {
#Как быть с poliline????
			    set func "Poligon"
			}
			x1 - y1 - x2 - y2 {
			    set func "Line"
			}
			default {
			    ;
			}
		    }
		    if {$func != "Path"} {
			break
		    }
		}
	    }
	       
	    set cmd [eval {Parse${func}Ex $xmllist $paropts $transAttr} $args]
	    if {[llength $cmd]} {
		lappend cmdList $cmd
	    }
#puts "ParseElemRecursiveEx -> func=$func: cmd=$cmd"
	}
	g {
#puts "ParseElemRecursiveEx -> g: $xmllist C=[getchildren $xmllist]"
#puts "ParseElemRecursiveEx -> g: transAttr=$transAttr"
	    
	    # Need to collect the attributes for the g element since
	    # the child elements inherit them. g elements may be nested!
	    # Must parse any style to the actual attribute names.
	    array set attrA $args
	    array set attrA [getattr $xmllist]
	    unset -nocomplain attrA(id)
	    if {[info exists attrA(style)]} {
		array set attrA [StyleAttrToList $attrA(style)]
	    }
	    if {[info exists attrA(transform)]} {
#puts "ParseElemRecursiveEx -> g: attrA(transform)=$attrA(transform)"
		set tt [string map {")" "" } $attrA(transform)]
		append transAttr "[split $tt (] "
#puts "ParseElemRecursiveEx -> g 1: attrA(transform)=[split $tt (]"
		unset attrA(transform)
	    }
	    foreach c [getchildren $xmllist] {
#puts "ParseElemRecursiveEx -> getchildren=$c"
		set cmdList [concat $cmdList [eval {
		    ParseElemRecursiveEx $c $paropts $transAttr
		} [array get attrA]]]
	    }	    
	}
	a - f {
	    
	    # Need to collect the attributes for the g element since
	    # the child elements inherit them. g elements may be nested!
	    # Must parse any style to the actual attribute names.
	    array set attrA $args
	    array set attrA [getattr $xmllist]
	    unset -nocomplain attrA(id)
	    if {[info exists attrA(style)]} {
		array set attrA [StyleAttrToList $attrA(style)]
	    }
	    if {[info exists attrA(transform)]} {
		eval {lappend transAttr} [TransformAttrToList $attrA(transform)]
		unset attrA(transform)
	    }
	    foreach c [getchildren $xmllist] {
		set cmdList [concat $cmdList [eval {
		    ParseElemRecursiveEx $c $paropts $transAttr
		} [array get attrA]]]
	    }	    
	}
	linearGradient {
	    CreateLinearGradient $xmllist
	}
	radialGradient {
	    CreateRadialGradient $xmllist
	}
	foreignObject {
	    array set parseArr $paropts
	    if {[string length $parseArr(-foreignobjecthandler)]} {
		set elem [uplevel #0 $parseArr(-foreignobjecthandler) \
		  [list $xmllist $paropts $transformL] $args]
		if {$elem != ""} {
		    set cmdList [concat $cmdList $elem]
		}
	    }
	}
	defs {
	    eval {ParseDefs $xmllist $paropts $transAttr} $args
	}
	use - marker - symbol {
	    # todo
	}
    }

    return $cmdList
}

#ORLOV
proc svg2can::CreateCurrentColor {c} {
#Переменная для currentColor
    variable curColor
#    catch {unset curColor}
    set stcol [getcdata $c]
    set stcol [string map {"\{" " \{"} $stcol]
    set stcol [string map {"\}" "\} "} $stcol]
    set j [llength $stcol]
    for {set i 0} {$i < $j}  {incr i} {
	set t1 [string trim [lindex $stcol $i] "."]
	incr i
	set c1 [split [lindex $stcol $i] ":"]
	set curc [string trim [lindex $c1 1]]
	set curc [string trim $curc ";"]
	set curColor($t1) [string trim $curc]
    }

}

proc svg2can::ParseDefs {xmllist paropts transAttr args} {
    # @@@ Only gradients so far.
#puts "svg2can::ParseDefs c=[getchildren $xmllist]"
    foreach c [getchildren $xmllist] {
	set tag [gettag $c]
	if {$tag == "linearGradient" || $tag == "radialGradient"} {
	    set attr [getattr $c]
	    set idx [lsearch -exact $attr xlink:href]
	    if {$idx == -1} {
		if {$tag == "linearGradient"} {
		    CreateLinearGradient $c
		} else {
		    CreateRadialGradient $c
		}
	    }
	}
    }

    foreach c [getchildren $xmllist] {
	set tag [gettag $c]
#Без ссылок градиенты уже сделаны
	if {$tag == "linearGradient" || $tag == "radialGradient" } {
	    set attr [getattr $c]
	    set idx [lsearch -exact $attr xlink:href]
	    if {$idx == -1} {
		continue
	    }
	}

	switch -- $tag {
	    linearGradient {
		    CreateLinearGradient $c
	    }
	    radialGradient {
		    CreateRadialGradient $c
	    }
	    style {
#puts "svg2can::ParseDefs -> CreateCurrentColor: $c"
		CreateCurrentColor $c
	    }
	}
    }
}

proc svg2can::ParseCircleEx {xmllist paropts transAttr args} {
#ORLOV
#Переменная для currentColor
    variable curColor
    set curc -1

    set opts {}
    set cx 0
    set cy 0
    set presAttr {}
    array set attrA $args
    array set attrA [getattr $xmllist]

    foreach {key value} [array get attrA] {	
	switch -- $key {
	    cx - cy {
		set $key [parseLength $value]
	    }
	    id {
		lappend opts -tags $value
	    }
	    style {
		eval {lappend opts} [StyleToOptsEx [StyleAttrToList $value]]
	    }
	    transform {
		set tt [string map {")" "" } $value]
		set tt [string map {"," " " } $tt]
		set value "[split $tt (]"
		eval {lappend transAttr} [TransformAttrToList $value]
#		eval {lappend transAttr} [TransformAttrToList $value]
	    }
	    class {
#puts "ParseCircleEx: class - key=$key value=$value opts=$opts color=$curColor($value)"
		set valcl [string trim $value]
		if {[info exist curColor($valcl)]} {
		    set curc $curColor($valcl)
		}
	    }
	    default {
		lappend presAttr $key $value
	    }
	}
    }
#ORLOV
    if {$curc != -1} {
	set ind [lsearch -exact $opts "-fill"]
	set inds [lsearch -exact $opts "-stroke"]
	if {$ind != -1} {
	    incr ind
	    set opts [lreplace $opts $ind $ind $curc]
	}
	if {$inds != -1} {
	    incr inds
	    set opts [lreplace $opts $inds $inds $curc]
	}
    }

    if {[llength $transAttr]} {
	lappend opts -matrix [TransformAttrListToMatrix $transAttr]
    }
    set opts [StrokeFillDefaults [MergePresentationAttrEx $opts $presAttr]]
#ORLOV
    if {$curc != -1 && $ind == -1} {
	set ind [lsearch -exact $opts "-fill"]
	incr ind
	if {[lindex $opts $ind] == "currentColor"} {
	    set opts [lreplace $opts $ind $ind $curc]
	}
    }
    if {$curc != -1 && $inds == -1} {
	set inds [lsearch -exact $opts "-stroke"]
	incr inds
	if {[lindex $opts $inds] == "currentColor"} {
	    set opts [lreplace $opts $inds $inds $curc]
	}
    }

    return [concat create circle $cx $cy $opts]
}

proc svg2can::ParseEllipseEx {xmllist paropts transAttr args} {
#ORLOV
#Переменная для currentColor
    variable curColor
    set curc -1

    set opts {}
    set cx 0
    set cy 0
    set presAttr {}
    array set attrA $args
    array set attrA [getattr $xmllist]

    foreach {key value} [array get attrA] {	
	switch -- $key {
	    cx - cy {
		set $key [parseLength $value]
	    }
	    id {
		lappend opts -tags $value
	    }
	    style {
		eval {lappend opts} [StyleToOptsEx [StyleAttrToList $value]]
	    }
	    transform {
		set tt [string map {")" "" } $value]
		set tt [string map {"," " " } $tt]
		set value "[split $tt (]"
		eval {lappend transAttr} [TransformAttrToList $value]
#		eval {lappend transAttr} [TransformAttrToList $value]
	    }
	    class {
#puts "ParseEllipseEx: class - key=$key value=$value opts=$opts color=$curColor($value)"
		set valcl [string trim $value]
		if {[info exist curColor($valcl)]} {
		    set curc $curColor($valcl)
		}
	    }
	    default {
		lappend presAttr $key $value
	    }
	}
    }
#ORLOV
    if {$curc != -1} {
	set ind [lsearch -exact $opts "-fill"]
	set inds [lsearch -exact $opts "-stroke"]
	if {$ind != -1} {
	    incr ind
	    set opts [lreplace $opts $ind $ind $curc]
	}
	if {$inds != -1} {
	    incr inds
	    set opts [lreplace $opts $inds $inds $curc]
	}
    }

    if {[llength $transAttr]} {
	lappend opts -matrix [TransformAttrListToMatrix $transAttr]
    }
    set opts [StrokeFillDefaults [MergePresentationAttrEx $opts $presAttr]]
#ORLOV
    if {$curc != -1 && $ind == -1} {
	set ind [lsearch -exact $opts "-fill"]
	incr ind
	if {[lindex $opts $ind] == "currentColor"} {
	    set opts [lreplace $opts $ind $ind $curc]
	}
    }
    if {$curc != -1 && $inds == -1} {
	set inds [lsearch -exact $opts "-stroke"]
	incr inds
	if {[lindex $opts $inds] == "currentColor"} {
	    set opts [lreplace $opts $inds $inds $curc]
	}
    }

    return [concat create ellipse $cx $cy $opts]    
}

proc svg2can::ParseImageEx {xmllist paropts transAttr args} {

    set x 0
    set y 0    
    set width  0
    set height 0
    set opts {}
    set presAttr {}
    array set attrA $args
    array set attrA [getattr $xmllist]
    array set paroptsA $paropts

    foreach {key value} [array get attrA] {	
	switch -- $key {
	    x - y {
		set $key [parseLength $value]
	    }
	    height - width {
		# A value of 0 disables rendering in SVG.
		# tkpath uses 0 for using natural sizes.
		if {$value == 0.0} {
		    return
		}
		set $key [parseLength $value]
	    }
	    id {
		lappend opts -tags $value
	    }
	    style {
		eval {lappend opts} [StyleToOptsEx [StyleAttrToList $value]]
	    }
	    transform {
		eval {lappend transAttr} [TransformAttrToList $value]
	    }
	    xlink:href {
		set xlinkhref $value
	    }
	    default {
		lappend presAttr $key $value
	    }
	}
    }
    lappend opts -width $width -height $height
    if {[llength $transAttr]} {
	lappend opts -matrix [TransformAttrListToMatrix $transAttr]
    }
    if {[string length $paroptsA(-imagehandlerex)]} {		    
	uplevel #0 $paroptsA(-imagehandlerex) [list $xmllist $opts]
	return
    }

    # Handle the xlink:href attribute.
    if {[info exists xlinkhref]} {

	switch -glob -- $xlinkhref {
	    file:/* {			
		set path [::uri::urn::unquote $xlinkhref]
		set path [string map {file:/// /} $path]
		if {[string length $paroptsA(-imagehandler)]} {		    
		    set cmd [concat create image $x $y $opts]
		    lappend cmd -file $path -height $height -width $width
		    set photo [uplevel #0 $paroptsA(-imagehandler) [list $cmd]]
		    lappend opts -image $photo
		} else {			
		    if {[string tolower [file extension $path]] eq ".gif"} {
			set photo [image create photo -file $path -format gif]
			cache_add image $photo
		    } else {
			set photo [image create photo -file $path]
			cache_add image $photo
		    }
		    lappend opts -image $photo
		}
	    }
	    http:/* {
		if {[string length $paroptsA(-httphandler)]} {
		    set cmd [concat create image $x $y $opts]
		    lappend cmd -url $xlinkhref -height $height -width $width
		    uplevel #0 $paroptsA(-httphandler) [list $cmd]
		}
		return
	    }
	    default {
		return
	    }
	}	
    }
    
    set opts [MergePresentationAttrEx $opts $presAttr]
    return [concat create pimage $x $y $opts]    
}

proc svg2can::ParseLineEx {xmllist paropts transAttr args} {
#ORLOV
#Переменная для currentColor
    variable curColor
    set curc -1

    set x1 0
    set y1 0
    set x2 0
    set y2 0
    set opts {}
    set presAttr {}
    array set attrA $args
    array set attrA [getattr $xmllist]

    foreach {key value} [array get attrA] {	
	switch -- $key {
	    x1 - y1 - x2 - y2 {
		set $key [parseLength $value]
	    }
	    id {
		lappend opts -tags $value
	    }
	    style {
		eval {lappend opts} [StyleToOptsEx [StyleAttrToList $value]]
	    }
	    transform {
		eval {lappend transAttr} [TransformAttrToList $value]
	    }
	    class {
#puts "ParseLineEx: class - key=$key value=$value opts=$opts color=$curColor($value)"
		set valcl [string trim $value]
		if {[info exist curColor($valcl)]} {
		    set curc $curColor($valcl)
		}
	    }
	    default {
		lappend presAttr $key $value
	    }
	}
    }
#ORLOV
    if {$curc != -1} {
	set ind [lsearch -exact $opts "-fill"]
	set inds [lsearch -exact $opts "-stroke"]
	if {$ind != -1} {
	    incr ind
	    set opts [lreplace $opts $ind $ind $curc]
	}
	if {$inds != -1} {
	    incr inds
	    set opts [lreplace $opts $inds $inds $curc]
	}
    }

    if {[llength $transAttr]} {
	lappend opts -matrix [TransformAttrListToMatrix $transAttr]
    }
    set opts [StrokeFillDefaults [MergePresentationAttrEx $opts $presAttr] 1]
#ORLOV
    if {$curc != -1 && $ind == -1} {
	set ind [lsearch -exact $opts "-fill"]
	incr ind
	if {[lindex $opts $ind] == "currentColor"} {
	    set opts [lreplace $opts $ind $ind $curc]
	}
    }
    if {$curc != -1 && $inds == -1} {
	set inds [lsearch -exact $opts "-stroke"]
	incr inds
	if {[lindex $opts $inds] == "currentColor"} {
	    set opts [lreplace $opts $inds $inds $curc]
	}
    }

    return [concat create pline $x1 $y1 $x2 $y2 $opts]    
}

proc svg2can::ParsePathEx {xmllist paropts transAttr args} {
#ORLOV
#Переменная для currentColor
    variable curColor
#puts "ParsePathEx: XAXA"

    set opts {}
    set presAttr {}
    set path {}
#ORLOV
    set clfill {}
    set curc -1

    array set attrA $args
    array set attrA [getattr $xmllist]
    foreach {key value} [array get attrA] {
#puts "ParsePathEx 0: key=$key  value=$value"
	switch -- $key {
	    d { 
if {$value == ""} {
    return ""
}
		set path [parsePathAttr $value]
	    }
	    id {
		lappend opts -tags $value
	    }
	    style {
		eval {lappend opts} [StyleToOptsEx [StyleAttrToList $value]]
	    }
	    transform {
#puts "ParsePathEx 0: transform transAttr=$transAttr value=$value"
		set tt [string map {")" "" } $value]
		set tt [string map {"," " " } $tt]
		set value "[split $tt (]"
#puts "ParsePathEx 0: transform transAttr=$transAttr value=$value"

		eval {lappend transAttr} [TransformAttrToList $value]
#puts "ParsePathEx 1: transform transAttr=$transAttr"
	    }
	    class {
#puts "ParsePathEx: class - key=$key value=\"$value\" opts=$opts color=$curColor([string trim $value])"
		set valcl [string trim $value]
		if {[info exist curColor($valcl)]} {
		    set curc $curColor($valcl)
		}
	    }
	    default {
		lappend presAttr $key $value 
	    }
	}
    }
#ORLOV
    if {$curc != -1} {
#puts "ParsPathEx: curs=$curc curColor"
	set ind [lsearch -exact $opts "-fill"]
	set inds [lsearch -exact $opts "-stroke"]
	if {$ind != -1} {
	    incr ind
	    set opts [lreplace $opts $ind $ind $curc]
	}
	if {$inds != -1} {
	    incr inds
	    set opts [lreplace $opts $inds $inds $curc]
	}
    }
    
#puts "ParsePathEx: 0 transAttr=$transAttr"
    if {[llength $transAttr]} {
	lappend opts -matrix [TransformAttrListToMatrix $transAttr]
    }
#puts "ParsePathEx: 1 opts=$opts"
    set opts [StrokeFillDefaults [MergePresentationAttrEx $opts $presAttr]]
#puts "ParsePathEx: 2 opts=$opts"
#ORLOV
    if {$curc != -1 && $ind == -1} {
	set ind [lsearch -exact $opts "-fill"]
	incr ind
	if {[lindex $opts $ind] == "currentColor"} {
	    set opts [lreplace $opts $ind $ind $curc]
	}
    }
    if {$curc != -1 && $inds == -1} {
	set inds [lsearch -exact $opts "-stroke"]
	incr inds
	if {[lindex $opts $inds] == "currentColor"} {
	    set opts [lreplace $opts $inds $inds $curc]
	}
    }

    set ind [lsearch -exact $opts "-fill"]
    incr ind
    if {$ind > 0} {
	if {[lindex $opts $ind] == "currentColor"} {
puts "ParsePathEx: -fill =currentColor. Replase???"
	    set color $svg2can::curColor([lindex [array name svg2can::curColor] 0])
	    set opts [lreplace $opts $ind $ind $color]
	}
    }

#puts "ParsePathEx 0: END"

    return [concat create path [list $path] $opts]
}

# Handle different defaults for fill and stroke.

proc svg2can::StrokeFillDefaults {opts {noFill 0}} {

    array set optsA $opts
    if {!$noFill && ![info exists optsA(-fill)]} {
	set optsA(-fill) black
    }
    if {[info exists optsA(-fillgradient)]} {
	unset -nocomplain optsA(-fill)
    }
    if {![info exists optsA(-stroke)]} {
	set optsA(-stroke) {}
    }
    return [array get optsA]
}

proc svg2can::ParsePolylineEx {xmllist paropts transAttr args} {

    set opts {}
    set points {0 0}
    set presAttr {}
    array set attrA $args
    array set attrA [getattr $xmllist]

    foreach {key value} [array get attrA] {	
	switch -- $key {
	    points {
		set points [PointsToList $value]
	    }
	    id {
		lappend opts -tags $value
	    }
	    style {
		eval {lappend opts} [StyleToOptsEx [StyleAttrToList $value]]
	    }
	    transform {
		eval {lappend transAttr} [TransformAttrToList $value]
	    }
	    default {
		lappend presAttr $key $value
	    }
	}
    }
    if {[llength $transAttr]} {
	lappend opts -matrix [TransformAttrListToMatrix $transAttr]
    }
    set opts [StrokeFillDefaults [MergePresentationAttrEx $opts $presAttr]]
    return [concat create polyline $points $opts]    
}

proc svg2can::ParsePolygonEx {xmllist paropts transAttr args} {
#ORLOV
#Переменная для currentColor
    variable curColor
    set curc -1

    set opts {}
    set points {0 0}
    set presAttr {}
    array set attrA $args
    array set attrA [getattr $xmllist]

    foreach {key value} [array get attrA] {	
	switch -- $key {
	    points {
		set points [PointsToList $value]
	    }
	    id {
		lappend opts -tags $value
	    }
	    style {
		eval {lappend opts} [StyleToOptsEx [StyleAttrToList $value]]
	    }
	    transform {
		set tt [string map {")" "" } $value]
		set tt [string map {"," " " } $tt]
		set value "[split $tt (]"
		eval {lappend transAttr} [TransformAttrToList $value]
#		eval {lappend transAttr} [TransformAttrToList $value]
	    }
	    class {
#puts "ParsePoligonEx: class - key=$key value=$value opts=$opts color=$curColor($value)"
		set valcl [string trim $value]
		if {[info exist curColor($valcl)]} {
		    set curc $curColor($valcl)
		}
	    }
	    default {
		lappend presAttr $key $value
	    }
	}
    }
#ORLOV
    if {$curc != -1} {
	set ind [lsearch -exact $opts "-fill"]
	set inds [lsearch -exact $opts "-stroke"]
	if {$ind != -1} {
	    incr ind
	    set opts [lreplace $opts $ind $ind $curc]
	}
	if {$inds != -1} {
	    incr inds
	    set opts [lreplace $opts $inds $inds $curc]
	}
    }

    if {[llength $transAttr]} {
	lappend opts -matrix [TransformAttrListToMatrix $transAttr]
    }
    set opts [StrokeFillDefaults [MergePresentationAttrEx $opts $presAttr]]
#ORLOV
    if {$curc != -1 && $ind == -1} {
	set ind [lsearch -exact $opts "-fill"]
	incr ind
	if {[lindex $opts $ind] == "currentColor"} {
	    set opts [lreplace $opts $ind $ind $curc]
	}
    }
    if {$curc != -1 && $inds == -1} {
	set inds [lsearch -exact $opts "-stroke"]
	incr inds
	if {[lindex $opts $inds] == "currentColor"} {
	    set opts [lreplace $opts $inds $inds $curc]
	}
    }

    return [concat create ppolygon $points $opts]    
}

proc svg2can::ParseRectEx {xmllist paropts transAttr args} {

    set opts {}
    set x 0
    set y 0
    set width  0
    set height 0
    set presAttr {}
#ORLOV
#Переменная для currentColor
    variable curColor
    set curc -1

    array set attrA $args
    array set attrA [getattr $xmllist]
    
    foreach {key value} [array get attrA] {	
	switch -- $key {
	    x - y - width - height {
		set $key [parseLength $value]
	    }
	    id {
		lappend opts -tags $value
	    }
	    style {
		eval {lappend opts} [StyleToOptsEx [StyleAttrToList $value]]
	    }
	    transform {
		set tt [string map {")" "" } $value]
		set tt [string map {"," " " } $tt]
		set value "[split $tt (]"
		eval {lappend transAttr} [TransformAttrToList $value]
#		eval {lappend transAttr} [TransformAttrToList $value]
	    }
	    class {
#puts "ParseRectEx: class - key=$key value=$value opts=$opts color=$curColor($value)"
		set valcl [string trim $value]
		if {[info exist curColor($valcl)]} {
		    set curc $curColor($valcl)
		}
	    }
	    default {
		lappend presAttr $key $value
	    }
	}
    }
#ORLOV
    if {$curc != -1} {
	set ind [lsearch -exact $opts "-fill"]
	set inds [lsearch -exact $opts "-stroke"]
	if {$ind != -1} {
	    incr ind
	    set opts [lreplace $opts $ind $ind $curc]
	}
	if {$inds != -1} {
	    incr inds
	    set opts [lreplace $opts $inds $inds $curc]
	}
    }

    if {[llength $transAttr]} {
	lappend opts -matrix [TransformAttrListToMatrix $transAttr]
    }
    set x2 [expr {$x + $width}]
    set y2 [expr {$y + $height}]
    set opts [StrokeFillDefaults [MergePresentationAttrEx $opts $presAttr]]
#ORLOV
    if {$curc != -1 && $ind == -1} {
	set ind [lsearch -exact $opts "-fill"]
	incr ind
	if {[lindex $opts $ind] == "currentColor"} {
	    set opts [lreplace $opts $ind $ind $curc]
	}
    }
    if {$curc != -1 && $inds == -1} {
	set inds [lsearch -exact $opts "-stroke"]
	incr inds
	if {[lindex $opts $inds] == "currentColor"} {
	    set opts [lreplace $opts $inds $inds $curc]
	}
    }

    return [concat create prect $x $y $x2 $y2 $opts]    
}

# svg2can::ParseText --
# 
#       Takes a text element and returns a list of canvas create text commands.
#       Assuming that chdata is not mixed with elements, we should now have
#       either chdata OR more elements (tspan).

proc svg2can::ParseText {xmllist paropts transformL args} {
    set x 0
    set y 0
    set xAttr 0
    set yAttr 0
    set cmdList [ParseTspan $xmllist $transformL x y xAttr yAttr {}]

#    return [lindex $cmdList 0]
    return $cmdList

}

proc svg2can::ParseTextEx {xmllist paropts transAttr args} {
    return [eval {ParseText $xmllist $paropts {}} $args]
}

# svg2can::ParseTspan --
# 
#       Takes a tspan or text element and returns a list of canvas
#       create text commands.

proc svg2can::ParseTspan {xmllist transformL xVar yVar xAttrVar yAttrVar opts} { 
    variable tmptag
    variable systemFont
    upvar $xVar x
    upvar $yVar y
    upvar $xAttrVar xAttr
    upvar $yAttrVar yAttr

    # Nested tspan elements do not inherit x, y, dx, or dy attributes set.
    # Sibling tspan elements do inherit x, y attributes.
    # Keep two separate sets of x and y; (x,y) and (xAttr,yAttr):
    # (x,y) 
    
    # Inherit opts.
    array set optsA $opts
    array set optsA [ParseTextAttr $xmllist xAttr yAttr baselineShift]

    set tag [gettag $xmllist]
    set childList [getchildren $xmllist]
    set cmdList {}
    if {[string equal $tag "text"]} {
	set x $xAttr
	set y $yAttr
    }
    
    if {[llength $childList]} {
	
	# Nested tspan elements do not inherit x, y set via attributes.
	if {[string equal $tag "tspan"]} {
	    set xAttr $x
	    set yAttr $y
	}
	set opts [array get optsA]
	foreach c $childList {
	    
	    switch -- [gettag $c] {
		tspan {
		    set cmdList [concat $cmdList \
		      [ParseTspan $c $transformL x y xAttr yAttr $opts]]
		}
		default {
		    # empty
		}
	    }
	}
    } else {
	set str [getcdata $xmllist]
	set optsA(-text) $str
	if {[llength $transformL]} {
	    lappend optsA(-tags) $tmptag
	}
	set opts [array get optsA]
	set theFont $systemFont
	if {[info exists optsA(-font)]} {
	    set theFont $optsA(-font)
	}
	
	# Need to adjust the text position so that the baseline matches y.
	# nw to baseline
	set ascent [font metrics $theFont -ascent]

if {0} {
	set cmdList [list [concat create ptext  \
	  $xAttr [expr {$yAttr - $ascent + $baselineShift}] $opts]]	
	set cmdList [AddAnyTransformCmds $cmdList $transformL]
}
	set cmdList [concat create ptext  \
	  $xAttr [expr {$yAttr - $ascent + $baselineShift}] $opts]

	set cmdList [AddAnyTransformCmds $cmdList $transformL]
	
	# Each text insert moves both the running coordinate sets.
	# newlines???
	set deltax [font measure $theFont $str]
	set x     [expr {$x + $deltax}]
	set xAttr [expr {$xAttr + $deltax}]
    }
    return $cmdList
}

# svg2can::ParseTextAttr --
# 
#       Parses the attributes in xmllist and returns the translated canvas
#       option list.

proc svg2can::ParseTextAttr {xmllist xVar yVar baselineShiftVar} {    
    variable systemFont
    upvar $xVar x
    upvar $yVar y
    upvar $baselineShiftVar baselineShift
#ORLOV
#Переменная для currentColor
    variable curColor
    set curc -1

    # svg defaults to start with y being the baseline while tk default is c.
    #set opts {-anchor sw}
    # Anchor nw is simplest when newlines.
#   set opts {-anchor nw}
    set opts {-textanchor nw}
    set presAttr {}
    set baselineShift 0
    
    foreach {key value} [getattr $xmllist] {
	
	switch -- $key {
	    baseline-shift {
		set baselineShiftSet $value
	    }
	    dx {
		set x [expr {$x + $value}]
	    }
	    dy {
		set y [expr {$y + $value}]
	    }
	    id {
		lappend opts -tags $value
	    }
	    style {
		set opts [concat $opts \
		  [StyleToOpts text [StyleAttrToList $value]]]
	    }
	    x - y {
		set $key $value
	    }
	    class {
#puts "svg2can::ParseTextAttr: class - key=$key value=\"$value\" opts=$opts color=$curColor([string trim $value])"
		set valcl [string trim $value]
		if {[info exist curColor($valcl)]} {
		    set curc $curColor($valcl)
		}
	    }
	    default {
		lappend presAttr $key $value
	    }
	}
    }
#ORLOV
    if {$curc != -1} {
#puts "ParsPathEx: curs=$curc curColor"
	set ind [lsearch -exact $opts "-fill"]
	set inds [lsearch -exact $opts "-stroke"]
	if {$ind != -1} {
	    incr ind
	    set opts [lreplace $opts $ind $ind $curc]
	}
	if {$inds != -1} {
	    incr inds
	    set opts [lreplace $opts $inds $inds $curc]
	}
    }
#ORLOV
    if {$curc != -1 && $ind == -1} {
	set ind [lsearch -exact $opts "-fill"]
	incr ind
	if {[lindex $opts $ind] == "currentColor"} {
	    set opts [lreplace $opts $ind $ind $curc]
	}
    }
    if {$curc != -1 && $inds == -1} {
	set inds [lsearch -exact $opts "-stroke"]
	incr inds
	if {[lindex $opts $inds] == "currentColor"} {
	    set opts [lreplace $opts $inds $inds $curc]
	}
    }
    set ind [lsearch -exact $opts "-fill"]
    incr ind
    if {$ind > 0} {
	if {[lindex $opts $ind] == "currentColor"} {
puts "ParseTextAttr: -fill =currentColor. Replase???"
	    set color $svg2can::curColor([lindex [array name svg2can::curColor] 0])
	    set opts [lreplace $opts $ind $ind $color]
	}
    }


    array set optsA $opts
    set theFont $systemFont
    if {[info exists optsA(-font)]} {
	set theFont $optsA(-font)
    }
    if {[info exists baselineShiftSet]} {
	set baselineShift [BaselineShiftToDy $baselineShiftSet $theFont]
    }
    return [MergePresentationAttr text $opts $presAttr]
}

# svg2can::AttrToCoords --
# 
#       Returns coords from SVG attributes.
#       
# Arguments:
#       type        SVG type
#       attr        list of geometry attributes
#       
# Results:
#       list of coordinates

proc svg2can::AttrToCoords {type attrlist} {
    
    # Defaults.
    array set attr {
	cx      0
	cy      0
	height  0
	r       0
	rx      0
	ry      0
	width   0
	x       0
	x1      0
	x2      0
	y       0
	y1      0
	y2      0
    }
    array set attr $attrlist
    
    switch -- $type {
	circle {
	    set coords [list  \
	      [expr {$attr(cx) - $attr(r)}] [expr {$attr(cy) - $attr(r)}] \
	      [expr {$attr(cx) + $attr(r)}] [expr {$attr(cy) + $attr(r)}]]	
	}
	ellipse {
	    set coords [list  \
	      [expr {$attr(cx) - $attr(rx)}] [expr {$attr(cy) - $attr(ry)}] \
	      [expr {$attr(cx) + $attr(rx)}] [expr {$attr(cy) + $attr(ry)}]]
	}
	image {
	    set coords [list $attr(x) $attr(y)]
	}
	line {
	    set coords [list $attr(x1) $attr(y1) $attr(x2) $attr(y2)]
	}
	path {
	    # empty
	}
	polygon {
	    set coords [PointsToList $attr(points)] 
	}
	polyline {
	    set coords [PointsToList $attr(points)] 
	}
	rect {
	    set coords [list $attr(x) $attr(y) \
	      [expr {$attr(x) + $attr(width)}] [expr {$attr(y) + $attr(height)}]]
	}
	text {
	    set coords [list $attr(x) $attr(y)]
	}
    }
    return $coords
}

# @@@ There is a lot TODO here!

proc svg2can::CreateLinearGradient {xmllist} {
    variable gradientIDToToken
#ORLOV
    variable gradID
    
    set x1 0
    set y1 0
    set x2 1
    set y2 0
    set method pad
    set units bbox
    set stops {}
    # We first need to find out if any xlink:href attribute since:
    # Any 'linearGradient' attributes which are defined on the
    # referenced element which are not defined on this element are 
    # inherited by this element.
    set attr [getattr $xmllist]
    set idx [lsearch -exact $attr xlink:href]
set er 0
    if {$idx >= 0 && [expr {$idx % 2 == 0}]} {
	set value [lindex $attr [incr idx]]
	if {![string match {\#*} $value]} {
#puts "code error unrecognized 1 gradient uri \"$value\""
	    return -code error "unrecognized 1 gradient uri \"$value\""
	}
	set uri [string range $value 1 end]
	if {![info exists gradientIDToToken($uri)]} {
#ORLOV
#puts "code error - unrecognized 2 gradient uri \"$value\" ; xmllist=$xmllist"
set er -1
	    if {![info exists gradID($uri)]} {
		array set gradID [list $uri [list "$xmllist"]]
	    } else {
	        lappend gradID($uri) "$xmllist"
	    }
	    return
#	    return -code error "unrecognized 2 gradient uri \"$value\""
	}
if {$er == 0} {
	set hreftoken $gradientIDToToken($uri)
#ORLOV
if {0} {
	set units  [::tkp::gradient cget $hreftoken -units]
	set method [::tkp::gradient cget $hreftoken -method]
	set hrefstops [::tkp::gradient cget $hreftoken -stops]
	foreach {x1 y1 x2 y2} [::tkp::gradient cget $hreftoken -lineartransition] { break }	
}
	set units  [${svg2can::priv(wcan)} gradient cget $hreftoken -units]
	set method [${svg2can::priv(wcan)} gradient cget $hreftoken -method]
	set hrefstops [${svg2can::priv(wcan)} gradient cget $hreftoken -stops]
	foreach {x1 y1 x2 y2} [${svg2can::priv(wcan)} gradient cget $hreftoken -lineartransition] { break }	
}
    }    

    foreach {key value} $attr {	
	switch -- $key {
	    x1 - y1 - x2 - y2 {
		set $key [parseUnaryOrPercentage $value]
	    }
	    id {
		set id $value
	    }
	    gradientUnits {
		set units [string map \
		  {objectBoundingBox bbox userSpaceOnUse userspace} $value]
	    }
	    spreadMethod {
		set method $value
	    }
	}
    }
    if {![info exists id]} {
	return
    }
    
    # If this element has no defined gradient stops, and the referenced element 
    # does, then this element inherits the gradient stop from the referenced 
    # element.
    set stops [ParseGradientStops $xmllist]    
    if {$stops eq {}} {
	if {[info exists hrefstops]} {
	    set stops $hrefstops
	}
    }
#puts "CreateLinearGradient start"
#    set token [::tkp::gradient create linear -method $method -units $units -lineartransition [list $x1 $y1 $x2 $y2] -stops $stops]
    set token [${svg2can::priv(wcan)} gradient create linear -method $method -units $units -lineartransition [list $x1 $y1 $x2 $y2] -stops $stops]
#puts "CreateLinearGradient end=$token"
    set gradientIDToToken($id) $token
    cache_add gradient $token

}

proc svg2can::CreateRadialGradient {xmllist} {
    variable gradientIDToToken

    set cx 0.5
    set cy 0.5
    set r  0.5
    set fx 0.5
    set fy 0.5
    set method pad
    set units bbox
    set stops {}
    
    # We first need to find out if any xlink:href attribute since:
    # Any 'linearGradient' attributes which are defined on the
    # referenced element which are not defined on this element are 
    # inherited by this element.
    set attr [getattr $xmllist]
    set idx [lsearch -exact $attr xlink:href]
    if {$idx >= 0 && [expr {$idx % 2 == 0}]} {
	set value [lindex $attr [incr idx]]
	if {![string match {\#*} $value]} {
	    return -code error "unrecognized rad1 gradient uri \"$value\""
	}
	set uri [string range $value 1 end]
	if {![info exists gradientIDToToken($uri)]} {
	    return -code error "unrecognized rad2 gradient uri \"$value\""
	}
	set hreftoken $gradientIDToToken($uri)
#ORLOV
if {0} {
	set units  [::tkp::gradient cget $hreftoken -units]
	set method [::tkp::gradient cget $hreftoken -method]
	set hrefstops [::tkp::gradient cget $hreftoken -stops]
	set transL [::tkp::gradient cget $hreftoken -radialtransition]
}
#puts "CreateRadialGradient start hreftoken=$hreftoken"
	set units  [${svg2can::priv(wcan)} gradient cget $hreftoken -units]
	set method [${svg2can::priv(wcan)} gradient cget $hreftoken -method]
	set hrefstops [${svg2can::priv(wcan)} gradient cget $hreftoken -stops]
#	set transL [${svg2can::priv(wcan)} gradient cget $hreftoken -radialtransition]
if {![catch {${svg2can::priv(wcan)} gradient cget $hreftoken -radialtransition} transL]} {
	set cx [lindex $transL 0]
	set cy [lindex $transL 1]
	if {[llength $transL] > 2} {
	    set r [lindex $transL 2]
	    if {[llength $transL] == 5} {
		set fx [lindex $transL 3]
		set fy [lindex $transL 4]
	    }
	}
}
    }    

    foreach {key value} [getattr $xmllist] {	
	switch -- $key {
	    cx - cy - r - fx - fy {
		set $key [parseUnaryOrPercentage $value]
	    }
	    id {
		set id $value
	    }
	    gradientUnits {
		set units [string map \
		  {objectBoundingBox bbox userSpaceOnUse userspace} $value]
	    }
	    spreadMethod {
		set method $value
	    }
	}
    }
    if {![info exists id]} {
	return
    }
    # If this element has no defined gradient stops, and the referenced element 
    # does, then this element inherits the gradient stop from the referenced 
    # element.
    set stops [ParseGradientStops $xmllist]    
    if {$stops eq {}} {
	if {[info exists hrefstops]} {
	    set stops $hrefstops
	}
    }
#puts "CreateRadialGradient start"
#    set token [::tkp::gradient create radial -method $method -units $units -radialtransition [list $cx $cy $r $fx $fy] -stops $stops]
    set token [${svg2can::priv(wcan)} gradient create radial -method $method -units $units -radialtransition [list $cx $cy $r $fx $fy] -stops $stops]
#puts "CreateRadialGradient end=$token"
    set gradientIDToToken($id) $token
    cache_add gradient $token

}

proc svg2can::ParseGradientStops {xmllist} {
    set curc -1
    
    set stops {}
    
    foreach stopE [getchildren $xmllist] {
	if {[gettag $stopE] eq "stop"} {
	    set opts {}
	    set offset 0
	    set color black
	    set opacity 1
	    
	    foreach {key value} [getattr $stopE] {
		switch -- $key {
		    offset {
			set offset [parseUnaryOrPercentage $value]
		    }
		    stop-color {
			set color [parseColor $value]
		    }
		    stop-opacity {
			set opacity $value
		    }
		    style {
			set opts [StopsStyleToStopSpec [StyleAttrToList $value]]
		    }
		    class {
#puts "svg2can::ParseGradientStops: class - key=$key value=\"$value\" opts=$opts color=$svg2can::curColor([string trim $value])"
			set valcl [string trim $value]
			if {[info exist curColor($valcl)]} {
			    set curc $curColor($valcl)
			}
		    }
		}
	    }
#puts "svg2can::ParseGradientStops: color=$color opts=$opts"
	    set inds [lsearch -exact $opts "color"]
	    if {$curc != -1} {
		set color $curc
		set inds [lsearch -exact $opts "color"]
		incr inds
		if {[lindex $opts $inds] == "currentColor"} {
		    set opts [lreplace $opts $inds $inds $curc]
		}
	    } elseif {$color  == "currentColor"} {
		if {[array size svg2can::curColor] == 1} {
		    set color $svg2can::curColor([array name svg2can::curColor])
		    set inds [lsearch -exact $opts "color"]
		    incr inds
		    if {[lindex $opts $inds] == "currentColor"} {
			set opts [lreplace $opts $inds $inds $color]
		    }
		}
	    } else {
		    incr inds
		    if {[lindex $opts $inds] == "currentColor"} {
puts "svg2can::ParseGradientStops: color=currentColor. Replase???"
			set color $svg2can::curColor([lindex [array name svg2can::curColor] 0])
			set opts [lreplace $opts $inds $inds $color]
		    }
	    }

	    # Style takes precedence.
	    array set stopA [list color $color opacity $opacity]
	    array set stopA $opts
	    lappend stops [list $offset $stopA(color) $stopA(opacity)]
	}
    }
    return $stops
}

proc svg2can::parseUnaryOrPercentage {offset} {
    if {[string is double -strict $offset]} {
	return $offset
    } elseif {[regexp {(.+)%} $offset - percent]} {
	return [expr {$percent/100.0}]
    }
}

# svg2can::parseColor --
# 
#       Takes a SVG color definition and turns it into a Tk color.
#       
# Arguments:
#       color       SVG color
#       
# Results:
#       tk color

proc svg2can::parseColor {color} {
    
    if {[regexp {rgb\(([0-9]{1,3})%, *([0-9]{1,3})%, *([0-9]{1,3})%\)}  \
      $color - r g b]} {
	set col "#"
	foreach c [list $r $g $b] {
	    append col [format %02x [expr {round(2.55 * $c)}]]
	}
    } elseif {[regexp {rgb\(([0-9]{1,3}), *([0-9]{1,3}), *([0-9]{1,3})\)}  \
      $color - r g b]} {
	set col "#"
	foreach c [list $r $g $b] {
	    append col [format %02x $c]
	}
    } else {
	set col [MapNoneToEmpty $color]
    }
#ORLOV
if {0 && $col == "currentColor"} {
    puts "parseColor: col=currentColor"
} 
#puts "parseColor: color=$color"
    if {[string length $color] == 9 && [string range $color 0 0] == "#"} {
	set col [string range $col 0 6]
    }


    return $col
}

proc svg2can::parseFillToList {value} {
    variable gradientIDToToken
#ORLOV
    variable gradID
#puts "gradID: START parseFillToList"
    foreach n [array names gradID] {
#puts "gradID: name=$n"

	foreach c1 $gradID($n) {
#puts "parseFillToList: c=$c1"
	    set c [lindex $c1 0]
	    set tag [gettag $c]
#puts "gradID: tag=$tag"
	    switch -- $tag {
		linearGradient {
		    CreateLinearGradient $c1
		}
		radialGradient {
		    CreateRadialGradient $c1
		}
	    }
	}
    }
    foreach n [array names gradID] {
	unset gradID($n)
    }
#puts "gradID: parseFillToList END"


    if {[regexp {url\(#(.+)\)} $value - id]} {
	#puts "\t id=$id"
	if {[info exists gradientIDToToken($id)]} {
	    #puts "\t gradientIDToToken=$gradientIDToToken($id)"
	    return [list -fill $gradientIDToToken($id)]
	} else {
#	    puts "--------> missing gradientIDToToken id=$id"
	    return [list -fill cyan]
	}
    } else {
	return [list -fill [parseColor $value]]
    }
}

proc svg2can::parseStrokeToList {value} {
    variable gradientIDToToken
#ORLOV
    variable gradID
#puts "gradID: START parseStrokeToList"
    foreach n [array names gradID] {
#puts "gradID: name=$n"

	foreach c1 $gradID($n) {
#puts "parseFillToList: c=$c1"
	    set c [lindex $c1 0]
	    set tag [gettag $c]
#puts "gradID: tag=$tag"
	    switch -- $tag {
		linearGradient {
		    CreateLinearGradient $c1
		}
		radialGradient {
		    CreateRadialGradient $c1
		}
	    }
	}
    }
    foreach n [array names gradID] {
	unset gradID($n)
    }
#puts "gradID: parseStrokeToList END"


    if {[regexp {url\(#(.+)\)} $value - id]} {
	#puts "\t id=$id"
	if {[info exists gradientIDToToken($id)]} {
	    #puts "\t gradientIDToToken=$gradientIDToToken($id)"
#К сожалению не работает градиентная заливка для опции -stroke
#	    return [list -stroke $gradientIDToToken($id)]
	    return [list -stroke cyan]
	} else {
#	    puts "--------> missing gradientIDToToken id=$id"
	    return [list -stroke black]
	}
    } else {
	return [list -stroke [parseColor $value]]
    }
}

proc svg2can::parseLength {length} {    
    if {[string is double -strict $length]} {
	return $length
    }    
    # SVG is using: px, pt, mm, cm, em, ex, in, %.
    # @@@ Incomplete!
    set length [string map {px ""  pt p  mm m  cm c  in i} $length]
    return [winfo fpixels . $length]
}

proc svg2can::parseArcSweep {dd} {
#return $dd
    set ret 1
    set path ""
    set seek 0
#puts "svg2can::parseArcSweep: path=$d"
    while {$ret } {
	set ret [regexp  -indices -- {([aA])([ -.[0-9]+)} [string range $dd $seek end] ind]
	if {$ret == 0} {
	    append path [string range $dd $seek end]
	    continue
	}
	foreach {ind1 ind2} $ind {
	    set tind $ind2
	    incr ind2 $seek
	    incr ind1 $seek
#puts "A=[string range $dd $ind1 $ind2] \nind1=$ind1 $ind2=$ind2 seek=$seek"
	    set arcsweep [string range $dd $ind1 $ind2]
	    if {[llength $arcsweep] < 7} {
		regsub -- {([0-1])([0-1])([\-.]*[0-9]*)} [string range $dd $ind1 $ind2] {\1 \2 \3} arcsweep
	    }
#puts "Anew= $arcsweep "
	    incr ind1 -1
	    incr ind2
	    incr ind2 -1
	}
	    append path [string range $dd $seek $ind1]
	append path "$arcsweep"
	incr seek $tind
    }
#puts "svg2can::parseArcSweep END: path=$path"
    return $path
}

proc svg2can::parsePathAttr {path} {
#puts "svg2can::parsePathAttr"
    regsub -all -- {([a-zA-Z])([0-9])} $path {\1 \2} path
    regsub -all -- {([0-9])([a-zA-Z])} $path {\1 \2} path
    regsub -all -- {([a-zA-Z])([a-zA-Z])} $path {\1 \2} path
#Я добавил
    set path [string map {- " -"  , " "} $path]
    regsub -all -- {([a-zA-Z])(\.[0-9]*)(\.[0-9])} $path { \1 \2 \3} path
#    regsub -all -- {([0-9]+\.[0-9]*)(\.[0-9]+)} $path { \1 \2 } path
    regsub -all -- {([\-]*[0-9]*\.[0-9]*)(\.[0-9]+)} $path { \1 \2 } path

    regsub -all -- {([\-]*[0-9]+)([\ ]*)e([\ ]*)([\-]*[0-9]+)} $path {\1e\4} path

#Разбор h[-]. и т.п.
    regsub -all --  {([a-zA-Z])([-]*[0-9]*[.][0-9]*)} $path {\1 \2} path
#Разбор ArcSweep 
    set path [svg2can::parseArcSweep $path]
#  regsub -all -- {([0-1])([0-1])([0-9]*)} $path {\1 \2 \3} path
# regsub -all -- {([0-1])([0-1])([\-.]*[0-9]*)} $path {\1 \2 \3} path

    return $path
if {0} {
    regsub -all -- {([a-zA-Z])([0-9])} $path {\1 \2} path
    regsub -all -- {([0-9])([a-zA-Z])} $path {\1 \2} path
    regsub -all -- {([a-zA-Z])([a-zA-Z])} $path {\1 \2} path
    return [string map {- " -"  , " "} $path]
}

}

# svg2can::StyleToOpts --
# 
#       Takes the style attribute as a list and parses it into
#       resonable canvas drawing options.
#       Discards all attributes that don't map to an item option.
#       
# Arguments:
#       type        tk canvas item type
#       styleList
#       
# Results:
#       list of canvas options

proc svg2can::StyleToOpts {type styleList args} {
    
    variable textAnchorMap
    
    array set argsA {
	-setdefaults 1 
	-origfont    {Helvetica 12}
    }
    array set argsA $args

    # SVG and canvas have different defaults.
    if {$argsA(-setdefaults)} {
	switch -- $type {
	    oval - polygon - rectangle {
		array set optsA {-fill black -outline ""}
	    }
	    line {
		array set optsA {-fill black}
	    }
	}
    }
    
    set fontSpec $argsA(-origfont)
    set haveFont 0
    
    foreach {key value} $styleList {
	
	switch -- $key {
	    fill {
		switch -- $type {
		    arc - oval - polygon - rectangle - text {
			set optsA(-fill) [parseColor $value]
		    }
		}
	    }
	    font-family {
#		lset fontSpec 0 $value
#		set haveFont 1
		set optsA(-fontfamily) $value
	    }
	    font-size {
		set optsA(-fontsize) [parseLength $value]
#		set haveFont 1
	    }
	    font-style {
		switch -- $value {
		    italic {
			lappend fontSpec italic
		    }
		}
#		set haveFont 1
	    }
	    font-weight {
		set optsA(-fontweight) $value
if {0} {
		switch -- $value {
		    bold {
			lappend fontSpec bold
		    }
		}
		set haveFont 1
}
	    }
	    marker-end {
		set optsA(-arrow) last
	    }
	    marker-start {
		set optsA(-arrow) first		
	    }
	    stroke {
		if {$value == "none"} {
		    set optsA(-stroke) {}
		} else {
		    set optsA(-stroke) $value
		}
	    
if {0} {	    
		switch -- $type {
		    arc - oval - polygon - rectangle {
			set optsA(-outline) [parseColor $value]
		    }
		    line {
			set optsA(-fill) [parseColor $value]
		    }
		}
}
	    }
	    stroke-dasharray {
		set dash [split $value ,]
		if {[expr {[llength $dash]%2 == 1}]} {
		    set dash [concat $dash $dash]
		}
	    }
	    stroke-linecap {	
		# canvas: butt (D), projecting , round 
		# svg:    butt (D), square, round
if {0} {
		if {[string equal $value "square"]} {
		    set optsA(-capstyle) "projecting"
		}
		if {![string equal $value "butt"]} {
		    set optsA(-capstyle) $value
		}
}
		set optsA(-strokelinecap) $value
	    }
	    stroke-linejoin {
#		set optsA(-joinstyle) $value
		set optsA(-strokelinejoin) $value
	    }
	    stroke-miterlimit {
		# empty
	    }
	    stroke-opacity {
		set optsA(-strokeopacity) $value
	    }
	    stroke-width {
if {0} {
		if {![string equal $type "text"]} {
		    set optsA(-width) $value
		}
}
		    set optsA(-strokewidth) [parseLength $value]
	    }
	    text-anchor {
		set optsA(-textanchor) $textAnchorMap($value)
	    }
	    text-decoration {
		switch -- $value {
		    line-through {
			lappend fontSpec overstrike
		    }
		    underline {
			lappend fontSpec underline
		    }
		}
		set haveFont 1
	    }
	}
    }
if {0} {
    if {$haveFont} {
	set optsA(-font) $fontSpec
    }
}
    return [array get optsA]
}

proc svg2can::StyleToOptsEx {styleList args} {
    variable curColor
#puts "StyleToOptsEx styleList=$styleList args=$args"
    set colorcur -1
    foreach {key value} $styleList {    
#puts "StyleToOptsEx key=$key value=$value"
	switch -- $key {
	    color {
#puts "StyleToOptsEx COLOR key=$key value=$value optsA=[array get optsA]"
		set colorcur $value
	    }
	    class {
#puts "StyleToOptsEx CLASS key=$key value=$value optsA=[array get optsA]"
#		set optsA(-fill) $curColor($value)
	    }
	    fill {
#puts "StyleToOptsEx FILL key=$key value=$value optsA=[array get optsA]"
		foreach {name val} [parseFillToList $value] { break }
		set optsA($name) $val
#puts "StyleToOptsEx FILL key=$key value=$value optsA=[array get optsA]"
	    } 
	    opacity {
		# @@@ This is much more complicated than this for groups!
		set optsA(-fillopacity) $value
		set optsA(-strokeopacity) $value
	    }
	    stroke {
#puts "StyleToOptsEx STROKE key=$key value=$value optsA=[array get optsA]"
#		set optsA(-$key) [parseColor $value]		
		foreach {name val} [parseStrokeToList $value] { break }
		set optsA($name) $val
	    }
	    stroke-dasharray {
		if {$value eq "none"} {
		    set optsA(-strokedasharray) {}
		} else {
		    set dash [split $value ,]
		    set optsA(-strokedasharray) $dash
		}
	    }
	    fill-opacity - stroke-linejoin - stroke-miterlimit - stroke-opacity {		
		set name [string map {"-" ""} $key]
		set optsA(-$name) $value
	    }
	    stroke-linecap {
		# svg:    butt (D), square, round
		# canvas: butt (D), projecting , round 
		if {$value eq "square"} {
		    set value "projecting"
		}
		set name [string map {"-" ""} $key]
		set optsA(-$name) $value
	    }
	    stroke-width {		
		set name [string map {"-" ""} $key]
		set optsA(-$name) [parseLength $value]
	    }
	    r - rx - ry - width - height {
		set optsA(-$key) [parseLength $value]
	    }
	}
    }

    if {[info exist optsA(-fill)]} {
	if {$optsA(-fill) == "currentcolor"} {

	    if {$colorcur != -1} {
		set optsA(-fill) $colorcur
	    }
	}
    }

    return [array get optsA]
}

# svg2can::StopsStyleToStopSpec --
# 
#       Takes the stop style attribute as a list and parses it into
#       a flat array for the gradient stopSpec: {offset color ?opacity?}

proc svg2can::StopsStyleToStopSpec {styleList} {
    
    foreach {key value} $styleList {    
	switch -- $key {
	    stop-color {
		set optsA(color) [parseColor $value]		
	    }
	    stop-opacity {
		set optsA(opacity) $value
	    }
	}
    }
    return [array get optsA]
}

# svg2can::EllipticArcParameters --
# 
#       Conversion from endpoint to center parameterization.
#       From: http://www.w3.org/TR/2003/REC-SVG11-20030114

proc svg2can::EllipticArcParameters {x1 y1 rx ry phi fa fs x2 y2} {
    variable pi

    # NOTE: direction of angles are opposite for Tk and SVG!
    
    # F.6.2 Out-of-range parameters 
    if {($x1 == $x2) && ($y1 == $y2)} {
	return skip
    }
    if {[expr {$rx == 0}] || [expr {$ry == 0}]} {
	return lineto
    }
    set rx [expr {abs($rx)}]
    set ry [expr {abs($ry)}]
    set phi [expr {fmod($phi, 360) * $pi/180.0}]
    if {$fa != 0} {
	set fa 1
    }
    if {$fs != 0} {
	set fs 1
    }
    
    # F.6.5 Conversion from endpoint to center parameterization 
    set dx [expr {($x1-$x2)/2.0}]
    set dy [expr {($y1-$y2)/2.0}]
    set x1prime [expr {cos($phi) * $dx + sin($phi) * $dy}]
    set y1prime [expr {-sin($phi) * $dx + cos($phi) * $dy}]
    
    # F.6.6 Correction of out-of-range radii
    set rx [expr {abs($rx)}]
    set ry [expr {abs($ry)}]
    set x1prime2 [expr {$x1prime * $x1prime}]
    set y1prime2 [expr {$y1prime * $y1prime}]
    set rx2 [expr {$rx * $rx}]
    set ry2 [expr {$ry * $ry}]
    set lambda [expr {$x1prime2/$rx2 + $y1prime2/$ry2}]
    if {$lambda > 1.0} {
	set rx [expr {sqrt($lambda) * $rx}]
	set ry [expr {sqrt($lambda) * $ry}]
	set rx2 [expr {$rx * $rx}]
	set ry2 [expr {$ry * $ry}]
    }    
    
    # Compute cx' and cy'
    set sign [expr {$fa == $fs ? -1 : 1}]
    set square [expr {($rx2 * $ry2 - $rx2 * $y1prime2 - $ry2 * $x1prime2) /  \
      ($rx2 * $y1prime2 + $ry2 * $x1prime2)}]
    set root [expr {sqrt(abs($square))}]
    set cxprime [expr {$sign * $root * $rx * $y1prime/$ry}]
    set cyprime [expr {-$sign * $root * $ry * $x1prime/$rx}]
    
    # Compute cx and cy from cx' and cy'
    set cx [expr {$cxprime * cos($phi) - $cyprime * sin($phi) + ($x1 + $x2)/2.0}]
    set cy [expr {$cxprime * sin($phi) + $cyprime * cos($phi) + ($y1 + $y2)/2.0}]

    # Compute start angle and extent
    set ux [expr {($x1prime - $cxprime)/double($rx)}]
    set uy [expr {($y1prime - $cyprime)/double($ry)}]
    set vx [expr {(-$x1prime - $cxprime)/double($rx)}]
    set vy [expr {(-$y1prime - $cyprime)/double($ry)}]

    set sign [expr {$uy > 0 ? 1 : -1}]
    set theta [expr {$sign * acos( $ux/hypot($ux, $uy) )}]

    set sign [expr {$ux * $vy - $uy * $vx > 0 ? 1 : -1}]
    set delta [expr {$sign * acos( ($ux * $vx + $uy * $vy) /  \
      (hypot($ux, $uy) * hypot($vx, $vy)) )}]
    
    # To degrees
    set theta [expr {$theta * 180.0/$pi}]
    set delta [expr {$delta * 180.0/$pi}]
    #set delta [expr {fmod($delta, 360)}]
    set phi   [expr {fmod($phi, 360)}]
    
    if {($fs == 0) && ($delta > 0)} {
	set delta [expr {$delta - 360}]
    } elseif {($fs ==1) && ($delta < 0)} {
	set delta [expr {$delta + 360}]
    }

    # NOTE: direction of angles are opposite for Tk and SVG!
    set theta [expr {-1*$theta}]
    set delta [expr {-1*$delta}]
    
    return [list $cx $cy $rx $ry $theta $delta $phi]
}

# svg2can::MergePresentationAttr --
# 
#       Let the style attribute override the presentation attributes.

proc svg2can::MergePresentationAttr {type opts presAttr} {
    
    if {[llength $presAttr]} {
	array set optsA [StyleToOpts $type $presAttr]
	array set optsA $opts
	set opts [array get optsA]
    }
    return $opts
}

proc svg2can::MergePresentationAttrEx {opts presAttr} {
    
    if {[llength $presAttr]} {
	array set optsA [StyleToOptsEx $presAttr]
	array set optsA $opts
	set opts [array get optsA]
    }
    return $opts
}

proc svg2can::StyleAttrToList {style} {    
    return [split [string trim [string map {" " ""} $style] \;] :\;]
}

proc svg2can::BaselineShiftToDy {baselineshift fontSpec} {
    
    set linespace [font metrics $fontSpec -linespace]
    
    switch -regexp -- $baselineshift {
	sub {
	    set dy [expr {0.8 * $linespace}]
	}
	super {
	    set dy [expr {-0.8 * $linespace}]
	}
	{-?[0-9]+%} {
	    set dy [expr {0.01 * $linespace * [string trimright $baselineshift %]}]
	}
	default {
	    # 0.5em ?
	    set dy $baselineshift
	}
    }
    return $dy
}

# svg2can::PathAddRelative --
# 
#       Utility function to add a relative point from the path to the 
#       coordinate list. Updates iVar, and the current point.

proc svg2can::PathAddRelative {path coVar iVar cpxVar cpyVar} {
    upvar $coVar  co
    upvar $iVar   i
    upvar $cpxVar cpx
    upvar $cpyVar cpy

    set newx [expr {$cpx + [lindex $path [incr i]]}]
    set newy [expr {$cpy + [lindex $path [incr i]]}]
    lappend co $newx $newy
    set cpx $newx
    set cpy $newy
}

proc svg2can::PointsToList {points} {
    return [string map {, " "} $points]
}

# svg2can::ParseTransformAttr --
# 
#       Parse the svg syntax for the transform attribute to a simple tcl
#       list.

proc svg2can::ParseTransformAttr {attrlist} {  
    set cmd ""
    set idx [lsearch -exact $attrlist "transform"]
    if {$idx >= 0} {
	set cmd [TransformAttrToList [lindex $attrlist [incr idx]]]
    }
    return $cmd
}

proc svg2can::TransformAttrToList {cmd} {    
    regsub -all -- {\( *([-0-9.]+) *\)} $cmd { \1} cmd
    regsub -all -- {\( *([-0-9.]+)[ ,]+([-0-9.]+) *\)} $cmd { {\1 \2}} cmd
    regsub -all -- {\( *([-0-9.]+)[ ,]+([-0-9.]+)[ ,]+([-0-9.]+) *\)} \
      $cmd { {\1 \2 \3}} cmd
    regsub -all -- {,} $cmd {} cmd
    return $cmd
}

# svg2can::TransformAttrListToMatrix --
# 
#       Processes a SVG transform attribute to a transformation matrix.
#       Used by tkpath only.
#       
#       | a c tx |
#       | b d ty |
#       | 0 0 1  |
#       
#       linear form : {a b c d tx ty}

proc svg2can::TransformAttrListToMatrix {transform} {
    variable degrees2Radians
    
    # @@@ I don't have 100% control of multiplication order!
    set i 0
#puts "TransformAttrListToMatrix: transform=$transform"

    foreach {op value} $transform {
#puts "TransformAttrListToMatrix: XAXA op=$op value=$value"
	switch -- $op {
	    matrix {
#ORLOV
	set value [string map {")" "" } $value]
	set value [string map {"," " "} $value]
    regsub -all -- {([\-]*[0-9]*\.[0-9]*)(\.[0-9]+)} $value { \1 \2 } value

    regsub -all -- {([\-]*[0-9]+)([\ ]*)e([\ ]*)([\-]*[0-9]+)} $value {\1e\4} value
    regsub -all --  {([0-9])(-[\.0-9])} $value {\1 \2} value
		set m([incr i]) $value
#puts "TransformAttrListToMatrix: op=matrix i=$i value=$value"
	    }
	    rotate {
		set value [string map {"," " "} $value]
#puts "TransformAttrListToMatrix: op=rotate i=$i value=$value"

		if {[llength $value] == 1} {
		    set phi [lindex $value 0]
		    set xr 0
		    set yr 0
		} else {
		    set phi [lindex $value 2]
		    set xr [lindex $value 0]
		    set yr [lindex $value 1]
		}
		set phi_my [svg2can::degre2radian $phi]
		set m_my [tkp::matrix rotate $phi_my $xr $yr]
#puts "TransformAttrListToMatrix: m_my=$m_my"		
		set m_my1 [tkp::matrix mult "{1 0} {0 1} {0 0}" $m_my]
#puts "TransformAttrListToMatrix: m_my1=$m_my1"		

		foreach {a1 a2} [lindex $m_my1 0] {break}
		foreach {a3 a4} [lindex $m_my1 1] {break}
		foreach {a5 a6} [lindex $m_my1 2] {break}
		set m([incr i]) [list $a1 $a2 $a3 $a4 $a5 $a6]

if {0} {
puts "TransformAttrListToMatrix: op=rotate phi=$phi value_0=[lindex $value 0]"
		set cosPhi  [expr {cos($degrees2Radians*$phi)}]
		set sinPhi  [expr {sin($degrees2Radians*$phi)}]
		set msinPhi [expr {-1.0*$sinPhi}]
		if {[llength $value] == 1} {
		    set m([incr i])  \
		      [list $cosPhi $sinPhi $msinPhi $cosPhi 0 0]
		} else {
		    set cx [lindex $value 1]
		    set cy [lindex $value 2]
		    set m([incr i]) [list $cosPhi $sinPhi $msinPhi $cosPhi \
		      [expr {-$cx*$cosPhi + $cy*$sinPhi + $cx}] \
		      [expr {-$cx*$sinPhi - $cy*$cosPhi + $cy}]]
		}
}
#puts "TransformAttrListToMatrix: op=rotate phi_my=$phi_my m([set i])=$m([set i])"

	    }
	    scale {
		set value [string map {"," " "} $value]
		set sx [lindex $value 0]
		if {[llength $value] > 1} {
		    set sy [lindex $value 1]
		} else {
		    set sy $sx
		}
		set m([incr i]) [list $sx 0 0 $sy 0 0]
	    }
	    skewx {
		set tana [expr {tan($degrees2Radians*[lindex $value 0])}]
		set m([incr i]) [list 1 0 $tana 1 0 0]
	    }
	    skewy {
		set tana [expr {tan($degrees2Radians*[lindex $value 0])}]
		set m([incr i]) [list 1 $tana 0 1 0 0]
	    }
	    translate {
#puts "TransformAttrListToMatrix:1 translate value=$value"
#ORLOV
		regsub -all --  {([0-9])(-[\.0-9])} $value {\1 \2} value
		set value [string map {"," " " } $value]
		set tx [lindex $value 0]
		if {[llength $value] > 1} {
		    set ty [lindex $value 1]
		} else {
		    set ty 0
		}
		set m([incr i]) [list 1 0 0 1 $tx $ty]
#puts "TransformAttrListToMatrix:1 translate value=$value i=$i m($i)=$m($i)"
	    }
	}
    }
    if {$i == 1} {
	# This is the most common case.
	set mat $m($i)
    } else {
	set mat {1 0 0 1 0 0}
	foreach i [lsort -integer [array names m]] {
#puts "TransformAttrListToMatrix: mat=$mat m($i)=$m($i)"
	    set mat [MMult $mat $m($i)]
	}
    }
    foreach {a b c d tx ty} $mat { break }
#puts "TransformAttrListToMatrix -> mat=$mat"

    return [list [list $a $b] [list $c $d] [list $tx $ty]]
}

proc svg2can::MMult {m1 m2} {
#puts "MMult m1=$m1 \nm2=$m2 "

    foreach {a1 b1 c1 d1 tx1 ty1} $m1 { break }
    foreach {a2 b2 c2 d2 tx2 ty2} $m2 { break }
    return [list \
      [expr {$a1*$a2  + $c1*$b2}]        \
      [expr {$b1*$a2  + $d1*$b2}]        \
      [expr {$a1*$c2  + $c1*$d2}]        \
      [expr {$b1*$c2  + $d1*$d2}]        \
      [expr {$a1*$tx2 + $c1*$ty2 + $tx1}] \
      [expr {$b1*$tx2 + $d1*$ty2 + $ty1}]]
}

# svg2can::CreateTransformCanvasCmdList --
# 
#       Takes a parsed list of transform attributes and turns them
#       into a sequence of canvas commands.
#       Standard items only which miss a matrix option.

proc svg2can::CreateTransformCanvasCmdList {tag transformL} {
    
    set cmdList {}
    foreach {key argument} $transformL {
	
	switch -- $key {
	    translate {
		lappend cmdList [concat [list move $tag] $argument]
	    }
	    scale {
		
		switch -- [llength $argument] {
		    1 {
			set xScale $argument
			set yScale $argument
		    }
		    2 {
			foreach {xScale yScale} $argument break
		    }
		    default {
			set xScale 1.0
			set yScale 1.0
		    }
		}
		lappend cmdList [list scale $tag 0 0 $xScale $yScale]
	    }
	}
    }
    return $cmdList
}

proc svg2can::AddAnyTransformCmds {cmdList transformL} {
    variable tmptag
    
    if {[llength $transformL]} {
	set cmdList [concat $cmdList \
	  [CreateTransformCanvasCmdList $tmptag $transformL]]
	lappend cmdList [list dtag $tmptag]
    }
    return $cmdList
}

proc svg2can::MapNoneToEmpty {val} {

    if {[string equal $val "none"]} {
	return
    } else {
	return $val
    }
}

proc svg2can::FlattenList {hilist} {
    
    set flatlist {}
    FlatListRecursive $hilist flatlist
    return $flatlist
}

proc svg2can::FlatListRecursive {hilist flatlistVar} {
    upvar $flatlistVar flatlist
    
    if {[string equal [lindex $hilist 0] "create"]} {
	set flatlist [list $hilist]
    } else {
	foreach c $hilist {
	    if {[string equal [lindex $c 0] "create"]} {
		lappend flatlist $c
	    } else {
		FlatListRecursive $c flatlist
	    }
	}
    }
}

# svg2can::gettag, getattr, getcdata, getchildren --
# 
#       Accesor functions to the specific things in a xmllist.

proc svg2can::gettag {xmllist} { 
    return [lindex $xmllist 0]
}

proc svg2can::getattr {xmllist} { 
    return [lindex $xmllist 1]
}

proc svg2can::getcdata {xmllist} { 
    return [lindex $xmllist 3]
}

proc svg2can::getchildren {xmllist} { 
    return [lindex $xmllist 4]
}

proc svg2can::_DrawSVG {fileName w} {
    set fd [open $fileName r]
    set xml [read $fd]
    close $fd
    set xmllist [tinydom::documentElement [tinydom::parse $xml]]
    set cmdList [svg2can::parsesvgdocument $xmllist]
    foreach c $cmdList {
	puts $c
	eval $w $c
    }
}
#Add V. Orlov
proc svg2can::SVGFileToCanvas {w filePath} {
#puts "SVGFileToCanvas: file=$filePath"    
    array unset svg2can::curColor

    set svg2can::priv(wcan) $w
    # Opens the data file.
    if {[catch {open $filePath r} fd]} {
	set tail [file tail $filePath]
	tk_messageBox -icon error -title "Error" -message "Cannot read $tail : $fd"
	return
    }
    fconfigure $fd -encoding utf-8
    set xml [read $fd]
#puts "xml=$xml"    
    set xmllist [tinydom::documentElement [tinydom::parse $xml]]
#puts "xmllist=$xmllist"    
    # Update the utags...
    set cmdList [svg2can::parsesvgdocument $xmllist \
      -imagehandler [list ::CanvasFile::SVGImageHandler $w] \
      -foreignobjecthandler [list ::CanvasUtils::SVGForeignObjectHandler $w]]
#puts "cmdList=$cmdList"    
    set gr [${svg2can::priv(wcan)} create group -matrix {{1 0} {0 1} {0 0}}]

    foreach cmd $cmdList {
#puts "cmd=$cmd"
	append cmd " -parent [set gr]"
	eval ${svg2can::priv(wcan)} $cmd 
    }
    close $fd
#Очищаем массив с именами gradient-ов
    foreach nam [array names svg2can::gradientIDToToken ] {
	unset svg2can::gradientIDToToken($nam)
    }
    return $gr
}

proc svg2can::SVGXmlToCanvas {w xml} {
#puts "SVGFileToCanvas: file=$filePath"    
    array unset svg2can::curColor
    set svg2can::priv(wcan) $w
#puts "xml=$xml"    
    set xmllist [tinydom::documentElement [tinydom::parse $xml]]
#puts "xmllist=$xmllist"    
    # Update the utags...
    set cmdList [svg2can::parsesvgdocument $xmllist \
      -imagehandler [list ::CanvasFile::SVGImageHandler $w] \
      -foreignobjecthandler [list ::CanvasUtils::SVGForeignObjectHandler $w]]
#puts "cmdList=$cmdList"    
    set gr [${svg2can::priv(wcan)} create group -matrix {{1 0} {0 1} {0 0}}]

    foreach cmd $cmdList {
#puts "cmd=$cmd"
	append cmd " -parent [set gr]"
	eval ${svg2can::priv(wcan)} $cmd 
    }
#Очищаем массив с именами gradient-ов
    foreach nam [array names svg2can::gradientIDToToken ] {
	unset svg2can::gradientIDToToken($nam)
    }
    return $gr
}

proc svg2can::SVGFileToCmds {w filePath} {
#puts "SVGFileToCmds: file=$filePath"    
    array unset svg2can::curColor
    set svg2can::priv(wcan) $w
    # Opens the data file.
    if {[catch {open $filePath r} fd]} {
	set tail [file tail $filePath]
	tk_messageBox -icon error -title "Error" -message "Cannot read $tail : $fd"
	return
    }
    fconfigure $fd -encoding utf-8
    set xml [read $fd]
    set xmllist [tinydom::documentElement [tinydom::parse $xml]]
#puts "SVGFileToCmds: xmllist=$xmllist"    
    # Update the utags...
    set cmdList [svg2can::parsesvgdocument $xmllist \
      -imagehandler [list ::CanvasFile::SVGImageHandler $w] \
      -foreignobjecthandler [list ::CanvasUtils::SVGForeignObjectHandler $w]]

    return $cmdList
}

proc svg2can::cloneGrad {wcan grad canv} {
#wcan - холст с группой
#canv - новый холст для группы
#Клонируем градиент 
    set type [$wcan gradient type $grad]
    set cmd "$canv gradient create $type "
    foreach option [$wcan gradient configure $grad] {
	set optval [lindex $option 4]
	if {$optval != {}} {
	    lappend cmd [lindex $option 0] $optval
	} 
    }
#    puts "cloneGrad: cmd=$cmd"
    return [eval $cmd]
}


proc svg2can::copyGroup {wcan canv group {args ""}} {
#wcan - холст с группой
#canv - новый холст для группы
#args: -x - координата по X; -y - координата по Y
#-width - ширина группы; -height - высота группы; Но пока что-то не так....
    if {[$wcan type $group] != "group"} {
	return -1
    }
    foreach {x0 y0 x1 y1} [$wcan bbox $group] {break}
    set widthorig [expr {$x1 - $x0}]
    set heightorig [expr {$y1 - $y0}]
    set scalex 1
    set scaley 1
    if {$args != ""} {
	if {[ expr { [llength $args] % 2}] != 0} {
	    puts "copyGroup: bad length args=$args"
	    return -1
	}
	foreach {arg value} $args {
	    set value [winfo fpixels $canv $value]
	    switch -exact -- $arg {
		-x {
		    set x0 $value
		}
		-y {
		    set y0 $value
		}
		-width {
		    set width $value
		    set scalex [expr {$width / $widthorig}]
		}
		-height {
		    set height $value
		    set scaley [expr {$height / $heightorig}]
		}
		default {
		    puts "Bad args: arg=$arg"
		}
	    }
	}
    }
    set grnew [$canv create group -m [$wcan itemcget $group -m]]
    foreach item [$wcan children $group] {

	set command ""
	lappend command $canv create
	set type [$wcan type $item]
	if {$type == ""} {
	    puts "copyGroup: Bad svg group=$group item=$item canv=$canv wcan=$wcan"
	    continue
	}
	lappend command $type
	eval lappend command "\"[$wcan coords $item]\""
#Читаем аттрибуты
	set options [list]
	foreach conf [$wcan itemconfigure $item] {
	    if {[lindex $conf 0] == "-tags"} {continue}
	    if {[lindex $conf 0] == "-parent"} {continue}
	    set default [lindex $conf 3]
	    set value [lindex $conf 4]
	    if {[lindex $conf 0] == "-fill" && [string first "gradient" $value] == 0} {
#		set value [::svgwidget::cloneGrad $wcan $value $canv]
		set value [svg2can::cloneGrad $wcan $value $canv]
    		lappend options [lindex $conf 0] $value
	    } elseif {[string compare $default $value] != 0} {
    		lappend options [lindex $conf 0] $value
	    }
	}
	append command [subst " $options  -parent $grnew"]
#Создаем объект
	set copytag [eval $command]
	if {$copytag == ""} {return -1}
    }
#Масштабирование Группы
    foreach {width height xy} [$wcan itemcget $group -matrix] {
	foreach {w1 w0} $width {
	    set w1 [expr {$w1 * $scalex}]
	}
	foreach {h0 h1} $height {
	    set h1 [expr {$h1 * $scaley}]
	}
	$canv itemconfigure $grnew -matrix [list "$w1 $w0" "$h0 $h1" "$xy"]
    }
#Перемещение Группы
    foreach {width height xy} [$canv itemcget $grnew -matrix] {
	foreach {xm ym} $xy {
	    foreach {x1 y1 x2 y2} [$canv bbox $grnew] {
		set dx [expr {[winfo fpixels $wcan $x0] - $x1 }] 
		set dy [expr {[winfo fpixels $wcan $y0] - $y1 }]
		set x [expr {$xm + $dx}]
		set y [expr {$ym + $dy}]
	    }
	}
	$canv itemconfigure $grnew -matrix [list "$width" "$height" "$x $y"]
    }
    return $grnew
  }
#Радианы в градусы и наоборот
proc svg2can::radian2degre {radian} {
    set pi [expr {2 * asin(1)}]
    return [expr {$radian * 180.0 / $pi}]
}
proc svg2can::degre2radian {degre} {
    set pi [expr {2 * asin(1)}]
    return [expr {$degre * $pi / 180}]
}


proc svg2can::id2coordscenter {w id} {
#Координаты прямоугольника вокруг объекта
    foreach {x0 y0 x1 y1} [$w bbox $id] {break}
#точка вращения - центр
    set xc [expr {($x1 - $x0) / 2.0 + $x0 }]
    set yc [expr {($y1 - $y0) / 2.0 + $y0 }]
    return [list $xc $yc]
}

#Вернуть объект в исходное (угол поворота 0)
proc svg2can::id2angle0 {w id } {
#    if {[idissvg $id] == 0} {return}
    set m [list {1.0 0.0} {-0.0 1.0} {0.0 0.0}]
    $w itemconfigure $id -m $m
}
#Повернуть id на угол
proc svg2can::rotateid2angle {w id deg {retm 0}} {
    set pi [expr 2*asin(1)]
    set phi [expr {$deg * $pi / 180.0}]
#puts "rotateid2angle id=$id deg=$deg phi=$phi"
    set coors [svg2can::id2coordscenter $w $id]
#puts "rotateid2angle id=$id deg=$deg phi=$phi coors=$coors "
    foreach {xr yr} [svg2can::id2coordscenter $w $id] {break}
#    set m1 [::tkp::matrix rotate $phi [lindex $coors 0] [lindex $coors 1]]

#С КООРДИНАТАМИ ЛЕВОООГО ВЕРХНЕГО УГЛА
#foreach {xr  yr x1 y1} [.c bbox $id] {break}


    set m1 [::tkp::matrix rotate $phi $xr $yr]
	if {$retm != 0} {
	    return $m1
	}
#puts "rotateid2angle id=$id deg=$deg phi=$phi coors=$xr $yr m=$m1"
#Читаем что было
set mOrig [$w itemcget $id -m]
#puts "rotateid2angle: m1=$m1\n\tmOrig=$mOrig"
    if {$mOrig != ""} {
	    set m1 [::tkp::matrix mult $mOrig $m1]
#puts "rotateid2angle Full: m1=$m1\n\tmOrig=$mOrig"
    }

    $w itemconfigure $id -m $m1
#Новые координаты центра
    foreach {xrn yrn} [svg2can::id2coordscenter $w $id] {break}
#Перемещение по x и y
	foreach {width height xy} [$w itemcget $id -matrix] {
	    foreach {x y} $xy {
		set x [expr {$x + ($xr - $xrn)}]
		set y [expr {$y + ($yr - $yrn)}]
	    }
	    $w itemconfigure $id -matrix [list "$width" "$height" "$x $y"]
	}


    return
}

proc svg2can::parsepath {d} {
	set i 0
	set len [string length $d]
	set dpath ""
	while {$i < $len} {
	    set ss [string range $d $i $i]
	    if {$ss == ","} {
		append dpath " "
	    } elseif {$ss == "-"} {
		append dpath "  $ss"
	    } elseif {$ss == "\\"} {
		append dpath "  "
	    } elseif {[string is alpha $ss]} {
		append dpath " $ss "
	    } else {
		append dpath "$ss"
	    }
	    incr i
	}
    return "$dpath"
}
