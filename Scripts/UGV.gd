extends RigidBody2D

# Constants
const TRACK_DIST_FROM_CENTER = 11 #px
const WHEEL_RADIUS = 1 # unknown
const PX2METER = 0.1 #1 pixel is 10cm
const MAX_LIN_SPEED = 3/PX2METER #m/s
const MAX_ANG_SPEED = 2 #rad/s
const GRAVITY = 50

# Internal Classes
class State:
	var l_linear_vel = Vector2()
	var g_linear_vel = Vector2()
	var angular_vel = 0.0
	var mass = 1600

class EnvironmentalForces:
	var central_force : Vector2
	var central_torque : float

class Friction:
	var friction_x = 0.9
	var friction_y = 0.2
	var friction_ang = 0.2
	func calculateFriction(state: State) -> EnvironmentalForces:
		var env_forces = EnvironmentalForces.new()
		env_forces.central_force.x = -1*sign(state.l_linear_vel.x)*friction_x*state.mass*GRAVITY
		env_forces.central_force.y = -1*sign(state.l_linear_vel.y)*friction_y*state.mass*GRAVITY
		env_forces.central_torque = -1*sign(state.angular_vel)*friction_ang*state.mass*GRAVITY*TRACK_DIST_FROM_CENTER
		return env_forces
	
class UGVController:
	var braking_coefficient : float = 1000
	
	func cmd_vel_to_lr(_velocity : Vector2) -> Vector2:
		#convert cmd_vel to individual track speeds
		var lr_rpm = Vector2()
		var lin_vel = _velocity.x
		var ang_vel = _velocity.y
		lr_rpm.x = (lin_vel - ang_vel*TRACK_DIST_FROM_CENTER*PX2METER)
		lr_rpm.y = (lin_vel + ang_vel*TRACK_DIST_FROM_CENTER*PX2METER)
		return lr_rpm
		
	func calculateUGVDynamics(target_velocity, state: State) -> Vector2:
		var target_track_velocities =  cmd_vel_to_lr(target_velocity)
#		print(local_linear_velocity)
		var current_track_velocities = cmd_vel_to_lr(Vector2(state.l_linear_vel.y, state.angular_vel))
		print(state.l_linear_vel)
		var track_forces = Vector2()
		if (target_velocity.length() == 0):
			#engine brake
			track_forces.x = -1*current_track_velocities.x*braking_coefficient 
			track_forces.y = -1*current_track_velocities.y*braking_coefficient
		else: 
			track_forces.x = target_track_velocities.x * 5000
			track_forces.y = target_track_velocities.y * 5000
		return track_forces

# Class variables
var target_velocity = Vector2()
var frictionForces : Friction
var ugv_controller : UGVController

func add_force_local(pos: Vector2, force: Vector2):
	var pos_local = self.transform.basis_xform(pos)
	var force_local = -self.transform.basis_xform(force) 
	self.add_force(pos_local, force_local)
	
func get_input():
	target_velocity = Vector2()
	if Input.is_action_pressed("forward"):
		target_velocity.x = MAX_LIN_SPEED
	if Input.is_action_pressed("backward"):
		target_velocity.x = -MAX_LIN_SPEED
	if Input.is_action_pressed("left"):
		target_velocity.y = MAX_ANG_SPEED
	if Input.is_action_pressed("right"):
		target_velocity.y = -MAX_ANG_SPEED

func _ready():
	ugv_controller = UGVController.new()
	frictionForces = Friction.new()

func _process(delta):
	get_input()

func _physics_process(delta):
	var state = State.new()
	state.g_linear_vel = linear_velocity
	state.l_linear_vel = -transform.basis_xform_inv(linear_velocity)
	state.angular_vel = angular_velocity
	# Zero current forces
	applied_force = Vector2()
	applied_torque = 0
	# Calculate current forces
	var friction_forces = frictionForces.calculateFriction(state)
	add_force_local(Vector2(), friction_forces.central_force)
	add_torque(friction_forces.central_torque)
	var track_forces = ugv_controller.calculateUGVDynamics(target_velocity, state)
	add_force_local(Vector2(-TRACK_DIST_FROM_CENTER,0), Vector2(0,track_forces.x)) #left
	add_force_local(Vector2(TRACK_DIST_FROM_CENTER,0), Vector2(0,track_forces.y)) #right
