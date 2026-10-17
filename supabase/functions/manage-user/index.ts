import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const json = (body: Record<string, unknown>, status = 200) =>
  Response.json(body, { status, headers: { "Cache-Control": "no-store" } });

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "Method not allowed." }, 405);

  const authorization = request.headers.get("authorization") ?? "";
  const token = authorization.replace(/^Bearer\s+/i, "").trim();
  if (!token) return json({ error: "Sign in as a company administrator." }, 401);

  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceKey) return json({ error: "User management is not configured." }, 500);

  const admin = createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: authData, error: authError } = await admin.auth.getUser(token);
  const actor = authData.user;
  if (authError || !actor) return json({ error: "Your session is invalid. Sign in again." }, 401);

  const { data: actorProfile, error: actorError } = await admin
    .from("profiles")
    .select("company_id,role,status")
    .eq("id", actor.id)
    .maybeSingle();
  if (actorError || !actorProfile || actorProfile.role !== "admin" || actorProfile.status !== "active") {
    return json({ error: "Only an active company administrator can manage users." }, 403);
  }

  let body: Record<string, unknown>;
  try {
    const parsed: unknown = await request.json();
    if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
      return json({ error: "Request body must be a JSON object." }, 400);
    }
    body = parsed as Record<string, unknown>;
  } catch {
    return json({ error: "Request body must be valid JSON." }, 400);
  }

  const action = body.action;
  if (action === "create") {
    const name = typeof body.name === "string" ? body.name.trim() : "";
    const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
    const password = typeof body.password === "string" ? body.password : "";
    const phone = typeof body.phone === "string" ? body.phone.trim() : "";
    const role = body.role;
    if (!name || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || password.length < 12 ||
        (role !== "admin" && role !== "staff")) {
      return json({ error: "Enter a name, valid email, password with at least 12 characters, and valid role." }, 400);
    }

    const { data: created, error: createError } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { name },
    });
    if (createError || !created.user) {
      return json({ error: createError?.message ?? "Could not create the user account." }, 400);
    }

    const { error: profileError } = await admin.from("profiles").insert({
      id: created.user.id,
      company_id: actorProfile.company_id,
      name,
      email,
      phone,
      role,
      status: "active",
    });
    if (profileError) {
      await admin.auth.admin.deleteUser(created.user.id);
      return json({ error: "The account was created but its company profile failed; the account was rolled back." }, 500);
    }
    return json({ id: created.user.id }, 201);
  }

  if (action !== "update" && action !== "remove") {
    return json({ error: "Unknown user management action." }, 400);
  }

  const targetId = typeof body.id === "string" ? body.id : "";
  if (!targetId) return json({ error: "A user id is required." }, 400);
  if (action === "remove" && targetId === actor.id) {
    return json({ error: "You cannot remove your own account." }, 400);
  }

  const { data: target, error: targetError } = await admin
    .from("profiles")
    .select("id,company_id,role,status,email")
    .eq("id", targetId)
    .eq("company_id", actorProfile.company_id)
    .maybeSingle();
  if (targetError || !target) return json({ error: "That user was not found in your company." }, 404);

  if (action === "update") {
    const name = typeof body.name === "string" ? body.name.trim() : "";
    const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
    const password = typeof body.password === "string" ? body.password : "";
    const phone = typeof body.phone === "string" ? body.phone.trim() : "";
    const role = body.role;
    if (!name || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) ||
        (role !== "admin" && role !== "staff") || (password.length > 0 && password.length < 12)) {
      return json({ error: "Enter a name, valid email, optional password of at least 12 characters, and valid role." }, 400);
    }
    if (target.role === "admin" && role !== "admin" && target.status === "active") {
      const { count, error } = await admin.from("profiles")
        .select("id", { count: "exact", head: true })
        .eq("company_id", actorProfile.company_id)
        .eq("role", "admin")
        .eq("status", "active");
      if (error) return json({ error: "Could not verify active administrator count." }, 500);
      if ((count ?? 0) <= 1) return json({ error: "The company must keep at least one active administrator." }, 409);
    }

    const authUpdate: { email?: string; password?: string; user_metadata: { name: string } } = {
      user_metadata: { name },
    };
    if (email !== target.email) authUpdate.email = email;
    if (password) authUpdate.password = password;
    const { error: authUpdateError } = await admin.auth.admin.updateUserById(targetId, authUpdate);
    if (authUpdateError) return json({ error: authUpdateError.message }, 400);

    const { error: profileUpdateError } = await admin.from("profiles").update({
      name, email, phone, role, updated_at: new Date().toISOString(),
    }).eq("id", targetId).eq("company_id", actorProfile.company_id);
    if (profileUpdateError) return json({ error: "Authentication details changed, but the company profile update failed." }, 500);
    return json({ id: targetId });
  }

  if (target.role === "admin" && target.status === "active") {
    const { count, error } = await admin.from("profiles")
      .select("id", { count: "exact", head: true })
      .eq("company_id", actorProfile.company_id)
      .eq("role", "admin")
      .eq("status", "active");
    if (error) return json({ error: "Could not verify active administrator count." }, 500);
    if ((count ?? 0) <= 1) return json({ error: "The company must keep at least one active administrator." }, 409);
  }

  const { error: banError } = await admin.auth.admin.updateUserById(targetId, {
    ban_duration: "876000h",
  });
  if (banError) return json({ error: banError.message }, 400);
  const { error: disableError } = await admin.from("profiles").update({
    status: "disabled", updated_at: new Date().toISOString(),
  }).eq("id", targetId).eq("company_id", actorProfile.company_id);
  if (disableError) return json({ error: "Sign-in was blocked, but the profile could not be disabled." }, 500);
  return json({ id: targetId, status: "disabled" });
});
