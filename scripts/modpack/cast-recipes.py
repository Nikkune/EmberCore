"""
Reads the casting recipes of a Minecraft instance (mod jars, then kubejs/data, then the castingTable() calls
of kubejs/server_scripts) and writes:
- src/projects/smeltery/shared/castRecipesData.ts: for each fluid, the cast formats it can be poured into
  and the mB of one casting;
- src/projects/smeltery/shared/craftRecipesData.ts: the castings onto an item (an apple and 720 mB of gold
  make a golden apple), for the craft table and basin.

- Item casting (tconstruct:casting_table / casting_basin): the format is the cast's (tag .../casts/<kind>/<format>
  or item <format>_cast); a basin with no cast is 'block'. Fluid tags are resolved with kubejs/exported/tags.
- Tool parts (tconstruct:table_casting_material): a fluid casts a part when a tconstruct:material_fluid recipe
  turns it into a material that has the part's stats; mB = item_cost x the fluid's amount per material unit.
- Conditions: forge:mod_loaded (mod ids of the jars), forge:tag_empty (exported item tags), not / and / or;
  any other condition counts as met.

Usage: python3 -I scripts/modpack/cast-recipes.py "<instance>/minecraft" [out.ts]
The jars are only read (zip), never extracted.
"""
import json
import os
import re
import sys
import zipfile

ROOT = sys.argv[1]
SHARED = os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../src/projects/smeltery/shared')
OUT = os.path.join(SHARED, 'castRecipesData.ts')
CRAFT_OUT = os.path.join(SHARED, 'craftRecipesData.ts')

# Stats a material needs for each tool part (Tinkers 3.7); a part not listed casts for every material.
PART_STATS = {
    'pick_head': 'head', 'small_axe_head': 'head', 'small_blade': 'head', 'hammer_head': 'head',
    'broad_blade': 'head', 'broad_axe_head': 'head', 'large_plate': 'head', 'great_blade': 'head',
    'large_round_plate': 'head', 'slender_blade': 'head', 'wrench_head': 'head',
    'tool_binding': 'extra', 'round_plate': 'extra',
    'tool_handle': 'handle', 'tough_handle': 'handle',
    'bow_limb': 'limb', 'bow_grip': 'grip',
}


def read_tags(path):
    """kubejs/exported/tags/<kind>.txt: '#tag' then '- entry' lines (an entry may be another #tag)."""
    tags, current = {}, None
    if not os.path.exists(path):
        return tags
    for line in open(path, encoding='utf-8', errors='replace'):
        line = line.rstrip('\n')
        if line.startswith('#'):
            current = line[1:].strip()
            tags.setdefault(current, [])
        elif line.startswith('- ') and current is not None:
            tags[current].append(line[2:].strip())
    return tags


def resolve(tags, tag, seen=None):
    seen = seen or set()
    if tag in seen:
        return set()
    seen.add(tag)
    out = set()
    for entry in tags.get(tag, []):
        if entry.startswith('#'):
            out |= resolve(tags, entry[1:], seen)
        else:
            out.add(entry)
    return out


EXPORT = os.path.join(ROOT, 'kubejs/exported/tags')
FLUID_TAGS = read_tags(os.path.join(EXPORT, 'fluids.txt'))
ITEM_TAGS = read_tags(os.path.join(EXPORT, 'items.txt'))

# Every data file, by path: jars first, kubejs/data overrides them (as a datapack does).
files, mod_ids = {}, set()
mods = os.path.join(ROOT, 'mods')
for jar in sorted(os.listdir(mods)):
    if not jar.endswith('.jar'):
        continue
    try:
        archive = zipfile.ZipFile(os.path.join(mods, jar))
    except zipfile.BadZipFile:
        continue
    for name in archive.namelist():
        if name == 'META-INF/mods.toml':
            mod_ids |= set(re.findall(r'modId\s*=\s*"([^"]+)"', archive.read(name).decode('utf-8', 'replace')))
        if name.startswith('data/') and name.endswith('.json') and ('/recipes/' in name or '/tinkering/materials/stats/' in name):
            files[name] = (archive, name)
kubedata = os.path.join(ROOT, 'kubejs/data')
for folder, _, names in os.walk(kubedata):
    for name in names:
        if name.endswith('.json'):
            full = os.path.join(folder, name)
            files['data/' + os.path.relpath(full, kubedata).replace(os.sep, '/')] = (None, full)


def load(entry):
    archive, name = entry
    try:
        raw = archive.read(name) if archive is not None else open(name, 'rb').read()
        return json.loads(raw.decode('utf-8', 'replace'))
    except (ValueError, OSError):
        return None


def met(condition):
    kind = condition.get('type')
    if kind == 'forge:mod_loaded':
        return condition.get('modid') in mod_ids
    if kind == 'forge:not':
        return not met(condition.get('value', {}))
    if kind == 'forge:tag_empty':
        return len(resolve(ITEM_TAGS, condition.get('tag', ''))) == 0
    if kind == 'forge:and':
        return all(met(value) for value in condition.get('values', []))
    if kind == 'forge:or':
        return any(met(value) for value in condition.get('values', []))
    return True


def fluids_of(ingredient):
    """Fluid names and amount of a recipe's fluid ingredient ({name|tag, amount} or a list of them)."""
    if isinstance(ingredient, list):
        out = []
        for part in ingredient:
            out += fluids_of(part)
        return out
    if not isinstance(ingredient, dict):
        return []
    amount = ingredient.get('amount', 0)
    if 'name' in ingredient:
        return [(ingredient['name'], amount)]
    if 'tag' in ingredient:
        return [(name, amount) for name in resolve(FLUID_TAGS, ingredient['tag']) if 'flowing' not in name]
    return []


def format_of_cast(cast):
    if cast is None:
        return None
    if isinstance(cast, list):
        cast = cast[0] if cast else None
        if cast is None:
            return None
    tag, item = cast.get('tag'), cast.get('item')
    if tag and ':casts/' in tag or tag and '/casts/' in tag:
        return tag.rsplit('/', 1)[1]
    if item:
        name = item.split(':', 1)[1]
        for suffix in ('_red_sand_cast', '_sand_cast', '_cast'):
            if name.endswith(suffix):
                return name[:-len(suffix)]
    return None


casts = {}  # fluid -> {format: amount}
crafts = set()  # (caster kind, input item or #tag, fluid, amount, result item, cast consumed)


def item_of(result):
    """The item a recipe result names: an item, or the first item of a tag."""
    if isinstance(result, str):
        return result
    if isinstance(result, dict):
        if 'item' in result:
            return result['item']
        if 'tag' in result:
            items = sorted(resolve(ITEM_TAGS, result['tag']))
            return items[0] if items else None
    return None


def input_of(cast):
    """An item cast that is not a cast: 'minecraft:apple' or '#forge:dusts/glowstone'."""
    if isinstance(cast, list):
        cast = cast[0] if cast else None
    if not isinstance(cast, dict):
        return None
    if cast.get('item'):
        return cast['item']
    if cast.get('tag'):
        return '#' + cast['tag']
    return None


def add(fluid, fmt, amount):
    if amount <= 0:
        return
    known = casts.setdefault(fluid, {})
    known[fmt] = min(known.get(fmt, amount), amount)


material_fluids, parts, stats = [], [], {}
for path, entry in files.items():
    if '/tinkering/materials/stats/' in path:
        recipe = load(entry)
        if isinstance(recipe, dict):
            ns = path.split('/')[1]
            stats[ns + ':' + path.rsplit('/', 1)[1][:-5]] = set(key.split(':', 1)[1] for key in recipe.get('stats', {}))
        continue
    recipe = load(entry)
    if not isinstance(recipe, dict) or not all(met(c) for c in recipe.get('conditions', [])):
        continue
    kind = recipe.get('type')
    if kind in ('tconstruct:casting_table', 'tconstruct:casting_basin'):
        fmt = format_of_cast(recipe.get('cast'))
        if fmt is None and kind == 'tconstruct:casting_basin' and 'cast' not in recipe:
            fmt = 'block'
        if fmt is None:
            source, result = input_of(recipe.get('cast')), item_of(recipe.get('result'))
            if source is not None and result is not None:
                caster = 'table' if kind == 'tconstruct:casting_table' else 'basin'
                for fluid, amount in fluids_of(recipe.get('fluid')):
                    if amount > 0:
                        crafts.add((caster, source, fluid, amount, result, bool(recipe.get('cast_consumed', False))))
            continue
        for fluid, amount in fluids_of(recipe.get('fluid')):
            add(fluid, fmt, amount)
    elif kind == 'tconstruct:material_fluid':
        output = recipe.get('output')
        material = output if isinstance(output, str) else (output or {}).get('material')
        if material:
            material_fluids.append((material.split('#')[0], fluids_of(recipe.get('fluid'))))
    elif kind == 'tconstruct:table_casting_material':
        fmt = format_of_cast(recipe.get('cast'))
        if fmt is not None:
            parts.append((fmt, recipe.get('item_cost', 1)))

# KubeJS castingTable(cast, consumed, fluid, amount, output, cool) calls.
scripts = os.path.join(ROOT, 'kubejs/server_scripts')
call = re.compile(r"castingTable\(\s*['\"]([^'\"]+)['\"]\s*,\s*\w+\s*,\s*['\"]([^'\"]+)['\"]\s*,\s*(\d+)")
for folder, _, names in os.walk(scripts):
    for name in names:
        if name.endswith('.js'):
            text = open(os.path.join(folder, name), encoding='utf-8', errors='replace').read()
            for cast, fluid, amount in call.findall(text):
                add(fluid, cast.rsplit('/', 1)[1], int(amount))

for material, fluids in material_fluids:
    have = stats.get(material, set())
    for fmt, cost in set(parts):
        need = PART_STATS.get(fmt)
        if need is not None and need not in have:
            continue
        for fluid, amount in fluids:
            add(fluid, fmt, cost * amount)

lines = [
    '// Generated by scripts/modpack/cast-recipes.py from the Ragnamod VII instance: do not edit by hand.',
    '',
    '/**',
    ' * The casting recipes of the modpack: for each fluid, every cast format it can be poured into and the mB',
    " * of one casting ('ingot:90 nugget:10 ...'). A format not listed has no recipe for that fluid.",
    ' */',
    'export const CAST_RECIPES: Record<string, string> = {',
]
for fluid in sorted(casts):
    pairs = ' '.join(f'{fmt}:{amount}' for fmt, amount in sorted(casts[fluid].items()))
    lines.append(f"\t'{fluid}': '{pairs}',")
lines.append('};')
open(OUT, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
craft = [
    '// Generated by scripts/modpack/cast-recipes.py from the Ragnamod VII instance: do not edit by hand.',
    '',
    '/**',
    ' * Castings onto an item, for the craft table and basin: [caster, item or #tag on it, fluid, mB, result,',
    ' * whether the item is used up].',
    ' */',
    'export const CRAFT_RECIPES: [string, string, string, number, string, boolean][] = [',
]
for caster, source, fluid, amount, result, consumed in sorted(crafts):
    craft.append(f"\t['{caster}', '{source}', '{fluid}', {amount}, '{result}', {'true' if consumed else 'false'}],")
craft.append('];')
open(CRAFT_OUT, 'w', encoding='utf-8').write('\n'.join(craft) + '\n')
print(f'{len(crafts)} craft castings -> {CRAFT_OUT}')
print(f'{len(casts)} fluids, {sum(len(v) for v in casts.values())} casts, {len(material_fluids)} material fluids, '
      f'{len(set(parts))} parts, {len(mod_ids)} mods -> {OUT}')
