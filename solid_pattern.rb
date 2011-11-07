require 'sketchup.rb'

SCRIPTS_DIR = "/Users/robindeits/Projects/ScratchHolograms"
PYTHON_PATH = "/usr/local/bin/python"

###########################################################
#
#    This program is based heavily on the dataexporter plugin
#    http://modelisation.nancy.archi.fr/rld/plugin_details.php?id=101
#
#    Which was distributed with the following copyright information:
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
  arc_on = false
  view_angle_range = [-Math::PI / 3, Math::PI / 3]
  sweep_start = @camera.eye - pos
  num_angle_steps = (view_angle_range[1] - view_angle_range[0]) / @angle_step_rad
  ray_vector = Geom::Transformation.rotation(pos,
											 @rot_axis_vector,
											 view_angle_range[0]) * sweep_start
  sweep_step_xform = Geom::Transformation.rotation(pos,
												   @rot_axis_vector,
												   @angle_step_rad)
  (1..num_angle_steps).each do |i|
	  intersect = @model.raytest([pos, ray_vector])
	  angle = view_angle_range[0] + (i-1) * @angle_step_rad
	  if (!intersect) and (!arc_on)
		  @file.write "%.3f,%.3f,%.3f,%3f," % [
			  @camera.eye.vector_to(pos).dot(@camera.xaxis),
			  @camera.eye.vector_to(pos).dot(@camera.yaxis),
			  @camera.eye.vector_to(pos).dot(@camera.zaxis.reverse)+@z_offset,
			  angle]
		  arc_on = true
	  elsif (intersect) and (arc_on)
		  @file.write "%.3f\n" % [angle - @angle_step_rad]
		  arc_on = false
	  end
	  ray_vector = sweep_step_xform * ray_vector
  end
  if arc_on
	  arc_on = false
	  @file.write "%.3f\n" % view_angle_range[1]
  end
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
	num_segments = (edge.length / @interpolate_step).round
	# puts "num_segments"
	# puts num_segments
	if num_segments > 1
		(1..(num_segments-1)).each do |i|
			remaining_segments = (edge.length / @interpolate_step)
			# puts "remaining segments"
			# puts remaining_segments
			# puts "splitting at"
			# puts 1.0 - 1.0 / remaining_segments
			new_edge = edge.split(1.0 - 1.0 / remaining_segments)
			@edges << new_edge
			@vertices << new_edge.end
		end
	end
  @edges << edge
  @vertices << edge.end
  @vertices << edge.start
end

#--------------------------------------------------------------------------
def collectEdges( entity, trans )
  # return if not entity.visible?
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
    @vertices.each { |vert| dumpVertex( vert, subtrans ) }
  end
  
  entity.entities.each { |sub| dumpEntity( sub, subtrans ) }
end

#--------------------------------------------------------------------------
def dumpEntity( entity, trans )

  # return if not entity.visible?

  #----------- GROUP -----------------
  if entity.is_a? Sketchup::Group

    DumpGroup( entity, entity.transformation, trans, "G %s\n" % entity.name.to_s );

  #----------- COMPONENT -----------------
  elsif entity.is_a? Sketchup::ComponentInstance
    DumpGroup( entity.definition, entity.transformation, trans, "G %s_%s\n" % [entity.definition.name.to_s, entity.entityID.to_s] );

  end
end

#--------------------------------------------------------------------------
def dumpToFile( filename )
    @model=Sketchup.active_model
    what=@model.selection

    # nothing selected? Use whole model
    if (what.count==0)
      what = @model.entities
    end
	@camera = @model.active_view.camera
	origin = Geom::Point3d.new(0,0,0)
	@z_offset = @camera.eye.vector_to(origin.project_to_line([@camera.eye, @camera.direction])).length
	@angle_step_rad = 1 * Math::PI / 180
	@rot_axis_vector = @camera.yaxis
    # @rot_axis_vector = Geom::Vector3d.new(0,0,1)
	interpolate_resolution = 10
	bounds = @model.bounds
	max_bound = [bounds.width, bounds.height, bounds.depth].max
	@interpolate_step = max_bound / interpolate_resolution

  @file = File.new( filename, "w" )
  if not @file
          UI.messagebox "Problem opening @file "+filename+" for writing", MB_OK, "Error"
          return
  end

  begin
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

    begin
      exporter = EdgeDataExporter.new()
      exporter.dumpToFile( filename )
    rescue => bang
      print "Error: " + bang
    end
end
#--------------------------------------------------------------------------

#--------------------------------------------------------------------------
def ExportPattern()
	Sketchup.send_action "showRubyPanel:"
    proposal = File.basename( Sketchup.active_model.path )
    if proposal != ""
      proposal = proposal.split(".")[0]
      proposal += ".pattern"
    else
      proposal = "Untitled.pattern"
    end

    filename = UI.savepanel( "Export Edge Data File", nil, proposal )

    dumpEdgeDataFile( filename ) if filename
	puts "Finished exporting vertex data."
	puts "Running python script..."
	base_dir = File.dirname(Sketchup.active_model.path)
	scripts_dir = SCRIPTS_DIR
	Dir.chdir(scripts_dir)
	d = IO.popen(PYTHON_PATH + " draw_pattern.py " + base_dir + "/" + proposal)
	puts "Done. Python results will appear as soon as they are completed"
end

# Register within Sketchup
if(file_loaded("solid_pattern.rb"))
	 menu = UI.menu("Plugins");
	menu.add_item("Make Solid Scratch Pattern...") { ExportPattern() }
end

#--------------------------------------------------------------------------
file_loaded("solid_pattern.rb")
