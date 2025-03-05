-- Create profiles table if it doesn't exist (may already exist in your app)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
  full_name TEXT,
  updated_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create chat rooms table
CREATE TABLE chat_rooms (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;

-- Create chat messages table
CREATE TABLE chat_messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Optional: Create chat room members table (for private rooms in the future)
CREATE TABLE chat_room_members (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(room_id, user_id)
);

-- Enable Row Level Security
ALTER TABLE chat_room_members ENABLE ROW LEVEL SECURITY;

-- Create policies for chat_rooms
-- Anyone can view chat rooms
CREATE POLICY "Anyone can view chat rooms"
  ON chat_rooms FOR SELECT
  USING (true);

-- Only authenticated users can create chat rooms
CREATE POLICY "Authenticated users can create chat rooms"
  ON chat_rooms FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Only the creator can update their chat room
CREATE POLICY "Users can update their own chat rooms"
  ON chat_rooms FOR UPDATE
  TO authenticated
  USING (auth.uid() = created_by);

-- Create policies for chat_messages
-- Anyone can view messages
CREATE POLICY "Anyone can view chat messages"
  ON chat_messages FOR SELECT
  USING (true);

-- Only authenticated users can insert messages
CREATE POLICY "Authenticated users can insert messages"
  ON chat_messages FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Only the message author can update or delete their messages
CREATE POLICY "Users can update their own messages"
  ON chat_messages FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own messages"
  ON chat_messages FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Create policies for chat_room_members
-- Anyone can view room members
CREATE POLICY "Anyone can view room members"
  ON chat_room_members FOR SELECT
  USING (true);

-- Only authenticated users can join rooms
CREATE POLICY "Authenticated users can join rooms"
  ON chat_room_members FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Create function to update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for chat_rooms
CREATE TRIGGER update_chat_rooms_updated_at
BEFORE UPDATE ON chat_rooms
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Create realtime publication for chat messages
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime;
COMMIT;

-- Add tables to the publication
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_rooms;
