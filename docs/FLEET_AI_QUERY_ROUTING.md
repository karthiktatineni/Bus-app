# Fleet AI Query Routing

Fleet AI must use the authenticated Supabase RPCs below for operational data. It must not write ad hoc SQL, query another company, or infer database facts from chat history. RPC functions apply company scoping on the database side.

| User intent / example | Assistant tool | Supabase RPC and arguments | Retrieval path |
|---|---|---|---|
| Fleet totals, active vehicles, vehicles in workshop: “How many buses are active?” | `fleet_summary` | `rpc_get_fleet_summary()` | Live database only |
| Vehicle status, odometer, registration, last service: “What is the status of KA 01 AB 1234?” | `vehicle_status` | `rpc_query_vehicle_status(search_query text)` | Live database only |
| Due soon / overdue work: “Which buses are overdue?” | `due_maintenance` | `rpc_get_due_maintenance(days_ahead integer)` | Live database only |
| Expiring permits/insurance/documents: “Which documents expire this month?” | `expiring_documents` | `rpc_get_expiring_documents(within_days integer)` | Live database only |
| Spending, bill totals, service costs: “How much did we spend?” | `cost_breakdown` | `rpc_get_cost_breakdown(start_date date, end_date date, p_vehicle_id uuid)` | Live database only; defaults to the last 30 calendar days and the whole company |
| Repair instructions, manual specifications, troubleshooting: “How do I inspect the brake system?” | RAG retrieval | Create a 2048-dimension NVIDIA embedding, then `rpc_search_fleet_knowledge(p_embedding vector(2048), p_limit integer)` | Authorized company/shared knowledge chunks, then answer with citations |
| Add/replace knowledge documents | Ingestion process only | `rpc_ingest_fleet_knowledge(p_company_id uuid, p_source_name text, p_chunk_text text, p_embedding vector(2048))` | Server-side service role only; never callable as a chatbot tool |

## Cost RPC contract

The cost function requires both ISO date arguments (`start_date`, `end_date`). The backend always sends both and uses `p_vehicle_id: null` for company-wide cost totals. A non-null vehicle value must be a UUID already visible in the conversation or trusted database tool output. A registration such as `KA 01 AB 1234`, a vehicle name, an empty string, or the word `all` is never passed to the UUID field.

If a model produces invalid dates, the backend substitutes its documented 30-day date window. Missing vehicle scope means a company-wide total. An invalid model-produced vehicle identifier is rejected before the cost RPC; the assistant receives a tool error and must resolve the registration with `rpc_query_vehicle_status` or ask the user. It must never silently report company-wide data as vehicle-specific.

## Error handling

The backend logs only the RPC path plus PostgREST `code`, `message`, and `hint` (truncated); it does not log request bodies, access tokens, or user records. HTTP 502 responses identify the failed RPC and PostgREST error code. Typical diagnostic codes:

- `PGRST202`: RPC signature missing from PostgREST schema cache or argument names do not match the deployed function.
- `22P02`: invalid UUID/date argument reached PostgreSQL.
- `42883`: deployed function/signature does not exist.
- `42501`: database permission or function grant issue.
- `22000`: pgvector dimension or vector input error.

When a query fails, use the exact error code and RPC name to repair the migration/function signature or backend mapping. Do not retry arbitrary SQL or use service-role credentials for user chat queries.
