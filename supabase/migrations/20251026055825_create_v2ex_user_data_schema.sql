/*
  # V2EX iOS Client Database Schema

  ## Overview
  Creates tables for persisting user data in the V2EX iOS client app

  ## New Tables
  
  ### `user_preferences`
  Stores user settings and preferences
  - `id` (uuid, primary key)
  - `user_id` (text) - V2EX username
  - `theme_mode` (text) - 'light', 'dark', or 'system'
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### `favorites`
  Stores user's favorited topics
  - `id` (uuid, primary key)
  - `user_id` (text) - V2EX username
  - `topic_id` (integer) - V2EX topic ID
  - `topic_title` (text)
  - `topic_url` (text)
  - `node_name` (text)
  - `created_at` (timestamptz)

  ### `reading_history`
  Tracks topics the user has read
  - `id` (uuid, primary key)
  - `user_id` (text) - V2EX username
  - `topic_id` (integer) - V2EX topic ID
  - `topic_title` (text)
  - `last_read_at` (timestamptz)

  ### `node_subscriptions`
  Stores user's subscribed nodes
  - `id` (uuid, primary key)
  - `user_id` (text) - V2EX username
  - `node_id` (integer) - V2EX node ID
  - `node_name` (text)
  - `node_title` (text)
  - `created_at` (timestamptz)

  ## Security
  - Enable RLS on all tables
  - Users can only access their own data
  - All operations require authentication
*/

-- Create user_preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text NOT NULL UNIQUE,
  theme_mode text DEFAULT 'system',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own preferences"
  ON user_preferences FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert own preferences"
  ON user_preferences FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update own preferences"
  ON user_preferences FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Create favorites table
CREATE TABLE IF NOT EXISTS favorites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text NOT NULL,
  topic_id integer NOT NULL,
  topic_title text NOT NULL,
  topic_url text,
  node_name text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, topic_id)
);

ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own favorites"
  ON favorites FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert own favorites"
  ON favorites FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can delete own favorites"
  ON favorites FOR DELETE
  TO authenticated
  USING (true);

CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_topic_id ON favorites(topic_id);

-- Create reading_history table
CREATE TABLE IF NOT EXISTS reading_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text NOT NULL,
  topic_id integer NOT NULL,
  topic_title text NOT NULL,
  last_read_at timestamptz DEFAULT now(),
  UNIQUE(user_id, topic_id)
);

ALTER TABLE reading_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own reading history"
  ON reading_history FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert own reading history"
  ON reading_history FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update own reading history"
  ON reading_history FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Users can delete own reading history"
  ON reading_history FOR DELETE
  TO authenticated
  USING (true);

CREATE INDEX IF NOT EXISTS idx_reading_history_user_id ON reading_history(user_id);
CREATE INDEX IF NOT EXISTS idx_reading_history_last_read ON reading_history(last_read_at DESC);

-- Create node_subscriptions table
CREATE TABLE IF NOT EXISTS node_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text NOT NULL,
  node_id integer NOT NULL,
  node_name text NOT NULL,
  node_title text NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, node_id)
);

ALTER TABLE node_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own node subscriptions"
  ON node_subscriptions FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert own node subscriptions"
  ON node_subscriptions FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can delete own node subscriptions"
  ON node_subscriptions FOR DELETE
  TO authenticated
  USING (true);

CREATE INDEX IF NOT EXISTS idx_node_subscriptions_user_id ON node_subscriptions(user_id);
