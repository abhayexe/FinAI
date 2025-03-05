# Live Chat Feature Setup Guide

This guide will help you set up the live chat feature in your Finance AI App using Supabase as the backend.

## Prerequisites

1. You should already have a Supabase project set up for your Finance AI App
2. Make sure your `.env` file contains the Supabase URL and anon key:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

## Setting Up Supabase Tables

1. Go to your Supabase project dashboard
2. Navigate to the SQL Editor
3. Create a new query
4. **Quick Fix (Recommended)**: Run the `fix_chat_issues.sql` script to automatically set up all required tables and fix common issues:
   ```sql
   -- This will create all necessary tables and fix common issues
   ```
5. Alternatively, you can run the individual scripts:
   - First, run the `profiles_schema.sql` script to create the profiles table:
     ```sql
     -- This creates the profiles table which is required for user information
     ```
   - Then, run the `chat_schema.sql` script to create the chat tables:
     ```sql
     -- This creates chat_rooms, chat_messages, and chat_room_members tables
     ```

## Understanding the Database Schema

The chat feature uses the following tables:

1. **profiles** - User profiles (may already exist in your app)
2. **chat_rooms** - List of chat rooms
3. **chat_messages** - Messages sent in chat rooms
4. **chat_room_members** - (Optional) For future implementation of private rooms

### 1. Table Schema

1. `profiles` - Stores user profile information
   - `id` - UUID of the user (from auth.users)
   - `full_name` - Display name of the user
   - `updated_at` - Last update timestamp
   - `created_at` - Creation timestamp

2. `chat_rooms` - Stores information about chat rooms
   - `id` - UUID of the chat room
   - `name` - Name of the chat room
   - `created_by` - UUID of the user who created the room (references profiles.id)
   - `created_at` - Creation timestamp
   - `updated_at` - Last update timestamp

3. `chat_messages` - Stores messages sent in chat rooms
   - `id` - UUID of the message
   - `room_id` - UUID of the chat room (references chat_rooms.id)
   - `user_id` - UUID of the user who sent the message (references profiles.id)
   - `content` - Content of the message
   - `created_at` - Creation timestamp

4. `chat_room_members` - Stores membership information for chat rooms (for future use)
   - `id` - UUID of the membership
   - `room_id` - UUID of the chat room (references chat_rooms.id)
   - `user_id` - UUID of the user (references profiles.id)
   - `created_at` - Creation timestamp

### 2. Troubleshooting Database Issues
If you encounter errors like "foreign key constraint violation" when creating chat rooms, it means the user doesn't have a profile. Run the `fix_chat_issues.sql` script to create profiles for all existing users.

## Security

The SQL schema includes Row Level Security (RLS) policies that:

1. Allow anyone to view chat rooms and messages
2. Only allow authenticated users to create chat rooms and send messages
3. Only allow users to update or delete their own messages

## How to Use the Chat Feature

### Creating a Chat Room
1. Navigate to the Chat Rooms screen from the Home screen
2. Tap the "+" button to create a new chat room
3. Enter a name for the chat room and tap "Create"

### Joining a Chat Room
1. On the Chat Rooms screen, you'll see a list of all available chat rooms
2. Tap on any chat room to join it and start chatting

### Chatting with Friends
1. Both you and your friend need to have accounts in the app
2. Create a chat room with a unique name that your friend can recognize
3. Tell your friend the name of the chat room you created
4. Your friend can then find and join that chat room from their app

### Sending Messages
1. In a chat room, type your message in the text field at the bottom
2. Tap the send button to send your message
3. Your message will appear in the chat with your name and profile picture

### Deleting Messages
- You can only delete your own messages
- Long-press on your message and select "Delete" from the menu

## Troubleshooting

If you encounter any issues:

1. Make sure your Supabase project is properly set up
2. Check that the SQL schema was executed successfully
3. Verify that your app is correctly authenticated with Supabase
4. Check the Flutter console for any error messages

### Common Issues
1. **Error creating chat room**: Make sure you have a profile in the `profiles` table. The app should create this automatically, but if you're having issues, try signing out and signing back in.

2. **Can't see messages**: Ensure you have a stable internet connection for real-time updates.

3. **Profile not showing**: If your name shows as "Unknown", go to the profile settings to update your display name.

## Future Enhancements

Some potential enhancements you might want to add:

1. Private chat rooms
2. Direct messaging between users
3. Message reactions and replies
4. Media sharing capabilities
5. Online status indicators
- Private chat rooms with invitations
- Direct messaging between users
- Message reactions and attachments
- User online status indicators
