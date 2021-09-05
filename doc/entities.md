# Entities
## Article
**table:** articles
### Attributes
#### id
**type:** integer
Primary key of `Article` for database.

#### project_id
**type:** integer
Foreign key on `Project`. References the `Project` that this `Article` was created or imported in.

#### shop_section_id
**type:** integer
Foreign key on `ShopSection`. References the `ShopSection` where this `Article` can be found.

#### shelf_life_days
**type:** integer
Indicates how many days the `Article` could be stored, before it has to be processed.

#### preorder_servings
**type:** integer

#### preorder_workdays
**type:** integer

#### name
**type:** integer
Human-readable name of the `Article`.

#### comment
**type:** text
User specified comment of the `Article`.


## Unit
**table:** units
### Attributes
#### id
**type:** integer
Primary key of `Unit` for database.

#### project_id
**type:** integer
Foreign key on `Project`. References the `Project` that this `Unit` was created or imported in.

#### quantity_id
**type:** integer
Foreign key on `Quantity`. References the `Quantity` that this `Unit` is for.

#### to_quantity_default
**type:** real
Factor to multiply by to get to the value in the `Quantity`'s default `Unit`.

#### space'
**type:** boolean
Indicates if the `Unit`'s (short\_/long\_)name should be prepended with a space or not.

#### short_name
**type:** text
Human-readable short variant of the name of the `Unit`. E.g.: `kg` for Kilogram.

#### long_name
**type:** text
Human-readable long variant of the name of the `Unit`. E.g.: `Kilogram` for Kilogram.


## DishIngredient
**table:** dish_ingredients
### Attributes
#### id
**type:** integer
Primary key of `DishIngredient` for database.

#### position
**type:** integer
Position of the `DishIngredient` in the `IngredientsEditor`.

#### dish_id
**type:** integer
Foreign key on the `id` of a `Dish`. References the `Dish` that this `DishIngredient` belongs to.

#### prepare
**type:** boolean
Indicates wether this `DishIngredient` has to be prepared before processing or not.

#### article_id
**type:** integer
Foreign key on the `id` of an `Article`. References the `Article` that this `DishIngredient` is derived from.

#### unit_id
**type:** integer
Foreign key on the `id` of an `Unit`. References the `Unit` this `DishIngredient` is in.

#### value
**type:** real
Current value of the `DishIngredient`.

#### comment
**type:** text
User specified comment of the `DishIngredient`.

#### item_id
**type:** integer
Foreign key on `id` of `Item`. References the `Item` on a `PurchaseList` that belongs to this `DishIngredient`.

