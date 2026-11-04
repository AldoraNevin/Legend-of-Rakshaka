# Coastal chambers and physical map

`coastal_graph.gd` describes topology only: 6–8 required rooms from entrance to
exit, and two optional treasure branches. No room grid coordinates live in the
graph. `coastal_profiles.gd` defines five authored chamber profiles (long low hall,
tall cave, and stepped-ceiling alcoves). The seeded generator assigns profiles,
widths, heights and elevations, then connects chambers with enclosed stair
corridors. The old three-row rectangular grid is no longer used.

All physical space is built from a union of 16px-aligned air regions. Only the
exposed boundary becomes solid collision geometry; shared openings have no
walls. Solid corridor stairs rise/fall 32px per tread, with 128px overhead
clearance. Each branch is a separate upper chamber connected by a real shaft.
One-way steps support ascent, while clear strips beside the steps allow return
without a teleport or movement upgrade. Two optional chests each grant 5 coins.

M opens the physical level map and pauses gameplay. M/Escape closes it. Its
blue air regions come directly from the layout; walls, floors and platforms
come from actual instantiated collision shapes. Player, entrance, exit and both
chests are shown at their real positions. The graph is never rendered as a map.

Validation checks 200 deterministic seeds, chamber separation, connected air,
main-route support, missing steps and broken graph/shell rejection. The physics
suite walks continuously from spawn to exit over 12 seeds with speed 100,
jump velocity 300 and gravity 1000. A second suite climbs both optional branches
and returns through each shaft. Reward, map input/pause lifecycle, stage seed
propagation and exit transitions have separate regression tests.

Run tests with Godot `--headless --fixed-fps 60 --path . --log-file <writable-path>
--script Tests/<test>.gd`. `test_coastal_interior_physics.gd` and
`test_coastal_currents.gd` remain compatibility entry points for the new physical
branch-return tests; the layout no longer uses teleport currents. Run
`test_coastal_map.gd` without `--headless` and append `-- --capture` to render
`Docs/coastal-map-preview.png`.
