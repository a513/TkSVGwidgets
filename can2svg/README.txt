Your question:
 
Given that tkpath is modeled on svg, is svg output possible?
 
Yes, it is possible.
Unpack the attached archive and navigate to the `TestExportFromTkpath` folder.
Place your `tkpath` package folder into the `~/TestExportFromTkpath/PackageAdd` directory.
Then, launch the Tcl/Tk interpreter (e.g., `wish`).
Add the path to the package folder to the `auto_path` variable:
 
lappend auto_path PackageAdd
 
Now you can run the `test_1.tcl` example:
 
source test_1.tcl
 
You will see two windows on the screen displaying SVG objects (screenshots are included in the archive).
 
 
The `wish` window contains SVG images drawn using `tkpath`. These images
are saved as SVG files: `test1.svg`, `test2.svg`, and `test3.svg`. You can view them with any SVG viewer.
Everything required for exporting to SVG files is contained in the `can2svg.tcl` file.
You can load it like this:
 
source can2svg.tcl
 
The export command is `can2svg::can2xmlfile`:
 
#      can2svg::can2xmlfile widgetPath fileName lid ?options?
#           widgetPath:        the canvas widget path
#           fileName:        the file path or "xmldata"
#           lid            list of object IDs on the canvas or "all"    
#           options:   -height
#                      -width
#         Results: file or xml-data
# 
 
The second window, `win1`, shows the import of SVG files onto a `tkp::canvas`.
Importing is more complex; to use it, you need to load the `svg2can` package.
 
 
I think it would be a good idea to include at least the `can2svg` file to allow exporting images from `tkpath` to SVG files.
