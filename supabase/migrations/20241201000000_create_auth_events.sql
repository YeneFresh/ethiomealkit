-- Create auth_events table for monitoring authentication flows
CREATE TABLE IF NOT EXISTS auth_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  event TEXT NOT NULL CHECK (event IN ('link_sent', 'otp_used', 'signin_success', 'signin_error', 'signup_success', 'signup_error', 'password_reset', 'logout')),
  provider TEXT NOT NULL CHECK (provider IN ('magic_link', 'password', 'otp', 'biometric')),
  route TEXT,
  error_code TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_auth_events_user_id ON auth_events(user_id);
CREATE INDEX IF NOT EXISTS idx_auth_events_event ON auth_events(event);
CREATE INDEX IF NOT EXISTS idx_auth_events_provider ON auth_events(provider);
CREATE INDEX IF NOT EXISTS idx_auth_events_created_at ON auth_events(created_at);

-- Enable RLS
ALTER TABLE auth_events ENABLE ROW LEVEL SECURITY;

-- RLS policies: users can only see their own events, admins can see all
CREATE POLICY "Users can view own auth events" ON auth_events
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all auth events" ON auth_events
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
      AND raw_user_meta_data->>'role' = 'admin'
    )
  );

-- Function to log auth events (callable from client)
CREATE OR REPLACE FUNCTION log_auth_event(
  p_event TEXT,
  p_provider TEXT,
  p_route TEXT DEFAULT NULL,
  p_error_code TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_event_id UUID;
BEGIN
  INSERT INTO auth_events (
    user_id,
    event,
    provider,
    route,
    error_code,
    metadata
  ) VALUES (
    auth.uid(),
    p_event,
    p_provider,
    p_route,
    p_error_code,
    p_metadata
  ) RETURNING id INTO v_event_id;
  
  RETURN v_event_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION log_auth_event(TEXT, TEXT, TEXT, TEXT, JSONB) TO authenticated;

