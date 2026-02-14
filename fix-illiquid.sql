-- Fix illiquid flags
-- Step 1: Set ALL investments to liquid (is_illiquid = FALSE)
UPDATE investments SET is_illiquid = FALSE;

-- Step 2: Mark only these as illiquid:
-- Indian Property
UPDATE investments 
SET is_illiquid = TRUE 
WHERE LOWER(name) LIKE '%property%' 
   OR LOWER(name) LIKE '%flat%'
   OR LOWER(name) LIKE '%house%'
   OR LOWER(name) LIKE '%real estate%';

-- Locked Crypto Tokens
UPDATE investments 
SET is_illiquid = TRUE 
WHERE LOWER(name) LIKE '%locked%'
   OR LOWER(name) LIKE '%vested%'
   OR LOWER(name) LIKE '%staked%';

-- VAY ESOPs
UPDATE investments 
SET is_illiquid = TRUE 
WHERE LOWER(name) LIKE '%esop%'
   OR LOWER(name) LIKE '%vay%';

-- Verify: Check what's now marked as illiquid
SELECT name, amount, currency, is_illiquid 
FROM investments 
ORDER BY is_illiquid DESC, name;
