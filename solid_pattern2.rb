require 'sketchup.rb'

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
  num_angle_steps = (view_angle_range[1] - view_angle_range[0]) / @angle_step_rad
  ray_vector = Geom::Transformation.rotation(pos,
											 @rot_axis_vector,
											 view_angle_range[0]) * @sweep_start
  sweep_step_xform = Geom::Transformation.rotation(pos,
												   @rot_axis_vector,
												   @angle_step_rad)
  (1..num_angle_steps).each do |i|
	  intersect = $model.raytest([pos, ray_vector])
	  angle = view_angle_range[0] + (i-1) * @angle_step_rad
	  # if intersect
	  #     puts "from"
	  #     puts pos
	  #     puts "direction"
	  #     puts ray_vector
	  #     puts "intersect"
	  #     puts intersect[0]
	  # end
	  if (!intersect) and (!arc_on)
		  puts "turning arc on at"
		  puts ray_vector
		  @file.write "%.3f,%.3f,%.3f,%3f," % [pos[0],
			  pos[1],
			  pos[2],
			  angle]
		  arc_on = true
	  elsif (intersect) and (arc_on)
		  puts "turning arc off at"
		  puts ray_vector
		  @file.write "%.3f\n" % [angle - @angle_step_rad]
		  arc_on = false
	  end
	  ray_vector = sweep_step_xform * ray_vector
  end
  if arc_on
	  puts "turning arc off at"
	  puts ray_vector
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
    @vertices.each { |vert| dumpVertex( vert, subtrans ) }
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
	@angle_step_rad = 1 * Math::PI / 180
	@sweep_start = Geom::Vector3d.new(1, 0, 0)
    @rot_axis_vector = Geom::Vector3d.new(0, 0, 1)

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
    $model=Sketchup.active_model
    what=$model.selection

    # nothing selected? Use whole model
    if (what.count==0)
      what = $model.entities
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
end

# Register within Sketchup
if(file_loaded("solid_pattern2.rb"))
	 menu = UI.menu("Plugins");
	menu.add_item("Make Solid Scratch Pattern2...") { ExportPattern() }
end

#--------------------------------------------------------------------------
file_loaded("solid_pattern2.rb")
