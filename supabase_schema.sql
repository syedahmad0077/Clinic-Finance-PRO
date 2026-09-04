-- ========================================================
-- SYED SADIQ POLY CLINIC - FINANCIAL MANAGEMENT DATABASE SCHEMA
-- ========================================================

-- 1. Create Users Table
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    role TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create Transactions Table (Ledger)
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    description TEXT NOT NULL,
    entered_by UUID REFERENCES public.users(id) ON DELETE SET NULL
);

-- 3. Create Patient Lab Receipts Table
CREATE TABLE IF NOT EXISTS public.patient_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    patient_name TEXT NOT NULL,
    age INT,
    gender TEXT,
    contact TEXT,
    tests JSONB NOT NULL,
    total_fee NUMERIC(12, 2) NOT NULL DEFAULT 0,
    amount_paid NUMERIC(12, 2) NOT NULL DEFAULT 0,
    remaining_balance NUMERIC(12, 2) NOT NULL DEFAULT 0,
    entered_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    transaction_id UUID REFERENCES public.transactions(id) ON DELETE SET NULL
);

-- 4. Create Clinic Tokens Table
CREATE TABLE IF NOT EXISTS public.clinic_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    patient_name TEXT NOT NULL,
    contact TEXT,
    token_number INT NOT NULL,
    consultation_fee NUMERIC(12, 2) NOT NULL DEFAULT 0,
    entered_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    transaction_id UUID REFERENCES public.transactions(id) ON DELETE SET NULL
);

-- 5. Seed Default Staff Members
INSERT INTO public.users (id, name, role) VALUES 
    ('11111111-1111-1111-1111-111111111111', 'Muzaffar', 'Lab'),
    ('22222222-2222-2222-2222-222222222222', 'Dr. Naeem Sadiq', 'Clinic')
ON CONFLICT (id) DO NOTHING;

-- 6. Enable Realtime on Core Tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.transactions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.patient_receipts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.clinic_tokens;

-- 7. Row Level Security (RLS) Configuration
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clinic_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read users" ON public.users FOR SELECT USING (true);
CREATE POLICY "Allow public all transactions" ON public.transactions FOR ALL USING (true);
CREATE POLICY "Allow public all patient_receipts" ON public.patient_receipts FOR ALL USING (true);
CREATE POLICY "Allow public all clinic_tokens" ON public.clinic_tokens FOR ALL USING (true);
