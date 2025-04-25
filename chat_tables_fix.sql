-- This script checks if the required tables exist and creates them if they don't
-- It also adds the tables to the realtime publication

-- Check if uuid-ossp extension is enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Check if conversations table exists and create it if it doesn't
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'conversations') THEN
        CREATE TABLE conversations (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user1_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            user2_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            last_message_content TEXT,
            last_message_time TIMESTAMP WITH TIME ZONE,
            has_unread_messages BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            CONSTRAINT different_users CHECK (user1_id <> user2_id)
        );
        
        RAISE NOTICE 'Created conversations table';
    ELSE
        RAISE NOTICE 'Conversations table already exists';
        
        -- Check if all required columns exist and add them if they don't
        IF NOT EXISTS (SELECT FROM information_schema.columns 
                      WHERE table_schema = 'public' AND table_name = 'conversations' 
                      AND column_name = 'last_message_content') THEN
            ALTER TABLE conversations ADD COLUMN last_message_content TEXT;
            RAISE NOTICE 'Added last_message_content column to conversations table';
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns 
                      WHERE table_schema = 'public' AND table_name = 'conversations' 
                      AND column_name = 'last_message_time') THEN
            ALTER TABLE conversations ADD COLUMN last_message_time TIMESTAMP WITH TIME ZONE;
            RAISE NOTICE 'Added last_message_time column to conversations table';
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns 
                      WHERE table_schema = 'public' AND table_name = 'conversations' 
                      AND column_name = 'has_unread_messages') THEN
            ALTER TABLE conversations ADD COLUMN has_unread_messages BOOLEAN DEFAULT FALSE;
            RAISE NOTICE 'Added has_unread_messages column to conversations table';
        END IF;
    END IF;
END
$$;

-- Check if messages table exists and create it if it doesn't
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'messages') THEN
        CREATE TABLE messages (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
            sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            content TEXT NOT NULL,
            is_read BOOLEAN DEFAULT FALSE,
            status TEXT DEFAULT 'sent',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE 'Created messages table';
    ELSE
        RAISE NOTICE 'Messages table already exists';
        
        -- Check if all required columns exist and add them if they don't
        IF NOT EXISTS (SELECT FROM information_schema.columns 
                      WHERE table_schema = 'public' AND table_name = 'messages' 
                      AND column_name = 'is_read') THEN
            ALTER TABLE messages ADD COLUMN is_read BOOLEAN DEFAULT FALSE;
            RAISE NOTICE 'Added is_read column to messages table';
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns 
                      WHERE table_schema = 'public' AND table_name = 'messages' 
                      AND column_name = 'status') THEN
            ALTER TABLE messages ADD COLUMN status TEXT DEFAULT 'sent';
            RAISE NOTICE 'Added status column to messages table';
        END IF;
    END IF;
END
$$;

-- Create RLS policies for conversations if they don't exist
DO $$
BEGIN
    -- Enable RLS on conversations table
    ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
    
    -- Check if policies exist and create them if they don't
    IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'conversations' AND policyname = 'Users can view their own conversations') THEN
        CREATE POLICY "Users can view their own conversations"
            ON conversations FOR SELECT
            USING (auth.uid() = user1_id OR auth.uid() = user2_id);
        RAISE NOTICE 'Created SELECT policy for conversations';
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'conversations' AND policyname = 'Users can create conversations they are part of') THEN
        CREATE POLICY "Users can create conversations they are part of"
            ON conversations FOR INSERT
            WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);
        RAISE NOTICE 'Created INSERT policy for conversations';
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'conversations' AND policyname = 'Users can update their own conversations') THEN
        CREATE POLICY "Users can update their own conversations"
            ON conversations FOR UPDATE
            USING (auth.uid() = user1_id OR auth.uid() = user2_id);
        RAISE NOTICE 'Created UPDATE policy for conversations';
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'conversations' AND policyname = 'Users can delete their own conversations') THEN
        CREATE POLICY "Users can delete their own conversations"
            ON conversations FOR DELETE
            USING (auth.uid() = user1_id OR auth.uid() = user2_id);
        RAISE NOTICE 'Created DELETE policy for conversations';
    END IF;
END
$$;

-- Create RLS policies for messages if they don't exist
DO $$
BEGIN
    -- Enable RLS on messages table
    ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
    
    -- Check if policies exist and create them if they don't
    IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'messages' AND policyname = 'Users can view messages in their conversations') THEN
        CREATE POLICY "Users can view messages in their conversations"
            ON messages FOR SELECT
            USING (
                auth.uid() IN (
                    SELECT user1_id FROM conversations WHERE id = conversation_id
                    UNION
                    SELECT user2_id FROM conversations WHERE id = conversation_id
                )
            );
        RAISE NOTICE 'Created SELECT policy for messages';
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'messages' AND policyname = 'Users can send messages in their conversations') THEN
        CREATE POLICY "Users can send messages in their conversations"
            ON messages FOR INSERT
            WITH CHECK (
                auth.uid() = sender_id AND
                auth.uid() IN (
                    SELECT user1_id FROM conversations WHERE id = conversation_id
                    UNION
                    SELECT user2_id FROM conversations WHERE id = conversation_id
                )
            );
        RAISE NOTICE 'Created INSERT policy for messages';
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'messages' AND policyname = 'Users can update their own messages') THEN
        CREATE POLICY "Users can update their own messages"
            ON messages FOR UPDATE
            USING (auth.uid() = sender_id);
        RAISE NOTICE 'Created UPDATE policy for messages';
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'messages' AND policyname = 'Users can delete their own messages') THEN
        CREATE POLICY "Users can delete their own messages"
            ON messages FOR DELETE
            USING (auth.uid() = sender_id);
        RAISE NOTICE 'Created DELETE policy for messages';
    END IF;
END
$$;

-- Create or replace function to update conversation timestamp
CREATE OR REPLACE FUNCTION update_conversation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversations
    SET updated_at = NOW(),
        last_message_content = NEW.content,
        last_message_time = NEW.created_at,
        has_unread_messages = TRUE
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update conversation timestamp if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_trigger WHERE tgname = 'update_conversation_timestamp_trigger') THEN
        CREATE TRIGGER update_conversation_timestamp_trigger
        AFTER INSERT ON messages
        FOR EACH ROW
        EXECUTE FUNCTION update_conversation_timestamp();
        
        RAISE NOTICE 'Created update_conversation_timestamp trigger';
    ELSE
        RAISE NOTICE 'update_conversation_timestamp trigger already exists';
    END IF;
END
$$;

-- Create or replace function to mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_as_read()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_read = TRUE AND OLD.is_read = FALSE THEN
        -- Check if all messages to this receiver in this conversation are read
        IF NOT EXISTS (
            SELECT 1 FROM messages
            WHERE conversation_id = NEW.conversation_id
            AND receiver_id = NEW.receiver_id
            AND is_read = FALSE
            AND id <> NEW.id
        ) THEN
            -- Update the conversation to indicate no unread messages
            UPDATE conversations
            SET has_unread_messages = FALSE
            WHERE id = NEW.conversation_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to mark messages as read if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_trigger WHERE tgname = 'mark_messages_as_read_trigger') THEN
        CREATE TRIGGER mark_messages_as_read_trigger
        AFTER UPDATE ON messages
        FOR EACH ROW
        WHEN (NEW.is_read = TRUE AND OLD.is_read = FALSE)
        EXECUTE FUNCTION mark_messages_as_read();
        
        RAISE NOTICE 'Created mark_messages_as_read trigger';
    ELSE
        RAISE NOTICE 'mark_messages_as_read trigger already exists';
    END IF;
END
$$;

-- Add tables to realtime publication if they're not already there
DO $$
BEGIN
    -- Check if supabase_realtime publication exists
    IF EXISTS (SELECT FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        -- Add conversations table to publication if it's not already there
        IF NOT EXISTS (
            SELECT FROM pg_publication_tables 
            WHERE pubname = 'supabase_realtime' 
            AND schemaname = 'public' 
            AND tablename = 'conversations'
        ) THEN
            ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
            RAISE NOTICE 'Added conversations table to supabase_realtime publication';
        ELSE
            RAISE NOTICE 'Conversations table is already in supabase_realtime publication';
        END IF;
        
        -- Add messages table to publication if it's not already there
        IF NOT EXISTS (
            SELECT FROM pg_publication_tables 
            WHERE pubname = 'supabase_realtime' 
            AND schemaname = 'public' 
            AND tablename = 'messages'
        ) THEN
            ALTER PUBLICATION supabase_realtime ADD TABLE messages;
            RAISE NOTICE 'Added messages table to supabase_realtime publication';
        ELSE
            RAISE NOTICE 'Messages table is already in supabase_realtime publication';
        END IF;
    ELSE
        RAISE NOTICE 'supabase_realtime publication does not exist. Please create it manually in the Supabase dashboard.';
    END IF;
END
$$;
