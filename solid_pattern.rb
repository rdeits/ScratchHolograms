require 'sketchup.rb'

SCRIPTS_DIR = "/Users/robindeits/Projects/ScratchHolograms"
PYTHON_PATH = "/usr/local/bin/python"

MIN_RESOLUTION = 10
MAX_RESOLUTION = 50

IMAGE_SIZE_IN = 4
VIEWING_HEIGHT_IN = 24


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
  # puts pos
  # if @last_plotted_point
  #     if @last_plotted_point.distance(pos) < @min_separation
  #         return
  #     end
  # end
  # @last_plotted_point = pos
  @plotted_points.each do |point|
	  if pos.distance(point) < @min_separation
		  return
	  end
  end
  @plotted_points.insert(pos)
  arc_on = false
  # sweep_start = @camera.eye - pos
  # sweep_start = @camera.zaxis.reverse 
  # ray_vector = Geom::Transformation.rotation(pos,
  #                                            @rot_axis_vector,
  #                                            @view_angle_range[0]) * sweep_start
  # sweep_step_xform = Geom::Transformation.rotation(pos,
  #                                                  @rot_axis_vector,
  #                                                  @angle_step_rad)

  view_pos = @view_start_pos
  (1..@num_angle_steps).each do |i|
	  intersect = @model.raytest([pos, pos.vector_to(view_pos)])
	  angle = Math.atan2(view_pos.x - pos.x, view_pos.z - pos.z)
	  if (!intersect) and (!arc_on)
		  @file.write "%.3f,%.3f,%.3f,%3f," % [
			  pos.x,
			  pos.y,
			  pos.z,
			  angle]
		  arc_on = true
	  elsif (intersect) and (arc_on)
		  @file.write "%.3f\n" % (angle - @angle_step_rad)
		  arc_on = false
	  end
	  view_pos = @view_step_xform * view_pos
  end
  if arc_on
	  arc_on = false
	  @file.write "%.3f\n" % (Math.atan2(view_pos.x - pos.x, view_pos.z - pos.z))
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
	@plotted_points = Set.new()
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
	@angle_step_rad = 1 * Math::PI / 180
	rot_axis_vector = Geom::Vector3d.new(0, 1, 0)
    @view_angle_range = [-Math::PI / 3, Math::PI / 3]
    @num_angle_steps = (@view_angle_range[1] - @view_angle_range[0]) / @angle_step_rad
	# view_rot_center = origin.project_to_line([@camera.eye, @camera.direction]) 
    # @view_step_xform = Geom::Transformation.rotation(view_rot_center,
	#                                                  rot_axis_vector,
	#                                                 @angle_step_rad)
	# @view_start_pos = Geom::Transformation.rotation(view_rot_center,
	#                                                 rot_axis_vector,
	#                                                 @view_angle_range[0]) * @camera.eye
	
	@plotted_points = Set.new()
    # @rot_axis_vector = Geom::Vector3d.new(0,0,1)
	bounds = @model.bounds
	model_size = [bounds.width, bounds.height, bounds.depth].max
	view_radius = VIEWING_HEIGHT_IN / IMAGE_SIZE_IN * model_size
	@view_start_pos = Geom::Point3d.new(0, 0, view_radius).transform(
		Geom::Transformation.rotation(origin,
									  rot_axis_vector,
									  @view_angle_range[0]))
	@view_step_xform = Geom::Transformation.rotation(origin,
													rot_axis_vector,
													@angle_step_rad)
	@interpolate_step = model_size / MIN_RESOLUTION
	@min_separation = model_size / MAX_RESOLUTION
	# @last_plotted_point = nil

  @file = File.new( filename, "w" )
  if not @file
          UI.messagebox "Problem opening @file "+filename+" for writing", MB_OK, "Error"
          return
  end

  # begin
    what.each{ |entity| dumpEntity( entity, nil ) }
  # ensure
    @file.close
  # end
end

end

#-----------------------------------------------------------------------------
def dumpEdgeDataFile( filename )

      exporter = EdgeDataExporter.new()
      exporter.dumpToFile( filename )
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
	if !proposal
		return
	end

    dumpEdgeDataFile( filename ) if filename
	puts "Finished exporting vertex data."
	puts "Running python script..."
	base_dir = File.dirname(filename)
	scripts_dir = SCRIPTS_DIR
	Dir.chdir(scripts_dir)
	d = IO.popen(PYTHON_PATH + " draw_pattern.py " + base_dir + "/" + proposal)
	puts "Data export done. Python results will appear as soon as they are completed"
	while d.gets != nil
		puts d.gets
	end
end

# Register within Sketchup
if(file_loaded("solid_pattern.rb"))
	 menu = UI.menu("Plugins");
	menu.add_item("Make Solid Scratch Pattern...") { ExportPattern() }
end

#--------------------------------------------------------------------------
file_loaded("solid_pattern.rb")
