# Copyright (C) 2025 Nyzterra Team & CyberSugar Studios
extends Node

# Simple sprites for recipe instructions, attempting to use emojis as placeholders
const FIRE_ICON = "🔥"
const CHOP_ICON = "🔪"

# Map to convert ingredient names to sprites
## TODO: ADD SPRITES
const INGREDIENT_ICON_MAP = {
	"Oil": "🛢️",
	"Onion": "🧅",
	"Garlic": "🧄",
	"Potato": "🥔",
	"Carrot": "🥕",
	"Water": "💧",
	"Rabbit": "🐇",
	"Stock": "🦴",
	"Thyme": "🌿",
	"Parsley": "[parsleySprite]",
	"Rosemary": "[rosemarySprite]",
	"Salt": "🧂",
	"Pepper": "🌶️"
}

func ParseRecipeToInstructions(recipeName: String) -> String:
	if not KitchenController.recipes.has(recipeName):
		return "ERROR: Recipe not found"
	
	var recipeData = KitchenController.recipes[recipeName]
	var instructions = ""
	
	for i in recipeData.size():
		var step = recipeData[i]
		
		if step["heat"] == 0.0 and step["ingredients"].is_empty() and step["wait"] == 0.0 and step["time"] == 0.0:
			instructions += "\n" + "Done! Turn off heat."
			break
		
		instructions += "STEP %d " % (i + 1)
		instructions += GetHeatIcons(step["heat"])
		instructions += "\n"
		
		for ingredient in step["ingredients"]:
			instructions += GetIngredientLine(ingredient)
			instructions += "\n"
	
	return instructions

func GetHeatIcons(heatValue: float) -> String:
	if heatValue == 100.0:
		return FIRE_ICON + FIRE_ICON + FIRE_ICON
	elif heatValue == 50.0:
		return FIRE_ICON + FIRE_ICON
	elif heatValue == 25.0:
		return FIRE_ICON
	else:
		return ""

func GetIngredientLine(ingredientData: Dictionary) -> String:
	var line = ""
	var fullName = ingredientData["name"]
	
	var isChopped = "(Chopped)" in fullName
	var baseName = fullName.replace(" (Chopped)", "")
	
	if INGREDIENT_ICON_MAP.has(baseName):
		line += INGREDIENT_ICON_MAP[baseName]
	else:
		line += "[ERROR!!! ?_? HUH?]"
	
	if isChopped:
		line += " " + CHOP_ICON
	
	line += " x%d" % ingredientData["amount"]
	
	return line
