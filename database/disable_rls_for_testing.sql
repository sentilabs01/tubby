-- Temporarily disable RLS for testing OAuth integration
-- WARNING: This is for development/testing only!

-- Disable RLS on all tables
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences DISABLE ROW LEVEL SECURITY;
ALTER TABLE uploaded_files DISABLE ROW LEVEL SECURITY;
ALTER TABLE collaborative_sessions DISABLE ROW LEVEL SECURITY;

-- Grant all permissions to anon role
GRANT ALL ON users TO anon;
GRANT ALL ON api_keys TO anon;
GRANT ALL ON user_preferences TO anon;
GRANT ALL ON uploaded_files TO anon;
GRANT ALL ON collaborative_sessions TO anon;

-- Verify RLS is disabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND tablename IN ('users', 'api_keys', 'user_preferences');

-- To re-enable RLS later, run:
-- ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY; 