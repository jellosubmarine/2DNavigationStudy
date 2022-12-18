extends Path2D

func _process(delta):
	var l = Line2D.new()   
	l.default_color = Color(1,1,1,1)  
	l.width = 20  
	for point in curve.get_baked_points():  
		l.add_point(point + position) 
