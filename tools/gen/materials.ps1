# Generates every data file of the materials unit (U9) from the tables below:
#   BP  items/, blocks/, loot_tables/blocks/, recipes/ (crafting, furnace, stonecutter)
#   RP  models/blocks/materials_*.geo.json, blocks.d/materials.json, terrain_texture.d/materials.json,
#       item_texture.d/materials.json, texts.d/{en_US,zh_CN}/materials.lang
#   assets/recipes/<type>/  Create processing recipes for the U3 loader (+ tags/materials.json)
#   src/feature/materials/MaterialsBlocks.inc  the block table the C++ side reads (tools, drops)
#
#   pwsh tools/gen/materials.ps1
#
# Names (en_US / zh_CN, Create's wording) come from tools/gen/materials.names.tsv. Behaviour
# numbers (hardness, resistance, foods, recipes) follow Create 6.0.10; see docs/SPEC.md §2.4 / §3.6.
param()
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$utf8 = [Text.UTF8Encoding]::new($false)

# ---- output helpers -------------------------------------------------------------------------------
$script:files = [System.Collections.Generic.List[string]]::new()
function Save-Text([string]$rel, [string]$text) {
    $full = Join-Path $root $rel
    $dir = Split-Path -Parent $full
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    [IO.File]::WriteAllText($full, $text, $utf8)
    $script:files.Add($rel.Replace('\', '/'))
}
function Save-Json([string]$rel, $obj) {
    Save-Text $rel ((($obj | ConvertTo-Json -Depth 64 -Compress:$false) -replace "`r`n", "`n") + "`n")
}
function O { param([Parameter(ValueFromRemainingArguments)]$kv) $h = [ordered]@{}; for ($i = 0; $i -lt $kv.Count; $i += 2) { $h[[string]$kv[$i]] = $kv[$i + 1] }; $h }

# Clear what a previous run generated (the unit owns these patterns only).
$manifest = Join-Path $PSScriptRoot 'materials.generated.txt'
if (Test-Path $manifest) {
    foreach ($rel in Get-Content $manifest) { $p = Join-Path $root $rel; if ($rel -and (Test-Path $p)) { Remove-Item $p } }
}

# ---- names ----------------------------------------------------------------------------------------
$names = @{}
foreach ($line in [IO.File]::ReadAllLines((Join-Path $PSScriptRoot 'materials.names.tsv'), $utf8)) {
    if (!$line.Trim()) { continue }
    $c = $line.Split("`t"); $names[$c[0]] = @{ en = $c[1]; zh = $c[2] }
}
function NameOf([string]$id) { if (!$names.ContainsKey($id)) { throw "no name for '$id' in materials.names.tsv" }; $names[$id] }

$enLang = [System.Collections.Generic.List[string]]::new()
$zhLang = [System.Collections.Generic.List[string]]::new()
$itemTextures = [ordered]@{}
$terrainTextures = [ordered]@{}
$blockSounds = [ordered]@{}
$cppBlocks = [System.Collections.Generic.List[string]]::new()

function Add-Name([string]$id, [string]$kind) {
    $n = NameOf $id
    $prefix = if ($kind -eq 'block') { 'tile' } else { 'item' }
    $enLang.Add("$prefix.bearing:$id.name=$($n.en)")
    $zhLang.Add("$prefix.bearing:$id.name=$($n.zh)")
}
function Tex([string]$key, [string]$file) { if (!$terrainTextures.Contains($key)) { $terrainTextures[$key] = O textures "textures/blocks/$file" } }

# ---- items ----------------------------------------------------------------------------------------
# id, stack, category, extra component hashtable
$compatMetals = 'osmium', 'platinum', 'silver', 'tin', 'lead', 'quicksilver', 'aluminum', 'uranium', 'nickel'
$items = [System.Collections.Generic.List[object]]::new()
function Item($id, [int]$stack = 64, [string]$cat = 'items', $extra = $null) { $items.Add(@{ id = $id; stack = $stack; cat = $cat; extra = $extra }) }

foreach ($id in 'raw_zinc', 'zinc_ingot', 'zinc_nugget', 'brass_ingot', 'brass_nugget', 'brass_sheet', 'copper_sheet',
    'iron_sheet', 'golden_sheet', 'copper_nugget', 'andesite_alloy', 'crushed_raw_iron', 'crushed_raw_gold',
    'crushed_raw_copper', 'crushed_raw_zinc', 'powdered_obsidian', 'cinder_flour', 'wheat_flour', 'dough',
    'rose_quartz', 'polished_rose_quartz', 'electron_tube', 'precision_mechanism', 'propeller', 'whisk', 'brass_hand',
    'crafter_slot_cover', 'sturdy_sheet', 'transmitter', 'pulp', 'blaze_cake_base') { Item $id }
# Create hides the compat crushed ores while no mod provides the metal (TagDependentIngredientItem).
foreach ($m in $compatMetals) { Item "crushed_raw_$m" 64 'none' }
Item 'incomplete_precision_mechanism' 1 'none'
Item 'unprocessed_obsidian_sheet' 1 'none'
Item 'cardboard' 64 'items' (O 'minecraft:fuel' (O duration 50.0))                       # burnTime 1000
Item 'experience_nugget' 64 'items' (O 'minecraft:glint' $true 'minecraft:rarity' 'uncommon')
Item 'refined_radiance' 64 'items' (O 'minecraft:glint' $true 'minecraft:rarity' 'uncommon')
Item 'shadow_steel' 64 'items' (O 'minecraft:rarity' 'uncommon')
Item 'chromatic_compound' 16 'items' (O 'minecraft:rarity' 'uncommon')
Item 'blaze_cake' 64 'items' (O 'minecraft:fuel' (O duration 320.0))                      # burnTime 6400
Item 'creative_blaze_cake' 64 'items' (O 'minecraft:fuel' (O duration 107374182.0) 'minecraft:rarity' 'epic')

function Food([int]$nutrition, [double]$sat, [double]$seconds = 1.6, [bool]$always = $false, [string]$anim = 'eat', [string]$converts = $null) {
    $food = O nutrition $nutrition saturation_modifier $sat can_always_eat $always
    if ($converts) { $food['using_converts_to'] = $converts }
    O 'minecraft:food' $food 'minecraft:use_animation' $anim 'minecraft:use_modifiers' (O use_duration $seconds movement_modifier 0.35)
}
Item 'bar_of_chocolate' 64 'items' (Food 6 0.3)
Item 'sweet_roll' 64 'items' (Food 6 0.8)
Item 'chocolate_glazed_berries' 64 'items' (Food 7 0.8)
Item 'honeyed_apple' 64 'items' (Food 8 0.8)
# Builder's Tea: 42 ticks, drink, always edible, Haste (3 min) applied by the mod, bottle back.
Item 'builders_tea' 16 'items' (Food 1 0.6 2.1 $true 'drink' 'minecraft:glass_bottle')

foreach ($it in $items) {
    $comp = O 'minecraft:icon' "bearing_$($it.id)" 'minecraft:display_name' (O value "item.bearing:$($it.id).name") 'minecraft:max_stack_size' $it.stack
    if ($it.extra) { foreach ($k in $it.extra.Keys) { $comp[$k] = $it.extra[$k] } }
    Save-Json "assets/pack/bp/items/$($it.id).json" (O format_version '1.21.70' 'minecraft:item' (O description (O identifier "bearing:$($it.id)" menu_category (O category $it.cat)) components $comp))
    $itemTextures["bearing_$($it.id)"] = O textures "textures/items/$($it.id)"
    Add-Name $it.id 'item'
}

# ---- blocks ---------------------------------------------------------------------------------------
# Common block components. $tool: pickaxe|axe; $tier: none|stone|iron (Create's needs_*_tool tags).
function Base-Components($b) {
    $c = O 'minecraft:destructible_by_mining' (O seconds_to_destroy $b.hardness) `
        'minecraft:destructible_by_explosion' (O explosion_resistance $b.resistance) `
        'minecraft:map_color' $b.map `
        'minecraft:loot' "loot_tables/blocks/$($b.id).json"
    if ($b.light) { $c['minecraft:light_emission'] = $b.light }
    # Create's mineable/<tool> + needs_iron_tool tags: the game's tool speeds and tier rules
    $c["tag:minecraft:is_$($b.tool)_item_destructible"] = O
    if ($b.tier -eq 'iron') { $c['tag:minecraft:iron_tier_destructible'] = O }
    $c
}
function Mat([string]$tex) { O texture $tex render_method 'opaque' }
function Block-Doc($b, $components, $states = $null, $traits = $null, $perms = $null) {
    $desc = O identifier "bearing:$($b.id)" menu_category (O category $b.cat)
    if ($b.group) { $desc.menu_category['group'] = $b.group }
    if ($states) { $desc['states'] = $states }
    if ($traits) { $desc['traits'] = $traits }
    $blk = O description $desc components $components
    if ($perms) { $blk['permutations'] = @($perms) }
    O format_version '1.21.70' 'minecraft:block' $blk
}
function Save-Loot([string]$name, [string]$item, [int]$count = 1, $extra = @()) {
    $entry = O type 'item' name $item weight 1
    if ($count -ne 1) { $entry['functions'] = @(O function 'set_count' count $count) }
    $pools = @(O rolls 1 entries @($entry))
    foreach ($e in $extra) { $pools += O rolls 1 entries @((O type 'item' name $e weight 1)) }
    Save-Json "assets/pack/bp/loot_tables/blocks/$name.json" (O pools $pools)
}
function Register-Block($b, [string]$shape, [string]$drop = 'self') {
    $blockSounds["bearing:$($b.id)"] = O sound $b.sound
    Add-Name $b.id 'block'
    $tool = if ($b.tool) { $b.tool } else { 'pickaxe' }
    $tier = if ($b.tier) { $b.tier } else { 'none' }
    $up = { param($s) $s.Substring(0, 1).ToUpperInvariant() + $s.Substring(1) }
    $cppBlocks.Add("BR_MATERIALS_BLOCK(`"bearing:$($b.id)`", Tool::$(& $up $tool), Tier::$(& $up $tier), Shape::$(& $up $shape), Drop::$(& $up $drop))")
}

# full cube: $faces = @{ '*' = tex; up = tex; ... }
function Cube-Block($b, $faces, [string]$drop = 'self', [string]$lootItem = $null) {
    $c = Base-Components $b
    $c['minecraft:geometry'] = 'minecraft:geometry.full_block'
    $mi = [ordered]@{}; foreach ($k in $faces.Keys) { $mi[$k] = Mat $faces[$k] }
    $c['minecraft:material_instances'] = $mi
    Save-Json "assets/pack/bp/blocks/$($b.id).json" (Block-Doc $b $c)
    Save-Loot $b.id ($(if ($lootItem) { $lootItem } else { "bearing:$($b.id)" }))
    Register-Block $b 'cube' $drop
}
# rotated pillar (Create's RotatedPillarBlock, axis from the clicked face)
function Pillar-Block($b, [string]$side, [string]$end) {
    $c = Base-Components $b
    $c['minecraft:geometry'] = 'minecraft:geometry.full_block'
    $c['minecraft:material_instances'] = O '*' (Mat $side) up (Mat $end) down (Mat $end)
    $perms = @(
        (O condition "q.block_state('minecraft:block_face') == 'north' || q.block_state('minecraft:block_face') == 'south'" components (O 'minecraft:transformation' (O rotation @(90, 0, 0)))),
        (O condition "q.block_state('minecraft:block_face') == 'east' || q.block_state('minecraft:block_face') == 'west'" components (O 'minecraft:transformation' (O rotation @(0, 0, 90))))
    )
    $traits = O 'minecraft:placement_position' (O enabled_states @('minecraft:block_face'))
    Save-Json "assets/pack/bp/blocks/$($b.id).json" (Block-Doc $b $c $null $traits $perms)
    Save-Loot $b.id "bearing:$($b.id)"
    Register-Block $b 'pillar'
}
# horizontal axis (Create's cardboard blocks: axis of the player's horizontal facing)
function HAxis-Block($b, [string]$side, [string]$end, [string]$drop = 'self') {
    $c = Base-Components $b
    $c['minecraft:geometry'] = 'minecraft:geometry.full_block'
    $c['minecraft:material_instances'] = O '*' (Mat $side) north (Mat $end) south (Mat $end)
    $perms = @(
        (O condition "q.block_state('minecraft:cardinal_direction') == 'east' || q.block_state('minecraft:cardinal_direction') == 'west'" components (O 'minecraft:transformation' (O rotation @(0, 90, 0))))
    )
    $traits = O 'minecraft:placement_direction' (O enabled_states @('minecraft:cardinal_direction'))
    Save-Json "assets/pack/bp/blocks/$($b.id).json" (Block-Doc $b $c $null $traits $perms)
    Register-Block $b 'haxis' $drop
}

# --- partials: geometry (world aligned boxes, no transformation so collision matches) ----------
function Face-Uv([int[]]$a, [int[]]$s) {
    # $a = x0,y0,z0 (0..16), $s = size
    $x0 = $a[0]; $y0 = $a[1]; $z0 = $a[2]; $x1 = $x0 + $s[0]; $y1 = $y0 + $s[1]; $z1 = $z0 + $s[2]
    O north (O uv @((16 - $x1), (16 - $y1)) uv_size @($s[0], $s[1])) `
        south (O uv @($x0, (16 - $y1)) uv_size @($s[0], $s[1])) `
        east (O uv @((16 - $z1), (16 - $y1)) uv_size @($s[2], $s[1])) `
        west (O uv @($z0, (16 - $y1)) uv_size @($s[2], $s[1])) `
        up (O uv @($x0, $z0) uv_size @($s[0], $s[2])) `
        down (O uv @($x0, (16 - $z1)) uv_size @($s[0], $s[2]))
}
function Geo-Cube([int[]]$a, [int[]]$s) { O origin @(($a[0] - 8), $a[1], ($a[2] - 8)) size $s uv (Face-Uv $a $s) }
function Geo-Bone([string]$name, $cubes) { O name $name pivot @(0, 0, 0) cubes @($cubes) }
function Save-Geo([string]$file, [string]$id, $bones) {
    Save-Json "assets/pack/rp/models/blocks/$file" (O format_version '1.21.0' 'minecraft:geometry' @((O description (O identifier $id texture_width 16 texture_height 16 visible_bounds_width 2 visible_bounds_height 2 visible_bounds_offset @(0, 0.5, 0)) bones @($bones))))
}
$quarters = [ordered]@{ nw = @(0, 0); ne = @(8, 0); sw = @(0, 8); se = @(8, 8) }
$stairBones = @((Geo-Bone 'slab_bottom' @(Geo-Cube @(0, 0, 0) @(16, 8, 16))), (Geo-Bone 'slab_top' @(Geo-Cube @(0, 8, 0) @(16, 8, 16))))
foreach ($q in $quarters.Keys) {
    $p = $quarters[$q]
    $stairBones += Geo-Bone "upper_$q" @(Geo-Cube @($p[0], 8, $p[1]) @(8, 8, 8))
    $stairBones += Geo-Bone "lower_$q" @(Geo-Cube @($p[0], 0, $p[1]) @(8, 8, 8))
}
Save-Geo 'materials_stairs.geo.json' 'geometry.bearing.materials_stairs' $stairBones
Save-Geo 'materials_slab.geo.json' 'geometry.bearing.materials_slab' @((Geo-Bone 'bottom' @(Geo-Cube @(0, 0, 0) @(16, 8, 16))), (Geo-Bone 'top' @(Geo-Cube @(0, 8, 0) @(16, 8, 16))))
# Java wall: post 4..12 (16 high), sides 5..11 wide reaching the block edge, low 14 / tall 16 high.
$wallSides = [ordered]@{ north = @(@(5, 0, 0), @(6, 14, 8)); south = @(@(5, 0, 8), @(6, 14, 8)); west = @(@(0, 0, 5), @(8, 14, 6)); east = @(@(8, 0, 5), @(8, 14, 6)) }
$wallBones = @(Geo-Bone 'post' @(Geo-Cube @(4, 0, 4) @(8, 16, 8)))
foreach ($k in $wallSides.Keys) {
    $wallBones += Geo-Bone $k @(Geo-Cube $wallSides[$k][0] $wallSides[$k][1])
    $tall = @($wallSides[$k][1][0], 16, $wallSides[$k][1][2])
    $wallBones += Geo-Bone "${k}_tall" @(Geo-Cube $wallSides[$k][0] $tall)
}
Save-Geo 'materials_wall.geo.json' 'geometry.bearing.materials_wall' $wallBones

function Box([int]$x0, [int]$y0, [int]$z0, [int]$sx, [int]$sy, [int]$sz) { O origin @(($x0 - 8), $y0, ($z0 - 8)) size @($sx, $sy, $sz) }
$dirs = [ordered]@{ north = @(0, -1); east = @(1, 0); south = @(0, 1); west = @(-1, 0) }
$ccw = @{ north = 'west'; east = 'north'; south = 'east'; west = 'south' }
$cornerSets = [ordered]@{
    none = @(@(1, 1), @(1, -1)); inner_left = @(@(1, 1), @(1, -1), @(-1, 1)); inner_right = @(@(1, 1), @(1, -1), @(-1, -1))
    outer_left = @(, @(1, 1)); outer_right = @(, @(1, -1))
}
# Quarter (back/front, left/right) of a stair facing $dir -> 'nw' | 'ne' | 'sw' | 'se'.
function Quarter([string]$dir, [int]$back, [int]$left) {
    $d = $dirs[$dir]; $l = $dirs[$ccw[$dir]]
    $x = $back * $d[0] + $left * $l[0]; $z = $back * $d[1] + $left * $l[1]
    ($(if ($z -lt 0) { 'n' } else { 's' })) + ($(if ($x -lt 0) { 'w' } else { 'e' }))
}

function Stairs-Block($b, [string]$tex, [string[]]$allStairs) {
    $c = Base-Components $b
    $c['minecraft:geometry'] = 'geometry.bearing.materials_stairs'
    $c['minecraft:material_instances'] = O '*' (Mat $tex)
    $c['minecraft:selection_box'] = Box 0 0 0 16 16 16
    $perms = @()
    foreach ($half in 'bottom', 'top') {
        foreach ($dir in $dirs.Keys) {
            foreach ($corner in $cornerSets.Keys) {
                $vis = [ordered]@{ slab_bottom = ($half -eq 'bottom'); slab_top = ($half -eq 'top') }
                foreach ($q in $quarters.Keys) { $vis["upper_$q"] = $false; $vis["lower_$q"] = $false }
                $boxes = @()
                if ($half -eq 'bottom') { $boxes += Box 0 0 0 16 8 16 } else { $boxes += Box 0 8 0 16 8 16 }
                foreach ($bl in $cornerSets[$corner]) {
                    $q = Quarter $dir $bl[0] $bl[1]
                    $level = if ($half -eq 'bottom') { 'upper' } else { 'lower' }
                    $vis["${level}_$q"] = $true
                    $p = $quarters[$q]
                    $boxes += Box $p[0] ($(if ($half -eq 'bottom') { 8 } else { 0 })) $p[1] 8 8 8
                }
                $perms += O condition "q.block_state('minecraft:vertical_half') == '$half' && q.block_state('minecraft:cardinal_direction') == '$dir' && q.block_state('minecraft:corner') == '$corner'" `
                    components (O 'minecraft:geometry' (O identifier 'geometry.bearing.materials_stairs' bone_visibility $vis) 'minecraft:collision_box' $boxes)
            }
        }
    }
    $traits = O 'minecraft:placement_direction' (O enabled_states @('minecraft:corner_and_cardinal_direction') blocks_to_corner_with @($allStairs)) `
        'minecraft:placement_position' (O enabled_states @('minecraft:vertical_half'))
    Save-Json "assets/pack/bp/blocks/$($b.id).json" (Block-Doc $b $c $null $traits $perms)
    Save-Loot $b.id "bearing:$($b.id)"
    Register-Block $b 'stairs'
}

# Slab: Create's bottom/top/double as minecraft:vertical_half + bearing:double (the mod merges a
# second slab into a single one and drops two).
function Slab-Block($b, [string]$top, [string]$side, [string]$doubleTex) {
    $c = Base-Components $b
    $c['minecraft:geometry'] = O identifier 'geometry.bearing.materials_slab' bone_visibility (O bottom "q.block_state('minecraft:vertical_half') == 'bottom'" top "q.block_state('minecraft:vertical_half') == 'top'")
    $c['minecraft:material_instances'] = O '*' (Mat $side) up (Mat $top) down (Mat $top)
    $c['minecraft:collision_box'] = Box 0 0 0 16 8 16
    $c['minecraft:selection_box'] = Box 0 0 0 16 8 16
    $perms = @(
        (O condition "q.block_state('minecraft:vertical_half') == 'top' && !q.block_state('bearing:double')" components (O 'minecraft:collision_box' (Box 0 8 0 16 8 16) 'minecraft:selection_box' (Box 0 8 0 16 8 16))),
        (O condition "q.block_state('bearing:double')" components (O 'minecraft:geometry' 'minecraft:geometry.full_block' 'minecraft:collision_box' $true 'minecraft:selection_box' $true 'minecraft:material_instances' (O '*' (Mat $doubleTex)) 'minecraft:loot' "loot_tables/blocks/$($b.id)_double.json"))
    )
    $traits = O 'minecraft:placement_position' (O enabled_states @('minecraft:vertical_half'))
    Save-Json "assets/pack/bp/blocks/$($b.id).json" (Block-Doc $b $c (O 'bearing:double' @($false, $true)) $traits $perms)
    Save-Loot $b.id "bearing:$($b.id)"
    Save-Loot "$($b.id)_double" "bearing:$($b.id)" 2
    Register-Block $b 'slab'
}

# Wall: Bedrock's connection trait gives the four connections; the mod adds Java's WallBlock
# rules (src/feature/materials/MaterialsConnections.cpp): bearing:up (the post: unless straight,
# or forced by the block above) and bearing:tall_<dir> (a side covered by the block above is 16
# high instead of 14). The collision (24 px as Java) comes from the mod's collision hook; the JSON
# boxes are what vanilla clients predict with (Bedrock caps them at 16 px).
function Wall-Block($b, [string]$tex) {
    $c = Base-Components $b
    $vis = O post "q.block_state('bearing:up') == 1"
    foreach ($k in $wallSides.Keys) {
        $vis[$k] = "q.block_state('minecraft:connection_$k') && q.block_state('bearing:tall_$k') == 0"
        $vis["${k}_tall"] = "q.block_state('minecraft:connection_$k') && q.block_state('bearing:tall_$k') == 1"
    }
    $c['minecraft:geometry'] = O identifier 'geometry.bearing.materials_wall' bone_visibility $vis
    $c['minecraft:material_instances'] = O '*' (Mat $tex)
    $perms = @()
    foreach ($post in 0, 1) {
        foreach ($mask in 0..15) {
            $n = [bool]($mask -band 1); $e = [bool]($mask -band 2); $s = [bool]($mask -band 4); $w = [bool]($mask -band 8)
            $boxes = @(); $x0 = 16; $z0 = 16; $x1 = 0; $z1 = 0
            $parts = @()
            if ($post -or $mask -eq 0) { $parts += , @(4, 4, 8, 8) }
            if ($n) { $parts += , @(5, 0, 6, 8) }; if ($s) { $parts += , @(5, 8, 6, 8) }
            if ($w) { $parts += , @(0, 5, 8, 6) }; if ($e) { $parts += , @(8, 5, 8, 6) }
            foreach ($p in $parts) {
                $boxes += Box $p[0] 0 $p[1] $p[2] 16 $p[3]
                $x0 = [Math]::Min($x0, $p[0]); $z0 = [Math]::Min($z0, $p[1]); $x1 = [Math]::Max($x1, $p[0] + $p[2]); $z1 = [Math]::Max($z1, $p[1] + $p[3])
            }
            $cond = "q.block_state('bearing:up') == $post && q.block_state('minecraft:connection_north') == $([int]$n) && q.block_state('minecraft:connection_east') == $([int]$e) && q.block_state('minecraft:connection_south') == $([int]$s) && q.block_state('minecraft:connection_west') == $([int]$w)"
            $perms += O condition $cond components (O 'minecraft:collision_box' $boxes 'minecraft:selection_box' (Box $x0 0 $z0 ($x1 - $x0) 16 ($z1 - $z0)))
        }
    }
    $states = O 'bearing:up' @(0, 1) 'bearing:tall_north' @(0, 1) 'bearing:tall_east' @(0, 1) 'bearing:tall_south' @(0, 1) 'bearing:tall_west' @(0, 1)
    $traits = O 'minecraft:connection' (O enabled_states @('minecraft:cardinal_connections'))
    $doc = Block-Doc $b $c $states $traits $perms
    $doc.format_version = '1.26.0' # the minecraft:connection trait needs 1.26.0
    Save-Json "assets/pack/bp/blocks/$($b.id).json" $doc
    Save-Loot $b.id "bearing:$($b.id)"
    Register-Block $b 'wall'
}

# Connected textures of the layered stone and the stone pillars (Create's HorizontalCTBehaviour /
# RotatedPillarCTBehaviour). The mod keeps bearing:c_<dir> (the neighbour on <dir> connects,
# MaterialsConnections.cpp); every combination picks the face textures:
#   layered: sides `<s>_layered_<m>` (Create's HORIZONTAL_KRYPPERS: left / right only), top and
#            bottom `<s>_cap_<m>` (OMNIDIRECTIONAL: the four edges);
#   pillar:  faces along the axis `<s>_cap_<m>`, sides `<s>_pillar_<m>` (RECTANGLE: four edges).
# m = edge mask, bits 1 top, 2 right, 4 bottom, 8 left as seen from outside the face.
$faceEdges = [ordered]@{
    north = @('up', 'west', 'down', 'east'); south = @('up', 'east', 'down', 'west')
    east = @('up', 'north', 'down', 'south'); west = @('up', 'south', 'down', 'north')
    up = @('north', 'east', 'south', 'west'); down = @('south', 'east', 'north', 'west')
}
$ctDirs = @('down', 'up', 'north', 'south', 'west', 'east')
function Edge-Mask([string]$face, $conn, [int[]]$edges = @(0, 1, 2, 3)) {
    $m = 0
    foreach ($i in $edges) { if ($conn[$faceEdges[$face][$i]]) { $m = $m -bor (1 -shl $i) } }
    $m
}
function Layered-Block($b, [string]$n) {
    $c = Base-Components $b
    $c['minecraft:geometry'] = 'minecraft:geometry.full_block'
    $c['minecraft:material_instances'] = O '*' (Mat "bearing_${n}_layered_0") up (Mat "bearing_${n}_cap_0") down (Mat "bearing_${n}_cap_0")
    $hd = @('north', 'south', 'west', 'east')
    $perms = @()
    foreach ($bits in 0..15) {
        $conn = @{}; $cond = @()
        for ($i = 0; $i -lt 4; $i++) { $on = (($bits -shr $i) -band 1) -eq 1; $conn[$hd[$i]] = $on; $cond += "q.block_state('bearing:c_$($hd[$i])') == $([int]$on)" }
        $mi = O
        foreach ($f in $faceEdges.Keys) {
            if ($f -in 'up', 'down') { $mi[$f] = Mat "bearing_${n}_cap_$(Edge-Mask $f $conn)" }
            else { $mi[$f] = Mat "bearing_${n}_layered_$(Edge-Mask $f $conn @(1, 3))" }
        }
        $mi['*'] = $mi['north']
        $perms += O condition ($cond -join ' && ') components (O 'minecraft:material_instances' $mi)
    }
    $states = O; foreach ($d in $hd) { $states["bearing:c_$d"] = @(0, 1) }
    Save-Json "assets/pack/bp/blocks/$($b.id).json" (Block-Doc $b $c $states $null $perms)
    Save-Loot $b.id "bearing:$($b.id)"
    Register-Block $b 'layered'
}
# The pillar's model is turned onto its axis by minecraft:transformation, so a model face shows on
# the world face the rotation takes it to: the face's edge neighbours are looked up in world space.
$axisTurns = [ordered]@{
    y = @{ cond = "q.block_state('minecraft:block_face') == 'up' || q.block_state('minecraft:block_face') == 'down'"; rot = @(0, 0, 0); map = @{ up = 'up'; down = 'down'; north = 'north'; south = 'south'; west = 'west'; east = 'east' } }
    z = @{ cond = "q.block_state('minecraft:block_face') == 'north' || q.block_state('minecraft:block_face') == 'south'"; rot = @(90, 0, 0); map = @{ up = 'north'; north = 'down'; down = 'south'; south = 'up'; west = 'west'; east = 'east' } }
    x = @{ cond = "q.block_state('minecraft:block_face') == 'east' || q.block_state('minecraft:block_face') == 'west'"; rot = @(0, 0, 90); map = @{ up = 'west'; west = 'down'; down = 'east'; east = 'up'; north = 'north'; south = 'south' } }
}
function StonePillar-Block($b, [string]$n) {
    $c = Base-Components $b
    $c['minecraft:geometry'] = 'minecraft:geometry.full_block'
    $c['minecraft:material_instances'] = O '*' (Mat "bearing_${n}_pillar_0") up (Mat "bearing_${n}_cap_0") down (Mat "bearing_${n}_cap_0")
    $perms = @()
    foreach ($ax in $axisTurns.Keys) {
        $t = $axisTurns[$ax]
        foreach ($bits in 0..63) {
            $world = @{}; $cond = @()
            for ($i = 0; $i -lt 6; $i++) { $on = (($bits -shr $i) -band 1) -eq 1; $world[$ctDirs[$i]] = $on; $cond += "q.block_state('bearing:c_$($ctDirs[$i])') == $([int]$on)" }
            # the connections seen from the model's faces
            $conn = @{}; foreach ($d in $ctDirs) { $conn[$d] = $world[$t.map[$d]] }
            $mi = O
            foreach ($f in $faceEdges.Keys) {
                if ($f -in 'up', 'down') { $mi[$f] = Mat "bearing_${n}_cap_$(Edge-Mask $f $conn)" }
                else { $mi[$f] = Mat "bearing_${n}_pillar_$(Edge-Mask $f $conn)" }
            }
            $mi['*'] = $mi['north']
            $comps = O 'minecraft:material_instances' $mi
            if ($ax -ne 'y') { $comps['minecraft:transformation'] = O rotation $t.rot }
            $perms += O condition "($($t.cond)) && $($cond -join ' && ')" components $comps
        }
    }
    $states = O; foreach ($d in $ctDirs) { $states["bearing:c_$d"] = @(0, 1) }
    $traits = O 'minecraft:placement_position' (O enabled_states @('minecraft:block_face'))
    Save-Json "assets/pack/bp/blocks/$($b.id).json" (Block-Doc $b $c $states $traits $perms)
    Save-Loot $b.id "bearing:$($b.id)"
    Register-Block $b 'stonePillar'
}

function B([string]$id, [double]$hardness, [double]$resistance, [string]$map, [string]$sound, [string]$cat = 'construction', $more = @{}) {
    $b = @{ id = $id; hardness = $hardness; resistance = $resistance; map = $map; sound = $sound; cat = $cat; group = $null; tool = 'pickaxe'; tier = 'none'; light = 0 }
    foreach ($k in $more.Keys) { $b[$k] = $more[$k] }
    $b
}

# Metals, ores and other material blocks (Create's AllBlocks; properties copied from the vanilla
# block Create starts from: gold ore 3/3, deepslate gold ore 4.5/3, raw gold block 5/6, iron
# block 5/6, gold block 3/6, andesite 1.5/6, amethyst 1.5/1.5, deepslate 3/6, mushroom stem .2/.2).
Tex 'bearing_zinc_ore' 'zinc_ore'; Tex 'bearing_deepslate_zinc_ore' 'deepslate_zinc_ore'
Cube-Block (B 'zinc_ore' 3 3 '#a7a7a7' 'stone' 'nature' @{ group = 'minecraft:itemGroup.name.ore'; tier = 'iron' }) @{ '*' = 'bearing_zinc_ore' } 'zincOre' 'bearing:raw_zinc'
Cube-Block (B 'deepslate_zinc_ore' 4.5 3 '#707070' 'deepslate' 'nature' @{ group = 'minecraft:itemGroup.name.ore'; tier = 'iron' }) @{ '*' = 'bearing_deepslate_zinc_ore' } 'zincOre' 'bearing:raw_zinc'
foreach ($m in @(
        @('raw_zinc_block', 5, 6, '#7fa796', 'stone', 'iron'), @('zinc_block', 5, 6, '#7fa796', 'metal', 'iron'),
        @('brass_block', 5, 6, '#ba8524', 'metal', 'iron'), @('andesite_alloy_block', 1.5, 6, '#707070', 'stone', 'none'),
        @('rose_quartz_tiles', 3, 6, '#a04d4e', 'deepslate', 'none'), @('small_rose_quartz_tiles', 3, 6, '#a04d4e', 'deepslate', 'none'))) {
    Tex "bearing_$($m[0])" $m[0]
    Cube-Block (B $m[0] $m[1] $m[2] $m[3] $m[4] 'construction' @{ tier = $m[5] }) @{ '*' = "bearing_$($m[0])" }
}
Tex 'bearing_experience_block' 'experience_block'
Cube-Block (B 'experience_block' 3 6 '#007c00' 'amethyst_block' 'construction' @{ light = 15 }) @{ '*' = 'bearing_experience_block' }
foreach ($id in 'industrial_iron_block', 'weathered_iron_block') {
    Tex "bearing_$id" $id; Tex "bearing_${id}_top" "${id}_top"
    Cube-Block (B $id 3 6 '#4c4c4c' 'netherite') @{ '*' = "bearing_$id"; up = "bearing_${id}_top"; down = "bearing_${id}_top" }
}
Tex 'bearing_rose_quartz_block' 'rose_quartz_block'; Tex 'bearing_rose_quartz_block_top' 'rose_quartz_block_top'
Pillar-Block (B 'rose_quartz_block' 1.5 1.5 '#a04d4e' 'deepslate') 'bearing_rose_quartz_block' 'bearing_rose_quartz_block_top'
foreach ($id in 'cardboard_block', 'bound_cardboard_block') {
    Tex "bearing_$id" $id; Tex "bearing_${id}_end" "${id}_end"
    $b = B $id 0.2 0.2 '#664c33' 'wood' 'construction' @{ tool = 'axe' }
    if ($id -eq 'cardboard_block') { Save-Loot $id 'bearing:cardboard_block'; HAxis-Block $b "bearing_$id" "bearing_${id}_end" }
    else { Save-Loot $id 'bearing:cardboard_block' 1 @('minecraft:string'); HAxis-Block $b "bearing_$id" "bearing_${id}_end" 'boundCardboard' }
}

# ---- decorative stone (Create's palettes) -------------------------------------------------------
# name, hardness, resistance, map colour, sound, Create stone?, natural texture variants
$stones = @(
    @('granite', 1.5, 6, '#976d4d', 'stone', $false, 0), @('diorite', 1.5, 6, '#fffcf5', 'stone', $false, 0),
    @('andesite', 1.5, 6, '#707070', 'stone', $false, 0), @('calcite', 0.75, 0.75, '#d1b1a1', 'calcite', $false, 0),
    @('dripstone', 1.5, 1, '#4c3223', 'dripstone_block', $false, 0), @('deepslate', 3, 6, '#646464', 'deepslate', $false, 0),
    @('tuff', 1.5, 6, '#392923', 'tuff', $false, 0),
    @('asurine', 1.25, 6, '#334cb2', 'deepslate', $true, 4), @('crimsite', 1.25, 6, '#993333', 'deepslate', $true, 4),
    @('limestone', 1.25, 0.8, '#f7e9a3', 'stone', $true, 0), @('ochrum', 1.25, 0.75, '#ba8524', 'calcite', $true, 4),
    @('scoria', 1.5, 6, '#664c33', 'stone', $true, 0), @('scorchia', 1.5, 6, '#392923', 'stone', $true, 0),
    @('veridium', 1.25, 6, '#167e86', 'tuff', $true, 4)
)
$vanillaStone = @{ granite = 'minecraft:granite'; diorite = 'minecraft:diorite'; andesite = 'minecraft:andesite'; calcite = 'minecraft:calcite'; dripstone = 'minecraft:dripstone_block'; deepslate = 'minecraft:deepslate'; tuff = 'minecraft:tuff' }
$allStairs = @()
foreach ($s in $stones) { foreach ($p in "cut_$($s[0])", "polished_cut_$($s[0])", "cut_$($s[0])_brick", "small_$($s[0])_brick") { $allStairs += "bearing:${p}_stairs" } }

$stoneTypes = [ordered]@{}   # stone -> ids of the stone_types tag (Create: every full/stairs/wall + the raw stone)
$palette = [ordered]@{}      # stone -> list of @{ id; kind; base } for recipes
foreach ($s in $stones) {
    $n = $s[0]
    $mk = { param($id, $more = @{}) B $id $s[1] $s[2] $s[3] $s[4] 'construction' $more }
    foreach ($t in 'cut', 'polished', 'slab', 'brick', 'small_brick') { Tex "bearing_${n}_$t" "palettes/${n}_$t" }
    foreach ($m in 0, 2, 8, 10) { Tex "bearing_${n}_layered_$m" "palettes/${n}_layered_$m" }
    foreach ($m in 0..15) { Tex "bearing_${n}_cap_$m" "palettes/${n}_cap_$m"; Tex "bearing_${n}_pillar_$m" "palettes/${n}_pillar_$m" }
    $tag = [System.Collections.Generic.List[string]]::new()
    $list = [System.Collections.Generic.List[object]]::new()
    if ($s[5]) {
        $variants = $s[6]
        if ($variants -gt 0) {
            $terrainTextures["bearing_$n"] = O textures (O variations @(0..($variants - 1) | ForEach-Object { O path "textures/blocks/palettes/${n}_natural_$_" weight 1 }))
        } else { Tex "bearing_$n" "palettes/$n" }
        Cube-Block (& $mk $n) @{ '*' = "bearing_$n" }
    }
    $raw = if ($s[5]) { "bearing:$n" } else { $vanillaStone[$n] }
    # patterns: [block id, texture, stairs/slab/wall prefix, slab side texture]
    $patterns = @(
        @("cut_$n", "bearing_${n}_cut", "cut_$n", "bearing_${n}_cut"),
        @("polished_cut_$n", "bearing_${n}_polished", "polished_cut_$n", "bearing_${n}_slab"),
        @("cut_${n}_bricks", "bearing_${n}_brick", "cut_${n}_brick", "bearing_${n}_brick"),
        @("small_${n}_bricks", "bearing_${n}_small_brick", "small_${n}_brick", "bearing_${n}_small_brick")
    )
    foreach ($p in $patterns) {
        Cube-Block (& $mk $p[0]) @{ '*' = $p[1] }
        Stairs-Block (& $mk "$($p[2])_stairs" @{ group = 'minecraft:itemGroup.name.stairs' }) $p[1] $allStairs
        Slab-Block (& $mk "$($p[2])_slab" @{ group = 'minecraft:itemGroup.name.slab' }) $p[1] $p[3] $p[1]
        Wall-Block (& $mk "$($p[2])_wall" @{ group = 'minecraft:itemGroup.name.walls' }) $p[1]
        $tag.Add("bearing:$($p[0])"); $tag.Add("bearing:$($p[2])_stairs"); $tag.Add("bearing:$($p[2])_wall")
        $list.Add(@{ base = "bearing:$($p[0])"; prefix = "bearing:$($p[2])" })
    }
    Layered-Block (& $mk "layered_$n") $n
    StonePillar-Block (& $mk "${n}_pillar") $n
    $tag.Add("bearing:layered_$n"); $tag.Add("bearing:${n}_pillar"); $tag.Add($raw)
    $stoneTypes[$n] = $tag
    $palette[$n] = $list
}

# ---- recipes (behavior pack) --------------------------------------------------------------------
# Create's c: tags resolved to the one Bedrock item each stands for.
$tagItem = @{
    'c:nuggets/iron' = 'minecraft:iron_nugget'; 'c:nuggets/zinc' = 'bearing:zinc_nugget'; 'c:nuggets/brass' = 'bearing:brass_nugget'
    'c:nuggets/copper' = 'bearing:copper_nugget'; 'c:ingots/iron' = 'minecraft:iron_ingot'; 'c:ingots/gold' = 'minecraft:gold_ingot'
    'c:ingots/copper' = 'minecraft:copper_ingot'; 'c:ingots/zinc' = 'bearing:zinc_ingot'; 'c:ingots/brass' = 'bearing:brass_ingot'
    'c:storage_blocks/zinc' = 'bearing:zinc_block'; 'c:storage_blocks/brass' = 'bearing:brass_block'; 'c:strings' = 'minecraft:string'
    'c:plates/iron' = 'bearing:iron_sheet'; 'c:plates/brass' = 'bearing:brass_sheet'; 'c:plates/copper' = 'bearing:copper_sheet'
    'c:gems/quartz' = 'minecraft:quartz'; 'c:dusts/redstone' = 'minecraft:redstone'; 'c:flours/wheat' = 'bearing:wheat_flour'
    'c:rods/wooden' = 'minecraft:stick'; 'c:dyes/black' = 'minecraft:black_dye'; 'c:dyes/lime' = 'minecraft:lime_dye'
    'c:raw_materials/zinc' = 'bearing:raw_zinc'
}
function Ing([string]$s) {
    if ($s.StartsWith('#')) { $t = $s.Substring(1); if (!$tagItem.ContainsKey($t)) { throw "unresolved tag $t" }; return O item $tagItem[$t] }
    O item $s
}
function Shaped([string]$name, [string[]]$pattern, [hashtable]$key, [string]$result, [int]$count = 1) {
    $k = [ordered]@{}; foreach ($c in ($key.Keys | Sort-Object)) { $k[$c] = Ing $key[$c] }
    $first = $k[($key.Keys | Sort-Object | Select-Object -First 1)]
    Save-Json "assets/pack/bp/recipes/materials/$name.json" (O format_version '1.20.10' 'minecraft:recipe_shaped' (O description (O identifier "bearing:$name") tags @('crafting_table') pattern @($pattern) key $k unlock @((O item $first.item)) result (O item $result count $count)))
}
function Shapeless([string]$name, [string[]]$ingredients, [string]$result, [int]$count = 1) {
    $ings = @($ingredients | ForEach-Object { Ing $_ })
    Save-Json "assets/pack/bp/recipes/materials/$name.json" (O format_version '1.20.10' 'minecraft:recipe_shapeless' (O description (O identifier "bearing:$name") tags @('crafting_table') ingredients $ings unlock @((O item $ings[0].item)) result (O item $result count $count)))
}
function Cutting([string]$name, [string]$source, [string]$result, [int]$count = 1) {
    Save-Json "assets/pack/bp/recipes/materials/stonecutting/$name.json" (O format_version '1.20.10' 'minecraft:recipe_shapeless' (O description (O identifier "bearing:$name") tags @('stonecutter') ingredients @((O item $source)) unlock @((O item $source)) result (O item $result count $count)))
}
# Bedrock furnaces cook in 10 s (furnace), 5 s (blast furnace, smoker), 30 s (campfire): Create's
# 200 / 100 / 100 / 600 ticks.
function Furnace([string]$name, [string]$source, [string]$output, [string[]]$tags) {
    Save-Json "assets/pack/bp/recipes/materials/$name.json" (O format_version '1.20.10' 'minecraft:recipe_furnace' (O description (O identifier "bearing:$name") tags @($tags) input $source output $output))
}

# crafting/materials, crafting/kinetics (ingredients), crafting/appliances
Shaped 'andesite_alloy' @('BA', 'AB') @{ A = 'minecraft:andesite'; B = '#c:nuggets/iron' } 'bearing:andesite_alloy'
Shaped 'andesite_alloy_from_zinc' @('BA', 'AB') @{ A = 'minecraft:andesite'; B = '#c:nuggets/zinc' } 'bearing:andesite_alloy'
Shaped 'andesite_alloy_block' @('CCC', 'CCC', 'CCC') @{ C = 'bearing:andesite_alloy' } 'bearing:andesite_alloy_block'
Shapeless 'andesite_alloy_from_block' @('bearing:andesite_alloy_block') 'bearing:andesite_alloy' 9
Shapeless 'bound_cardboard_block' @('bearing:cardboard_block', '#c:strings') 'bearing:bound_cardboard_block'
Shaped 'brass_block_from_compacting' @('###', '###', '###') @{ '#' = '#c:ingots/brass' } 'bearing:brass_block'
Shaped 'brass_ingot_from_compacting' @('###', '###', '###') @{ '#' = '#c:nuggets/brass' } 'bearing:brass_ingot'
Shapeless 'brass_ingot_from_decompacting' @('#c:storage_blocks/brass') 'bearing:brass_ingot' 9
Shapeless 'brass_nugget_from_decompacting' @('#c:ingots/brass') 'bearing:brass_nugget' 9
Shaped 'cardboard_block' @('CC', 'CC') @{ C = 'bearing:cardboard' } 'bearing:cardboard_block'
Shapeless 'cardboard_from_block' @('bearing:cardboard_block') 'bearing:cardboard' 4
Shapeless 'cardboard_from_bound_block' @('bearing:bound_cardboard_block') 'bearing:cardboard' 4
Shaped 'copper_ingot' @('CCC', 'CCC', 'CCC') @{ C = '#c:nuggets/copper' } 'minecraft:copper_ingot'
Shapeless 'copper_nugget' @('#c:ingots/copper') 'bearing:copper_nugget' 9
Shaped 'electron_tube' @('L', 'N') @{ L = 'bearing:polished_rose_quartz'; N = '#c:plates/iron' } 'bearing:electron_tube'
Shaped 'experience_block' @('CCC', 'CCC', 'CCC') @{ C = 'bearing:experience_nugget' } 'bearing:experience_block'
Shapeless 'experience_nugget_from_block' @('bearing:experience_block') 'bearing:experience_nugget' 9
Shapeless 'raw_zinc' @('bearing:raw_zinc_block') 'bearing:raw_zinc' 9
Shaped 'raw_zinc_block' @('CCC', 'CCC', 'CCC') @{ C = 'bearing:raw_zinc' } 'bearing:raw_zinc_block'
Shapeless 'rose_quartz' @('#c:gems/quartz', '#c:dusts/redstone', '#c:dusts/redstone', '#c:dusts/redstone', '#c:dusts/redstone', '#c:dusts/redstone', '#c:dusts/redstone', '#c:dusts/redstone', '#c:dusts/redstone') 'bearing:rose_quartz'
Shapeless 'rose_quartz_tiles_from_conversion' @('bearing:small_rose_quartz_tiles') 'bearing:rose_quartz_tiles'
Shapeless 'small_rose_quartz_tiles_from_conversion' @('bearing:rose_quartz_tiles') 'bearing:small_rose_quartz_tiles'
Shaped 'transmitter' @(' N ', 'LLL', ' R ') @{ L = '#c:plates/copper'; N = 'minecraft:lightning_rod'; R = '#c:dusts/redstone' } 'bearing:transmitter'
Shaped 'zinc_block_from_compacting' @('###', '###', '###') @{ '#' = '#c:ingots/zinc' } 'bearing:zinc_block'
Shaped 'zinc_ingot_from_compacting' @('###', '###', '###') @{ '#' = '#c:nuggets/zinc' } 'bearing:zinc_ingot'
Shapeless 'zinc_ingot_from_decompacting' @('#c:storage_blocks/zinc') 'bearing:zinc_ingot' 9
Shapeless 'zinc_nugget_from_decompacting' @('#c:ingots/zinc') 'bearing:zinc_nugget' 9
Shaped 'brass_hand' @(' A ', 'BBB', ' B ') @{ A = 'bearing:andesite_alloy'; B = '#c:plates/brass' } 'bearing:brass_hand'
Shaped 'crafter_slot_cover' @('AAA') @{ A = '#c:nuggets/brass' } 'bearing:crafter_slot_cover'
Shaped 'propeller' @(' S ', 'SCS', ' S ') @{ C = 'bearing:andesite_alloy'; S = '#c:plates/iron' } 'bearing:propeller'
Shaped 'whisk' @(' C ', 'SCS', 'SSS') @{ C = 'bearing:andesite_alloy'; S = '#c:plates/iron' } 'bearing:whisk'
Shapeless 'book' @('bearing:cardboard', 'minecraft:paper', 'minecraft:paper', 'minecraft:paper') 'minecraft:book'
Shaped 'item_frame' @('SSS', 'SPS', 'SSS') @{ P = 'bearing:cardboard'; S = '#c:rods/wooden' } 'minecraft:frame'
Shapeless 'name_tag' @('#c:dyes/black', '#c:strings', 'bearing:cardboard') 'minecraft:name_tag'
Shapeless 'slime_ball' @('bearing:dough', '#c:dyes/lime') 'minecraft:slime_ball'
Shapeless 'dough' @('#c:flours/wheat', 'minecraft:water_bucket') 'bearing:dough'
Shaped 'scorchia' @('###', '#D#', '###') @{ '#' = 'bearing:scoria'; D = '#c:dyes/black' } 'bearing:scorchia' 8

# U3's attribute filter waited for brass_nugget (SPEC §2.26): brass nugget, wool, brass nugget.
Save-Json 'assets/pack/bp/recipes/materials/attribute_filter.json' (O format_version '1.20.10' 'minecraft:recipe_shaped' (O description (O identifier 'bearing:attribute_filter') tags @('crafting_table') pattern @('NWN') key (O N (O item 'bearing:brass_nugget') W (O tag 'minecraft:wool')) unlock @((O item 'bearing:brass_nugget')) result (O item 'bearing:attribute_filter')))

# stonecutting (non-palette)
foreach ($id in 'industrial_iron_block', 'weathered_iron_block') { Cutting "${id}_from_ingots_iron_stonecutting" 'minecraft:iron_ingot' "bearing:$id" 2 }
Cutting 'rose_quartz_block_from_rose_quartz_stonecutting' 'bearing:rose_quartz' 'bearing:rose_quartz_block' 2
Cutting 'rose_quartz_tiles_from_polished_rose_quartz_stonecutting' 'bearing:polished_rose_quartz' 'bearing:rose_quartz_tiles' 2
Cutting 'small_rose_quartz_tiles_from_polished_rose_quartz_stonecutting' 'bearing:polished_rose_quartz' 'bearing:small_rose_quartz_tiles' 2

# furnace recipes (smelting + blasting where Create has both)
foreach ($m in @(@('copper', 'minecraft:copper_ingot'), @('gold', 'minecraft:gold_ingot'), @('iron', 'minecraft:iron_ingot'), @('zinc', 'bearing:zinc_ingot'))) {
    Furnace "$($m[1].Split(':')[1])_from_crushed" "bearing:crushed_raw_$($m[0])" $m[1] @('furnace', 'blast_furnace')
}
Furnace 'zinc_ingot_from_ore' 'bearing:zinc_ore' 'bearing:zinc_ingot' @('furnace', 'blast_furnace')
Furnace 'zinc_ingot_from_deepslate_ore' 'bearing:deepslate_zinc_ore' 'bearing:zinc_ingot' @('furnace', 'blast_furnace')
Furnace 'zinc_ingot_from_raw_ore' 'bearing:raw_zinc' 'bearing:zinc_ingot' @('furnace', 'blast_furnace')
Furnace 'bread' 'bearing:dough' 'minecraft:bread' @('furnace', 'smoker', 'campfire', 'soul_campfire')
Furnace 'scoria' 'minecraft:soul_sand' 'bearing:scoria' @('furnace')

# palettes: slab / stairs / wall crafting, slab recycling, stonecutting from the stone_types tag
foreach ($n in $palette.Keys) {
    foreach ($p in $palette[$n]) {
        $base = $p.base; $pre = $p.prefix; $preName = $pre.Split(':')[1]; $baseName = $base.Split(':')[1]
        Shaped "${preName}_slab" @('XXX') @{ X = $base } "${pre}_slab" 6
        Shaped "${preName}_stairs" @('X  ', 'XX ', 'XXX') @{ X = $base } "${pre}_stairs" 4
        Shaped "${preName}_wall" @('XXX', 'XXX') @{ X = $base } "${pre}_wall" 6
        Shapeless "${preName}_slab_recycling" @("${pre}_slab", "${pre}_slab") $base
    }
    $outputs = @()
    foreach ($p in $palette[$n]) { $outputs += , @($p.base, 1); $outputs += , @("$($p.prefix)_stairs", 1); $outputs += , @("$($p.prefix)_slab", 2); $outputs += , @("$($p.prefix)_wall", 1) }
    $outputs += , @("bearing:layered_$n", 1); $outputs += , @("bearing:${n}_pillar", 1)
    $outputs += , @($stoneTypes[$n][$stoneTypes[$n].Count - 1], 1)  # the raw stone
    foreach ($o in $outputs) {
        foreach ($in in $stoneTypes[$n]) {
            if ($in -eq $o[0]) { continue }
            Cutting "$($o[0].Split(':')[1])_from_$($in.Split(':')[1])_stonecutting" $in $o[0] $o[1]
        }
    }
}

# ---- processing recipes (U3 loader, Create's 1.21 format with bearing ids) ---------------------
# ingredient strings: 'id' | '#tag' | 'F:fluid*amount' | 'FT:fluid_tag*amount' | 'a|b' (alternatives)
# result strings: 'id' | 'id*count' | 'id@chance' | 'id*count@chance' | 'F:fluid*amount'
function PIng([string]$s) {
    if ($s.Contains('|')) { return , @($s.Split('|') | ForEach-Object { PIng $_ }) }
    if ($s.StartsWith('F:')) { $a = $s.Substring(2).Split('*'); return O fluid $a[0] amount ([int]$a[1]) }
    if ($s.StartsWith('FT:')) { $a = $s.Substring(3).Split('*'); return O fluid_tag $a[0] amount ([int]$a[1]) }
    if ($s.StartsWith('#')) { return O tag $s.Substring(1) }
    O item $s
}
function PRes([string]$s) {
    if ($s.StartsWith('F:')) { $a = $s.Substring(2).Split('*'); return O fluid $a[0] amount ([int]$a[1]) }
    $chance = $null
    if ($s.Contains('@')) { $chance = [double]$s.Split('@')[1]; $s = $s.Split('@')[0] }
    $count = 1
    if ($s.Contains('*')) { $count = [int]$s.Split('*')[1]; $s = $s.Split('*')[0] }
    $r = O id $s
    if ($count -ne 1) { $r['count'] = $count }
    if ($null -ne $chance) { $r['chance'] = $chance }
    $r
}
# Recipes the processing units already ship with Create's data (U13 bulk: crushing / milling /
# splashing, U19 fluids: filling / emptying): theirs, not generated here.
$ownedElsewhere = [System.Collections.Generic.HashSet[string]]@('crushing/asurine', 'crushing/asurine_recycling', 'crushing/coal_ore', 'crushing/copper_ore', 'crushing/crimsite', 'crushing/crimsite_recycling', 'crushing/deepslate_coal_ore', 'crushing/deepslate_copper_ore', 'crushing/deepslate_diamond_ore', 'crushing/deepslate_emerald_ore', 'crushing/deepslate_gold_ore', 'crushing/deepslate_iron_ore', 'crushing/deepslate_lapis_ore', 'crushing/deepslate_redstone_ore', 'crushing/deepslate_zinc_ore', 'crushing/diamond_ore', 'crushing/emerald_ore', 'crushing/gilded_blackstone', 'crushing/gold_ore', 'crushing/iron_ore', 'crushing/lapis_ore', 'crushing/nether_gold_ore', 'crushing/nether_quartz_ore', 'crushing/netherrack', 'crushing/obsidian', 'crushing/ochrum', 'crushing/ochrum_recycling', 'crushing/raw_copper', 'crushing/raw_copper_block', 'crushing/raw_gold', 'crushing/raw_gold_block', 'crushing/raw_iron', 'crushing/raw_iron_block', 'crushing/raw_zinc', 'crushing/raw_zinc_block', 'crushing/redstone_ore', 'crushing/tuff', 'crushing/tuff_recycling', 'crushing/veridium', 'crushing/veridium_recycling', 'crushing/zinc_ore', 'emptying/builders_tea', 'filling/blaze_cake', 'filling/builders_tea', 'filling/chocolate_glazed_berries', 'filling/glowstone', 'filling/gunpowder', 'filling/honeyed_apple', 'filling/redstone', 'filling/sweet_roll', 'milling/wheat', 'splashing/crushed_raw_copper', 'splashing/crushed_raw_gold', 'splashing/crushed_raw_iron', 'splashing/crushed_raw_zinc', 'splashing/industrial_iron_block', 'splashing/wheat_flour')
function P([string]$type, [string]$name, [string[]]$ingredients, [string[]]$results, $extra = @{}) {
    if ($ownedElsewhere.Contains("$type/$name")) { return }
    $doc = O type "bearing:$type" ingredients @($ingredients | ForEach-Object { , (PIng $_) }) results @($results | ForEach-Object { PRes $_ })
    foreach ($k in ($extra.Keys | Sort-Object)) { $doc[$k] = $extra[$k] }
    Save-Json "assets/recipes/$type/$name.json" $doc
}
$t250 = @{ processing_time = 250 }; $t350 = @{ processing_time = 350 }; $t400 = @{ processing_time = 400 }
# crushing: ores, raw ores, Create's stones (+ their palette recycling), netherrack, obsidian, tuff
P crushing zinc_ore @('bearing:zinc_ore') @('bearing:crushed_raw_zinc', 'bearing:crushed_raw_zinc@0.75', 'bearing:experience_nugget@0.75', 'minecraft:cobblestone@0.125') $t250
P crushing deepslate_zinc_ore @('bearing:deepslate_zinc_ore') @('bearing:crushed_raw_zinc*2', 'bearing:crushed_raw_zinc@0.25', 'bearing:experience_nugget@0.75', 'minecraft:cobbled_deepslate@0.125') $t350
P crushing iron_ore @('minecraft:iron_ore') @('bearing:crushed_raw_iron', 'bearing:crushed_raw_iron@0.75', 'bearing:experience_nugget@0.75', 'minecraft:cobblestone@0.125') $t250
P crushing deepslate_iron_ore @('minecraft:deepslate_iron_ore') @('bearing:crushed_raw_iron*2', 'bearing:crushed_raw_iron@0.25', 'bearing:experience_nugget@0.75', 'minecraft:cobbled_deepslate@0.125') $t350
P crushing gold_ore @('minecraft:gold_ore') @('bearing:crushed_raw_gold', 'bearing:crushed_raw_gold@0.75', 'bearing:experience_nugget*2@0.75', 'minecraft:cobblestone@0.125') $t250
P crushing deepslate_gold_ore @('minecraft:deepslate_gold_ore') @('bearing:crushed_raw_gold*2', 'bearing:crushed_raw_gold@0.25', 'bearing:experience_nugget*2@0.75', 'minecraft:cobbled_deepslate@0.125') $t350
P crushing copper_ore @('minecraft:copper_ore') @('bearing:crushed_raw_copper*5', 'bearing:crushed_raw_copper@0.25', 'bearing:experience_nugget@0.75', 'minecraft:cobblestone@0.125') $t250
P crushing deepslate_copper_ore @('minecraft:deepslate_copper_ore') @('bearing:crushed_raw_copper*7', 'bearing:crushed_raw_copper@0.25', 'bearing:experience_nugget@0.75', 'minecraft:cobbled_deepslate@0.125') $t350
P crushing coal_ore @('minecraft:coal_ore') @('minecraft:coal', 'minecraft:coal@0.75', 'bearing:experience_nugget@0.75', 'minecraft:cobblestone@0.125') @{ processing_time = 150 }
P crushing deepslate_coal_ore @('minecraft:deepslate_coal_ore') @('minecraft:coal*2', 'minecraft:coal@0.25', 'bearing:experience_nugget@0.75', 'minecraft:cobbled_deepslate@0.125') @{ processing_time = 300 }
P crushing diamond_ore @('minecraft:diamond_ore') @('minecraft:diamond', 'minecraft:diamond@0.75', 'bearing:experience_nugget@0.75', 'minecraft:cobblestone@0.125') @{ processing_time = 350 }
P crushing deepslate_diamond_ore @('minecraft:deepslate_diamond_ore') @('minecraft:diamond*2', 'minecraft:diamond@0.25', 'bearing:experience_nugget@0.75', 'minecraft:cobbled_deepslate@0.125') @{ processing_time = 450 }
P crushing emerald_ore @('minecraft:emerald_ore') @('minecraft:emerald', 'minecraft:emerald@0.75', 'bearing:experience_nugget@0.75', 'minecraft:cobblestone@0.125') @{ processing_time = 350 }
P crushing deepslate_emerald_ore @('minecraft:deepslate_emerald_ore') @('minecraft:emerald*2', 'minecraft:emerald@0.25', 'bearing:experience_nugget@0.75', 'minecraft:cobbled_deepslate@0.125') @{ processing_time = 450 }
P crushing lapis_ore @('minecraft:lapis_ore') @('minecraft:lapis_lazuli*10', 'minecraft:lapis_lazuli@0.5', 'bearing:experience_nugget@0.75', 'minecraft:cobblestone@0.125') $t250
P crushing deepslate_lapis_ore @('minecraft:deepslate_lapis_ore') @('minecraft:lapis_lazuli*12', 'minecraft:lapis_lazuli@0.5', 'bearing:experience_nugget@0.75', 'minecraft:cobbled_deepslate@0.125') $t350
P crushing redstone_ore @('minecraft:redstone_ore') @('minecraft:redstone*6', 'minecraft:redstone@0.5', 'bearing:experience_nugget@0.75', 'minecraft:cobblestone@0.125') $t250
P crushing deepslate_redstone_ore @('minecraft:deepslate_redstone_ore') @('minecraft:redstone*7', 'minecraft:redstone@0.5', 'bearing:experience_nugget@0.75', 'minecraft:cobbled_deepslate@0.125') $t350
P crushing nether_gold_ore @('minecraft:nether_gold_ore') @('minecraft:gold_nugget*18', 'bearing:experience_nugget@0.75', 'minecraft:netherrack@0.125') $t350
P crushing nether_quartz_ore @('minecraft:quartz_ore') @('minecraft:quartz*2', 'minecraft:quartz@0.25', 'bearing:experience_nugget@0.75', 'minecraft:netherrack@0.125') $t350
P crushing gilded_blackstone @('minecraft:gilded_blackstone') @('minecraft:gold_nugget*18', 'bearing:experience_nugget@0.75', 'minecraft:blackstone@0.125') $t400
foreach ($m in 'iron', 'gold', 'copper', 'zinc') {
    $xp = if ($m -eq 'gold') { 2 } else { 1 }
    $rawItem = if ($m -eq 'zinc') { 'bearing:raw_zinc' } else { "minecraft:raw_$m" }
    $rawBlock = if ($m -eq 'zinc') { 'bearing:raw_zinc_block' } else { "minecraft:raw_${m}_block" }
    $xpStr = if ($xp -eq 1) { '' } else { "*$xp" }
    P crushing "raw_$m" @($rawItem) @("bearing:crushed_raw_$m", "bearing:experience_nugget$xpStr@0.75") $t400
    P crushing "raw_${m}_block" @($rawBlock) @("bearing:crushed_raw_$m*9", "bearing:experience_nugget*$(9 * $xp)@0.75") $t400
}
$stoneOres = [ordered]@{
    asurine = @('bearing:crushed_raw_zinc@0.3', 'bearing:zinc_nugget@0.3'); crimsite = @('bearing:crushed_raw_iron@0.4', 'minecraft:iron_nugget@0.4')
    ochrum = @('bearing:crushed_raw_gold@0.2', 'minecraft:gold_nugget@0.2'); veridium = @('bearing:crushed_raw_copper@0.8', 'bearing:copper_nugget@0.8')
}
foreach ($k in $stoneOres.Keys) {
    P crushing $k @("bearing:$k") $stoneOres[$k] $t250
    P crushing "${k}_recycling" @("#bearing:stone_types/$k") $stoneOres[$k] $t250
}
$tuffOut = @('minecraft:flint@0.25', 'minecraft:gold_nugget@0.1', 'bearing:copper_nugget@0.1', 'bearing:zinc_nugget@0.1', 'minecraft:iron_nugget@0.1')
P crushing tuff @('minecraft:tuff') $tuffOut $t350
P crushing tuff_recycling @('#bearing:stone_types/tuff') $tuffOut $t350
P crushing netherrack @('minecraft:netherrack') @('bearing:cinder_flour', 'bearing:cinder_flour@0.5') $t250
P crushing obsidian @('minecraft:obsidian') @('bearing:powdered_obsidian', 'minecraft:obsidian@0.75') @{ processing_time = 500 }
P milling wheat @('minecraft:wheat') @('bearing:wheat_flour', 'bearing:wheat_flour*2@0.25', 'minecraft:wheat_seeds@0.25') @{ processing_time = 150 }
P mixing andesite_alloy @('minecraft:andesite', '#c:nuggets/iron') @('bearing:andesite_alloy')
P mixing andesite_alloy_from_zinc @('minecraft:andesite', '#c:nuggets/zinc') @('bearing:andesite_alloy')
P mixing brass_ingot @('#c:ingots/copper', '#c:ingots/zinc') @('bearing:brass_ingot*2') @{ heat_requirement = 'heated' }
P mixing cardboard_pulp @('#bearing:pulpifiable', '#bearing:pulpifiable', '#bearing:pulpifiable', '#bearing:pulpifiable', 'F:minecraft:water*250') @('bearing:pulp')
P mixing chocolate_melting @('bearing:bar_of_chocolate') @('F:bearing:chocolate*250') @{ heat_requirement = 'heated' }
P mixing dough_by_mixing @('#c:flours/wheat', 'F:minecraft:water*1000') @('bearing:dough')
P compacting blaze_cake @('#c:eggs', 'minecraft:sugar', 'bearing:cinder_flour') @('bearing:blaze_cake_base')
P compacting chocolate @('F:bearing:chocolate*250') @('bearing:bar_of_chocolate')
P pressing brass_ingot @('#c:ingots/brass') @('bearing:brass_sheet')
P pressing copper_ingot @('#c:ingots/copper') @('bearing:copper_sheet')
P pressing gold_ingot @('#c:ingots/gold') @('bearing:golden_sheet')
P pressing iron_ingot @('#c:ingots/iron') @('bearing:iron_sheet')
P pressing cardboard @('bearing:pulp') @('bearing:cardboard')
P sandpaper_polishing rose_quartz @('bearing:rose_quartz') @('bearing:polished_rose_quartz')
P splashing crushed_raw_copper @('bearing:crushed_raw_copper') @('bearing:copper_nugget*9', 'minecraft:clay_ball@0.5')
P splashing crushed_raw_gold @('bearing:crushed_raw_gold') @('minecraft:gold_nugget*9', 'minecraft:quartz@0.5')
P splashing crushed_raw_iron @('bearing:crushed_raw_iron') @('minecraft:iron_nugget*9', 'minecraft:redstone@0.75')
P splashing crushed_raw_zinc @('bearing:crushed_raw_zinc') @('bearing:zinc_nugget*9', 'minecraft:gunpowder@0.25')
P splashing industrial_iron_block @('bearing:industrial_iron_block') @('bearing:weathered_iron_block')
P splashing wheat_flour @('#c:flours/wheat') @('bearing:dough')
P filling blaze_cake @('bearing:blaze_cake_base', 'F:minecraft:lava*250') @('bearing:blaze_cake')
P filling builders_tea @('minecraft:glass_bottle', 'F:bearing:tea*250') @('bearing:builders_tea')
P filling chocolate_glazed_berries @('minecraft:sweet_berries', 'F:bearing:chocolate*250') @('bearing:chocolate_glazed_berries')
P filling honeyed_apple @('minecraft:apple', 'FT:c:honey*250') @('bearing:honeyed_apple')
P filling sweet_roll @('minecraft:bread', 'FT:c:milk*250') @('bearing:sweet_roll')
# Potion fluid fillings of cinder flour (night vision -> glowstone, harming -> gunpowder, strength -> redstone)
foreach ($pf in @(@('glowstone', 'minecraft:night_vision', 'minecraft:glowstone_dust'), @('gunpowder', 'minecraft:harming', 'minecraft:gunpowder'), @('redstone', 'minecraft:strength', 'minecraft:redstone'))) {
    $doc = O type 'bearing:filling' ingredients @((O item 'bearing:cinder_flour'), (O fluid 'bearing:potion' amount 25 potion $pf[1] bottle 'regular')) results @((O id $pf[2]))
    if (-not $ownedElsewhere.Contains("filling/$($pf[0])")) { Save-Json "assets/recipes/filling/$($pf[0]).json" $doc }
}
P emptying builders_tea @('bearing:builders_tea') @('minecraft:glass_bottle', 'F:bearing:tea*250')
# item_application/bound_cardboard_inworld ships with U15 (assembly), which owns Create's manual application recipes.

# sequenced assembly: precision mechanism (5 loops) and sturdy sheet
$deploy = { param($with) O type 'bearing:deploying' ingredients @((O item 'bearing:incomplete_precision_mechanism'), (PIng $with)) results @((O id 'bearing:incomplete_precision_mechanism')) }
Save-Json 'assets/recipes/sequenced_assembly/precision_mechanism.json' (O type 'bearing:sequenced_assembly' ingredient (O tag 'c:plates/gold') loops 5 `
        results @((O id 'bearing:precision_mechanism' chance 120.0), (O id 'bearing:golden_sheet' chance 8.0), (O id 'bearing:andesite_alloy' chance 8.0), (O id 'bearing:cogwheel' chance 5.0), (O id 'minecraft:gold_nugget' chance 3.0), (O id 'bearing:shaft' chance 2.0), (O id 'bearing:crushed_raw_gold' chance 2.0), (O id 'minecraft:iron_ingot'), (O id 'minecraft:clock')) `
        sequence @((& $deploy 'bearing:cogwheel'), (& $deploy 'bearing:large_cogwheel'), (& $deploy '#c:nuggets/iron')) `
        transitional_item (O id 'bearing:incomplete_precision_mechanism'))
Save-Json 'assets/recipes/sequenced_assembly/sturdy_sheet.json' (O type 'bearing:sequenced_assembly' ingredient (O tag 'c:dusts/obsidian') results @((O id 'bearing:sturdy_sheet')) `
        sequence @((O type 'bearing:filling' ingredients @((O item 'bearing:unprocessed_obsidian_sheet'), (O fluid 'minecraft:lava' amount 500)) results @((O id 'bearing:unprocessed_obsidian_sheet'))),
        (O type 'bearing:pressing' ingredients @((O item 'bearing:unprocessed_obsidian_sheet')) results @((O id 'bearing:unprocessed_obsidian_sheet'))),
        (O type 'bearing:pressing' ingredients @((O item 'bearing:unprocessed_obsidian_sheet')) results @((O id 'bearing:unprocessed_obsidian_sheet')))) `
        transitional_item (O id 'bearing:unprocessed_obsidian_sheet'))

# tags for the loader (Create's c: / create: tags of the materials)
$tags = [ordered]@{
    'c:nuggets/zinc' = @('bearing:zinc_nugget'); 'c:nuggets/brass' = @('bearing:brass_nugget'); 'c:nuggets/copper' = @('bearing:copper_nugget')
    'c:ingots/zinc' = @('bearing:zinc_ingot'); 'c:ingots/brass' = @('bearing:brass_ingot')
    'c:storage_blocks/zinc' = @('bearing:zinc_block'); 'c:storage_blocks/brass' = @('bearing:brass_block'); 'c:storage_blocks/raw_zinc' = @('bearing:raw_zinc_block')
    'c:storage_blocks/raw_iron' = @('minecraft:raw_iron_block'); 'c:storage_blocks/raw_gold' = @('minecraft:raw_gold_block'); 'c:storage_blocks/raw_copper' = @('minecraft:raw_copper_block')
    'c:raw_materials/zinc' = @('bearing:raw_zinc'); 'c:raw_materials/iron' = @('minecraft:raw_iron'); 'c:raw_materials/gold' = @('minecraft:raw_gold'); 'c:raw_materials/copper' = @('minecraft:raw_copper')
    'c:ores/zinc' = @('bearing:zinc_ore', 'bearing:deepslate_zinc_ore')
    'c:plates/iron' = @('bearing:iron_sheet'); 'c:plates/gold' = @('bearing:golden_sheet'); 'c:plates/copper' = @('bearing:copper_sheet'); 'c:plates/brass' = @('bearing:brass_sheet'); 'c:plates/obsidian' = @('bearing:sturdy_sheet')
    'bearing:plates' = @('bearing:iron_sheet', 'bearing:golden_sheet', 'bearing:copper_sheet', 'bearing:brass_sheet', 'bearing:sturdy_sheet', 'bearing:cardboard')
    'c:dusts/obsidian' = @('bearing:powdered_obsidian'); 'c:flours/wheat' = @('bearing:wheat_flour'); 'bearing:flours' = @('bearing:wheat_flour')
    'c:eggs' = @('minecraft:egg'); 'c:strings' = @('minecraft:string'); 'c:gems/quartz' = @('minecraft:quartz'); 'c:dusts/redstone' = @('minecraft:redstone')
    'bearing:crushed_raw_materials' = @('bearing:crushed_raw_iron', 'bearing:crushed_raw_gold', 'bearing:crushed_raw_copper', 'bearing:crushed_raw_zinc')
    'bearing:create_ingots' = @('bearing:andesite_alloy', 'bearing:zinc_ingot', 'bearing:brass_ingot')
    'bearing:pulpifiable' = @('minecraft:bamboo', 'minecraft:sugar_cane', 'minecraft:oak_sapling', 'minecraft:spruce_sapling', 'minecraft:birch_sapling', 'minecraft:jungle_sapling', 'minecraft:acacia_sapling', 'minecraft:dark_oak_sapling', 'minecraft:cherry_sapling', 'minecraft:mangrove_propagule', 'minecraft:pale_oak_sapling')
    'bearing:upright_on_belt' = @('bearing:blaze_cake_base', 'bearing:blaze_cake', 'bearing:creative_blaze_cake', 'bearing:builders_tea')
}
foreach ($n in $stoneTypes.Keys) { $tags["bearing:stone_types/$n"] = @($stoneTypes[$n]) }
Save-Json 'assets/recipes/tags/materials.json' $tags

# ---- RP fragments and the C++ table ---------------------------------------------------------------
Save-Json 'assets/pack/rp/item_texture.d/materials.json' $itemTextures
Save-Json 'assets/pack/rp/terrain_texture.d/materials.json' $terrainTextures
Save-Json 'assets/pack/rp/blocks.d/materials.json' $blockSounds
Save-Text 'assets/pack/rp/texts.d/en_US/materials.lang' (($enLang -join "`n") + "`n")
Save-Text 'assets/pack/rp/texts.d/zh_CN/materials.lang' (($zhLang -join "`n") + "`n")
Save-Text 'src/feature/materials/MaterialsBlocks.inc' ("// Generated by tools/gen/materials.ps1 - do not edit.`n// BR_MATERIALS_BLOCK(id, tool, tier, shape, drop)`n" + ($cppBlocks -join "`n") + "`n")

$script:files.Sort()
[IO.File]::WriteAllText($manifest, (($script:files -join "`n") + "`n"), $utf8)
Write-Host "materials: $($items.Count) items, $($cppBlocks.Count) blocks, $($script:files.Count) files"
