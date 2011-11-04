require 'sketchup.rb'
# require 'gsl'

class ModelScanner
	def getModelZRange( model )
		zRange = [nil, nil]
		model.entities.each do |entity|
			entityZRange = getEntityZRange( entity )
			if entityZRange
				if !zRange[0] or entityZRange[0] < zRange[0]
					zRange[0] = entityZRange[0]
				end
				if !zRange[1] or entityZRange[1] > zRange[1]
					zRange[1] = entityZRange[1]
				end
			end
		end
		return zRange
	end

	def getEntityZRange( entity )
		trans = nil
		if entity.is_a? Sketchup::Group
	  
		  zRange = getGroupZRange( entity, entity.transformation, trans, "G %s\n" % entity.name.to_s );
	  
		#----------- COMPONENT -----------------
		elsif entity.is_a? Sketchup::ComponentInstance
		  zRange = getGroupZRange( entity.definition, entity.transformation, trans, "G %s_%s\n" % [entity.definition.name.to_s, entity.entityID.to_s] );
	  
		end
		return zRange
	end

	def getGroupZRange( entity, etrans, trans, name )
		subtrans = combineTransformation( trans, etrans )
		@edges = []
		@vertices = []
		entity.entities.each { |sub| collectEdges( sub, subtrans ) }
		
		@vertices.uniq!
		@edges.uniq!
		zRange = [nil, nil]
		@vertices.each do |vertex| 
			pos = subtrans * vertex.position
			if !zRange[0] or pos[2] < zRange[0]
				zRange[0] = pos[2]
			end
			if !zRange[1] or pos[2] > zRange[1]
				zRange[1] = pos[2]
			end
			# print vertex.position.to_s + "\n"
			# print zRange.to_s + "\n"
		end
		return zRange
	end

	def collectEdge( edge )
	  @edges << edge
	  @vertices << edge.end
	  @vertices << edge.start
	end

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
	def collectEdges( entity, trans )
	  return if not entity.visible?
	  collectEdge( entity ) if entity.is_a? Sketchup::Edge
	end
end


def ExportPattern()
    proposal = File.basename( Sketchup.active_model.path )
    if proposal != ""
      proposal = proposal.split(".")[0]
      proposal += ".pattern"
    else
      proposal = "Untitled.pattern"
    end

    filename = UI.savepanel( "Export Pattern File", nil, proposal )
	Sketchup.send_action "showRubyPanel:"
    DumpPatternFile( filename ) if filename
end

def DumpPatternFile( filename )
	file = File.open(filename, mode="wb")
	if not file
	  	  UI.messagebox "Problem opening @file "+filename+" for writing", MB_OK, "Error"
	  	  return
	end
    view_angle = Math::PI/2
    num_angle_steps = 20
	num_z_steps = 5
    angle_step = 2 * view_angle / (num_angle_steps - 1)
    model = Sketchup.active_model
    view = model.active_view
    camera = view.camera
    eye = camera.eye
    rot_axis_vector = Geom::Vector3d.new(0, 0, 1)
    model_center = Geom::Point3d.new(0,0,0)
    ray_init_xform = Geom::Transformation.rotation(model_center,
                                                    rot_axis_vector,
                                                    -view_angle)
	scan_xform = Geom::Transformation.rotation(model_center,
                                                  rot_axis_vector,
                                                  angle_step)
	scanner = ModelScanner.new()
	zRange = scanner.getModelZRange( model )
	# puts zRange
	z_step = (zRange[1] - zRange[0]) / (num_z_steps-1)
	(1..num_z_steps).each do |i|
		z = zRange[0] + (i-1) * z_step
		z_vector = Geom::Vector3d.new(0, 0, z)
		z_xform = Geom::Transformation.translation(z_vector )
		# puts "z=", z
		ray_start = ray_init_xform * eye
		(1..num_angle_steps).each do |j|
			# puts "angle=", -view_angle + (j-1) * angle_step
			# puts model_center
			# puts ray_start
			# puts model_center-ray_start
			# puts Geom::Vector3d.new(model_center-ray_start)
			item = model.raytest([z_xform * ray_start, 
								 model_center-ray_start])
			if item
				coords = item[0]
				puts "hit at", coords
				file.write "%.3f,%.3f,%.3f,%.3f,%.3f\n" % [coords[0], coords[1], coords[2], (-view_angle + (j-1.5) * angle_step), (-view_angle + (j-0.5) * angle_step)]
			end
			ray_start = scan_xform * ray_start
		end
	end
	file.close
end

# Register within Sketchup
if(file_loaded("solid_pattern.rb"))
	 menu = UI.menu("Plugins");
	menu.add_item("Make Solid Scratch Pattern...") { ExportPattern() }
end

#--------------------------------------------------------------------------
file_loaded("solid_pattern.rb")
