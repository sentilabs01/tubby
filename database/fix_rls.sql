-- Fix RLS policies for OAuth integration
-- This file contains SQL commands to fix Row Level Security issues

-- Drop existing policies that might be too restrictive
DROP POLICY IF EXISTS "Users can view their own data" ON users;
DROP POLICY IF EXISTS "Users can update their own data" ON users;
DROP POLICY IF EXISTS "Users can insert their own data" ON users;

-- Create more permissive policies for OAuth integration
CREATE POLICY "Users can view their own data" ON users
    FOR SELECT USING (auth.uid()::text = supabase_id::text);

CREATE POLICY "Users can update their own data" ON users
    FOR UPDATE USING (auth.uid()::text = supabase_id::text);

CREATE POLICY "Users can insert their own data" ON users
    FOR INSERT WITH CHECK (auth.uid()::text = supabase_id::text);

-- Add a policy to allow service role to manage users (for backend operations)
CREATE POLICY "Service role can manage users" ON users
    FOR ALL USING (auth.role() = 'service_role');

-- Grant necessary permissions to the anon role for OAuth
GRANT USAGE ON SCHEMA public TO anon;
GRANT ALL ON users TO anon;
GRANT ALL ON api_keys TO anon;
GRANT ALL ON user_preferences TO anon;
GRANT ALL ON uploaded_files TO anon;
GRANT ALL ON collaborative_sessions TO anon;

-- Enable RLS on all tables (if not already enabled)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE uploaded_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE collaborative_sessions ENABLE ROW LEVEL SECURITY; 