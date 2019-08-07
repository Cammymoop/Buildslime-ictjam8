extends Node

var r_menu

func set_menu(menu):
	r_menu = menu

func handle_item_selected(value, extra) -> bool:
	match value:
		'return':
			return true
		'get-job':
			if extra == -1:
				var max_job = get_node("/root/JobManager").get_next_job()
				if max_job == 1:
					find_parent('Root').find_node('Player').menu_selection('job', 1) # TODO refactor
					return true
				else:
					r_menu.add_child_numbers_prompt('get-job', 'Choose a job:', max_job, 1, max_job)
			else:
				find_parent('Root').find_node('Player').menu_selection('job', extra) # TODO refactor
				return true
		'restart-game':
			if extra == -1:
				r_menu.add_child_confirm_prompt('restart-game', 'Are you sure you want to reset?')
			else:
				if extra == 1:
					get_tree().reload_current_scene()
		'eval-job':
			if extra == 1:
				return true
			var the_map = find_parent('Root').find_node('JobMap') # TODO refactor
			var global = get_node("/root/GlobalData")
			var job_passed = get_node("/root/JobManager").check_job_completion(global.get_current_job_num(), the_map)
			if job_passed:
				r_menu.add_child_confirm_prompt('finish-job', 'Great! That\'s perfect! Are you done here?')
			else:
				print('adding popup')
				r_menu.add_text_popup("Hm, that's not quite right", 'eval-job', 1, true)
		'finish-job':
			if extra == 1:
				find_parent('Root').find_node('Player').menu_selection('finish-job', 1) # TODO refactor
				return true
			else:
				return true
		'leave-job':
			if extra == -1:
				r_menu.add_child_confirm_prompt('leave-job', 'Are you sure you leave?\n')
			else:
				if extra == 1:
					find_parent('Root').find_node('Player').menu_selection('leave-job', 1) # TODO refactor
					return true
		'view-job':
				find_parent('Root').find_node('Player').menu_selection('view-job', extra) # TODO refactor
				return true
		'save-game':
			if extra == -1:
				var max_save = 6
				r_menu.add_child_numbers_prompt('save-game', 'Choose a save:', 1, 1, max_save)
			else:
				var global = get_node("/root/GlobalData")
				var screenshotter = get_node("/root/Screenshotter")
				var scrn_name = screenshotter.get_screenshot_name(global.save_name) + '.png'
				r_menu.deactivate_menu()
				
				var pause_screen = find_parent('PauseScreen')
				pause_screen.queue_screenshot(scrn_name)
				print('yielding for screenshot')
				yield(pause_screen, "took_screenshot")
				print('done yielding for screenshot')
				
				r_menu.activate_menu()
				get_node("/root/SaveManager").save_game(str(extra), scrn_name)
				return false
		'load-game':
			if typeof(extra) == TYPE_INT and extra == -1:
				#print(len(get_node("/root/SaveManager").get_all_saves()))
				r_menu.add_child_file_menu('load-game')
			elif typeof(extra) == TYPE_STRING:
				print('want to load: ' + extra)
				get_node("/root/SaveManager").load_game(extra)
				return true
	
	# dont close menu
	return false


#	options.append(make_menu_option("return", "Return"))
#	options.append(make_menu_option("job", "Get job"))
#	options.append(make_menu_option("save-game", "Save"))
#	if loadable:
#		options.append(make_menu_option("load-game", "Load"))
#	options.append(make_menu_option("restart-game", "Reset Game"))