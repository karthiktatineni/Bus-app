import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  if (req.method !== "POST") return Response.json({ error: "Method not allowed" }, { status: 405 });
  const authorization = req.headers.get("Authorization");
  if (!authorization) return Response.json({ error: "Unauthorized" }, { status: 401 });
  const url = Deno.env.get("SUPABASE_URL")!;
  const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const userClient = createClient(url, anon, { global: { headers: { Authorization: authorization } } });
  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) return Response.json({ error: "Unauthorized" }, { status: 401 });
  const adminClient = createClient(url, serviceRole);
  const { data: profile } = await adminClient.from("profiles").select("company_id,role,status").eq("id", user.id).single();
  if (!profile || profile.role !== "admin" || profile.status !== "active") {
    return Response.json({ error: "Administrator access required." }, { status: 403 });
  }
  const body = await req.json();
  if (body.action !== "invite" || !["admin", "staff"].includes(body.role) ||
      typeof body.email !== "string" || typeof body.name !== "string") {
    return Response.json({ error: "Invalid invitation details." }, { status: 400 });
  }
  const { data, error } = await adminClient.auth.admin.inviteUserByEmail(body.email, {
    data: { name: body.name },
  });
  if (error || !data.user) return Response.json({ error: "Could not send user invitation." }, { status: 400 });
  const { error: insertError } = await adminClient.from("profiles").insert({
    id: data.user.id, company_id: profile.company_id, name: body.name,
    email: body.email, phone: body.phone ?? "", role: body.role, status: "invited",
  });
  if (insertError) {
    await adminClient.auth.admin.deleteUser(data.user.id);
    return Response.json({ error: "Could not create user profile." }, { status: 500 });
  }
  return Response.json({ id: data.user.id }, { status: 201 });
});
