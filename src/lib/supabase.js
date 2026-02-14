import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://wensfyzuxzbdyxlpusij.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndlbnNmeXp1eHpiZHl4bHB1c2lqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA4ODY5NDYsImV4cCI6MjA4NjQ2Mjk0Nn0.TtdATpy-mfv5AGrMm3OEf9mZzr9qxdQM---Q5Cw2S6Q'

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
