local _ = wesnoth.textdomain 'Bad_Moon_Rising'
-- maybe the layout as wml is easier to read?
local dialog_wml = wml.load "~add-ons/Bad_Moon_Rising/utils/help_dialog.cfg"

-- This help dialog is adapted from the World Conquest help dialog
-- TODO : the enemies list (skirmishes)

local function make_caption(text)
	return ("<big><b>%s</b></big>"):format(text)
end

local function help_page_text(caption, description)
	return caption, ("%s\n\n%s"):format(make_caption(caption), description)
end

-- the newlines are mostly due to the fact that the wrap key is pretty ineffective, and we end up with a vveerrryyy wide scrollbar
local bmr_worldmap ={}
table.insert(bmr_worldmap, {subtopic_id = "World Map", subtopic_text = "<small>Travel between scenarios is achieved through the World Map, \n where the player's forces are represented by a single leader unit, \n and any interaction leads to a different scenario. \n This can take some time, but gives you some limited control over \n the scenario progression, and a chance to upgrade your forces \n between scenarios.</small>", subtopic_icon = "help/worldmap.webp"})
table.insert(bmr_worldmap, {subtopic_id = "Campaign Scenarios", subtopic_text = "<small>The core scenarios of this campaign are like most other Wesnoth \n campaigns, a mix of strategy and story.</small>", subtopic_icon = "help/campaign.webp"})
table.insert(bmr_worldmap, {subtopic_id = "Shops", subtopic_text = "<small>There are a limited number of shops, usually reached through the World Map, \n where gear can be bought or sold.  They are often a place to \n recruit new followers or gather information.</small>", subtopic_icon = "help/shop.webp"})
table.insert(bmr_worldmap, {subtopic_id = "Battles", subtopic_text = "<small>The enemy units on the World Map represent another roaming army, \n and any interaction with them leads to a Battle Scenario. \n Such scenarios are bigger than the random skirmishes, but \n lesser than the core campaign scenarios.</small>", subtopic_icon = "help/battle.webp"})
table.insert(bmr_worldmap, {subtopic_id = "Skirmishes", subtopic_text = "<small>Enemies lurk behind every snowdrift and tree, so your forces will \n often stumble into random skirmishes as they move over the World Map. \n Each skirmish is short and not usually a problem, but they can \n take a toll as they add up.  Sometimes you get the first move, \n sometimes you are ambushed, so be sure to arrange your travelling party \n with an eye toward both experience and survival.</small>", subtopic_icon = "help/skirmish.webp"})

-- to make the internal IDs look better, probably belongs either in the equipment data or in a separate function
-- TODO translatable _ marks
local bmr_e_g = {}
-- positions
bmr_e_g["arms"] = "Arm Guards"
bmr_e_g["head"] = "Headgear"
bmr_e_g["shield"] = "Shields"
bmr_e_g["cloak"] = "Cloaks"
bmr_e_g["ring"] = "Hands"
bmr_e_g["amulet"] = "Miscellaneous"
bmr_e_g["torso"] = "Tunics and Armor"
bmr_e_g["foot"] = "Footgear"
bmr_e_g["weapon"] = "Weapons"
bmr_e_g["neck"] = "Throat Protection"
-- usage types
bmr_e_g["dog"] = "for use by canines"
bmr_e_g["all"] = "available to all"
bmr_e_g["orcish"] = "available to orcs"
bmr_e_g["amulet"] = "available to magi and shamans"
bmr_e_g["light_armor"] = "for light infantry"
bmr_e_g["heavy_armoor"] = "for heavy infantry"
bmr_e_g["shields"] = "for shield-bearers"
bmr_e_g["bow"] = "for archers"
bmr_e_g["sword"] = "for swordsmen"
bmr_e_g["axe"] = "for ax-wielders"
bmr_e_g["spear"] = "for spearmen"
bmr_e_g["despair"] = "for phantoms only"


function wesnoth.wml_actions.bmr_show_campaign_help(cfg)
    local curr_side = wesnoth.current.side
    local discovery_list = wml.variables["known_items["..curr_side.."].s"]
	local show_help_mechanics = cfg.show_mechanics ~= false
	local show_help_recruit = cfg.show_recruit ~= false
	local show_help_worldmap = cfg.show_worldmap ~= false
	local show_help_equipment = cfg.show_equipment ~= false
	if not discovery_list then
	    show_help_equipment = false
	end
	--local show_help_settings = cfg.show_settings ~= false
	-- maps the treeview rows to pagenumber in the help page.
	local index_map = {}

	local current_side = wesnoth.interface.get_viewing_side()
	local preshow = function(dialog)
		local str_cat_mechanics = _ "Overview"
		local str_des_mechanics = cfg.mechanics_text or
			make_caption( _ "General Help") .. "\n\n" ..
			_ "Bad Moon Rising has game mechanics that are very similar to standard Wesnoth singleplayer campaigns, however there are a few key differences as described here.\n"..
			_ "Questions or suggestions are always welcome and can be posted to:\n ".."https://forums.wesnoth.org" .."\n\n"..
			_ "<b>Inventory</b>\n" ..
			_ "Player and AI units can carry items and equipment.\n\n" ..
			_ "<b>Recruit and Recall</b>\n" ..
			_ "There are limits on new recruits, so spamming is less viable and even non-elite veterans can be important.\n\n" ..
			_ "<b>World Map</b>\n" ..
			_ "Between the main scenarios, there is a World Map that the player moves through to reach actual scenarios.\n\n" ..
			""
		local str_cat_worldmap, str_des_worldmap = help_page_text( _ "Campaign Navigation", _ "The world map is a psuedo-scenario that allows the player to move between campaign scenarios, shop scenarios, battles, and random skirmishes.")
		local str_cat_items, str_des_items = help_page_text( _ "Inventory", _ "Various weapons, armor, and other gear can be acquired throughout the campaign.  As they are discovered, they will show up in the list here.  Not every unit can use every item.")
		local str_cat_recruit, str_des_recruit = help_page_text( _ "Recruit and Recall" , _ "There is a limited pool of new recruits available to your forces, and while you can pick up more along the way, each life is precious.")
		--local str_cat_settings = _ "Settings"

		local root_node = dialog:find("treeview_topics")
		local details = dialog:find("details")

		function gui.widget.add_help_page(parent_node, args)
			local node_type = args.node_type or "category"
			local page_type = args.page_type or "simple"

			local node = parent_node:add_item_of_type(node_type)
			local details_page = details:add_item_of_type(page_type)
			if args.title then
				node.label_topic.label = args.title
				node.unfolded = false
			end
			index_map[table.concat(node.path, "_")] = details.item_count
			return node, details_page
		end

		---- add general overview topic ----
		if show_help_mechanics then
			local node, page = root_node:add_help_page {
				title = str_cat_mechanics
			}
			page.label_content.marked_up_text = str_des_mechanics
		end

		---- add general recruit topic ----
		if show_help_mechanics then
			local node, page = root_node:add_help_page {
				title = str_cat_recruit
			}
			page.label_content.marked_up_text = str_des_recruit
		end

		-- add general worldmap topic.
		if show_help_worldmap then
			local node, root_page = root_node:add_help_page {
				title = str_cat_worldmap
			}
			root_page.label_content.marked_up_text = str_des_worldmap
			-- add specific worldmap pages
			for i = 1, #bmr_worldmap do
				local name = bmr_worldmap[i].subtopic_id
				local text = bmr_worldmap[i].subtopic_text
				local icon = bmr_worldmap[i].subtopic_icon
				local subnode, sub_page = node:add_help_page {
					title = name,
					page_type = "worldmap",
					node_type = "subcategory",
				}
                local page_element = sub_page.treeview_map:add_item_of_type("map_details")
                page_element.map_caption.marked_up_text = string.format("<big><b>%s</b></big>", name)
                page_element.map_text.marked_up_text = text
                page_element.map_icon.label = icon
			end
		end

		-- add general equipment topic
		if show_help_equipment then
			local node, root_page = root_node:add_help_page {
				title = str_cat_items,
				page_type = "equipment"
			}
			root_page.desc.marked_up_text = str_des_items
            local position_old = "dummy"
            local subnode, subpage = nil, nil
            for i in ipairs(equipment_list.the_list) do
                if string.find(discovery_list, equipment_list.the_list[i].id) then
                    local item_icon = equipment_list.the_list[i].image or ""
                    local item_name = equipment_list.the_list[i].name or ""
                    local item_desc = equipment_list.the_list[i].text or ""
                    local item_usage = equipment_list.the_list[i].usage or ""
                    local item_position = equipment_list.the_list[i].position or ""
				-- local not_available = stringx.map_split(artifact.not_available or "")
                    if position_old ~= item_position then
                        subnode, sub_page = node:add_help_page {
                            title = bmr_e_g[item_position],
                            page_type = "equipment",
                            node_type = "subcategory",
                        }
                        page_element = sub_page.treeview_equipment:add_item_of_type("equipment_item")
                        page_element.image.label = "misc/blank-hex.png"
                        page_element.label_name.marked_up_text = string.format("<big><b>%s</b></big>", bmr_e_g[item_position])
                        position_old = item_position
                    end
                    page_element = sub_page.treeview_equipment:add_item_of_type("equipment_item")
                    page_element.image.label = item_icon
                    page_element.label_name.marked_up_text = "<b>".. item_name .. "</b> - <i>"..bmr_e_g[item_usage].."</i> \n" .. item_desc
                end
            end
		end
--[[ Settings would be good to have at some point, but needs more thought
		if show_help_settings then
			local node, page = root_node:add_help_page {
				title = str_cat_settings,
				page_type = "settings",
			}

			page.checkbox_use_markers.selected = not not wml.variables["bmr_config_enable_unitmarker"]
			page.checkbox_use_markers.enabled = false
			page.checkbox_use_pickup.selected = not not wml.variables["bmr_config_experimental_pickup"]
			page.checkbox_use_pickup.enabled = false
			page.checkbox_show_pickup_confirmation.selected = not bmr_utils.global_vars.skip_pickup_dialog
			page.checkbox_show_pickup_confirmation.enabled = true

			page.label_difficulty.marked_up_text = wml.variables["bmr_difficulty.name"] or "unknown"

			function page.checkbox_show_pickup_confirmation.on_modified()
				bmr_utils.global_vars.skip_pickup_dialog = not page.checkbox_show_pickup_confirmation.selected
			end
		end
]]
		root_node:focus()

		function root_node.on_modified()
			local selected_index = index_map[table.concat(root_node.selected_item_path, '_')]
			if selected_index ~= nil then
				details.selected_index = selected_index
			end
		end
	end

	gui.show_dialog(wml.get_child(dialog_wml, 'resolution'), preshow)
end

bmr_utils.menu_item {
	id = "BMR_Help_Item",
	description = _ "BMR Help",
	image= "help/closed_section.png~SCALE(18,17)",
	synced = false,
	filter = function(x, y)
		local u = wesnoth.units.get(x, y)
		-- this is still TODO
		-- if bmr_equipment.is_item_at(x, y) then
		--	return false
		-- end
		return not (u and u.side == wesnoth.current.side)
	end,
	handler = function(cx)
		wesnoth.wml_actions.bmr_show_campaign_help {
			x = cx.x1,
			y = cx.y1,
		}
	end
}
