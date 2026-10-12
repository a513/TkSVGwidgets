#  tinyfileutils.tcl ---
#  
#      A collection of some small file utility procedures.
#      
#  Copyright (c) 2002-2003  Mats Bengtsson
#  
#  This file is distributed under BSD style license.
#  
# $Id: tinyfileutils.tcl,v 1.11 2008-02-28 07:51:25 matben Exp $
#
#  In 2026, Vladimir Orlov added support for saving SVG objects to SVG files (XML code): 
#       can2svg::can2xmlfile.

package provide tinyfileutils 1.0


namespace eval ::tfileutils:: {}

# tfileutils::relative --
#
#       Constructs the relative file path from one absolute path to
#       another absolute path.
#
# Arguments:
#       srcpath        An absolute file path.
#	dstpath        An absolute file path.
#       
# Results:
#       The relative (unix-style) path from 'srcpath' to 'dstpath'.

proc ::tfileutils::relative {srcpath dstpath} {
    global  tcl_platform

    if {![string equal [file pathtype $srcpath] "absolute"]} {
	return -code error "::tfileutils::relative: the path \"$srcpath\" is not of type absolute"
    }
    if {![string equal [file pathtype $dstpath] "absolute"]} {
	return -code error "::tfileutils::relative: the path \"$dstpath\" is not of type absolute"
    }

    # Need real path without any file for the source path.
    set srcpath [getdirname $srcpath]
    set up {../}
    set srclist [file split $srcpath]
    set dstlist [file split $dstpath]
    
    # Must get rid of the extra ":" volume specifier on mac.
    if {[string equal $tcl_platform(platform) "macintosh"]} {
	set srclist [lreplace $srclist 0 0  \
	  [string trimright [lindex $srclist 0] :]]
	set dstlist [lreplace $dstlist 0 0  \
	  [string trimright [lindex $dstlist 0] :]]
    }
    set lensrc [llength $srclist]
    set lendst [llength $dstlist]
    set minlen [expr {($lensrc < $lendst) ? $lensrc : $lendst}]

    # Find first nonidentical dir; n = the number of common dirs
    # If there are no common dirs we are left with n = 0???    
    set n 0
    while {[string equal [lindex $srclist $n] [lindex $dstlist $n]] && \
      ($n < $minlen)} {
	incr n
    }
    set numUp [expr {$lensrc - $n}]
    set tmp {}
    for {set i 1} {$i <=$numUp} {incr i} {
	append tmp $up
    }
    return "${tmp}[join [lrange $dstlist $n end] /]"
}

# tfileutils::unixpath --
#
#       Translatates a native path type to a unix style.
#
# Arguments:
#       path        
#       
# Results:
#       The unix-style path of path.

proc ::tfileutils::unixpath {path} {
    global  tcl_platform
    
    set isabs [string equal [file pathtype $path] "absolute"]
    set plist [file split $path]
	
    # The volume specifier always leaves a ":"; {Macintosh HD:}
    if {$isabs && [string equal $tcl_platform(platform) "macintosh"]} {
	set volume [string trimright [lindex $plist 0] ":"]
	set plist [lreplace $plist 0 0 $volume]
    }
    set upath [join $plist /]
    if {$isabs} {
	set upath "/$upath"
    }
    return $upath
}

# Perhaps this could be replaced by [file normalize [file join ...]] ???

# addabsolutepathwithrelative ---
#
#       Adds the second, relative path, to the first, absolute path.
#       Always returns unix style absolute path.
#           
# Arguments:
#       absPath        an absolute path which is the "original" path.
#       toPath         a relative path which should be added.
#       
# Results:
#       The absolute unix style path by adding 'absPath' with 'relPath'.

proc addabsolutepathwithrelative {absPath relPath} {
    global  tcl_platform
    
    set state(debug) 0
    if {$state(debug) >= 3} {
	puts "addabsolutepathwithrelative:: absPath=$absPath, relPath=$relPath"
    }

    # Be sure to strip off any filename of the absPath.
    set absPath [getdirname $absPath]
    if {[file pathtype $absPath] != "absolute"} {
	error "first path must be an absolute path"
    } elseif {[file pathtype $relPath] != "relative"} {
	error "second path must be a relative path"
    }

    # This is the method to reach platform independence.
    # We must be sure that there are no path separators left.    
    set absP {}
    foreach elem [file split $absPath] {
	lappend absP [string trim $elem "/:\\"]
    }
    
    # If any up dir (../ ::  ), find how many. Only unix style.
    set nup [regsub -all {\.\./} $relPath {} newRelPath]
    # Mac???
    #set nup [expr {[regsub -all : $part "" x] - 1}]
   
    # Delete the same number of elements from the end of the absolute path
    # as there are up dirs in the relative path.    
    if {$nup > 0} {
	set iend [expr {[llength $absP] - 1}]
	set upAbsP [lreplace $absP [expr {$iend - $nup + 1}] $iend]
    } else {
	set upAbsP $absP
    }
    set relP {}
    foreach elem [file split $newRelPath] {
	lappend relP [string trim $elem "/:\\"]
    }
    set completePath "$upAbsP $relP"

    # On Windows we need special treatment of the "C:/" type drivers.
    if {[string equal $tcl_platform(platform) "windows"]} {
    	set finalAbsPath   \
	    "[lindex $completePath 0]:/[join [lrange $completePath 1 end] "/"]"
    } else {
        set finalAbsPath "/[join $completePath "/"]"
    }
    return $finalAbsPath
}

# tfileutils::appendfile --
#
#       Adds the second, relative path, to the first, absolute path.
#           
# Arguments:
#       dstFile     the destination file name
#       args        the files to append
#       
# Results:
#       none

proc ::tfileutils::appendfile {dstFile args} {
    
    set dst [open $dstFile {WRONLY APPEND}]
    fconfigure $dst -translation binary
    foreach f $args {
	set src [open $f RDONLY]
	fconfigure $src -translation binary
	fcopy $src $dst
	close $src
    }
    close $dst
}

# tfileutils::tempfile --
#
#   generate a temporary file name suitable for writing to
#   the file name will be unique, writable and will be in the 
#   appropriate system specific temp directory
#   Code taken from http://mini.net/tcl/772 attributed to
#    Igor Volobouev and anon.
#
# Arguments:
#   prefix     - a prefix for the filename, p
# Results:
#   returns a file name
#

proc ::tfileutils::tempfile {tmpdir {prefix {}}} {
    return [file normalize [TempFile $tmpdir $prefix]]
}

proc ::tfileutils::TempFile {tmpdir prefix} {

    set chars "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    set nrand_chars 10
    set maxtries 10
    set access [list RDWR CREAT EXCL TRUNC]
    set permission 0600
    set channel ""
    set checked_dir_writable 0

    for {set i 0} {$i < $maxtries} {incr i} {
	set newname $prefix
	for {set j 0} {$j < $nrand_chars} {incr j} {
	    append newname [string index $chars \
		    [expr {int(rand()*62)}]]
	}
	set newname [file join $tmpdir $newname]
	if {[file exists $newname]} {
	    after 1
	} else {
	    if {[catch {open $newname $access $permission} channel]} {
		if {!$checked_dir_writable} {
		    set dirname [file dirname $newname]
		    if {![file writable $dirname]} {
			return -code error "Directory $dirname is not writable"
		    }
		    set checked_dir_writable 1
		}
	    } else {
		# Success
		close $channel
		return $newname
	    }
	}
    }
    if {[string compare $channel ""]} {
	return -code error "Failed to open a temporary file: $channel"
    } else {
	return -code error "Failed to find an unused temporary file name"
    }
}

# tfileutils::deleteallfiles --
# 
#       Deletes all files in a directory but keeps the directory.

proc ::tfileutils::deleteallfiles {dir {pattern *}} {
    set files [eval {glob -nocomplain -directory $dir} -- $pattern]
    if {[llength $files]} {
	eval {file delete -force} $files
    }
}

#------------------------------------------------------------------------------


# uriencode.tcl --
#
#	Encoding of uri's and file names. Some code from tcllib.
#     Parts: Copyright (C) 2001 Pat Thoyts <Pat.Thoyts@bigfoot.com>
# 	extend the uri package to deal with URN (RFC 2141)
# 	see http://www.normos.org/ietf/rfc/rfc2141.txt
# 	
# $Id: uriencode.tcl,v 1.5 2008-02-10 09:43:21 matben Exp $

package require uri::urn

package provide uriencode 1.0

namespace eval uriencode {}

# uriencode::quotepath --
# 
#	Need to carefully avoid encoding any / in volume specifiers.
#	/root/...  or C:/disk/...
#       Always return path using unix separators "/"

proc uriencode::quotepath {path} {
    
    set isrel [string equal [file pathtype $path] "relative"]

    if {!$isrel} {
	
	# An absolute path. 
	# Be sure to get rid of unix style "/" and windows "C:/"
  	set plist [file split [string trimleft $path /]]
	set qpath [::uri::urn::quote [string trimright [lindex $plist 0] /]]
	foreach str [lrange $plist 1 end] {
	    lappend qpath [::uri::urn::quote $str]
	}	
    } else {
	
	# A relative path.
	set qpath [list]
	foreach str [file split $path] {
	    lappend qpath [::uri::urn::quote $str]
	}
    }
    
    # Build unix style path
    set qpath [join $qpath /]
    if {!$isrel} {
	set qpath "/$qpath"
    }
    return $qpath
}

proc uriencode::quoteurl {url} {

    # Only the file path part shall be encoded.
    if {![regexp {([^:]+://[^:/]+(:[0-9]+)?)(/.*)} $url  \
	match prepath x path]} {
	return -code error "Is not a valid url: $url"
    }
    set path [string trimleft $path /]
    return "${prepath}/[uriencode::quotepath $path]"
}

proc uriencode::decodefile {file} {
    return [::uri::urn::unquote $file]
}

proc uriencode::decodeurl {url} {
    return [::uri::urn::unquote $url]
}

#-----------------------------------------------------------------------


#  can2svg.tcl ---
#  
#      This file provides translation from canvas commands to XML/SVG format.
#      
#  Copyright (c) 2002-2007  Mats Bengtsson
#  
#  This file is distributed under BSD style license.
#
# $Id: can2svg.tcl,v 1.26 2008-01-27 08:19:36 matben Exp $
# 
# ########################### USAGE ############################################
#
#   NAME
#      can2svg - translate canvas command to SVG.
#      
#   SYNOPSIS
#      can2svg canvasCmd ?options?
#           canvasCmd is everything except the widget path name.
#           
#      can2svg::can2xmlfile widgetPath fileName lid ?options?
#           widgetPath:		the canvas widget path
#           fileName:    	the file path or "xmldata"
#	    lid			list of object IDs on the canvas or "all"    
#           options:   -height
#                      -width
#
#      can2svg::can2svg canvasCmd ?options?
#           options:    -httpbasedir        path
#                       -imagehandler       tclProc
#                       -ovalasellipse      0|1
#                       -reusedefs          0|1
#                       -uritype            file|http
#                       -usestyleattribute  0|1
#                       -usetags            0|all|first|last
#                       -windowitemhandler  tclProc
#
#      can2svg::config ?options?
#           options:        -allownewlines      0
#                        -filtertags         ""
#                        -httpaddr           localhost
#                        -ovalasellipse      0
#                        -reusedefs          1
#                        -uritype            file
#                        -usetags            all
#                        -usestyleattribute  1
#                       -windowitemhandler  tclProc
#
# ########################### CHANGES ##########################################
#
#   0.1      first release
#   0.2      URI encoded image file path
#   0.3      uses xmllists more, added svgasxmllist
#
# ########################### TODO #############################################
# 
#   handle units (m->mm etc.) 
#   better support for stipple patterns
#   how to handle tk editing? DOM?
#   
#   ...

# We need URN encoding for the file path in images. From my whiteboard code.

package require uriencode
package require tinyfileutils

package provide can2svg 0.3


namespace eval can2svg {

    namespace export can2svg can2xmlfile
    
    variable wcan
    variable confopts
    array set confopts {
        -allownewlines        0
        -filtertags           ""
        -httpaddr             localhost
        -ovalasellipse        0
        -reusedefs            0
        -uritype              file
        -usetags              all
        -usestyleattribute    1
        -windowitemhandler    ""
    }

    set confopts(-httpbasedir) [info script]
    
    variable formatArrowMarker
    variable formatArrowMarkerLast
    
    # The key into this array is 'arrowMarkerDef_$col_$a_$b_$c', where
    # col is color, and a, b, c are the arrow's shape.
    variable defsArrowMarkerArr

    # Similarly for stipple patterns.
    variable defsStipplePatternArr

    # This shouldn't be hardcoded!
    variable defaultFont {Helvetica 12}

    variable pi 3.14159265359
    variable anglesToRadians [expr $pi/180.0]
    variable grayStipples {gray75 gray50 gray25 gray12}
        
    # Make 4x4 squares. Perhaps could be improved.
    variable stippleDataArr
    
    set stippleDataArr(gray75)  \
      {M 0 0 h3  M 0 1 h1 M 2 1 h2
       M 0 2 h3  M 0 3 h1 M 2 3 h1}
    set stippleDataArr(gray50)  \
      {M 0 0 h1 M 2 0 h1  M 1 1 h1 M 3 1 h1
       M 0 2 h1 M 2 2 h1  M 1 3 h1 M 3 3 h1}
    set stippleDataArr(gray25)  \
      {M 3 0 h1 M 1 1 h1 M 3 2 h1 M 1 3 h1}
    set stippleDataArr(gray12)  \
      {M 1 1 h1 M 3 3 h1}
    
}


proc can2svg::config {args} {
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

# can2svg::can2svg --
#
#       Make xml out of a canvas command, widgetPath removed.
#       
# Arguments:
#       cmd         canvas create commands without prepending widget path.
#       args    -httpbasedir        path
#               -imagehandler       tclProc
#               -ovalasellipse      0|1
#               -reusedefs          0|1
#               -uritype            file|http
#               -usestyleattribute  0|1
#               -usetags            0|all|first|last
#       
# Results:
#   xml data

proc can2svg::can2svg {cmd args} {

    set xml ""
    foreach xmllist [eval {svgasxmllist $cmd} $args] {
        append xml [MakeXML $xmllist]
    }
    return $xml
}

# can2svg::svgasxmllist --
#
#       Make a list of xmllists out of a canvas command, widgetPath removed.
#       
# Arguments:
#       cmd         canvas create command without prepending widget path.
#       args    -httpbasedir        path
#               -imagehandler       tclProc
#               -ovalasellipse      0|1
#               -reusedefs          0|1
#               -uritype            file|http
#               -usestyleattribute  0|1
#               -usetags            0|all|first|last
#       
# Results:
#       a list of xmllist = {tag attrlist isempty cdata {child1 child2 ...}}

proc can2svg::svgasxmllist {cmd args} {
    
    variable confopts
    variable defsArrowMarkerArr
    variable defsStipplePatternArr
    variable defaultFont
    variable grayStipples
        
    set nonum_ {[^0-9]}
    set wsp_ {[ ]+}
    set xmlLL [list]
    
    array set argsA [array get confopts]
    array set argsA $args
    set args [array get argsA]
    
    if {![string equal [lindex $cmd 0] "create"]} {
        return
    }
    
    set type [lindex $cmd 1]
    set rest [lrange $cmd 2 end]
    
    # Separate coords from options.
    set indopt [lsearch -regexp $rest "-${nonum_}"]
    if {$indopt < 0} {
        set ind end
        set opts [list]
    } else {
        set ind [expr $indopt - 1]
        set opts [lrange $rest $indopt end]
    }
    
    # Flatten coordinate list!
    set coo [lrange $rest 0 $ind]
    if {[llength $coo] == 1} {
        set coo [lindex $coo 0]
    }
    array set optA $opts
    
    # Is the item in normal state? If not, return.
    if {[info exists optA(-state)] && $optA(-state) != "normal"} {
        return
    }
    
    # Figure out if we've got a spline.
    set haveSpline 0
    if {[info exists optA(-smooth)] && ($optA(-smooth) != "0") &&  \
      [info exists optA(-splinesteps)] && ($optA(-splinesteps) > 2)} {
        set haveSpline 1
    }
    if {[info exists optA(-fill)]} {
        set fillValue $optA(-fill)
#ORLOV
	if {[can2svg::filltype $fillValue] == "gradient"} {
	    set gradientValue $fillValue
	} else {
    	    if {![regexp {#[0-9]+} $fillValue]} {
        	set fillValue [FormatColorName $fillValue]
    	    }
        }
    } else {
        set fillValue black
    }
    if {[string length $argsA(-filtertags)] && [info exists optA(-tags)]} {
        set tag [uplevel #0 $argsA(-filtertags) [list $optA(-tags)]]
        set idAttr [list id $tag]
    } elseif {($argsA(-usetags) != "0") && [info exists optA(-tags)]} {
        
        # Remove any 'current' tag.
        set optA(-tags) \
          [lsearch -all -not -inline $optA(-tags) current]
        
        switch -- $argsA(-usetags) {
            all {                        
                set idAttr [list id $optA(-tags)]
            }
            first {
                set idAttr [list id [lindex $optA(-tags) 0]]
            }
            last {
                set idAttr [list id [lindex $optA(-tags) end]]
            }
        }
    } else {
        set idAttr ""
    }
    
#ORLOV fill - Gradient
    if {[info exists gradientValue]} {
	    set ret [can2svg::MakeGradientDef $gradientValue]
            set xmlLL [concat $xmlLL $ret]
    }    

    # If we need a marker (arrow head) need to make that first.
    if {[info exists optA(-arrow)] && ![string equal $optA(-arrow) "none"]} {
        if {[info exists optA(-arrowshape)]} {
            
            # Make a key of the arrowshape list into the array.
            regsub -all -- $wsp_ $optA(-arrowshape) _ shapeKey
            set arrowKey ${fillValue}_${shapeKey}
            set arrowShape $optA(-arrowshape)
#ORLOV
            set arrowShapeEnd $optA(-arrowshape)
        } else {
            set arrowKey ${fillValue}
            set arrowShape {8 10 3}
            set arrowShapeEnd {8 10 3}
        }
        if {!$argsA(-reusedefs) || \
          ![info exists defsArrowMarkerArr($arrowKey)]} {

            set defsArrowMarkerArr($arrowKey)  \
              [eval {MakeArrowMarker} $arrowShape $arrowShapeEnd {$fillValue}  $optA(-width)]
#              [eval {MakeArrowMarker} $arrowShape {$fillValue}]
            set xmlLL [concat $xmlLL $defsArrowMarkerArr($arrowKey)]
        }
    } elseif {[info exists optA(-startarrow)] && ( $optA(-startarrow) > 0 || $optA(-endarrow) > 0)} {
            set arrowKey [lrange $optA(-stroke) 1 end]
	    set pq "[expr {int ($optA(-startarrowlength) / $optA(-startarrowfill))}].0"
            set arrowShape {$optA(-startarrowlength) $pq  $optA(-startarrowwidth)}
	    set pq1 "[expr {int ($optA(-endarrowlength) / $optA(-endarrowfill))}].0"
            set arrowShapeEnd {$optA(-endarrowlength) $pq1  $optA(-endarrowwidth)}
            set fillValue $optA(-stroke)
        if {!$argsA(-reusedefs) || 1 || \
          ![info exists defsArrowMarkerArr($arrowKey)]} {
            set defsArrowMarkerArr($arrowKey)  \
              [eval {MakeArrowMarker} $arrowShape $arrowShapeEnd {$fillValue} $optA(-strokewidth)]
            set xmlLL \
              [concat $xmlLL $defsArrowMarkerArr($arrowKey)]
        }
    }

    # If we need a stipple bitmap, need to make that first. Limited!!!
    # Only: gray12, gray25, gray50, gray75
    foreach key {-stipple -outlinestipple} {
        if {[info exists optA($key)] &&  \
          ([lsearch $grayStipples $optA($key)] >= 0)} {
            set stipple $optA($key)
            if {![info exists defsStipplePatternArr($stipple)]} {
                set defsStipplePatternArr($stipple)  \
                  [MakeGrayStippleDef $stipple]
            }
            lappend xmlLL $defsStipplePatternArr($stipple)
        }
    }
#    puts "can2svg::svgasxmllist cmd=$cmd, args=$args"
    
    switch -- $type {
        
        arc {
            
            # Had to do it the hard way! (?)
            # "Wrong" coordinate system :-(
            set attr [CoordsToAttr $type $coo $opts elem]            
            if {[string length $idAttr] > 0} {
                set attr [concat $attr $idAttr]
            }
            set attr [concat $attr [MakeAttrList \
              $type $opts $argsA(-usestyleattribute)]]
            lappend xmlLL [MakeXMLList $elem -attrlist $attr]
        }
	pimage -
        bitmap - image {
            if {[info exists optA(-image)]} {
                set elem "image"
                set attr [eval {MakeImageAttr $coo $opts} $args]
                if {[string length $idAttr] > 0} {
                    set attr [concat $attr $idAttr]
                }
                set subEs [list]
                if {[info exists argsA(-imagehandler)]} {
                    set subE [uplevel #0 $argsA(-imagehandler) [list $cmd] $args]
                    if {[llength $subE]} {
                        set subEs [list $subE]
                    }
                }
#ORLOV
#Масштабирование асинхронное срабатывает только в Konqueror
#На google-chrome не срабатывает
#            set argsA(-usestyleattribute) 1
		if {$type == "pimage"} {
        	    set gtrans ""
        	    if {[info exists optA(-matrix)]} {
        		set a [lindex [lindex $optA(-matrix) 0] 0]
        		set b [lindex [lindex $optA(-matrix) 0] 1]
        		set c [lindex [lindex $optA(-matrix) 1] 0]
        		set d [lindex [lindex $optA(-matrix) 1] 1]
        		set e [lindex [lindex $optA(-matrix) 2] 0]
        		set f [lindex [lindex $optA(-matrix) 2] 1]
			set val " matrix($a $b $c $d $e $f)"
			append gtrans $val
        	    }
            	    lappend attr "transform" $gtrans
        	    if {[info exists optA(-fillopacity)]} {
			set val " opacity : $optA(-fillopacity)"
            	    lappend attr "style" $val
        	    }
		}
                lappend xmlLL [MakeXMLList $elem -attrlist $attr -subtags $subEs]
            }
        }
        line {
            set attr [CoordsToAttr $type $coo $opts elem]            
            if {[string length $idAttr] > 0} {
                set attr [concat $attr $idAttr]
            }                    
            set attr [concat $attr [MakeAttrList \
              $type $opts $argsA(-usestyleattribute)]]
            lappend xmlLL [MakeXMLList $elem -attrlist $attr]
        }
        oval {
            set attr [CoordsToAttr $type $coo $opts elem]            
            foreach {x y w h} [NormalizeRectCoords $coo] break
            if {[expr $w == $h] && !$argsA(-ovalasellipse)} {
                # set elem "circle";# circle needs an r: not an rx & ry
                set elem "ellipse"
            } else {
                set elem "ellipse"
            }
            if {[string length $idAttr] > 0} {
                set attr [concat $attr $idAttr]
            }
            set attr [concat $attr [MakeAttrList \
              $type $opts $argsA(-usestyleattribute)]]
            lappend xmlLL [MakeXMLList $elem -attrlist $attr]
        }
        polygon {
            set attr [CoordsToAttr $type $coo $opts elem]            
            if {[string length $idAttr] > 0} {
                set attr [concat $attr $idAttr]
            }
            set attr [concat $attr [MakeAttrList \
              $type $opts $argsA(-usestyleattribute)]]
            lappend xmlLL [MakeXMLList $elem -attrlist $attr]
        }
        rectangle {
	    set elem "rect"
            set attr [CoordsToAttr $type $coo $opts elem]            
            if {[string length $idAttr] > 0} {
                set attr [concat $attr $idAttr]
            }
            set attr [concat $attr [MakeAttrList $type $opts $argsA(-usestyleattribute)]]
            lappend xmlLL [MakeXMLList $elem -attrlist $attr]
        }
	ptext -
        text {
            set elem "text"
            set chdata ""
            set nlines 1
#ORLOV 
	    if {$type == "ptext"} {
		set optA(-font) "\"$optA(-fontfamily)\" [expr {int ($optA(-fontsize))}] $optA(-fontweight)"
		set optA(-anchor) $optA(-textanchor)
		if {$optA(-anchor) == "c"} {
		    set optA(-anchor) "center"
		}
		set optA(-width) 0
                if {[info exists optA(-matrix)]} {
#Число pi
		    set pi [expr 2*asin(1)]
		    set pangle [lindex [lindex $optA(-matrix) 0] 1]
		    set optA(-angle) [expr {360 - asin($pangle) * 180 / $pi}]
		}
	    }

            if {[info exists optA(-font)]} {
                set theFont $optA(-font)
            } else {
                set theFont $defaultFont
            }
            set ascent [font metrics $theFont -ascent]
            set lineSpace [font metrics $theFont -linespace]
            if {[info exists optA(-text)]} {
                set chdata $optA(-text)
                
                if {[info exists optA(-width)]} {
                    
                    # MICK O'DONNELL: if the text is wrapped in the wgt, we need
                    # to simulate linebreaks
                    # 
                    # If the item has got -width != 0 then we must wrap it ourselves
                    # using newlines since the -text does not have extra newlines
                    # at these linebreaks.
                    set lines [split $chdata \n]
                    set newlines {}
                    foreach line $lines {
                        set lines2 [SplitWrappedLines $line $theFont $optA(-width)]
                        set newlines [concat $newlines $lines2]
                    }
                    set chdata [join $newlines \n]
                    if {!$argsA(-allownewlines) || \
                      ([llength $newlines] > [llength $lines])} {
                        set nlines [expr [regexp -all "\n" $chdata] + 1]
                    }
                } else {
                    if {!$argsA(-allownewlines)} {
                        set nlines [expr [regexp -all "\n" $chdata] + 1]
                    }
                }
            }
            
            # Figure out the coords of the first baseline.
            set anchor center
            if {[info exists optA(-anchor)]} {
                set anchor $optA(-anchor)
            }                                        
            
            foreach {xbase ybase}  \
              [GetTextSVGCoords $coo $anchor $chdata $theFont $nlines] {}
#ORLOV это не соисем правильно
if {$xbase < 0} {set xbase 0}

            set attr [list "x" $xbase "y" $ybase]
            # angle is negated in order to fit 
            # canvas coordinate system
	    if {$type == "text"} {
        	if {[info exists optA(-angle)]} {
            	    set ang [expr {-1.0*$optA(-angle)}]
#Точку поворота берём из coo
#                set val "rotate($ang $xbase,$ybase)"
            	    set val "rotate($ang [lindex $coo 0], [lindex $coo 1])"

            	    lappend attr "transform" $val
        	}
	    } else {
        	set gtrans ""

        	if {[info exists optA(-matrix)]} {
        	    set a [lindex [lindex $optA(-matrix) 0] 0]
        	    set b [lindex [lindex $optA(-matrix) 0] 1]
        	    set c [lindex [lindex $optA(-matrix) 1] 0]
        	    set d [lindex [lindex $optA(-matrix) 1] 1]
        	    set e [lindex [lindex $optA(-matrix) 2] 0]
        	    set f [lindex [lindex $optA(-matrix) 2] 1]
		    set val " matrix($a $b $c $d $e $f)"
		    append gtrans $val
        	}
            	lappend attr "transform" $gtrans
	    }

            if {[string length $idAttr] > 0} {
                set attr [concat $attr $idAttr]
            }
            set attr [concat $attr [MakeAttrList $type $opts $argsA(-usestyleattribute)]]
            set dy 0
            if {$nlines > 1} {
                
                # Use the 'tspan' trick here.
                set subList {}
                foreach line [split $chdata "\n"] {
                    lappend subList [MakeXMLList "tspan"  \
                      -attrlist [list "x" $xbase "dy" $dy] -chdata $line]
                    set dy $lineSpace
                }
                lappend xmlLL [MakeXMLList $elem -attrlist $attr \
                  -subtags $subList]
            } else {
                lappend xmlLL [MakeXMLList $elem -attrlist $attr \
                  -chdata $chdata]
            }
        }
        window {
            # There is no svg for this; must be handled by application layer.            
            #puts "window: $cmd"
            if {[string length $argsA(-windowitemhandler)]} {
                set xmllist \
                  [uplevel #0 $argsA(-windowitemhandler) [list $cmd] $args]
                if {[llength $xmllist]} {
                    lappend xmlLL $xmllist
                }
            }
        }
        ptextXA -
	circle -
        ellipse -
	ppolygon -
	prect -
	polyline -
        path {
    	    variable groupX
    	    variable groupY
#	    puts "can2svg::svgasxmllist typePATH=$type:\ncoo=$coo \nopts=$opts  "
            if {[info exists optA(-matrix)]} {
#Число pi
		    set pi [expr 2*asin(1)]
		    set pangle [lindex [lindex $optA(-matrix) 0] 1]
		    set optA(-angle) [expr {360 - asin($pangle) * 180 / $pi}]
#puts "P=$type  MATRIX yes угол=$optA(-angle)"
	    }

            set attr [CoordsToAttr $type $coo $opts elem]            
            if {[string length $idAttr] > 0} {
                set attr [concat $attr $idAttr]
            }
            set gtrans ""
            if {[info exists groupX]} {
#        	set gtrans " translate([expr {-1.0 * $groupX}], [expr {-1.0 * $groupY}]) "
	    }

            if {[info exists optA(-matrix)]} {
        	set a [lindex [lindex $optA(-matrix) 0] 0]
        	set b [lindex [lindex $optA(-matrix) 0] 1]
        	set c [lindex [lindex $optA(-matrix) 1] 0]
        	set d [lindex [lindex $optA(-matrix) 1] 1]
        	set e [lindex [lindex $optA(-matrix) 2] 0]
        	set f [lindex [lindex $optA(-matrix) 2] 1]
		set val " matrix($a $b $c $d $e $f)"
		append gtrans $val
            }
                lappend attr "transform" $gtrans


            set argsA(-usestyleattribute) 1
            set attr [concat $attr [MakeAttrList $type $opts $argsA(-usestyleattribute)]]

            lappend xmlLL [MakeXMLList $elem -attrlist $attr]
        }
        default {
	    puts "can2svg::svgasxmllist: unknown type=$type"
        }
    }
    return $xmlLL
}

# can2svg::CoordsToAttr --
#
#       Makes a list of attributes corresponding to type and coords.
#       
# Arguments:
#
#       
# Results:
#       a list of attributes.

proc can2svg::CoordsToAttr {type coo opts svgElementVar} {
    variable wcan
    upvar $svgElementVar elem 

    array set optA $opts
    
    # Figure out if we've got a spline.
    set haveSpline 0
    if {[info exists optA(-smooth)] && ($optA(-smooth) != "0") &&  \
      [info exists optA(-splinesteps)] && ($optA(-splinesteps) > 2)} {
        set haveSpline 1
    }
    set attr {}

    switch -- $type {
        arc {
            set elem "path"
            set data [MakeArcPath $coo $opts]
            set attr [list "d" $data]
        }
        bitmap - image {
            array set __optA $opts
            if {[info exists __optA(-image)]} {
                set elem "image"
                set attr [ImageCoordsToAttr $coo $opts]
            }
        }
        line {
            if {$haveSpline} {
                set elem "path"
                set data [ParseSplineToPath $type $coo]
                set attr [list "d" $data]
            } else {
                set elem "polyline"
                set attr [list "points" $coo]
            }   
        }
        oval {
            
            # Assume SVG ellipse.
            set elem "ellipse"
            foreach {x y w h} [NormalizeRectCoords $coo] break
            set attr [list  \
              "cx" [expr $x + $w/2.0] "cy" [expr $y + $h/2.0]  \
              "rx" [expr $w/2.0]      "ry" [expr $h/2.0]]
        }
        polygon {
            if {$haveSpline} {
                set elem "path"
                set data [ParseSplineToPath $type $coo]
                set attr [list "d" $data]
            } else {
                set elem "polygon"
                set attr [list "points" $coo]
            }
        }
        rectangle {
            set elem "rect"
            foreach {x y w h} [NormalizeRectCoords $coo] break
            set attr [list "x" $x "y" $y "width" $w "height" $h]
        }
        text {
            set elem "text"
            # ?
        }
        ptext {
            set elem "text"
#puts "PTEXT coo=$coo"
            foreach {x y} $coo break
            set attr [list x $x y $y]
            # ?
        }
	prect {
            set elem "rect"
	    set indu [lsearch $optA(-tags) utag*]
	    set tektag [lindex $optA(-tags) $indu]
puts "PRECT coo=$coo indu=\"$indu\" tektag=\"$tektag\""
	    foreach {xx1 yy1 xx2 yy2} [$wcan bbox $tektag] {break}
            foreach {x y w h} [NormalizeRectCoords [$wcan coords $tektag]] break
#Выбрать rx и ry и убрать их из coo
            set attr [list "x" $x "y" $y "width" $w "height" $h "rx" $optA(-rx) "ry" $optA(-rx)]
        }
	polyline {
            set elem "polyline"
	    if {$optA(-strokewidth) > $optA(-startarrowwidth)} {
		foreach {x0 y0 x1 y1} $coo {break} 
		set sdvig [expr {$optA(-startarrowlength) / 2.0}]
		set x0 [expr {$x0 + $sdvig}]
		set x1 [expr {$x1 - $sdvig}]
        	set attr [list "points" "$x0 $y0 $x1 $y1"]
	    } else {
        	set attr [list "points" $coo]
	    }
#puts "can2svg::CoordsToAttr: POLYLINE coo=$coo  attr=$attr $optA(-strokewidth) > $optA(-startarrowwidth)"
        }
	ellipse {
            set elem "ellipse"
#######################
		set indu [lsearch $optA(-tags) utag*]
		set tektag [lindex $optA(-tags) $indu]
		foreach {xx1 yy1 xx2 yy2} [$wcan bbox $tektag] {break}
        	set attr [list "cx" [lindex $coo 0] "cy" [lindex $coo 1] "rx" $optA(-rx) "ry" $optA(-ry)]
	}
	circle {
            set elem "ellipse"
            set attr [list "cx" [lindex $coo 0] "cy" [lindex $coo 1] "rx" $optA(-rx) "ry" $optA(-rx)]
	}
	ppolygon {
            set elem "polygon"
            set attr [list "points" $coo]
#puts "can2svg::CoordsToAttr:  attr=$attr $optA(-strokewidth) > $optA(-startarrowwidth)"
        }
        path {
            set elem "path"
            set attr [list "d" $coo]
        }
        default {
	    puts "can2svg::CoordsToAttr: unknown type=$type"
        }
    }
    return $attr
}

# can2svg::MakeArcPath --
# 
#       Makes a path using A commands from an arc.
#       Conversion from center to endpoint parameterization.
#       From: http://www.w3.org/TR/2003/REC-SVG11-20030114

proc can2svg::MakeArcPath {coo opts} {
    
    variable anglesToRadians
    variable pi

    # Canvas defaults.
    array set optA {
        -extent 90
        -start  0
        -style  pieslice
    }
    array set optA $opts

    # Extract center and radius from bounding box.
    foreach {x1 y1 x2 y2} $coo break
    set cx [expr ($x1 + $x2)/2.0]
    set cy [expr ($y1 + $y2)/2.0]
    set rx [expr abs($x1 - $x2)/2.0]
    set ry [expr abs($y1 - $y2)/2.0]

    set start  [expr $anglesToRadians * $optA(-start)]
    set extent [expr $anglesToRadians * $optA(-extent)]

    # NOTE: direction of angles are opposite for Tk and SVG!    
    set theta1 [expr -1*$start]
    set delta  [expr -1*$extent]
    set theta2 [expr $theta1 + $delta]
    set phi 0.0

    # F.6.4 Conversion from center to endpoint parameterization.
    set x1 [expr $cx + $rx * cos($theta1) * cos($phi) -  \
      $ry * sin($theta1) * sin($phi)]
    set y1 [expr $cy + $rx * cos($theta1) * sin($phi) +  \
      $ry * sin($theta1) * cos($phi)]
    set x2 [expr $cx + $rx * cos($theta2) * cos($phi) -  \
      $ry * sin($theta2) * sin($phi)]
    set y2 [expr $cy + $rx * cos($theta2) * sin($phi) +  \
      $ry * sin($theta2) * cos($phi)]
    
    set fa [expr {abs($delta) > $pi} ? 1 : 0]
    set fs [expr {$delta > 0.0} ? 1 : 0]
    
    set data [format "M %.1f %.1f A" $x1 $y1]
    append data [format " %.1f %.1f %.1f %1d %1d %.1f %.1f"  \
      $rx $ry $phi $fa $fs $x2 $y2]
    
    switch -- $optA(-style) {
        arc {
            # empty.
        }
        chord {
            append data " Z"
        }
        pieslice {
            append data [format " L %.1f %.1f Z" $cx $cy]
        }
    }
    return $data
}

# can2svg::MakeArcPathNonA --
# 
#       Makes a path without any A commands from an arc.

proc can2svg::MakeArcPathNonA {coo opts} {

    variable anglesToRadians

    array set optA $opts
    
    foreach {x1 y1 x2 y2} $coo break
    set cx [expr ($x1 + $x2)/2.0]
    set cy [expr ($y1 + $y2)/2.0]
    set rx [expr abs($x1 - $x2)/2.0]
    set ry [expr abs($y1 - $y2)/2.0]
    set rmin [expr $rx > $ry ? $ry : $rx]
    
    # This approximation gives a maximum half pixel error.
    set deltaPhi [expr 2.0/sqrt($rmin)]
    set extent   [expr $anglesToRadians * $optA(-extent)]
    set start    [expr $anglesToRadians * $optA(-start)]
    set nsteps   [expr int(abs($extent)/$deltaPhi) + 2]
    set delta    [expr $extent/$nsteps]
    set data [format "M %.1f %.1f L"  \
      [expr $cx + $rx*cos($start)] [expr $cy - $ry*sin($start)]]
    for {set i 0} {$i <= $nsteps} {incr i} {
        set phi [expr $start + $i * $delta]
        append data [format " %.1f %.1f"  \
          [expr $cx + $rx*cos($phi)] [expr $cy - $ry*sin($phi)]]
    }
    if {[info exists optA(-style)]} {
        
        switch -- $optA(-style) {
            chord {
                append data " Z"
            }
            pieslice {
                append data [format " %.1f %.1f Z" $cx $cy]
            }
        }
    } else {
        
        # Pieslice is the default.
        append data [format " %.1f %.1f Z" $cx $cy]
    }
    return $data
}
#ORLOV Make Defs Gradient
proc can2svg::MakeGradientDef {gradient} {
    variable wcan
    array set Gradient [can2svg::parsegradient $wcan  $gradient]
    if {$Gradient(units) == "bbox"} {
	set units "bbox"
    } else {
	set units "userSpaceOnUse"
    }
    if {$Gradient(type) == "linear"} {
	set type "linearGradient"
	set gradientAttr [list "id" $gradient "x1" $Gradient(x0) "x2" $Gradient(x1) "y1" $Gradient(y0) "y2" $Gradient(y1) gradientsUnits $units]
    } else {
	set type "radialGradient"
	set gradientAttr [list "id" $gradient  "cx" $Gradient(cx) "cy" $Gradient(cy) "r" $Gradient(r) "fx" $Gradient(fx) "fy" $Gradient(fy) gradientsUnits $units]
    }
    set stopList [list]
    for {set i 0} {$i < $Gradient(i)} {incr i} {
	set stopAttr [list "id" "stop$gradient$i" "offset" $Gradient(offset$i) "stop-color" $Gradient(color$i) "stop-opacity" $Gradient(opacity$i)]
	append stopList " [MakeXMLList stop -attrlist $stopAttr]"
    }
    set defElemList [MakeXMLList "defs" -subtags  \
          [list [MakeXMLList $type -attrlist $gradientAttr \
          -subtags [list $stopList] ] ] ]
    return [list $defElemList]
}

# can2svg::MakeAttrList --
# 
#       Handles the use of style attributes or presenetation attributes.

proc can2svg::MakeAttrList {type opts usestyleattribute} {
    
    if {$usestyleattribute} {
        set attrList [list style [MakeStyleAttr $type $opts]]
    } else {
        set attrList [MakeStyleList $type $opts]
    }
    return $attrList
}

# can2svg::MakeStyleAttr --
#
#       Produce the SVG style attribute from the canvas item options.
#
# Arguments:
#       type        tk canvas widget item type
#       opts
#       
# Results:
#       The SVG style attribute as a a string.

proc can2svg::MakeStyleAttr {type opts} {
    set style ""
    set ind [lsearch $opts "-tags"]
    set svg 0
    if {$ind > -1} {
	incr ind
	set svg [lsearch [lindex $opts $ind] "svg"]
	if {$svg > -1} {
	    set svg 1
	}
    }
    if {$svg && ($type == "ellipse" || $type == "pimage" || $type == "path" || $type == "polyline" || $type == "prect" || $type == "ppolygon" || $type == "ptext")} {
	foreach {key value} [lrange $opts 0 end] {
	    if {$type == "prect"} {
		if {$key == "-rx" || $key == "-ry"} {
		    continue
		}
	    }
	    if {$key == "-tags" || $key == "-parent" || $key == "-state"} {continue}
	    if {[string length $key] > 7 && [string range $key 0 6]  == "-stroke"} {
		set key [string replace $key 0 6 "-stroke-"]
	    }
	    if {[string length $key] > 5 && [string range $key 0 4]  == "-font"} {
		set key [string replace $key 0 4 "-font-"]
		if {$key == "-font-size"} {
    		    if {$value > 0} {
        		# pixels (actually user units)
        		set funit pt
    		    } else {
        		# points
        		set funit px
    		    }        
    		    set  value "[expr abs($value)]$funit"
		}
	    }
	    if {$key  == "-fillopacity"} {
		set key "-fill-opacity"
	    } elseif {$key  == "-fillrule"} {
		set key "-fill-rule"
	    }

	    if {$value == ""} {
    		append style "[string range ${key} 1 end] : none; "
	    } else {
    		append style "[string range ${key} 1 end] : ${value}; "
    	    }
	}
    }
    
    foreach {key value} [MakeStyleList $type $opts] {
        append style "${key}: ${value}; "
    }
    return [string trim $style]
}

proc can2svg::MakeStyleList {type opts args} {
    
    array set argsA {
        -setdefaults 1 
    }
    array set argsA $args
    
#ORLOV
    if {$type == "polyline"} {
#Выбираем стрелки из tkpath - scg
	set arrowValue ""
	set fontsvg ""
	set strwidth 0
	foreach {key value} $opts {
    	    switch -- $key {
        	-fontsize -
        	-fontwidth -
        	-fontfamily {
            	    append $fontsvg " $value"
        	}
        	-startarrowlength {
            	    set a $value
        	}
        	-startarrowwidth {
            	    set b $value
        	}
        	-startarrowfill {
            	    set c $value
        	}
        	-endarrowlength {
            	    set a1 $value
        	}
        	-endarrowwidth {
            	    set b1 $value
        	}
        	-endarrowfill {
            	    set c1 $value
        	}
        	-startarrow {
        	    if {$value == 1} {
        		if {$arrowValue == ""} {
            		    set arrowValue "first"
            		} else {
            		    set arrowValue "both"
            		}
            	    }
        	}
        	-endarrow {
        	    if {$value == 1} {
        		if {$arrowValue == ""} {
            		    set arrowValue "last"
            		} else {
            		    set arrowValue "both"
            		}
		    }
        	}
        	-stroke {
            	    set fillCol $value
#            	    set fillCol [string range $value 1 end]
        	}
        	-strokewidth {
            	    set strwidth $value
        	}

    	    }
	}
	if {$fontsvg != ""} {
                array set styleArr [MakeFontStyleList $fontsvg]
	}
	
	set pq [expr {int($a / $c) * 1.0}]
        set arrowShape [list $a $pq  $b]
	set pq1 [expr {int($a1 / $c1) * 1.0}]
        set arrowShapeEnd [list $a1 $pq1  $b1]
	set optA(-arrowshapeEnd) $arrowShapeEnd
    } else {

    # Defaults for everything except text.
    if {$type != "polyline" && $type != "prect" && $type != "ptext" && $type != "path" && $type != "ppolygon" && $argsA(-setdefaults) && ![string equal $type "text"]} {
        array set styleArr {fill none stroke black}
    }
    set fillCol black
    foreach {key value} $opts {
        
        switch -- $key {
            -arrow {
                set arrowValue $value
            }
            -arrowshape {
                set arrowShape $value
                set arrowShapeEnd $value
            }
            -capstyle {
                if {[string equal $value "projecting"]} {
                    set value "square"
                }
                if {![string equal $value "butt"]} {
                    set styleArr(stroke-linecap) $value
                }
            }
            -dash {
                set dashValue $value
            }
            -dashoffset {
                if {$value != 0} {
                    set styleArr(stroke-dashoffset) $value
                }
            }
            -extent {
                # empty
            }
            -fill {
		#ORLOV gradient
		if {[can2svg::filltype $value] == "gradient"} {
                    set styleArr(fill) "url(#$value)"
#puts "can2svg::MakeStyleList: styleArr(fill)=$styleArr(fill)"
		} else {
                # Need to translate names to hex spec.
                if {![regexp {#[0-9]+} $value]} {
                    set value [FormatColorName $value]
                }
                set fillCol $value                
                if {[string equal $type "line"]} {
                    set styleArr(stroke) [MapEmptyToNone $value]
                } else {
                    set styleArr(fill) [MapEmptyToNone $value]
                }
                }
            }
            -font {
                array set styleArr [MakeFontStyleList $value]
                
            }
            -joinstyle {
                set styleArr(stroke-linejoin) $value                
            }
            -outline {
                set styleArr(stroke) [MapEmptyToNone $value]
            }
            -outlinestipple {
                set outlineStippleValue $value
            }
            -start {
                # empty
            }
            -stipple {
                set stippleValue $value
            }
            -width {
                set styleArr(stroke-width) $value
            }
        }
    }
    }
    # If any arrow specify its marker def url key.
    if {[info exists arrowValue]} {
        if {[info exists arrowShape]} {        
            foreach {a b c} $arrowShape break
#ORLOV
	    set colM [string range $fillCol  1 end]
	    set arrowIdKey "arrowMarkerDef_${colM}_${a}_${b}_${c}"
            foreach {a1 b1 c1} $arrowShapeEnd break
	    set arrowIdKeyLast "arrowMarkerLastDef_${colM}_${a1}_${b1}_${c1}"

        } else {
            set arrowIdKey "arrowMarkerDef_${fillCol}"
            set arrowIdKeyLast $arrowIdKey
        }
        switch -- $arrowValue {
            first {
                set styleArr(marker-start) "url(#$arrowIdKey)"
            }
            last {
                set styleArr(marker-end) "url(#$arrowIdKeyLast)"
            }
            both {
                set styleArr(marker-start) "url(#$arrowIdKey)"
                set styleArr(marker-end) "url(#$arrowIdKeyLast)"
            }
        }
    }
    
    if {[info exists stippleValue]} {
        
        # Overwrite any existing.
        set styleArr(fill) "url(#tile[string trimleft $stippleValue @])"
    }
    if {[info exists outlineStippleValue]} {
        
        # Overwrite any existing.
        set styleArr(stroke) "url(#tile[string trimleft $stippleValue @])"
    }
    
    # Transform dash value.
    if {[info exists dashValue]} {
                
        # Two different syntax here.                
        if {[regexp {[\.,\-_]} $dashValue]} {
            
            # .=2 ,=4 -=6 space=4    times stroke width.
            # A space enlarges the... space.
            # Not foolproof!
            regsub -all -- {[^ ]} $dashValue "& " dash
            regsub -all -- "   "  $dash  "12 " dash
            regsub -all -- "  "   $dash  "8 " dash
            regsub -all -- " "    $dash  "4 " dash
            regsub -all -- {\.}   $dash  "2 " dash
            regsub -all -- {,}    $dash  "4 " dash
            regsub -all -- {-}    $dash  "6 " dash                    
        
            # Multiply with stroke width if > 1.
            if {[info exists styleArr(stroke-width)] &&  \
              ($styleArr(stroke-width) > 1)} {
                set width $styleArr(stroke-width)
                set dashOrig $dash
                set dash {}
                foreach num $dashOrig {
                    lappend dash [expr int($width * $num)]
                }
            }
            set styleArr(stroke-dasharray) [string trim $dash]
        } else {
            set dashValue [string trim $dashValue]
            if {$dashValue ne ""} {
                set styleArr(stroke-dasharray) $dashValue
            }
        }
    }
    if {[string equal $type "polygon"]} {
        set styleArr(fill-rule) "evenodd"
    }        
    return [array get styleArr]
}

proc can2svg::FormatColorName {value} {

    if {[string length $value] == 0} {
        return $value
    }

    switch -- $value {
        black - white - red - green - blue {
            set col $value
        }
        default {
        
            # winfo rgb . white -> 65535 65535 65535
            foreach rgb [winfo rgb . $value] {
                lappend rgbx [expr $rgb >> 8]
            }
            set col [eval {format "#%02x%02x%02x"} $rgbx]
        }
    }
    return $col
}

# can2svg::MakeFontStyleList --
# 
#       Takes a tk font description and returns a flat style array.
#       
# Arguments:
#       fontDesc    a tk font description 
#       
# Results:
#       flat style array

proc can2svg::MakeFontStyleList {fontDesc} {    
    # MICK Modify - break a named font into its component fields
    set font [lindex $fontDesc 0]
    if {[lsearch -exact [font names] $font] > -1} {
        
        # This is a font name
        set styleArr(font-family) [font config $font -family]
        set fsize [font config $font -size]
        if {$fsize > 0} {
            # points
            set funit pt
        } else {
            # pixels (actually user units)
            set funit px
        }        
        set styleArr(font-size) "[expr abs($fsize)]$funit"
        if {[font config $font -slant] == "italic"} {
            set styleArr(font-style) italic
        }
        if {[font config $font -weight] == "bold"} {
            set styleArr(font-weight) bold
        }
        if {[font config $font -underline]} {
            set styleArr(text-decoration) underline
        }
        if {[font config $font -overstrike]} {
            set styleArr(text-decoration) overline
        }
    } else {
        set styleArr(font-family) [lindex $fontDesc 0]
        if {[llength $fontDesc] > 1} {
            # Mick: added pt at end
            set fsize [lindex $fontDesc 1]
            if {$fsize > 0} {
                # points
                set funit pt
            } else {
                # pixels (actually user units)
                set funit px
            }
            set styleArr(font-size) "[expr abs($fsize)]$funit"
        }
        if {[llength $fontDesc] > 2} {
            set tkstyle [lindex $fontDesc 2]
            switch -- $tkstyle {
                bold {
                    set styleArr(font-weight) $tkstyle
                }
                italic {
                    set styleArr(font-style) $tkstyle
                }
                underline {
                    set styleArr(text-decoration) underline
                }
                overstrike {
                    set styleArr(text-decoration) overline
                }
            }
        }                
    }
    return [array get styleArr]
}

# can2svg::SplitWrappedLines --
# 
# MICK O'DONNELL: added code to split wrapped lines
# This is actally only needed for text items with -width != 0.
# If -width = 0 then just return it.

proc can2svg::SplitWrappedLines {line font wgtWidth} {

     # If the text is shorter than the widget width, no need to wrap
     # If the wgtWidth comes out as 0, don't wrap
     if {$wgtWidth == 0 || [font measure $font $line] <= $wgtWidth} {
        return [list $line]
     }

     # Wrap the line
     set width 0
     set endchar 0
     while {$width < $wgtWidth} {
        set substr [string range $line 0 [incr endchar]]
        set width [font measure $font $substr]
     }

     # Go back till we find a nonwhite char
     set char [string index $line $endchar]
     set default [expr $endchar -1]
     while {[BreakChar $char] == 0} {
        if {$endchar == 0} {
            # we got to the front without breaking, so break midword
            set endchar $default
            break
        }
        set char [string index $line [incr endchar -1]]
     }
     set first [string range $line 0 $endchar]
     set rest [string range $line [expr $endchar+1] end]
     return [concat [list $first] [SplitWrappedLines $rest $font $wgtWidth]]
}

proc can2svg::BreakChar {char} {
     if [string is space $char] {return 1}
     if {$char == "-"} {return 1}
     if {$char == ","} {return 1}
     return 0
}

# can2svg::MakeImageAttr --
#
#       Special code is needed to make the attributes for an image item.
#       
# Arguments:
#       elem 
#       
# Results:
#   

proc can2svg::MakeImageAttr {coo opts args} {
    variable confopts
    
    array set optA {-anchor nw}
    array set optA $opts
    array set argsA $args
    
    set attrList [ImageCoordsToAttr $coo $opts]

    # We should make this an URI.
    set image $optA(-image)
    set fileName [$image cget -file]
    if {$fileName ne ""} {
        if {[string equal $argsA(-uritype) "file"]} {
            set uri [FileUriFromLocalFile $fileName]
        } elseif {[string equal $argsA(-uritype) "http"]} {
            set uri [HttpFromLocalFile $fileName]
        }
        lappend attrList "xlink:href" $uri
    } else {
        # Unclear if we can use base64 data in svg.
	set uri [$optA(-image) cget -data]
        lappend attrList "xlink:href" "data:image/png;base64,$uri"
    }    
    return $attrList
}

# Function � �: can2svg::ImageCoordsToAttr 
# ------------------------------ ------------------------------ --------- 
# Returns � � : list of x y width and height including description 
# Parameters �: coo �- coordinates of the image 
# � � � � � � � opts - argument list -anchor nw ... 
#
# Description : 
# fixme (Roger) 01/25/2008 :Why not using the bounding box? 
#
# Written � � : 2002-2007, Mats 
# Rewritten � : 01/25/2008, Roger 
# ------------------------------ ------------------------------ --------- 

proc can2svg::ImageCoordsToAttr {coo opts} { 
    
    array set optArr {-anchor nw}
    array set optArr $opts
    
    if {![info exists optArr(-image)]} { 
        return -code error "Missing -image option; can't parse that" 
    } 
    set theImage $optArr(-image) 

    lassign $coo x0 y0
#ORLOV
    set svg [lsearch $optArr(-tags) "svg"]
    if {$svg > -1} {
	set svg 1
    } else {
	set svg 0
    }
    if {$svg} {
	set w $optArr(-width)
	set h $optArr(-height) 
    } else { 

	set w [image width $theImage]
	set h [image height $theImage]
    }
    
    set x [expr {$x0 - $w/2.0}] 
    set y [expr {$y0 - $h/2.0}] 

    if { "center" ne $optArr(-anchor) } { 
        foreach orientation [split $optArr(-anchor) {}] { 
            switch $orientation { 
                n { set y $y0 } 
                s { set y [expr {$y0 - $w}] } 
                e { set x [expr {$x0 - $h}] } 
                w { set x $x0 } 
                default {} 
            } 
        } 
    } 
    return [list "x" $x "y" $y "width" $w "height" $h] 
}

proc can2svg::ImageCoordsToAttrBU {coo opts} {
    array set optA {-anchor nw}
    array set optA $opts
    if {[info exists optA(-image)]} {
        set theImage $optA(-image)
        set w [image width $theImage]
        set h [image height $theImage]
    } else {
        return -code error "Missing -image option; can't parse that"
    }
    foreach {x0 y0} $coo break
    
    switch -- $optA(-anchor) {
        nw {
            set x $x0
            set y $y0
        }
        n {
            set x [expr $x0 - $w/2.0]
            set y $y0
        }
        ne {
            set x [expr $x0 - $w]
            set y $y0
        }
        e {
            set x $x0
            set y [expr $y0 - $h/2.0]
        }
        se {
            set x [expr $x0 - $w]
            set y [expr $y0 - $h]
        }
        s {
            set x [expr $x0 - $w/2.0]
            set y [expr $y0 - $h]
        }
        sw {
            set x $x0
            set y [expr $y0 - $h]
        } 
        w {
            set x $x0
            set y [expr $y0 - $h/2.0]
        }
        center {
            set x [expr $x0 - $w/2.0]
            set y [expr $y0 - $h/2.0]
        }
    }
    set attrList [list "x" $x "y" $y "width" $w "height" $h]
    return $attrList
}

# can2svg::GetTextSVGCoords --
# 
#       Figure out the baseline coords of the svg text element from
#       the canvas text item.
#
# Arguments:
#       coo         {x y}
#       anchor
#       chdata      character data, newlines included.
#       
# Results:
#       raw xml data of the marker def element.

proc can2svg::GetTextSVGCoords {coo anchor chdata theFont nlines} {
    
    foreach {x y} $coo break
    set ascent [font metrics $theFont -ascent]
    set lineSpace [font metrics $theFont -linespace]

    # If not anchored to the west it gets more complicated.
    if {![string match $anchor "*w*"]} {
        
        # Need to figure out the extent of the text.
        if {$nlines <= 1} {
            set textWidth [font measure $theFont $chdata]
        } else {
            set textWidth 0
            foreach line [split $chdata "\n"] {
                set lineWidth [font measure $theFont $line]
                if {$lineWidth > $textWidth} {
                    set textWidth $lineWidth
                }
            }
        }
    }
    
    switch -- $anchor {
        nw {
            set xbase $x
            set ybase [expr $y + $ascent]
        }
        w {
            set xbase $x
            set ybase [expr $y - $nlines*$lineSpace/2.0 + $ascent]
        }
        sw {
            set xbase $x
            set ybase [expr $y - $nlines*$lineSpace + $ascent]
        }
        s {
            set xbase [expr $x - $textWidth/2.0]
            set ybase [expr $y - $nlines*$lineSpace + $ascent]
        }
        se {
            set xbase [expr $x - $textWidth]
            set ybase [expr $y - $nlines*$lineSpace + $ascent]
        }
        e {
            set xbase [expr $x - $textWidth]
            set ybase [expr $y - $nlines*$lineSpace/2.0 + $ascent]
        }
        ne {
            set xbase [expr $x - $textWidth]
            set ybase [expr $y + $ascent]
        } 
        n {
            set xbase [expr $x - $textWidth/2.0]
            set ybase [expr $y + $ascent]
        }
        center {
            set xbase [expr $x - $textWidth/2.0]
            set ybase [expr $y - $nlines*$lineSpace/2.0 + $ascent]
        }
    }
    
    return [list $xbase $ybase]
}

# can2svg::ParseSplineToPath --
# 
#       Make the path data string for a bezier.
#
# Arguments:
#       type        canvas type: line or polygon
#       coo         its coordinate list
#       
# Results:
#       path data string

proc can2svg::ParseSplineToPath {type coo} {
    
    set npts [expr [llength $coo]/2]
    
    # line is open ended while the polygon must be closed.
    # Need to construct a closed smooth polygon with path instructions.

    switch -- $npts {
        1 {
            set data "M [lrange $coo 0 1]"
        }
        2 {
            set data "M [lrange $coo 0 1] L [lrange $coo 2 3]"                                
        }
        3 {
            set data "M [lrange $coo 0 1] Q [lrange $coo 2 5]"
        }
        default {
            if {[string equal $type "polygon"]} {
                set x0s [expr ([lindex $coo 0] + [lindex $coo end-1])/2.]
                set y0s [expr ([lindex $coo 1] + [lindex $coo end])/2.]
                set data "M $x0s $y0s"
                    
                # Add Q1 and Q2 points.
                append data " Q [lrange $coo 0 1]"
                set x0 [expr ([lindex $coo 0] + [lindex $coo 2])/2.]
                set y0 [expr ([lindex $coo 1] + [lindex $coo 3])/2.]
                append data " $x0 $y0"
                set xctrlp [lindex $coo 2]
                set yctrlp [lindex $coo 3]
                set tind 4
            } else {
                set data "M [lrange $coo 0 1]"
                    
                # Add Q1 and Q2 points.
                append data " Q [lrange $coo 2 3]"
                set x0 [expr ([lindex $coo 2] + [lindex $coo 4])/2.]
                set y0 [expr ([lindex $coo 3] + [lindex $coo 5])/2.]
                append data " $x0 $y0"
                set xctrlp [lindex $coo 4]
                set yctrlp [lindex $coo 5]
                set tind 6
            }
            append data " T"                                
            foreach {x y} [lrange $coo $tind end-2] {
                #puts "x=$x, y=$y, xctrlp=$xctrlp, yctrlp=$yctrlp"
                
                # The T point is the midpoint between the
                # two control points.
                set x0 [expr ($x + $xctrlp)/2.0]
                set y0 [expr ($y + $yctrlp)/2.0]
                set xctrlp $x
                set yctrlp $y
                append data " $x0 $y0"
                #puts "data=$data"
            }
            if {[string equal $type "polygon"]} {
                set x0 [expr ([lindex $coo end-1] + $xctrlp)/2.0]
                set y0 [expr ([lindex $coo end] + $yctrlp)/2.0]
                append data " $x0 $y0"
                append data " $x0s $y0s"
            } else {
                append data " [lrange $coo end-1 end]"
            }
            #puts "data=$data"
        }
    }
    return $data
}

# can2svg::MakeArrowMarker --
# 
#       Make the xml for an arrow marker def element.
#
# Arguments:
#       a           arrows length along its symmetry line
#       b           arrows total length
#       c           arrows half width
#       col         its color
#       
# Results:
#       a list of xmllists of the marker def elements, both start and last.

proc can2svg::MakeArrowMarker {a b c a1 b1 c1 col strokewidth} {
    variable formatArrowMarker
    variable formatArrowMarkerLast
    unset -nocomplain formatArrowMarker
#puts "a=$a b=$b c=$c" 
#puts "a1=$a1 b1=$b1 c1=$c1 strokewidth=$strokewidth" 

    if {![info exists formatArrowMarker]} {
        
        # "M 0 c, b 0, a c, b 2*c Z" for the start marker.
        # "M 0 0, b c, 0 2*c, b-a c Z" for the last marker.
        set data "M 0 %s, %s 0, %s %s, %s %s Z"
        set style "fill: %s; stroke: %s;"
        set attr [list "d" $data "style" $style]
        set arrowList [MakeXMLList "path" -attrlist $attr]
        set markerAttr [list "id" %s "markerWidth" %s "markerHeight" %s  \
          "refX" %s "refY" %s "orient" "auto" "markerUnits" "userSpaceOnUse"]
        set defElemList [MakeXMLList "defs" -subtags  \
          [list [MakeXMLList "marker" -attrlist $markerAttr \
          -subtags [list $arrowList] ] ] ]
        set formatArrowMarker $defElemList
        
        # ...and the last arrow marker.
        set dataLast "M 0 0, %s %s, 0 %s, %s %s Z"
        set attrLast [list "d" $dataLast "style" $style]
        set arrowLastList [MakeXMLList "path" -attrlist $attrLast]
        set defElemLastList [MakeXMLList "defs" -subtags  \
          [list [MakeXMLList "marker" -attrlist $markerAttr \
          -subtags [list $arrowLastList] ] ] ]
        set formatArrowMarkerLast $defElemLastList
    }
#ORLOV
    set colM [string range $col  1 end]
    set idKey "arrowMarkerDef_${colM}_${a}_${b}_${c}"
    set idKeyLast "arrowMarkerLastDef_${colM}_${a1}_${b1}_${c1}"
    
    # Figure out the order of all %s substitutions.
    if {$strokewidth > $c} {
	set c $strokewidth
    }
    if {$strokewidth > $c1} {
	set c1 $strokewidth
    }
    
    set markerXML [format $formatArrowMarker $idKey  \
      $b [expr 2*$c] 0 $c  \
      $c $b $a $c $b [expr 2*$c] $col $col]
    set markerLastXML [format $formatArrowMarkerLast $idKeyLast  \
      $b1 [expr 2*$c1] $b1 $c1 \
      $b1 $c1 [expr 2*$c1] [expr $b1-$a1] $c1 $col $col]

    return [list $markerXML $markerLastXML]
}

# can2svg::MakeGrayStippleDef --
#
#

proc can2svg::MakeGrayStippleDef {stipple} {
    
    variable stippleDataArr
    
    set pathList [MakeXMLList "path" -attrlist  \
      [list "d" $stippleDataArr($stipple) "style" "stroke: black; fill: none;"]]
    set patterAttr [list "id" "tile$stipple" "x" 0 "y" 0 "width" 4 "height" 4 \
      "patternUnits" "userSpaceOnUse"]
    set defElemList [MakeXMLList "defs" -subtags  \
      [list [MakeXMLList "pattern" -attrlist $patterAttr \
      -subtags [list $pathList] ] ] ]
    
    return $defElemList
}

# can2svg::MapEmptyToNone --
#
#
# Arguments:
#       elem 
#       
# Results:
#   

proc can2svg::MapEmptyToNone {val} {

    if {[string length $val] == 0} {
        return "none"
    } else {
        return $val
    }
}

# can2svg::NormalizeRectCoords --
#
#
# Arguments:
#       elem 
#       
# Results:
#   

proc can2svg::NormalizeRectCoords {coo} {
    
    foreach {x1 y1 x2 y2} $coo {}
    return [list [expr $x2 > $x1 ? $x1 : $x2]  \
      [expr $y2 > $y1 ? $y1 : $y2]  \
      [expr abs($x1-$x2)]  \
      [expr abs($y1-$y2)]]
}

# can2svg::makedocument --
#
#       Adds the prefix and suffix elements to make a complete XML/SVG
#       document.
#
# Arguments:
#       elem 
#       
# Results:
#   

proc can2svg::makedocument {width height lid xml} {
    variable wcan
    global groupX
#ORLOV
    set viewbox ""
    if {$lid != ""} {
	foreach {x1 y1 x2 y2} [eval $wcan bbox $lid] {
	    set width [expr {$x2 - $x1 + 1}]
	    set height [expr {$y2 - $y1 + 1}]
	    set viewbox " viewBox='$x1 $y1 $width $height'"
	}
    }
    switch -- $::tcl_platform(platform) {
	"windows"        {
	    set enc " encoding='cp1251'"
	}
	"unix" - default {
	    set enc "encoding='utf-8'"
	}
    }

    set pre "<?xml version='1.0' $enc?>\n\
      <!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\"\
      \"Graphics/SVG/1.1/DTD/svg11.dtd\">"
    set svgStart "<svg width='$width' height='$height' $viewbox version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'>"
    set svgEnd "</svg>"
    return "${pre}\n${svgStart}\n${xml}${svgEnd}"
}

# can2svg::can2xmlfile --
#
#       Takes everything on a canvas widget, translates it to XML/SVG,
#       and puts it on a file or return it (for xmldata).
#       
# Arguments:
#       wcan	the canvas widget path
#       path    the file path or "xmldata"
#	lid	list of object IDs on the canvas or "all"    
#       args:   -height
#               -width 
#       
# Results:
#   

proc can2svg::can2xmlfile {wwcan path lid args} {
    variable wcan
    variable confopts
    variable defsArrowMarkerArr
    variable defsStipplePatternArr
#ORLOV 
    if {$path != "xmldata"} {
	if {[catch {set fd [open $path w]} ret]} {
    	    tk_messageBox -title "Export group to SVG" -message "Cannot open file for write:\n$path" -detail $ret -icon error
	    return ""
	}
    }

    set wcan $wwcan
    if {[llength $lid] == 1 && $lid == "all"} {
        set lid [$wcan find all]
#	return ""
    }
    set nlid [list]
    foreach id $lid {
	if {[$wcan type $id] != "group" && [$wcan type $id] != ""} {
	    lappend nlid $id
	    $wcan itemconfigure $id -tags "utag$id"
	}
    }
    if {[llength $nlid] < 1} {
	tk_messageBox -title "Export group to SVG" -message "Not group for export" -icon warning
	close $fd
	return
    }
    set lid $nlid
    unset nlid
    array set argsA [array get confopts]
#ORLOV
    
    foreach {x1 y1 x2 y2} [$wcan bbox [lindex $lid 0]] {break}
    set width [expr {$x2 - $x1 + 1}]
    set height [expr {$y2 - $y1 + 1}]

    array set argsA [list -width $width -height $height]
    array set argsA $args
    set args [array get argsA]
    
    # Need to make a fresh start for marker def's.
    unset -nocomplain defsArrowMarkerArr defsStipplePatternArr
    # This could have been done line by line.
    set xml ""
#ORLOV
    foreach id $lid {
        set type [$wcan type $id]
        set opts [$wcan itemconfigure $id]
        set opcmd {}
        foreach opt $opts {
            set op [lindex $opt 0]
            set val [lindex $opt 4]
            
            # Empty val's except -fill can be stripped off.
            if {![string equal $op "-fill"] && ([string length $val] == 0)} {
                continue
            }
            lappend opcmd $op $val
        }
        set co [$wcan coords $id]
        set cmd [concat "create" $type $co $opcmd]
        append xml "\t[eval {can2svg $cmd} $args]\n"        
    }

    set datasvg [makedocument $argsA(-width) $argsA(-height) $lid $xml]
    foreach id $lid {
	$wcan dtag $id "utag$id"
    }

    if {$path != "xmldata"} {
	puts $fd $datasvg
	close $fd
	return $path
    } else {
	return $datasvg
    }
}


# can2svg::MakeXML --
#
#       Creates raw xml data from a hierarchical list of xml code.
#       This proc gets called recursively for each child.
#       It makes also internal entity replacements on character data.
#       Mixed elements aren't treated correctly generally.
#       
# Arguments:
#       xmlList     a list of xml code in the format described in the header.
#       
# Results:
#       raw xml data.

proc can2svg::MakeXML {xmlList} {
        
    # Extract the XML data items.
    foreach {tag attrlist isempty chdata childlist} $xmlList {}
#ORLOV
    if {$tag == "stop"} {
	set rawxml ""
	foreach {tag attrlist isempty chdata childlist} $xmlList {
	    append rawxml "<$tag"
	    foreach {attr value} $attrlist {
    		append rawxml " ${attr}='${value}'"
	    }
    	    append rawxml "/>"
	}
        return $rawxml

    }

    set rawxml "<$tag"
    foreach {attr value} $attrlist {
        append rawxml " ${attr}='${value}'"
    }
    if {$isempty} {
        append rawxml "/>"
        return $rawxml
    } else {
        append rawxml ">"
    }
    
    # Call ourselves recursively for each child element. 
    # There is an arbitrary choice here where childs are put before PCDATA.
    foreach child $childlist {
        append rawxml [MakeXML $child]
    }
    
    # Make standard entity replacements.
    if {[string length $chdata]} {
        append rawxml [XMLCrypt $chdata]
    }
    append rawxml "</$tag>"
    return $rawxml
}

# can2svg::MakeXMLList --
#
#       Build an element list given the tag and the args.
#
# Arguments:
#       tagname:    the name of this element.
#       args:       
#           -empty   0|1      Is this an empty tag? If $chdata 
#                             and $subtags are empty, then whether 
#                             to make the tag empty or not is decided 
#                             here. (default: 1)
#            -attrlist {attr1 value1 attr2 value2 ..}   Vars is a list 
#                             consisting of attr/value pairs, as shown.
#            -chdata $chdata   ChData of tag (default: "").
#            -subtags {$subchilds $subchilds ...} is a list containing xmldata
#                             of $tagname's subtags. (default: no sub-tags)
#       
# Results:
#       a list suitable for can2svg::MakeXML.

proc can2svg::MakeXMLList {tagname args} {
        
    # Fill in the defaults.
    array set xmlarr {-isempty 1 -attrlist {} -chdata {} -subtags {}}
    
    # Override the defults with actual values.
    if {[llength $args] > 0} {
        array set xmlarr $args
    }
    if {!(($xmlarr(-chdata) eq "") && ($xmlarr(-subtags) eq ""))} {
        set xmlarr(-isempty) 0
    }
    
    # Build sub elements list.
    set sublist [list]
    foreach child $xmlarr(-subtags) {
        lappend sublist $child
    }
    set xmlList [list $tagname $xmlarr(-attrlist) $xmlarr(-isempty)  \
      $xmlarr(-chdata) $sublist]
    return $xmlList
}

# can2svg::XMLCrypt --
#
#       Makes standard XML entity replacements.
#
# Arguments:
#       chdata:     character data.
#       
# Results:
#       chdata with XML standard entities replaced.

proc can2svg::XMLCrypt {chdata} {

    foreach from {\& < > {"} {'}}   \
      to {{\&amp;} {\&lt;} {\&gt;} {\&quot;} {\&apos;}} {
        regsub -all $from $chdata $to chdata
    }
###"'
    return $chdata
}

# can2svg::FileUriFromLocalFile --
#
#       Not foolproof!

proc can2svg::FileUriFromLocalFile {path} {
        
    # Quote the disallowed characters according to the RFC for URN scheme.
    # ref: RFC2141 sec2.2
    return file://[uriencode::quotepath $path]
}

# can2svg::HttpFromLocalFile --
#
#       Translates an absolute file path to an uri encoded http address.

proc can2svg::HttpFromLocalFile {path} {
    variable confopts
    
    set relPath [::tfileutils::relative $confopts(-httpbasedir) $path]
    set relPath [uriencode::quotepath $relPath]
    return "http://$confopts(-httpaddr)/$relPath"
}


#Тип -fill: name - это цвет или градиентсная заливка?
proc can2svg::filltype {name}  {
    if {[catch {winfo rgb . $name} result ] == 0} {
        return "color"
    }
    if {[catch {.c gradient type $name} result ] == 0} {
        return "gradient"
    }
    return "bad"
}
proc can2svg::parsegradient {can grad} {
    array set Gradient []
    set Gradient(type) [$can gradient type $grad]
    set Gradient(units) [$can gradient cget $grad -units]
    if {$Gradient(type) == "linear"} {
	lassign [$can gradient cget $grad -lineartransition] Gradient(x0) Gradient(y0) Gradient(x1) Gradient(y1)
    } else {
	foreach {Gradient(cx) Gradient(cy) Gradient(r) Gradient(fx) Gradient(fy)} [$can gradient cget $grad -radialtransition] {break}
    }
    set i 0
    foreach stop [$can gradient cget $grad -stops] {
	lassign $stop Gradient(offset$i) Gradient(color$i) Gradient(opacity$i)
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
