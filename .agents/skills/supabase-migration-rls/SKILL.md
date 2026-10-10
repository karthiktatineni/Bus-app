---
name: supabase-migration-rls
description: How to write a migration, add RLS policies for admin/staff and company isolation, write SQL tests that prove cross-company and staff-escalation attempts fail.
---
# supabase-migration-rls

## When to use
When changing the database schema or security rules.

## Procedure
1. Create a new migration file in `supabase/migrations/`.
2. Write DDL statements to create/alter tables.
3. Enable RLS: `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;`.
4. Write policies enforcing `company_id` isolation.
5. Write policies enforcing `role` (admin vs staff).
6. Write pgTAP tests or equivalent SQL tests proving isolation.

## Definition of Done
- Migration runs cleanly.
- RLS tests pass, proving unauthorized access fails.
