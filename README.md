# DefArmy v1  

<img src="https://raw.githubusercontent.com/dev-masih/my-media-bin/master/defarmy/hero.jpg" alt="defarmy banner" style="max-width:100%;" />

This module helps you to create groups (army) of game objects (soldiers) and organize them in several different patterns or your customized pattern and manage moving and rotating game objects as a customizable group.  

The bellow git shows how DefArmy groups members and how it handles changing army pattern in real-time.  
<img src="https://raw.githubusercontent.com/dev-masih/my-media-bin/master/defarmy/change_pattern.gif" alt="change pattern" style="max-width:100%;" />  

This module can easily integrate with my other extension, [DefGraph](https://github.com/dev-masih/defgraph). You can use DefGraph to handle movements and rotation of the entire army and then use DefArmy to handle each soldier in the army.  
An example of integrating DefGraph with DefArmy, All green soldiers are in a separate army as red soldiers.  
<img src="https://raw.githubusercontent.com/dev-masih/my-media-bin/master/defarmy/combination_with_defgraph.gif" alt="integrating with defgraph" style="max-width:100%;" />  

This is a community project you are welcome to contribute to it, sending PR, suggest a feature or report a bug.  

## Installation  
You can use DefArmy in your project by adding this project as a [Defold library dependency](http://www.defold.com/manuals/libraries/). Open your game.project file and in the dependencies field under project add:  

	https://github.com/dev-masih/defarmy/archive/master.zip
  
Once added, you must require the main Lua module via  

```
local defarmy = require("defarmy.defarmy")
```
Then you can use the DefArmy functions using this module.  

[Official Defold game asset page for DefArmy](https://defold.com/assets/defarmy/)

## Army Settings  
There are several parameters that you can assign to an army and you can change these parameters at any time.
#### **Pattern:**  
This parameter determines the placement shape of soldiers in an army. this property is an enumeration value that can access via `defarmy.PATTERN` table. you can pass a custom function to create army pattern or choose one of the 5 built-in patterns. for example, in bellow images showed how each pattern will place 18 soldiers.  

<img src="https://raw.githubusercontent.com/dev-masih/my-media-bin/master/defarmy/pattern_bottom_to_top_square.png" alt="BOTTOM_TO_TOP_SQUARE"/> | <img src="https://raw.githubusercontent.com/dev-masih/my-media-bin/master/defarmy/pattern_top_to_bottom_square.png" alt="TOP_TO_BOTTOM_SQUARE"/> | <img src="https://raw.githubusercontent.com/dev-masih/my-media-bin/master/defarmy/pattern_triangle.png" alt="TRIANGLE"/>
:-------------: | :-------------: | :-------------:
**BOTTOM_TO_TOP_SQUARE** | **TOP_TO_BOTTOM_SQUARE** | **TRIANGLE**  

<img src="https://raw.githubusercontent.com/dev-masih/my-media-bin/master/defarmy/pattern_rhombus_tall.png" alt="RHOMBUS_TALL"/> | <img src="https://raw.githubusercontent.com/dev-masih/my-media-bin/master/defarmy/pattern_rhombus_short.png" alt="RHOMBUS_SHORT"/>
:-------------: | :-------------:
**RHOMBUS_TALL**  | **RHOMBUS_SHORT**  

**CUSTOMIZED**  
You can create a customized pattern, you should select `defarmy.PATTERN.CUSTOMIZED` as the pattern and pass a customized function to create pattern schema. This function will get a `number` as a parameter that is the total count of members in army and return a `table` that specify that each row of army pattern should have what number of soldiers in it, row count should **start from the bottom of the army and ends with top**. note that the sum of row values must be equal to the total count that passed to the customized pattern function. the 0 value rows will automatically remove from the table.  
  
> example:  
> <img src="https://raw.githubusercontent.com/dev-masih/my-media-bin/master/defarmy/pattern_triangle.png" alt="TRIANGLE"/>  
> for this pattern customize function should return a table like: `{3, 5, 4, 3, 2, 1}` with exactly this order.

#### **Stickiness:**  
This parameter determines is soldiers completely stick to their placements in an army or they follow their placements. this parameter mostly seen when an army is rotating.  

<img src="https://raw.githubusercontent.com/dev-masih/my-media-bin/master/defarmy/sticky.gif" alt="Sticky Army"/> | <img src="https://raw.githubusercontent.com/dev-masih/my-media-bin/master/defarmy/not_sticky.gif" alt="Not Sticky Army"/>
:-------------: | :-------------:
**Sticky** | **Not Sticky**  

## Functions  
These are the list of available functions to use, for better understanding of how this module works, please take a look at project examples.  

### `defarmy.army_create(army_center_position, army_initial_rotation, member_padding, is_sticky, army_pattern, [pattern_func])`  
Create a group of game objects (army) with specified member padding and pattern.  
#### **arguments:**  
* **army_center_position** `(vector3)` - Army center position
* **army_initial_rotation** `(quat)` - Army initial rotation quat
* **member_padding** `(number)` - Padding between members
* **is_sticky** `(boolean)` - Is members glued to their places in army  
* **army_pattern** `(PATTERN)` - Army pattern
* **pattern_func** `(func)` - Optional army customized pattern function `[nil]` *(see Pattern.CUSTOMIZED section)*  
#### **return:**  
* `(number)` - Newly added army id  

### `defarmy.army_remove(army_id)`  
Remove a grouping of game objects (army) and release it's members.  
#### **arguments:**  
* **army_id** `(number)` - Army id number  

### `defarmy.army_members(army_id)`  
Return an army members (soldiers) id.  
#### **arguments:**  
* **army_id** `(number)` - Army id number  
#### **return:**  
* `(table)` - List of soldier's id that were members of that army  

### `defarmy.army_update_position(army_id, army_center_position)`  
Update an army center position.  
#### **arguments:**  
* **army_id** `(number)` - Army id number  
* **army_center_position** `(vector3)` - New army center position  

### `defarmy.army_update_rotation(army_id, army_rotation)`  
Update an army rotation.  
#### **arguments:**  
* **army_id** `(number)` - Army id number  
* **army_rotation** `(quat)` - New army rotation quat  

### `defarmy.army_update_pattern(army_id, army_pattern, [pattern_func])`  
Update an army pattern.  
#### **arguments:**  
* **army_id** `(number)` - Army id number  
* **army_pattern** `(PATTERN)` - New army pattern  
* **pattern_func** `(func)` - Optional army customized pattern function `[nil]` *(see Pattern.CUSTOMIZED section)*  

### `defarmy.army_update_stickiness(army_id, is_sticky)` 
Update an army stickiness.  
#### **arguments:**  
* **army_id** `(number)` - Army id number  
* **is_sticky** `(boolean)` - Is members glued to their places in army  

### `defarmy.soldier_create(position, initial_direction, [army_id])`  
Create a new soldier and optionally assign it to an army.  
#### **arguments:**  
* **position** `(vector3)` - Soldier current position   
* **initial_direction** `(vector3)` - Soldier initial direction vecotr   
* **army_id** `(optinal number)` - Optional army id number `[nil]`   
#### **return:**  
* `(number)` - Newly added soldier id  

### `defarmy.soldier_join_army(soldier_id, army_id)`
Assign an existing soldier to a given army.  
#### **arguments:**  
* **soldier_id** `(number)` - Soldier id number  
* **army_id** `(number)` - Army id number  

### `defarmy.soldier_leave_army(soldier_id)`
Deassign a soldier from army.  
#### **arguments:**  
* **soldier_id** `(number)` - Soldier id number  

### `defarmy.soldier_remove(soldier_id)`
Completely remove a soldier.  
#### **arguments:**  
* **soldier_id** `(number)` - Soldier id number  

### `defarmy.soldier_move(soldier_id, current_position, speed, [threshold])`
Calculate a soldier next postion and rotation.  
#### **arguments:**  
* **soldier_id** `(number)` - Soldier id number  
* **current_position** `(number)` - Soldier current position  
* **speed** `(number)` - Soldier speed  
* **threshold** `(optinal number)` - Optional soldier placement detection threshold `[1]`  
#### **return:**  
* `(vector3)` - Soldier next position  
* `(quat)` - Soldier next rotation  

### `defarmy.army_debug_draw(army_id, debug_color)`
Army debugging.  
#### **arguments:**  
* **army_id** `(number)` - Army id number  
* **debug_color** `(vector4)` - Color used for debugging  

### `defarmy.soldier_debug_on(soldier_id, debug_color)`
Turn on soldier position debugging.  
#### **arguments:**  
* **soldier_id** `(number)` - Soldier id number  
* **debug_color** `(vector4)` - Color used for debugging  

### `defarmy.soldier_debug_off(soldier_id)`
Turn off soldier position debugging.  
#### **arguments:**  
* **soldier_id** `(number)` - Soldier id number  

## Donations  
If you really like my work and want to support me, consider donating to me with BTC or ETH. All donations are optional and are greatly appreciated. 🙏  

BTC: `1EdDfXRuqnb5a8RmtT7ZnjGBcYeNzXLM3e`  
ETH: `0x99d3D5816e79bCfB2aE30d1e02f889C40800F141`  
  
## License  
DefArmy is released under the MIT License. See the [bundled LICENSE](https://github.com/dev-masih/defarmy/blob/master/LICENSE) file for details.  
