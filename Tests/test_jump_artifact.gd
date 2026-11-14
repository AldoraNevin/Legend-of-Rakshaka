extends SceneTree
func _initialize():
 call_deferred("run")
func run():
 var saved = player_data.discovered_artifacts.duplicate()
 player_data.discovered_artifacts=[]
 var player=load("res://Scenes/Player/player.tscn").instantiate()
 root.add_child(player)
 player.set_physics_process(false)
 assert(player.max_jump==1)
 player.jump_count=1
 assert(not player.try_jump())
 player_data.discovered_artifacts=["Daun Kelor"]
 assert(not player.try_jump())
 player_data.discovered_artifacts=["Selendang Bidadari"]
 assert(player.try_jump())
 assert(player.max_jump==2 and player.jump_count==2)
 assert(not player.try_jump())
 player_data.discovered_artifacts=["selendang_bidadari"]
 assert(player_data.has_artifact("Selendang Bidadari"))
 player_data.discovered_artifacts=[]
 player_data.apply_player_stats(player)
 assert(player.max_jump==1)
 assert(player.max_wall_jump==2)
 player.wall_jump()
 assert(player.velocity.y==-player.wall_jump_force)
 assert(not player.try_jump())
 var tiles=load("res://Assets/Tileset/pantai_modular_solid.tres")
 var a=tiles.get_source(0)
 for x in range(8):
  var polygon=a.get_tile_data(Vector2i(x,4),0).get_collision_polygon_points(0,0)
  assert(polygon.size()>=3)
  assert(polygon!=PackedVector2Array([Vector2(-32,-32),Vector2(32,-32),Vector2(32,32),Vector2(-32,32)]))
 player_data.discovered_artifacts=saved
 player.queue_free()
 await process_frame
 print("PASS: air jump locked; only Selendang unlocks second jump; no third jump; wall jump retained; slope polygons configured.")
 quit()
