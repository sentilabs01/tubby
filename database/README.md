# Database Setup Instructions

## Quick Setup

1. **Go to your Supabase Dashboard**
   - Navigate to: https://supabase.com/dashboard/project/ewrbezytnhuovvmkepeg
   - Click on "SQL Editor" in the left sidebar

2. **Run the Schema**
   - Copy the contents of `database/schema.sql`
   - Paste it into the SQL Editor
   - Click "Run" to execute

3. **Verify Tables Created**
   - Go to "Table Editor" in the left sidebar
   - You should see these tables:
     - `api_keys`
     - `user_preferences` 
     - `uploaded_files`
     - `collaborative_sessions`

## What the Schema Creates

### Core Tables

**`api_keys`** - Stores encrypted API keys
- `user_id`: User identifier
- `service`: Service name ('gemini', 'anthropic', 'openai')
- `encrypted_key`: AES-256 encrypted API key
- Unique constraint on (user_id, service)

**`user_preferences`** - User settings and preferences
- Theme, terminal font settings
- One record per user

**`uploaded_files`** - Tracks file uploads
- File metadata and storage paths
- Links to Supabase Storage

**`collaborative_sessions`** - MCP agent collaboration
- Session management for multi-agent workflows

### Security Features

- **Row Level Security (RLS)** enabled on all tables
- **Policies** ensure users can only access their own data
- **Indexes** for optimal query performance
- **Triggers** for automatic timestamp updates

## Testing the Setup

After running the schema, you can test the API key functionality:

1. Start your Flask backend
2. Open the web app
3. Click the settings gear icon
4. Try saving a test API key

## Troubleshooting

If you get RLS policy errors:
- The policies use `auth.uid()` which requires authentication
- For development, you can temporarily disable RLS:
  ```sql
  ALTER TABLE api_keys DISABLE ROW LEVEL SECURITY;
  ```

## Next Steps

Once the database is set up:
1. Test API key storage/retrieval
2. Implement file upload to Supabase Storage
3. Add authentication integration 