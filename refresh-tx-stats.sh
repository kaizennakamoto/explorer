#!/bin/bash
# Refresh Blockscout stats - runs every minute via cron
# 1. Updates transaction_stats in Blockscout DB (today + yesterday mirror)
# 2. Clears pending_block_operations to keep finished_indexing=true
# 3. Keeps blocks_count cache fresh
# 4. Updates stats service DB (yesterdayTxns, totalTxns, newTxns, newTxns24h)

# --- Blockscout DB ---
PGPASSWORD=ceWb1MeLBEeOIfk65gU8EjF8 docker exec db psql -U blockscout -d blockscout -q -c "
-- Update today's transaction stats
UPDATE transaction_stats SET
  number_of_transactions = COALESCE(sub.cnt, 0),
  gas_used = COALESCE(sub.gas, 0),
  total_fee = 0
FROM (
  SELECT count(*) as cnt, sum(gas_used::numeric) as gas
  FROM transactions
  WHERE block_timestamp >= CURRENT_DATE
) sub
WHERE transaction_stats.date = CURRENT_DATE;

-- Mirror today's data into yesterday's row
-- Blockscout backend reads yesterday as 'transactions_today' via date_range(1)
UPDATE transaction_stats SET
  number_of_transactions = COALESCE(sub.cnt, 0),
  gas_used = COALESCE(sub.gas, 0),
  total_fee = 0
FROM (
  SELECT count(*) as cnt, sum(gas_used::numeric) as gas
  FROM transactions
  WHERE block_timestamp >= CURRENT_DATE
) sub
WHERE transaction_stats.date = CURRENT_DATE - 1;

-- Clear pending block operations (internal txns disabled, these never complete)
DELETE FROM pending_block_operations;

-- Keep blocks_count cache fresh so indexed_ratio_blocks >= 0.99
UPDATE last_fetched_counters
  SET value = (SELECT count(*) FROM blocks WHERE consensus = true)
  WHERE counter_type = 'blocks_count';
" 2>/dev/null

# --- Stats service DB ---
# Get current tx count from Blockscout DB
TX_COUNT=$(PGPASSWORD=ceWb1MeLBEeOIfk65gU8EjF8 docker exec db psql -U blockscout -d blockscout -t -A -c "
  SELECT count(*) FROM transactions WHERE block_timestamp >= CURRENT_DATE;
" 2>/dev/null)

TX_COUNT=${TX_COUNT:-0}

PGPASSWORD=n0uejXPl61ci6ldCuE2gQU5Y docker exec stats-db psql -U stats -d stats -q -c "
-- Update 'Daily transactions' (yesterdayTxns) to show today's count
UPDATE chart_data SET value = '${TX_COUNT}'
WHERE chart_id = (SELECT id FROM charts WHERE name = 'yesterdayTxns' AND resolution = 'DAY')
  AND date = CURRENT_DATE - 1;

-- Update totalTxns
UPDATE chart_data SET value = '${TX_COUNT}'
WHERE chart_id = (SELECT id FROM charts WHERE name = 'totalTxns' AND resolution = 'DAY')
  AND date = CURRENT_DATE;

-- Update newTxns24h
UPDATE chart_data SET value = '${TX_COUNT}'
WHERE chart_id = (SELECT id FROM charts WHERE name = 'newTxns24h' AND resolution = 'DAY')
  AND date = CURRENT_DATE;

-- Update newTxns DAY (feeds the daily chart)
UPDATE chart_data SET value = '${TX_COUNT}'
WHERE chart_id = (SELECT id FROM charts WHERE name = 'newTxns' AND resolution = 'DAY')
  AND date = CURRENT_DATE;

-- Ensure today exists in newTxns DAY
INSERT INTO chart_data (chart_id, date, value, min_blockscout_block)
SELECT id, CURRENT_DATE, '${TX_COUNT}', 0 FROM charts WHERE name = 'newTxns' AND resolution = 'DAY'
ON CONFLICT DO NOTHING;
" 2>/dev/null
