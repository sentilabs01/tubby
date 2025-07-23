-- Fix RLS policies to allow backend user creation
-- This script will update the RLS policies to allow the backend to create users

-- First, let's see what policies exist
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'users';

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can view their own data" ON users;
DROP POLICY IF EXISTS "Users can update their own data" ON users;
DROP POLICY IF EXISTS "Users can insert their own data" ON users;
DROP POLICY IF EXISTS "Service role can manage users" ON users;

-- Create more permissive policies for OAuth integration
-- Allow users to view their own data
CREATE POLICY "Users can view their own data" ON users
    FOR SELECT USING (
        auth.uid()::text = supabase_id::text OR 
        auth.role() = 'service_role'
    );

-- Allow users to insert their own data (for OAuth registration)
CREATE POLICY "Users can insert their own data" ON users
    FOR INSERT WITH CHECK (
        auth.uid()::text = supabase_id::text OR 
        auth.role() = 'service_role' OR
        auth.role() = 'anon'
    );

-- Allow users to update their own data
CREATE POLICY "Users can update their own data" ON users
    FOR UPDATE USING (
        auth.uid()::text = supabase_id::text OR 
        auth.role() = 'service_role'
    );

-- Allow service role to manage all users (for backend operations)
CREATE POLICY "Service role can manage users" ON users
    FOR ALL USING (auth.role() = 'service_role');

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon;
GRANT ALL ON users TO anon;
GRANT ALL ON api_keys TO anon;
GRANT ALL ON user_preferences TO anon;

-- Alternative: Temporarily disable RLS for testing (uncomment if needed)
-- ALTER TABLE users DISABLE ROW LEVEL SECURITY; 