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
	angle_step_rad = 1 * Math::PI / 180
	camera_angle_range = [-Math::PI/3, Math::PI/3]
	sweep_angle_range = [0, Math::PI * 2]
	num_camera_steps = (camera_angle_range[1] - camera_angle_range[0]) / angle_step_rad
	num_sweep_steps = (sweep_angle_range[1] - sweep_angle_range[0]) / angle_step_rad
	sweep_start = Geom::Vector3d.new(-1, 0, 0)

    rot_axis_vector = Geom::Vector3d.new(0, 0, 1)
    model_center = Geom::Point3d.new(0,0,0)
	camera_step_xform = Geom::Transformation.rotation(model_center,
													  rot_axis_vector,
													  angle_step_rad)
	num_z_steps = 5
    model = Sketchup.active_model
    view = model.active_view
    eye = view.camera.eye
	camera_start = Geom::Transformation.rotation(model_center,
												 rot_axis_vector,
												 camera_angle_range[0]) * eye
	scanner = ModelScanner.new()
	zRange = scanner.getModelZRange( model )
	# puts zRange
	z_step = (zRange[1] - zRange[0]) / (num_z_steps-1)
	(1..num_z_steps).each do |i|
		z = zRange[0] + (i-1) * z_step
		z_vector = Geom::Vector3d.new(0, 0, z)
		z_xform = Geom::Transformation.translation(z_vector)
		# puts "z=", z
		camera = camera_start
		(1..num_camera_steps).each do |j|
			sweep_step_xform = Geom::Transformation.rotation(camera,
															 rot_axis_vector,
															 angle_step_rad)
			sweep_vector = sweep_start
			(1..num_sweep_steps).each do |k|
				item = model.raytest([z_xform * camera, 
					sweep_vector])
				# puts camera
				# puts sweep_vector
				if item
					coords = item[0]
					# puts "hit at", coords
					file.write "%.3f,%.3f,%.3f,%.3f,%.3f\n" % [coords[0], 
						coords[1],
					   	coords[2], 
						-(sweep_angle_range[0] + (k-1.5) * angle_step_rad),
						-(sweep_angle_range[0] + (k-0.5) * angle_step_rad)]
				end
				sweep_vector = sweep_step_xform * sweep_vector
			end
			camera = camera_step_xform * camera
		end
	end
	puts "done"
	file.close
end

# Register within Sketchup
if(file_loaded("solid_pattern.rb"))
	 menu = UI.menu("Plugins");
	menu.add_item("Make Solid Scratch Pattern...") { ExportPattern() }
end

#--------------------------------------------------------------------------
file_loaded("solid_pattern.rb")
