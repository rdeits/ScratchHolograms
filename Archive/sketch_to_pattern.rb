require 'sketchup.rb'
###########################################################
#
#    Copyright (C) 2008 Uli Tessel (utessel@gmx.de)
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
###########################################################

class EdgeDataExporter
#--------------------------------------------------------------------------
def dumpVertex( vert, trans )

  if (trans)
    pos = trans * vert.position
  else
    pos = vert.position
  end

  x = pos.x.to_mm.to_f
  y = pos.y.to_mm.to_f
  z = pos.z.to_mm.to_f

  @file.write "v %10.3f;%10.3f;%10.3f;\n" % [x, y, z]
end

#--------------------------------------------------------------------------

def dumpEdge( edge )

  curve = edge.curve

  if (curve)
    @file.write "c %8d:" % [curve.entityID]
  else
    typ = edge.get_attribute "outline", "edgetype"
    
    if typ==nil
      @file.write "e "
    else
      @file.write typ+" "
    end
  end

  idx1 = @vertices.index edge.start
  idx2 = @vertices.index edge.end
  @file.write "%5d;%5d\n" % [idx1,idx2]
  
end

#--------------------------------------------------------------------------
def combineTransformation( t1, t2 )

   if (t1)
    if (t2)
      return t1 * t2
    else
      return t1
    end
  else
    return t2
  end

end

#--------------------------------------------------------------------------
def collectEdge( edge )
  @edges << edge
  @vertices << edge.end
  @vertices << edge.start
end

#--------------------------------------------------------------------------
def collectEdges( entity, trans )
  return if not entity.visible?
  collectEdge( entity ) if entity.is_a? Sketchup::Edge
end

#--------------------------------------------------------------------------
def DumpGroup( entity, etrans, trans, name )
  subtrans = combineTransformation( trans, etrans )

  @edges = []
  @vertices = []
  entity.entities.each { |sub| collectEdges( sub, subtrans ) }
  
  @vertices.uniq!
  @edges.uniq!

  if @edges.length>0
    @file.write name
    @file.write "V %d\n" % @vertices.length
    @vertices.each { |vert| dumpVertex( vert, subtrans ) }
    @file.write "E %d\n" % @edges.length
    @edges.each { |edge| dumpEdge( edge ) }
  end
  
  entity.entities.each { |sub| dumpEntity( sub, subtrans ) }
end

#--------------------------------------------------------------------------
def dumpEntity( entity, trans )

  return if not entity.visible?

  #----------- GROUP -----------------
  if entity.is_a? Sketchup::Group

    DumpGroup( entity, entity.transformation, trans, "G %s\n" % entity.name.to_s );

  #----------- COMPONENT -----------------
  elsif entity.is_a? Sketchup::ComponentInstance
    DumpGroup( entity.definition, entity.transformation, trans, "G %s_%s\n" % [entity.definition.name.to_s, entity.entityID.to_s] );

  end
end

#--------------------------------------------------------------------------
def dumpToFile( filename, what )

  @file = File.new( filename, "w" )
  if not @file
          UI.messagebox "Problem opening @file "+filename+" for writing", MB_OK, "Error"
          return
  end

  begin
    @file.write "Sketchup Edge Data\n"
    what.each{ |entity| dumpEntity( entity, nil ) }
  rescue StandardError => bang
    @file.write "\nClosed due to error: " + bang
    raise
  ensure
    @file.close
  end
end

end

#-----------------------------------------------------------------------------
def dumpEdgeDataFile( filename )
    model=Sketchup.active_model
    what=model.selection

    # nothing selected? Use whole model
    if (what.count==0)
      what = model.entities
    end

    begin
      exporter = EdgeDataExporter.new()
      exporter.dumpToFile( filename, what )
    rescue => bang
      print "Error: " + bang
    end
end
#--------------------------------------------------------------------------

#--------------------------------------------------------------------------
def DoEdgeDataExport()
    proposal = File.basename( Sketchup.active_model.path )
    if proposal != ""
      proposal = proposal.split(".")[0]
      proposal += ".edf"
    else
      proposal = "Untitled.edf"
    end

    filename = UI.savepanel( "Export Edge Data File", nil, proposal )

    dumpEdgeDataFile( filename ) if filename
    Sketchup.send_action "showRubyPanel:"
    print `mvim`
    print `echo python ~/Projects/ScratchHolograms/pattern_printer.py #{filename}`
    system("python ~/Projects/ScratchHolograms/pattern_printer.py #{filename}")
end

#--------------------------------------------------------------------------
# Register within Sketchup
if(file_loaded("sketch_to_pattern.rb"))
 	menu = UI.menu("Plugins");
	menu.add_item("Make Scratch Pattern...") { DoEdgeDataExport() }
end

#--------------------------------------------------------------------------
file_loaded("sketch_to_pattern.rb")
