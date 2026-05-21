-- ============================================================
-- Farm Sonar — Quality calculator specs (S8).
-- ============================================================
--
-- Plain Lua spec (no busted/luaunit). Run with:
--     lua sonar_farm_core/tests/server/quality_spec.lua
--
-- Validates the 7-factor weighted average, grade thresholds
-- (Bible §10 + Config.Farm.Quality.Grades), and the harvest-
-- timing penalty curve. Coverage matrix (6 cases) per B1 QA:
--
--   1. All-neutral factors → grade B (score in [60, 79]).
--   2. soil=100 + harvest_timing=100, rest neutral → A or S.
--   3. soil=0 + harvest_timing=0, rest neutral → C or D (score < 60).
--   4. Harvest-timing 1h late with decay 5/h → score 95 (< 100).
--   5. Weights sum check: with all factors = 70 and non-uniform
--      weights, weighted average MUST equal 70 (no off-by-one
--      in denominator).
--   6. Grade-from-score boundaries: 95→S, 94→A, 80→A, 79→B,
--      60→B, 59→C, 40→C, 39→D.
-- ============================================================

Config = {
    Farm = {
        Quality = {
            weights = {
                soil = 1.0,
                irrigation = 1.0,
                pest_impact = 1.0,
                weather_match = 1.0,
                seed_quality = 1.0,
                fertilization = 1.0,
                harvest_timing = 1.0,
            },
            NeutralDefaults = {
                irrigation = 70,
                pest_impact = 100,
                weather_match = 70,
                seed_quality = 70,
                fertilization = 70,
            },
            HarvestTimingDecayPerHour = 5,
            Grades = { S = 95, A = 80, B = 60, C = 40 },
        },
    },
}

Sonar = { Farm = {} }

local rows_by_plot = {
    neutral = {
        soil_score = 50,
        irrigation = 70,
        pest_impact = 100,
        weather_match = 70,
        seed_quality = 70,
        fertilization = 70,
        harvest_timing = 100,
    },
    optimal = {
        soil_score = 100,
        irrigation = 70,
        pest_impact = 100,
        weather_match = 70,
        seed_quality = 70,
        fertilization = 70,
        harvest_timing = 100,
    },
    worst = {
        soil_score = 0,
        irrigation = 70,
        pest_impact = 100,
        weather_match = 70,
        seed_quality = 70,
        fertilization = 70,
        harvest_timing = 0,
    },
    uniform_70 = {
        soil_score = 70,
        irrigation = 70,
        pest_impact = 70,
        weather_match = 70,
        seed_quality = 70,
        fertilization = 70,
        harvest_timing = 70,
    },
}

-- Boundary plots: every factor equals the target score so that
-- the weighted average (uniform weights) lands on that exact
-- score. Used by Case 6 to verify grade-from-score boundaries.
local boundary_scores = { 95, 94, 80, 79, 60, 59, 40, 39 }
for _, value in ipairs(boundary_scores) do
    rows_by_plot[('boundary_%d'):format(value)] = {
        soil_score = value,
        irrigation = value,
        pest_impact = value,
        weather_match = value,
        seed_quality = value,
        fertilization = value,
        harvest_timing = value,
    }
end

Sonar.Farm.DB = {
    row = function(query, params)
        local plot_id = params[1]
        local row = rows_by_plot[plot_id]
        if not row then
            return nil
        end

        if query:find('soil_score', 1, true) then
            return { soil_score = row.soil_score }
        end
        if query:find('irrigation', 1, true) then
            return { irrigation = row.irrigation }
        end
        if query:find('pest_impact', 1, true) then
            return { pest_impact = row.pest_impact }
        end
        if query:find('weather_match', 1, true) then
            return { weather_match = row.weather_match }
        end
        if query:find('seed_quality', 1, true) then
            return { seed_quality = row.seed_quality }
        end
        if query:find('fertilization', 1, true) then
            return { fertilization = row.fertilization }
        end
        if query:find('harvest_timing', 1, true) then
            return { harvest_timing = row.harvest_timing }
        end

        return nil
    end,
    execute = function()
        return true
    end,
}

dofile('sonar_farm_core/server/quality/factors/soil.lua')
dofile('sonar_farm_core/server/quality/factors/irrigation.lua')
dofile('sonar_farm_core/server/quality/factors/pest.lua')
dofile('sonar_farm_core/server/quality/factors/weather.lua')
dofile('sonar_farm_core/server/quality/factors/seed.lua')
dofile('sonar_farm_core/server/quality/factors/fertilization.lua')
dofile('sonar_farm_core/server/quality/factors/harvest_timing.lua')
dofile('sonar_farm_core/server/quality/calculator.lua')

local Quality = Sonar.Farm.Quality

-- ------------------------------------------------------------
-- Case 1: All-neutral factors → grade B.
-- soil=50, irrigation=70, pest=100, weather=70, seed=70, fert=70,
-- timing=100 → (50+70+100+70+70+70+100)/7 = 75.71 → 76 → B.
-- ------------------------------------------------------------
local neutral = Quality.Calculate('neutral')
assert(
    neutral.grade == 'B',
    ('expected neutral grade B, got %s (score %d)'):format(neutral.grade, neutral.score)
)
assert(
    neutral.score >= 60 and neutral.score <= 79,
    ('expected neutral score in [60,79], got %d'):format(neutral.score)
)

-- ------------------------------------------------------------
-- Case 2: soil=100 + harvest_timing=100, rest neutral → A or S.
-- (100+70+100+70+70+70+100)/7 = 82.86 → 83 → A.
-- ------------------------------------------------------------
local optimal = Quality.Calculate('optimal')
assert(
    optimal.grade == 'A' or optimal.grade == 'S',
    ('expected optimal grade A or S, got %s (score %d)'):format(optimal.grade, optimal.score)
)

-- ------------------------------------------------------------
-- Case 3: soil=0 + harvest_timing=0, rest neutral → C or D.
-- (0+70+100+70+70+70+0)/7 = 54.29 → 54 → C.
-- ------------------------------------------------------------
local worst = Quality.Calculate('worst')
assert(
    worst.grade == 'C' or worst.grade == 'D',
    ('expected worst grade C or D, got %s (score %d)'):format(worst.grade, worst.score)
)
assert(
    worst.score < 60,
    ('expected worst score < 60, got %d'):format(worst.score)
)

-- ------------------------------------------------------------
-- Case 4: Harvest-timing 1h late → score 95 (< 100, decay 5/h).
-- Also asserts the 2h-late case still lands at 90 (linear decay).
-- ------------------------------------------------------------
local one_hour_late = Quality.Factors.HarvestTiming:calculate(1000, 1000 + 3600)
assert(
    one_hour_late == 95,
    ('expected 1h-late timing score 95, got %s'):format(tostring(one_hour_late))
)
assert(one_hour_late < 100, 'late harvest must apply a penalty (score < 100)')

local two_hours_late = Quality.Factors.HarvestTiming:calculate(1000, 1000 + 7200)
assert(
    two_hours_late == 90,
    ('expected 2h-late timing score 90, got %s'):format(tostring(two_hours_late))
)

local on_time = Quality.Factors.HarvestTiming:calculate(1000, 1000)
assert(on_time == 100, 'on-time harvest must keep timing at 100')

-- ------------------------------------------------------------
-- Case 5: Weights sum check. With every factor = 70 and any
-- positive non-uniform weight set, the weighted average must
-- equal 70 (off-by-one in the denominator would shift it).
-- ------------------------------------------------------------
local original_weights = Config.Farm.Quality.weights
Config.Farm.Quality.weights = {
    soil = 2.0,
    irrigation = 1.0,
    pest_impact = 1.0,
    weather_match = 3.0,
    seed_quality = 1.0,
    fertilization = 1.0,
    harvest_timing = 1.0,
}
local uniform = Quality.Calculate('uniform_70')
assert(
    uniform.score == 70,
    ('weighted average of identical 70s must be 70, got %d (denominator off-by-one?)'):format(uniform.score)
)
Config.Farm.Quality.weights = original_weights

-- ------------------------------------------------------------
-- Case 6: Grade-from-score boundaries.
--   95→S, 94→A, 80→A, 79→B, 60→B, 59→C, 40→C, 39→D.
-- All factors at the boundary value → weighted avg = boundary
-- (uniform weights) → grade is the boundary's threshold bucket.
-- ------------------------------------------------------------
local expected_grades = {
    [95] = 'S',
    [94] = 'A',
    [80] = 'A',
    [79] = 'B',
    [60] = 'B',
    [59] = 'C',
    [40] = 'C',
    [39] = 'D',
}

for _, score_value in ipairs(boundary_scores) do
    local result = Quality.Calculate(('boundary_%d'):format(score_value))
    assert(
        result.score == score_value,
        ('boundary plot %d returned score %d (denominator drift?)'):format(score_value, result.score)
    )
    local expected = expected_grades[score_value]
    assert(
        result.grade == expected,
        ('boundary %d expected grade %s, got %s'):format(score_value, expected, result.grade)
    )
end

print('quality_spec.lua: OK (6 cases)')
