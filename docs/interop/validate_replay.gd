extends SceneTree
# Independent source-data checks; no claim of a second shipped game runtime.
func _initialize():
 var args = OS.get_cmdline_user_args()
 if args.size() != 1:
  push_error("Provide the exported replay JSON path")
  quit(1)
  return
 var data = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
 if data == null or data.get("size") != 9:
  quit(1)
  return
 var last_score = 0
 for turn in data.turns:
  assert(turn.before.size() == 81 and turn.after.size() == 81)
  for tile in turn.after:
   assert(tile >= 0 and tile <= 5)
  var a = int(turn.swap[0])
  var b = int(turn.swap[1])
  assert(abs(a % 9 - b % 9) + abs(a / 9 - b / 9) == 1)
  assert(turn.score >= last_score and turn.moves >= 0)
  last_score = turn.score
 print("Godot replay validation passed: ", data.turns.size(), " turns / 81 cells")
 quit(0)
