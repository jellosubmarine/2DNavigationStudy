extends RigidBody2D

const right_track_distance = 11 #m
const max_force = 100000
const px2meter = 0.1 #1 pixel is 10cm
const motor_brake = 10000

var track_forces = Vector2() #track forces

func add_force_local(pos: Vector2, force: Vector2):
	var pos_local = self.transform.basis_xform(pos)
	var force_local = -self.transform.basis_xform(force) 
	self.add_force(pos_local, force_local)

	
func get_input():
	track_forces = Vector2()
	if Input.is_action_pressed("forward"):
		track_forces.x = max_force
		track_forces.y = max_force
	if Input.is_action_pressed("backward"):
		track_forces.x = -max_force
		track_forces.y = -max_force
	if Input.is_action_pressed("left"):
		track_forces.x = -max_force
		track_forces.y = max_force
	if Input.is_action_pressed("right"):
		track_forces.x = max_force
		track_forces.y = -max_force
	

func _ready():
	pass

func _physics_process(delta):
	applied_force = Vector2()
	applied_torque = 0
	get_input()
	add_force_local(Vector2(-right_track_distance,0), Vector2(0,track_forces.x)) #left
	add_force_local(Vector2(right_track_distance,0), Vector2(0,track_forces.y)) #right
