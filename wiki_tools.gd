extends Node

# Name:     WikiTools
# Version:  1.3.0
# Author:   Darkly77
# Editors:  None (contributors: add your name here and remove this parenthesised text)
# Repo:     https://github.com/BrotatoMods/Brotato-WikiTools
#
# Usage: Add to your project and autoload this script. Call it `WikiTools`.
# Update the settings to match your mod and preferences.
#
# Results can be saved to a file (config.output_save):
#   %appdata%/Brotato/wiki-output.html
# Or printed to the debug log (config.output_print):
#   %appdata%/Brotato/logs/godot.log


# Config
# ==============================================================================

var mod_config = {
	mod_link        = 'Mod:Invasion', # Mod page name. Used to show a link back to the mod page
	mod_version     = '0.6.0',  # Shown above the content
	mod_unreleased  = true,     # If true, the output states that the shown items are part of an unreleased version

	# Uncomment whichever applies to your mod, or add your own
#	image_prefix = "",                  # Vanilla
#	image_prefix = "Mod-Extatonion-",   # Mod:Extatonion
	image_prefix = "Space_Gladiators-", # Mod:Invasion
}

var config = {

	# Funcs to run
	do_statscard  = true,   # If true, runs the statscard template generator
	do_basiclog   = false,  # If true, does a basic log listing all items, to godot.log

	# Saving
	output_save   = true,   # If true, saves the output:  user://wiki-output.html - %appdata%/Brotato/wiki-output.html
	output_print  = false,  # If true, prints the output: user://godot.log - %appdata%/Brotato/godot.log

	# Items
	items_count_vanilla = 158,    # Number of items in vanilla
	skip_vanilla        = true,   # If true, vanilla items are ignored in the output
	sort_by_alpha       = true,   # Sort alphabetically (abc)
	sort_by_tier        = true,   # Sort by rarity/tier
	skip_items = [                # Hide certain items from the loop. Accepts item IDs (`my_id`)
		# "item_invasion_info"
	],

	# Output: Top Text
	add_toptext     = true,  # If true, adds extra info above everything else
	add_disclaimers = true,  # If true, adds notes before the main output, saying the page is auto generated and uses JS
	add_table       = false, # If true, adds a table before the main grid, showing all the items (eg. see Mod:Invasion)

	# Output: Top Text - Mod Info
	mod_link        = mod_config.mod_link,
	mod_version     = mod_config.mod_version,
	mod_unreleased  = mod_config.mod_unreleased,

	# Output: General
	max_cols      = 5,       # Number of columns in the items grid (5)
	show_cost     = true,    # If true, shows the item cost in small text, after all its other stats
	show_tags     = true,    # If true, shows the item tags in small text, after the cost and other stats
	type          = "item",  # Type (either: item, weapon, character, difficulty). Only "item" is supported atm

	# Output: Images
	image_prefix = mod_config.image_prefix, # String to add before image filenames
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
			if config.skip_items.size() > 0 and config.skip_items.find(ItemService.items[i].my_id) != -1:
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

	# Optional: Sort by rarity/tier
	if config.sort_by_tier:
		items_arr.clear()
		items_arr.append_array(items_tier1)
		items_arr.append_array(items_tier2)
		items_arr.append_array(items_tier3)
		items_arr.append_array(items_tier4)

	# ----------------------------------------
	# Output - Start & Extras
	# ----------------------------------------

	print("[wiki_tools] statscard_log - Running")

	var html = ""

	# Back button
	if config.add_toptext:
		html += '{{LinkButton|' + config.mod_link + '|< Back to ' + config.mod_link + '}}'

	# Disclaimers
	if config.add_disclaimers:
		html += "\n\n\n''{{Color|grey|This page content was automatically generated so may have issues.}}''"
		html += "\n\n''{{Color|pastelred|This page uses custom scripts that are often updated. If something doesn't work, please use Ctrl+F5 to ensure your browser is using the latest script updates.}}''"
		html += "\n\n"

	# Top text
	if config.add_toptext:
		html += "\nThese items are for version: '''" + config.mod_version + "'''."
		if config.mod_unreleased:
			html += " This version hasn't been released yet."
		html += "\n\nCurrent items total: " + str(items_arr.size())
		html += " <small>({{Color|tier1|" + str(items_tier1.size()) + "}}, {{Color|tier2|" + str(items_tier2.size()) + "}}, {{Color|tier3|" + str(items_tier3.size()) + "}}, {{Color|tier4|" + str(items_tier4.size()) + "}})</small>"

	# Items table
	# @todo: Move to a func with a loop
	# @todo: Use str() instead
	if config.add_table:
		html += "\n\n\n"
		html += str(items_arr.size()) + ' new items:'
		html += '\n<table class="wikitable">' \
			+ '\n	<tr>' \
			+ '\n		<th>Tier</th>' \
			+ '\n		<th>#</th>' \
			+ '\n		<th>Items</th>' \
			+ '\n	</tr>'
		# Legendary
		html += '' \
			+ '\n	<tr>' \
			+ '\n		<td>{{Color|tier4|Legendary}}</td>' \
			+ '\n		<td>' + str(items_tier4.size()) + '</td>' \
			+ '\n		<td>'
		for i in items_tier4.size():
			var item_data = items_tier4[i] # ItemService.items[i]
			var item_name = tr(item_data.name)
			html += '{{Color|tier4|' + item_name + '}}'
			if i < (items_tier4.size() - 1):
				html += ', '
		html += '</td>' \
			+ '\n	</tr>'
		# Rare
		html += '' \
			+ '\n	<tr>' \
			+ '\n		<td>{{Color|tier3|Rare}}</td>' \
			+ '\n		<td>' + str(items_tier3.size()) + '</td>' \
			+ '\n		<td>'
		for i in items_tier3.size():
			var item_data = items_tier3[i] # ItemService.items[i]
			var item_name = tr(item_data.name)
			html += '{{Color|tier3|' + item_name + '}}'
			if i < (items_tier3.size() - 1):
				html += ', '
		html += '</td>' \
			+ '\n	</tr>'
		# Uncommon
		html += '' \
			+ '\n	<tr>' \
			+ '\n		<td>{{Color|tier2|Uncommon}}</td>' \
			+ '\n		<td>' + str(items_tier2.size()) + '</td>' \
			+ '\n		<td>'
		for i in items_tier2.size():
			var item_data = items_tier2[i] # ItemService.items[i]
			var item_name = tr(item_data.name)
			html += '{{Color|tier2|' + item_name + '}}'
			if i < (items_tier2.size() - 1):
				html += ', '
		html += '</td>' \
			+ '\n	</tr>'
		# Common
		html += '' \
			+ '\n	<tr>' \
			+ '\n		<td>{{Color|tier1|Common}}</td>' \
			+ '\n		<td>' + str(items_tier1.size()) + '</td>' \
			+ '\n		<td>'
		for i in items_tier1.size():
			var item_data = items_tier1[i] # ItemService.items[i]
			var item_name = tr(item_data.name)
			html += '{{Color|tier1|' + item_name + '}}'
			if i < (items_tier1.size() - 1):
				html += ', '
		html += '</td>' \
			+ '\n	</tr>'
		html += "\n</table>"
		html += '\n'

	# Wrap & filter buttons
	html += '\n\n\n<div class="statscard-grid" style="margin: 0 auto; max-width: 1230px;">'
	html += '\n	{{StatsCard_GridToggles|extra_btns=1}}'
	html += '\n\n	<div class="statscard-grid__main" style="max-height: 80vh; overflow: auto; display: flex; flex-wrap: wrap;">'

	# ----------------------------------------
	# Main Loop
	# ----------------------------------------

	var current_col = 1
	# var item_num = 1

	for i in items_arr.size(): # ItemService.items.size()

		var item_data = items_arr[i] # ItemService.items[i]

		# var padding_right = "padding-right: 20px;"
		# if current_col == config.max_cols:
			# padding_right = "padding-right: 0;"

		html += '' \
			+ '\n		<div id="' + item_data.my_id + '" class="statscard-grid__item" style="flex: 0 0 auto; padding: 0 20px 20px; margin-left: -20px;">' \
			+ '\n' + generate_stats_card( item_data, 3 ) \
			+ '\n		</div>' \
			# + "<!--" + str(item_num) + " of " + str(items_arr.size()) + "-->"

		if current_col == config.max_cols:
			current_col = 0

		current_col += 1
		# item_num += 1

	html += '\n	</div>' # <!--/.statscard-grid-->
	html += '\n</div>' # <!--/.statscard-grid__inner-->

	if config.output_print:
		print(html)

	if config.output_save:
		file_save(html, "user://wiki-output.html")

	print("[wiki_tools] statscard_log - Finished")



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
		# var effect_text_edit = effect_text #@TODO
		statscard += "\n" + indent + "| stat" + str(i + 1) + "  = " + effect_text_edit # eg "stat1"
		stat_num += 1

	if config.show_cost:
		statscard += "\n" + indent + "| stat" + str(stat_num) + "  = <span class='ibox__stats-costs' data-target-type='misc' style='display:none;'><small>{{Color|cream|Cost: " + str(item_data.value) + "}}</small></span>"
		stat_num += 1

	if config.show_tags:
		var tags_text = ""
		if item_data.tags.size() > 0:
			tags_text = arr_join(item_data.tags, "<br>")
		else:
			tags_text = "''none''"
		statscard += "\n" + indent + "| stat" + str(stat_num) + "  = <span class='ibox__stats-tags' data-target-type='misc' style='display:none;'><small>{{Color|grey|Tags:<br>" + tags_text + "}}</small></span>"
		stat_num += 1

	statscard += "\n" + indent + "}}"
	return statscard


func replace_bbcode(text:String)->String:
	# reference: src\singletons\utils.gd
	# reference: src\weapons\weapon_stats\weapon_stats.gd
	var text_edit = text

	# Dynamic Stats
	text_edit = text_edit.replacen( "[color=red]+0[/color]",      "" ) # Red
	text_edit = text_edit.replacen( "[color=red]-0[/color]",      "" )
	text_edit = text_edit.replacen( "[color=red]+-0[/color]",     "" )
	text_edit = text_edit.replacen( "[color=#00FF00]+0[/color]",  "" ) # Green
	text_edit = text_edit.replacen( "[color=#00FF00]-0[/color]",  "" )
	text_edit = text_edit.replacen( "[color=#00FF00]+-0[/color]", "" )
	text_edit = text_edit.replacen( "[color=white]+0[/color]",    "" ) # White
	text_edit = text_edit.replacen( "[color=white]-0[/color]",    "" )
	text_edit = text_edit.replacen( "[color=white]+-0[/color]",   "" )

	# Colors
	text_edit = text_edit.replacen( "[color=white]",   "{{Color|grey|" )   # used for scaling stat numbers, eg. "35% {{StatIcon|Armor}}"
	text_edit = text_edit.replacen( "[color=#00FF00]", "{{Color|green|" )  # Utils.POS_COLOR_STR
	text_edit = text_edit.replacen( "[color=red]",     "{{Color|red|" )    # Utils.NEG_COLOR_STR
	text_edit = text_edit.replacen( "[color=#555555]", "{{Color|grey|" )   # Utils.GRAY_COLOR_STR
	text_edit = text_edit.replacen( "[color=#EAE2B0]", "{{Color|cream|" )  # Utils.SECONDARY_FONT_COLOR
	text_edit = text_edit.replacen( "[color=#C8C8C8]", "{{Color|tier1|" )  # (Tier 1 on the wiki)
	text_edit = text_edit.replacen( "[color=#4A9BD1]", "{{Color|tier2|" )  # ItemService.TIER_UNCOMMON_COLOR
	text_edit = text_edit.replacen( "[color=#AD5AFF]", "{{Color|tier3|" )  # ItemService.TIER_RARE_COLOR
	text_edit = text_edit.replacen( "[color=#FF3B3B]", "{{Color|tier4|" )  # ItemService.TIER_LEGENDARY_COLOR
	text_edit = text_edit.replacen( "[/color]", "}}" )

	# Normalise Image Sizes
	# This is needed because the image sizes depend on your "Font Size" setting,
	# See `get_scaling_stat_text` in utils.gd ("var w = 20 * ProgressData.settings.font_size")
	#  80% = 16x16
	# 100% = 20x20 (we're setting all image sizes to this)
	# 105% = 21x21
	# 125% = 25x25
	text_edit = text_edit.replacen( "[img=16x16]", "[img=20x20]" )
	text_edit = text_edit.replacen( "[img=17x17]", "[img=20x20]" )
	text_edit = text_edit.replacen( "[img=18x18]", "[img=20x20]" )
	text_edit = text_edit.replacen( "[img=19x19]", "[img=20x20]" )
	text_edit = text_edit.replacen( "[img=20x20]", "[img=20x20]" ) # a non-change, included for completeness. 20 is the base size
	text_edit = text_edit.replacen( "[img=21x21]", "[img=20x20]" )
	text_edit = text_edit.replacen( "[img=22x22]", "[img=20x20]" )
	text_edit = text_edit.replacen( "[img=23x23]", "[img=20x20]" )
	text_edit = text_edit.replacen( "[img=24x24]", "[img=20x20]" )
	text_edit = text_edit.replacen( "[img=25x25]", "[img=20x20]" )

	# Stat Icons
	text_edit = text_edit.replacen( "[img=20x20]res://items/stats/armor.png[/img]",            "{{StatIcon|Armor}}" )
	text_edit = text_edit.replacen( "[img=20x20]res://items/stats/attack_speed.png[/img]",     "{{StatIcon|Attack Speed}}" )
	text_edit = text_edit.replacen( "[img=20x20]res://items/stats/crit_chance.png[/img]",      "{{StatIcon|Crit Chance}}" )
	text_edit = text_edit.replacen( "[img=20x20]res://items/stats/dodge.png[/img]",            "{{StatIcon|Dodge}}" )
	text_edit = text_edit.replacen( "[img=20x20]res://items/stats/elemental_damage.png[/img]", "{{StatIcon|Elemental Damage}}" )
	text_edit = text_edit.replacen( "[img=20x20]res://items/stats/engineering.png[/img]",      "{{StatIcon|Engineering}}" )
	text_edit = text_edit.replacen( "[img=20x20]res://items/stats/harvesting.png[/img]",       "{{StatIcon|Harvesting}}" )
	text_edit = text_edit.replacen( "[img=20x20]res://items/stats/hp_regeneration.png[/img]",  "{{StatIcon|Hp Regeneration}}" )
	text_edit = text_edit.replacen( "[img=20x20]res://items/stats/lifesteal.png[/img]",        "{{StatIcon|Lifesteal}}" )
	text_edit = text_edit.replacen( "[img=20x20]res://items/stats/luck.png[/img]",             "{{StatIcon|Luck}}" )
	text_edit = text_edit.replacen( "[img=20x20]res://items/stats/max_hp.png[/img]",           "{{StatIcon|Max HP}}" )
	text_edit = text_edit.replacen( "[img=20x20]res://items/stats/melee_damage.png[/img]",     "{{StatIcon|Melee Damage}}" )
	text_edit = text_edit.replacen( "[img=20x20]res://items/stats/percent_damage.png[/img]",   "{{StatIcon|Percent Damage}}" )
	text_edit = text_edit.replacen( "[img=20x20]res://items/stats/range.png[/img]",            "{{StatIcon|Range}}" )
	text_edit = text_edit.replacen( "[img=20x20]res://items/stats/ranged_damage.png[/img]",    "{{StatIcon|Ranged Damage}}" )
	text_edit = text_edit.replacen( "[img=20x20]res://items/stats/speed.png[/img]",            "{{StatIcon|Speed}}" )

	# Special cases for Invasion mod (and potentially others too)
	text_edit = text_edit.replacen( "[color=#CA64EA]", "{{Color|tier3|" ) # purple
	text_edit = text_edit.replacen( "[color=#EAE2B0]", "{{Color|cream|" ) # cream (SECONDARY_FONT_COLOR)
	text_edit = text_edit.replacen( "[img=20x20]res://mods-unpacked/Darkly77-Invasion/content/items/z_info/potatoheart.png[/img]", "" )

	# Line breaks
	text_edit = text_edit.replacen( "\n", "<br>" )

	## Misc BBCode
	text_edit = text_edit.replacen( "[i]", "''" )  # italics open (note: using [i] actually makes text huge!)
	text_edit = text_edit.replacen( "[/i]", "''" ) # italics close

	# Fix non-value dynamic stats
	text_edit = text_edit.replacen( "[]", "" )
	text_edit = text_edit.replacen( "[+0]", "" )
	text_edit = text_edit.replacen( "[+-0]", "" )

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
