extends Node

# Name:    WikiTools
# Version: 1.0.0
# Updated: 2022-12-16 (16th Dec)
# Author:  Darkly77
#
# Usage: Add to your project and autoload this script. Call it `WikiTools`.
# Replace the function in _ready with whichever one you want to run
#
# Results can either be printed to the debug log:
#   %appdata%/Brotato/logs/godot.log
# Or saved to a file:
#   %appdata%/Brotato/wiki-output.html


# Config
# ==============================================================================

var image_prefixes = {
	none       = "", # use for vanilla
	invasion   = "Space_Gladiators-", # Mod:Invasion
	extatonion = "Mod-Extatonion-",   # Mod:Extatonion
	# Add your own mod setting here, then apply it to config.image_prefix
}

var config = {

	# Funcs to run
	do_statscard  = true,   # If true, runs the statscard template generator
	do_basiclog   = false,  # If true, does a basic log listing all items, to godot.log

	# Saving
	output_print  = false,  # If true, prints the output: user://godot.log - %appdata%/Brotato/godot.log
	output_save   = true,   # If true, saves the output:  user://wiki-output.html - %appdata%/Brotato/wiki-output.html

	# Items
	skip_vanilla        = true,   # If true, vanilla items are ignored in the output
	items_count_vanilla = 158,    # Number of items in vanilla
	sort_by_alpha       = true,   # Sort alphabetically (abc)
	sort_by_tier        = true,   # Sort by rarity/tier
	skip_items = [                # Hide certain items from the loop. Accepts item IDs (`my_id`)
		# "item_invasion_info"
	],

	# Output: Top Text
	mod_link        = 'Mod:Invasion', # Mod page name. Used to show a link back to the mod page
	add_toptext     = true,     # If true, adds extra info above everything else
	add_disclaimers = true,     # If true, adds notes before the main output, saying the page is auto generated and uses JS
	mod_version     = '1.2.0',  # Shown above the content
	mod_unreleased  = true,     # If true, the output states that the shown items are part of an unreleased version

	# Output: Table/Wrapper
	max_cols      = 5,       # Number of table columns. 5 works best on desktop
	add_controls  = true,    # If true, adds {{StatsCard_GridToggles}}
	center_wrap   = true,    # If true, wraps the table in a center-aligned div

	# Output: General
	show_cost     = true,    # If true, shows the item cost in small text, after all its other stats
	show_tags     = true,    # If true, shows the item tags in small text, after the cost and other stats
	type          = "item",  # Type (either: item, weapon, character, difficulty). Only "item" is supported atm

	# Output: Image
	image_prefix = image_prefixes.invasion, # Change to your mod's image prefix (string). Leave blank (image_prefixes.none) for vanlla items
}


# Init
# ==============================================================================

# Called when the node enters the scene tree for the first time
# (ie. runs immediately when the game launches)
func _ready():
	if config.do_statscard:
		statscard_log()
	if config.do_basiclog:
		basic_log()
	pass


# Log - Template:StatsCard
# ==============================================================================

func statscard_log():

	# ----------------------------------------
	# Items - Setup + Sorting
	# ----------------------------------------

	# The array of items that are actually used in the loop
	var items_arr = []

	# Copy ItemService.items directly if vanilla isn't skipped and skip_items is empty
	if !config.skip_vanilla && config.skip_items.size() == 0:
		items_arr = ItemService.items.duplicate()
	else:
		# Filter out vanilla & skipped items
		# (expensive since we're also looping below, but acceptable in this use case)
		for i in ItemService.items.size():
			if config.skip_vanilla && (i+1 <= config.items_count_vanilla):
				continue
			if config.skip_items.size() > 0 and config.skip_items.find( ItemService.items[i].my_id ) != -1:
				continue
			items_arr.push_back(ItemService.items[i])

	var instance_MyItemSorter = MyItemSorter.new()

	# Sort items alphabetically
	if config.sort_by_alpha:
		# items_arr.sort_custom(instance_MyItemSorter, "sort_ascending_byname") # static, but doesn't apply translations
		items_arr.sort_custom(instance_MyItemSorter, "sort_ascending_byname_translated") # non-static version

	# ----------------------------------------
	# Items - Sort by Tier
	# ----------------------------------------

	# Optional: Sort by rarity/tier
	if config.sort_by_tier:
		var items_tier1 = []
		var items_tier2 = []
		var items_tier3 = []
		var items_tier4 = []

		for i in items_arr.size():
			if items_arr[i].tier == 0:
				items_tier1.push_back(items_arr[i])

		for i in items_arr.size():
			if items_arr[i].tier == 1:
				items_tier2.push_back(items_arr[i])

		for i in items_arr.size():
			if items_arr[i].tier == 2:
				items_tier3.push_back(items_arr[i])

		for i in items_arr.size():
			if items_arr[i].tier == 3:
				items_tier4.push_back(items_arr[i])

		items_arr.clear()
		items_arr.append_array(items_tier1)
		items_arr.append_array(items_tier2)
		items_arr.append_array(items_tier3)
		items_arr.append_array(items_tier4)

	# ----------------------------------------
	# Output - Start & Extras
	# ----------------------------------------

	print("[wiki_tools] statscard_log")

	var html = ""

	# Top text
	if config.add_toptext:
		html += '[[' + config.mod_link + '|< Back to Mod Page]]'
		html += "\n\nThese items are for version: '''" + config.mod_version + "'''."
		if config.mod_unreleased:
			html += " This version hasn't been released yet."
		html += "\n\nCurrent items total: " + str( items_arr.size() )

	# Disclaimers
	if config.add_disclaimers:
		html += "\n\n\n''{{Color|grey|This page content was automatically generated so may have issues.}}''"
		html += "\n\n''{{Color|pastelred|This page uses custom scripts that are often updated. Please use Ctrl+F5 to ensure your browser is using the latest version of them.}}''"
		html += "\n\n"

	# Wrap & filter buttons
	if config.center_wrap:
		html += '\n<div class="statscard-grid" style="margin: 0 auto; max-width: 1247px;">'
		if config.add_controls:
			html += '\n	{{StatsCard_GridToggles}}'
		html += '\n\n	<div class="statscard-grid__inner" style="height: 80vh; overflow: auto; max-width: 1247px;">'

	if !config.center_wrap && config.add_controls:
		html += '\n	{{StatsCard_GridToggles}}'
		html += "\n"

	# ----------------------------------------
	# Main Loop
	# ----------------------------------------

	var current_col = 1
	var item_num = 1

	html += '\n<table class="itembox-table" style="color:#eee; background:transparent; vertical-align:top;">'

	# for i in ItemService.items.size():
	for i in items_arr.size():

		# var item_data = ItemService.items[i]
		var item_data = items_arr[i]

		# Helpful info after each </td> - shows col num/total cols
		var info_comment = "<!--" + str(item_num) + " of " + str(items_arr.size()) + "-->"

		if current_col == 1:
			html += '\n	<tr>'

		html += '\n		<td style="vertical-align: top; padding-bottom: 20px; padding-right: 20px;">'
		html += '\n' + generate_stats_card( item_data, 3 )
		html += '\n		</td>' + info_comment

		if current_col == config.max_cols:
			html += '\n	</tr>'
			current_col = 0

		current_col += 1
		item_num += 1

	# Add empty columns if needed
	if items_arr.size() % 5 != 0:
		var empty_cols_count = config.max_cols - (items_arr.size() % config.max_cols) # modulus (get remainder)
		html += '\n		<td style="vertical-align: top; padding-bottom: 20px; padding-right: 20px;"><!-- EMPTY --></td>'.repeat(empty_cols_count)
		html += '\n	</tr>'

	html += '\n</table>'

	if config.center_wrap:
		html += '\n	</div> <!--/.statscard-grid-->'
		html += '\n</div> <!--/.statscard-grid__inner-->'

	if config.output_print:
		print(html)

	if config.output_save:
		file_save(html, "user://wiki-output.html")



func generate_stats_card(item_data, indent_num = 0):
	# Fixed values, these never need to change
	var statscard = ""
	var indent = "	".repeat(indent_num)

	# ----------------------------------------
	# Image Filename
	# ----------------------------------------

	#@todo: Add options for these
	# This might change depending on how you've named your icons, uncomment one of the approaches below.
	# Easiest way is to name your images as they're shown in-game, eg "Alien Baby"
	# You could also get the image filename from the resource, via: item.icon.resource_path.get_file()
	var image_filename = ""

	# Get from the item ID, stripping the "item_" prefix
	# image_filename = item_data.my_id.replace( "item_", "" )

	# Get from the Name - use this if the image name is the exact same as the item name (like all the items on the wiki)
	# image_filename = item_data.name

	# Get the file's name, directly from the path - eg. res://items/all/acid/acid_icon.png, or res://mods/items/abyssal_pact/abyssal_pact.png
	image_filename = item_data.icon.resource_path.get_file().replace( ".png", "" )

	# ----------------------------------------
	# Type & Tags
	# ----------------------------------------

	# Reference:
	# src\ui\menus\shop\item_description.gd

	var cat = "Item"

	if item_data.unique:
		cat = tr("UNIQUE")
	elif item_data.max_nb != - 1:
		cat = Text.text("LIMITED", [str(item_data.max_nb)])
	else :
		cat = tr("ITEM")

	# ----------------------------------------
	# Template:StatsCard
	# ----------------------------------------

	statscard += indent + "{{StatsCard"
	statscard += "\n" + indent + "| name   = " + tr(item_data.name)
	statscard += "\n" + indent + "| type   = " + config.type
	statscard += "\n" + indent + "| cat    = " + cat
	statscard += "\n" + indent + "| image  = " + config.image_prefix + image_filename + ".png"
	statscard += "\n" + indent + "| rarity = " + str(item_data.tier + 1)
	statscard += "\n" + indent + "| tags   = " + arr_join(item_data.tags, " ")

	var stat_num = 1

	for i in item_data.effects.size():
		var effect = item_data.effects[i]
		var effect_text = effect.get_text()
		var effect_text_edit = replace_bbcode( effect_text )
		statscard += "\n" + indent + "| stat" + str(i + 1) + "  = " + effect_text_edit # eg "stat1"
		stat_num += 1

	if config.show_cost:
		statscard += "\n" + indent + "| stat" + str(stat_num) + "  = <small>{{Color|cream|Cost: " + str(item_data.value) + "}}</small>"
		stat_num += 1

	if config.show_tags:
		var tags_text = ""
		if item_data.tags.size() > 0:
			tags_text = arr_join(item_data.tags, "<br>")
		else:
			tags_text = "''none''"
		statscard += "\n" + indent + "| stat" + str(stat_num) + "  = <small>{{Color|grey|Tags:<br>" + tags_text + "}}</small>"
		stat_num += 1

	statscard += "\n" + indent + "}}"
	return statscard


func replace_bbcode(text:String)->String:
	# reference: src\singletons\utils.gd
	# reference: src\weapons\weapon_stats\weapon_stats.gd
	var text_edit = text

	# Dynamic Stats
	text_edit = text_edit.replacen( "[+-0]", "" )
	text_edit = text_edit.replacen( "[[color=red]+-0[/color]]", "" )
	text_edit = text_edit.replacen( "[[color=#00ff00]+-0[/color]]", "" )
	text_edit = text_edit.replacen( "[[color=white]+-0[/color]]", "" )

	# Colors
	text_edit = text_edit.replacen( "[color=white]", "{{Color|grey|" )    # used for scaling stat numbers, eg. "{{StatIcon|Armor}}35%"
	text_edit = text_edit.replacen( "[color=#00ff00]", "{{Color|green|" ) # Utils.POS_COLOR_STR
	text_edit = text_edit.replacen( "[color=red]", "{{Color|red|" )       # Utils.NEG_COLOR_STR
	text_edit = text_edit.replacen( "[/color]", "}}" )

	# Stat Icons
	text_edit = text_edit.replacen( "[img=23x23]res://items/stats/armor.png[/img]", "{{StatIcon|Armor}}" )
	text_edit = text_edit.replacen( "[img=23x23]res://items/stats/attack_speed.png[/img]", "{{StatIcon|Attack Speed}}" )
	text_edit = text_edit.replacen( "[img=23x23]res://items/stats/crit_chance.png[/img]", "{{StatIcon|Crit Chance}}" )
	text_edit = text_edit.replacen( "[img=23x23]res://items/stats/dodge.png[/img]", "{{StatIcon|Dodge}}" )
	text_edit = text_edit.replacen( "[img=23x23]res://items/stats/elemental_damage.png[/img]", "{{StatIcon|Elemental Damage}}" )
	text_edit = text_edit.replacen( "[img=23x23]res://items/stats/engineering.png[/img]", "{{StatIcon|Engineering}}" )
	text_edit = text_edit.replacen( "[img=23x23]res://items/stats/harvesting.png[/img]", "{{StatIcon|Harvesting}}" )
	text_edit = text_edit.replacen( "[img=23x23]res://items/stats/hp_regeneration.png[/img]", "{{StatIcon|Hp Regeneration}}" )
	text_edit = text_edit.replacen( "[img=23x23]res://items/stats/lifesteal.png[/img]", "{{StatIcon|Lifesteal}}" )
	text_edit = text_edit.replacen( "[img=23x23]res://items/stats/luck.png[/img]", "{{StatIcon|Luck}}" )
	text_edit = text_edit.replacen( "[img=23x23]res://items/stats/max_hp.png[/img]", "{{StatIcon|Max HP}}" )
	text_edit = text_edit.replacen( "[img=23x23]res://items/stats/melee_damage.png[/img]", "{{StatIcon|Melee Damage}}" )
	text_edit = text_edit.replacen( "[img=23x23]res://items/stats/percent_damage.png[/img]", "{{StatIcon|Percent Damage}}" )
	text_edit = text_edit.replacen( "[img=23x23]res://items/stats/range.png[/img]", "{{StatIcon|Range}}" )
	text_edit = text_edit.replacen( "[img=23x23]res://items/stats/ranged_damage.png[/img]", "{{StatIcon|Ranged Damage}}" )
	text_edit = text_edit.replacen( "[img=23x23]res://items/stats/speed.png[/img]", "{{StatIcon|Speed}}" )

	# Special cases for Invasion mod
	text_edit = text_edit.replacen( "[color=#CA64EA]", "{{Color|tier3|" ) # purple
	text_edit = text_edit.replacen( "[img=23x23]res://mods/items/z_info/potatoheart.png[/img]", "" )

	# Line breaks
	text_edit = text_edit.replacen( "\n", "<br>" )

	return text_edit


# Log - Basic (for quick tests)
# ==============================================================================

func basic_log():
#	for i in range(0, ItemService.items.size()):
	for i in ItemService.items.size():
		if config.skip_vanilla and i <= (config.items_count_vanilla - 1):
			continue
		var item_data = ItemService.items[i]
		print( "----------------------------------------" )
		print(tr(item_data.name)) #text_key
		for effect in item_data.effects:
			var effect_text = effect.get_text() # src\items\global\item_parent_data.gd
			var effect_text_edit = replace_bbcode( effect_text ) # see also: item_data.get_effects_text
			print( "--effect:	" + effect_text_edit )
		print("--unique:	" + str(item_data.unique)) # src\items\global\item_data.gd
		print("--max_nb:	" + str(item_data.max_nb))
		print("--tags:  	" + str(item_data.tags))
		print("--tier:  	" + str(item_data.tier + 1))
		print("--cost:		" + str(item_data.value))
		# other stats: (item_data.gd + item_parent_data.gd)
		# my_id, unlocked_by_default, icon, has_gameplay_modifications, tracking_text, item_appearances


# Utilities
# ==============================================================================

# Save a file
# https://docs.godotengine.org/en/stable/classes/class_file.html
func file_save(content:String, path:String = "user://output.txt"):
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(content)
	file.close()

# Sort items in an array
# https://docs.godotengine.org/en/stable/classes/class_array.html#class-array-method-sort-custom
# If returns true, `a` will come before `b`
class MyItemSorter:
	# Sort alphanumerically (123abc)
	static func sort_ascending_byname(a, b):
		if a.name < b.name:
			return true
		return false

	# Sort alphanumerically, translated
	# WARNING: Non-static due to using tr(), so you'll need to create a new
	# instance of MyItemSorter, eg: var my_item_sorter = MyItemSorter.new()
	func sort_ascending_byname_translated(a, b):
		if tr(a.name) < tr(b.name):
			return true
		return false

	# Sort by tier (doesn't keep alpha sorting unfortunately, use a loop instead)
	static func sort_ascending_bytier(a, b):
		if a.tier < b.tier:
			return true
		return false

# Join an array as a string
# https://godotengine.org/qa/20058/elegant-way-to-create-string-from-array-items
func arr_join(arr, separator = ""):
	var output = "";
	for s in arr:
		output += str(s) + separator
	output = output.left( output.length() - separator.length() )
	return output
