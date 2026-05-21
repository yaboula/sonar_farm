-- ============================================================
-- Farm Sonar — Plot registry config (S5).
-- ============================================================
--
-- Anti-pattern §3 (no tunable values in production code):
-- every plot's identity, type, locale key, world anchor, radius
-- and *initial* soil score lives here, not in the service.
--
-- Loaded as a shared script so future client renderers (S6+) can
-- read the same anchor/radius without round-tripping the server.
-- All persistence remains server-only via `PlotService`
-- (Bible §9.2: server-authoritative).
--
-- The 8 plots below match the MLO ratio fixed by Bible §6.2 and
-- Roadmap S5: 4 extensive + 3 horticultural + 1 greenhouse.
--
-- Coordinate placeholders:
--   The values below are placeholder anchors near the
--   Grapeseed/Sandy Shores agricultural belt. The MLO project
--   will refine them in a follow-up integration pass; the
--   schema and service are coordinate-agnostic, so this is a
--   safe defer.
--
-- Seed semantics (ADR-010):
--   * `plot_id` is a stable natural key. Renaming a `plot_id`
--     creates a new row and orphans the previous one — never
--     rename, only deprecate.
--   * `initial_soil_score` is applied ONLY when the row is
--     first inserted. Reload never resets `soil_score` for an
--     existing plot.

Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Plots = Config.Farm.Plots or {}

-- Allowed plot type taxonomy. Validated server-side by
-- `PlotService` on every insert/update path.
Config.Farm.Plots.AllowedTypes = {
    extensive = true,
    horticultural = true,
    greenhouse = true,
}

-- Persistent soil score is a 0-100 integer (Bible §17).
Config.Farm.Plots.SoilScore = {
    Min = 0,
    Max = 100,
}

-- Initial lifecycle state assigned to every newly seeded plot.
-- S5 only ships `fallow`. Future slices (S6+) extend the state
-- machine; the column accepts any non-empty VARCHAR(32).
Config.Farm.Plots.InitialState = 'fallow'

-- Seeded MLO plots. Order does not matter: `plot_id` is the
-- identity key. Add/remove entries here and run
-- `/sonarfarm:plots:reload` to apply config-owned changes
-- without touching gameplay-owned fields.
Config.Farm.Plots.Seed = {
    -- ----- 4 extensive (cereal fields) -----
    {
        plot_id = 'mlo_field_extensive_01',
        plot_type = 'extensive',
        display_name_key = 'plots.field.extensive_01',
        coords_x = 1952.91,
        coords_y = 4770.65,
        coords_z = 42.76,
        heading = 313.68,
        radius = 1.5,
        initial_soil_score = 60,
    },
    {
        plot_id = 'mlo_field_extensive_02',
        plot_type = 'extensive',
        display_name_key = 'plots.field.extensive_02',
        coords_x = 2080.0,
        coords_y = 4790.0,
        coords_z = 41.0,
        radius = 28.0,
        initial_soil_score = 60,
    },
    {
        plot_id = 'mlo_field_extensive_03',
        plot_type = 'extensive',
        display_name_key = 'plots.field.extensive_03',
        coords_x = 2010.0,
        coords_y = 4860.0,
        coords_z = 41.0,
        radius = 28.0,
        initial_soil_score = 55,
    },
    {
        plot_id = 'mlo_field_extensive_04',
        plot_type = 'extensive',
        display_name_key = 'plots.field.extensive_04',
        coords_x = 2080.0,
        coords_y = 4860.0,
        coords_z = 41.0,
        radius = 28.0,
        initial_soil_score = 55,
    },

    -- ----- 3 horticultural (vegetables / leaves / bulbs / tubers) -----
    {
        plot_id = 'mlo_plot_horticultural_01',
        plot_type = 'horticultural',
        display_name_key = 'plots.plot.horticultural_01',
        coords_x = 1960.0,
        coords_y = 4920.0,
        coords_z = 41.0,
        radius = 10.0,
        initial_soil_score = 65,
    },
    {
        plot_id = 'mlo_plot_horticultural_02',
        plot_type = 'horticultural',
        display_name_key = 'plots.plot.horticultural_02',
        coords_x = 1980.0,
        coords_y = 4920.0,
        coords_z = 41.0,
        radius = 10.0,
        initial_soil_score = 65,
    },
    {
        plot_id = 'mlo_plot_horticultural_03',
        plot_type = 'horticultural',
        display_name_key = 'plots.plot.horticultural_03',
        coords_x = 2000.0,
        coords_y = 4920.0,
        coords_z = 41.0,
        radius = 10.0,
        initial_soil_score = 65,
    },

    -- ----- 1 greenhouse (industrial glass) -----
    {
        plot_id = 'mlo_greenhouse_01',
        plot_type = 'greenhouse',
        display_name_key = 'plots.greenhouse.01',
        coords_x = 1930.0,
        coords_y = 4960.0,
        coords_z = 41.0,
        radius = 12.0,
        initial_soil_score = 75,
    },
}
