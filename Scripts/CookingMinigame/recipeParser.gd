# Copyright (C) 2025 Nyzterra Team & CyberSugar Studios
extends Node

# Config
const ICON_SIZE = 32
const STEPS_PER_PAGE = 3

# Simple sprites for recipe instructions, attempting to use emojis as placeholders
const FIRE_ICON_PATH = "res://Assets/Images/KitchenPuzzle/heatHighIcon.png"
const CHOP_ICON_PATH = "res://Assets/Images/KitchenPuzzle/Knife.png"

# Map to convert ingredient names to sprites
const INGREDIENT_PATH_MAP = {
	"Oil": "res://Assets/Images/KitchenPuzzle/Ingredients/oilBottle_SingleIcon.png",
	"Onion": "res://Assets/Images/KitchenPuzzle/Ingredients/ingredientOnion.png",
	"Garlic": "res://Assets/Images/KitchenPuzzle/Ingredients/ingredientGarlic.png",
	"Potato": "res://Assets/Images/KitchenPuzzle/Ingredients/ingredientPotato.png",
	"Carrot": "res://Assets/Images/KitchenPuzzle/Ingredients/ingredientCarrot.png",
	"Water": "res://Assets/Images/KitchenPuzzle/Ingredients/waterBottle_SingleIcon.png",
	"Rabbit": "res://Assets/Images/KitchenPuzzle/Ingredients/ingredientRabbit.png",
	"Stock": "res://Assets/Images/KitchenPuzzle/Ingredients/stockBox.png",
	"Thyme": "res://Assets/Images/KitchenPuzzle/Ingredients/ingredientThyme.png",
	"Parsley": "res://Assets/Images/KitchenPuzzle/Ingredients/ingredientParsley.png",
	"Rosemary": "res://Assets/Images/KitchenPuzzle/Ingredients/ingredientRosemary.png",
	"Salt": "res://Assets/Images/KitchenPuzzle/Ingredients/ingredientShaker_SaltIcon.png",
	"Pepper": "res://Assets/Images/KitchenPuzzle/Ingredients/ingredientShaker_PepperIcon.png"
}

func ParseRecipeToInstructions(recipeName: String) -> Dictionary:
	var output = { "left": "", "right": "" }
	
	if not KitchenController.recipes.has(recipeName):
		output["left"] = "ERROR: Recipe not found"
		return output
	
	var recipeData = KitchenController.recipes[recipeName]
	
	for i in recipeData.size():
		var step = recipeData[i]
		var step_text = ""
		var waitTime = step["wait"] # Retrieve the wait time for cooking
		
		# Check for end marker
		if step["heat"] == 0.0 and step["ingredients"].is_empty() and step["wait"] == 0.0 and step["time"] == 0.0:
			step_text = "\nDone! Turn off heat."
		else:
			step_text += "STEP %d " % (i + 1)
			step_text += GetHeatIcons(step["heat"])
			step_text += "\n"
			
			if step["ingredients"].is_empty() and waitTime > 0.0: # Check if there are no ingredients and there is a wait time
				step_text += "Cover and braise."
				step_text += "\n"
			else:
				for ingredient in step["ingredients"]:
					step_text += GetIngredientLine(ingredient)
					step_text += "\n"
			
			# Add the cooking time (wait time) to the output
			if waitTime > 0.0:
				step_text += "(Wait for %.0f seconds)" % waitTime
				step_text += "\n"
				
			step_text += "\n" # Extra spacing between steps
		
		# DECIDE WHICH PAGE TO PUT TEXT ON
		if i < STEPS_PER_PAGE:
			output["left"] += step_text
		else:
			output["right"] += step_text
			
	return output

func GetImgTag(path: String) -> String:
	return "[img=%d]%s[/img]" % [ICON_SIZE, path]

func GetHeatIcons(heatValue: float) -> String:
	var fire_tag = GetImgTag(FIRE_ICON_PATH)
	if heatValue == 100.0: return fire_tag + fire_tag + fire_tag + " High Heat"
	elif heatValue == 50.0: return fire_tag + fire_tag + " Medium Heat"
	elif heatValue == 25.0: return fire_tag + " Low Heat"
	else: return ""

func GetIngredientLine(ingredientData: Dictionary) -> String:
	var line = ""
	var fullName = ingredientData["name"]
	var isChopped = "(Chopped)" in fullName
	var baseName = fullName.replace(" (Chopped)", "")
	
	if INGREDIENT_PATH_MAP.has(baseName):
		line += GetImgTag(INGREDIENT_PATH_MAP[baseName])
	else:
		line += baseName # Fallback to text
	
	if isChopped:
		line += " " + GetImgTag(CHOP_ICON_PATH)
	
	line += " x%d" % ingredientData["amount"]
	return line
