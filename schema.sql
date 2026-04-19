
-- ============================================================
-- Expense Tracker Schema
-- Run this in Neon SQL Editor
-- ============================================================

-- Roommates table
CREATE TABLE IF NOT EXISTS roommates (
  id SERIAL PRIMARY KEY,
  roommate TEXT NOT NULL UNIQUE,
  email TEXT
);

-- Expenses table
CREATE TABLE IF NOT EXISTS expenses (
  id SERIAL PRIMARY KEY,
  item TEXT NOT NULL,
  description TEXT NOT NULL,
  price NUMERIC(10,2) NOT NULL CHECK (price > 0),
  paid_by TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'other'
    CHECK (category IN ('food', 'utilities', 'taxes', 'household', 'other')),
  is_settled BOOLEAN NOT NULL DEFAULT FALSE,
  quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  is_personal BOOLEAN NOT NULL DEFAULT FALSE,
  store TEXT,
  total NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (total >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Repayment records
CREATE TABLE IF NOT EXISTS settlements (
  id SERIAL PRIMARY KEY,
  from_user TEXT NOT NULL,
  to_user TEXT NOT NULL,
  amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Monthly summary table
CREATE TABLE IF NOT EXISTS month_summary (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL DEFAULT 'unspecified',
  month DATE NOT NULL UNIQUE,
  spending NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (spending >= 0),
  personal NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (personal >= 0),
  total NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (total >= 0)
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_expenses_created ON expenses(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);
CREATE INDEX IF NOT EXISTS idx_expenses_store ON expenses(store);
CREATE INDEX IF NOT EXISTS idx_month_summary_month ON month_summary(month);
CREATE INDEX IF NOT EXISTS idx_month_summary_name ON month_summary(name);

-- ============================================================
-- Roommate Name Matching Function
-- ============================================================
-- Finds the best matching roommate by name similarity
-- Prioritizes: exact match (case-insensitive) → closest match by edit distance

CREATE OR REPLACE FUNCTION find_best_roommate(input_name TEXT)
RETURNS TABLE(id INTEGER, matched_name TEXT, confidence NUMERIC) AS $$
BEGIN
  RETURN QUERY
  WITH scored_roommates AS (
    SELECT
      r.id,
      r.roommate,
      -- Case-insensitive exact match = highest confidence (100%)
      CASE 
        WHEN LOWER(TRIM(r.roommate)) = LOWER(TRIM(input_name)) THEN 100
        -- Else: Levenshtein distance-based match (higher = better match, capped at 90%)
        ELSE GREATEST(0, 90 - (levenshtein(LOWER(TRIM(r.roommate)), LOWER(TRIM(input_name))) * 10))
      END AS confidence_score
    FROM roommates r
    WHERE r.roommate IS NOT NULL
  )
  SELECT 
    scored_roommates.id,
    scored_roommates.roommate AS matched_name,
    (scored_roommates.confidence_score)::NUMERIC AS confidence
  FROM scored_roommates
  WHERE confidence_score > 40  -- Only return matches with >40% confidence
  ORDER BY confidence_score DESC, matched_name ASC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Helper: Get best roommate name
-- ============================================================
-- Simpler function that returns just the matched roommate name

CREATE OR REPLACE FUNCTION get_best_roommate_name(input_name TEXT)
RETURNS TEXT AS $$
DECLARE
  matched_name TEXT;
BEGIN
  SELECT m.matched_name INTO matched_name
  FROM find_best_roommate(input_name) m;
  
  RETURN COALESCE(matched_name, input_name);
END;
$$ LANGUAGE plpgsql;
