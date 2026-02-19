-- ============================================================
-- 30 Days Discipline — Supabase SQL Schema
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- ── Table: profiles ──────────────────────────────────────────
CREATE TABLE public.profiles (
  id                  uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  display_name        text,
  no_fap_last_reset   timestamptz,
  updated_at         timestamptz DEFAULT now()
);

-- ── Table: tasks ─────────────────────────────────────────────
CREATE TABLE public.tasks (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title       text NOT NULL,
  category    text NOT NULL CHECK (category IN ('Deen', 'Study', 'Health', 'Personal')),
  start_date  date NOT NULL,
  total_days  integer NOT NULL CHECK (total_days > 0),
  created_at  timestamptz DEFAULT now()
);

-- ── Table: task_logs ─────────────────────────────────────────
CREATE TABLE public.task_logs (
  id              uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id         uuid REFERENCES public.tasks(id) ON DELETE CASCADE NOT NULL,
  user_id         uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  completed_date  date NOT NULL,
  UNIQUE(task_id, completed_date)  -- Prevent duplicate completion for same day
);

-- ── Enable Row Level Security ────────────────────────────────
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_logs ENABLE ROW LEVEL SECURITY;

-- ── RLS Policies: profiles ───────────────────────────────────
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- ── RLS Policies: tasks ──────────────────────────────────────
-- Users can only SELECT their own tasks
CREATE POLICY "Users can view own tasks"
  ON public.tasks FOR SELECT
  USING (auth.uid() = user_id);

-- Users can only INSERT tasks for themselves
CREATE POLICY "Users can create own tasks"
  ON public.tasks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can only UPDATE their own tasks
CREATE POLICY "Users can update own tasks"
  ON public.tasks FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can only DELETE their own tasks
CREATE POLICY "Users can delete own tasks"
  ON public.tasks FOR DELETE
  USING (auth.uid() = user_id);

-- ── RLS Policies: task_logs ──────────────────────────────────
-- Users can only SELECT their own logs
CREATE POLICY "Users can view own task_logs"
  ON public.task_logs FOR SELECT
  USING (auth.uid() = user_id);

-- Users can only INSERT logs for themselves
CREATE POLICY "Users can create own task_logs"
  ON public.task_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can only DELETE their own logs
CREATE POLICY "Users can delete own task_logs"
  ON public.task_logs FOR DELETE
  USING (auth.uid() = user_id);

-- ── Indexes for Performance ──────────────────────────────────
CREATE INDEX idx_tasks_user_id ON public.tasks(user_id);
CREATE INDEX idx_task_logs_user_id ON public.task_logs(user_id);
CREATE INDEX idx_task_logs_task_id ON public.task_logs(task_id);
CREATE INDEX idx_task_logs_completed_date ON public.task_logs(completed_date);
CREATE INDEX idx_task_logs_composite ON public.task_logs(user_id, completed_date);
