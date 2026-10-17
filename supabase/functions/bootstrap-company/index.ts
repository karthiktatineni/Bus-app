import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  if (req.method !== "POST") return Response.json({ error: "Method not allowed" }, { status: 405 });
  const configuredSecret = Deno.env.get("BOOTSTRAP_SECRET");
  if (!configuredSecret || req.headers.get("x-bootstrap-secret") !== configuredSecret) {
    return Response.json({ error: "Unauthorized" }, { status: 401 });
  }
  const body = await req.json();
  if (typeof body.company_name !== "string" || typeof body.admin_name !== "string" ||
      typeof body.admin_email !== "string" || !body.company_name.trim()) {
    return Response.json({ error: "Company and administrator details are required." }, { status: 400 });
  }
  const client = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { count, error: checkError } = await client.from("profiles").select("id", { count: "exact", head: true });
  if (checkError) return Response.json({ error: "Could not verify bootstrap state." }, { status: 500 });
  if ((count ?? 0) > 0) return Response.json({ error: "Bootstrap has already been completed." }, { status: 409 });
  const { data: company, error: companyError } = await client.from("companies")
    .insert({ name: body.company_name.trim() }).select("id").single();
  if (companyError) return Response.json({ error: "Could not create company." }, { status: 500 });
  const { data, error } = await client.auth.admin.inviteUserByEmail(body.admin_email, {
    data: { name: body.admin_name },
  });
  if (error || !data.user) {
    await client.from("companies").delete().eq("id", company.id);
    return Response.json({ error: "Could not invite primary administrator." }, { status: 400 });
  }
  const { error: profileError } = await client.from("profiles").insert({
    id: data.user.id, company_id: company.id, name: body.admin_name,
    email: body.admin_email, role: "admin", status: "invited",
  });
  if (profileError) {
    await client.auth.admin.deleteUser(data.user.id);
    await client.from("companies").delete().eq("id", company.id);
    return Response.json({ error: "Could not create administrator profile." }, { status: 500 });
  }
  await client.from("company_settings").insert({ company_id: company.id });
  return Response.json({ company_id: company.id, admin_user_id: data.user.id }, { status: 201 });
});
