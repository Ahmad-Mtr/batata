
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
