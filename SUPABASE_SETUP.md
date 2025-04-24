# Supabase Setup for Kotha Vada App

This document provides instructions on how to set up your Supabase project for the Kotha Vada app.

## 1. Create a Supabase Project

1. Go to [Supabase](https://supabase.com/) and sign in with your dev.square organization account.
2. Click on "New Project" and select your organization.
3. Enter a name for your project (e.g., "kothavada").
4. Choose a database password (make sure to save it somewhere secure).
5. Choose a region closest to your users.
6. Click "Create new project" and wait for it to be created.

## 2. Set Up Database Tables

1. Once your project is created, go to the SQL Editor in the Supabase dashboard.
2. Copy the contents of the `supabase_tables_setup.sql` file provided in this project.
3. Paste the SQL into the SQL Editor and click "Run".
4. This will create all the necessary tables, policies, and functions for the app.

## 3. Configure Storage

1. Go to the Storage section in the Supabase dashboard.
2. You should see a bucket named "room_images" that was created by the SQL script.
3. If not, create a new bucket named "room_images" and make it public.

## 4. Configure Authentication

1. Go to the Authentication section in the Supabase dashboard.
2. Under "Settings" > "URL Configuration", add your app's URL to the "Site URL" field.
   - For development, you can use `http://localhost:3000`
   - For production, use your actual app URL
3. Enable Email/Password sign-in method if it's not already enabled.

## 5. Get API Keys

1. Go to the Settings section (gear icon) in the Supabase dashboard.
2. Click on "API" in the sidebar.
3. You'll find your "Project URL" and "anon/public" key.
4. Copy these values and create a `.env` file in the project root with the following content:

```
SUPABASE_URL=YOUR_SUPABASE_URL
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Replace `YOUR_SUPABASE_URL` with your Project URL and `YOUR_SUPABASE_ANON_KEY` with your anon/public key.

## 6. Test the Connection

1. Run your Flutter app to test the connection to Supabase.
2. Try to sign up a new user to verify that authentication is working.
3. Check the Supabase dashboard to confirm that the user was created in both the `auth.users` and `public.users` tables.

## Additional Configuration

### Row Level Security (RLS)

The SQL script has already set up Row Level Security policies for all tables. These policies ensure that:

- Users can only read, update, and delete their own data
- Anyone can view rooms
- Only authenticated users can create rooms
- Only room owners can update or delete their rooms
- Users can only see their own notifications

### Storage Rules

The "room_images" bucket is set to public, which means anyone can view the images. However, only authenticated users can upload images due to the RLS policies.

### Realtime

If you want to enable realtime updates for notifications or rooms, go to the Database section in the Supabase dashboard, click on "Replication" in the sidebar, and enable realtime for the specific tables you want to track.

## Troubleshooting

If you encounter any issues:

1. Check the Supabase logs in the dashboard.
2. Verify that your API keys are correct.
3. Make sure your RLS policies are properly configured.
4. Ensure that your app has internet permissions in the AndroidManifest.xml and Info.plist files.
