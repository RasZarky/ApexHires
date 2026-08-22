import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { targetUserId, title, body, type, data } = await req.json();

    if (!targetUserId || !title || !body) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: targetUserId, title, body" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // OneSignal credentials from Supabase secrets
    const oneSignalAppId = (Deno.env.get("ONESIGNAL_APP_ID") || "").trim();
    const oneSignalApiKey = (Deno.env.get("ONESIGNAL_REST_API_KEY") || "").trim();

    console.log("App ID length:", oneSignalAppId.length, "starts with:", oneSignalAppId.substring(0, 8));
    console.log("API Key length:", oneSignalApiKey.length, "starts with:", oneSignalApiKey.substring(0, 8));

    if (!oneSignalAppId || !oneSignalApiKey) {
      console.error("OneSignal credentials not configured. ONESIGNAL_APP_ID:", oneSignalAppId ? "set" : "missing", "ONESIGNAL_REST_API_KEY:", oneSignalApiKey ? "set" : "missing");
      return new Response(
        JSON.stringify({ error: "Push notifications not configured. Run: supabase secrets set ONESIGNAL_APP_ID=... ONESIGNAL_REST_API_KEY=..." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Validate UUID format for app_id
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(oneSignalAppId)) {
      console.error("ONESIGNAL_APP_ID is not a valid UUID. Got:", oneSignalAppId);
      return new Response(
        JSON.stringify({ error: "ONESIGNAL_APP_ID is not a valid UUID format" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Send push notification via OneSignal REST API
    // Uses external_user_id which we set via OneSignal.login(userId) in the Flutter app
    const oneSignalResponse = await fetch(
      "https://onesignal.com/api/v1/notifications",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          Authorization: `Basic ${oneSignalApiKey}`,
        },
        body: JSON.stringify({
          app_id: oneSignalAppId,
          include_external_user_ids: [targetUserId],
          headings: { en: title },
          contents: { en: body },
          data: data || { type },
          // Web-specific
          web_buttons: data?.action_url
            ? [{ id: "open", text: "Open", url: data.action_url }]
            : undefined,
          // iOS-specific
          ios_badgeType: "Increase",
          ios_badgeCount: 1,
        }),
      }
    );

    const result = await oneSignalResponse.json();

    if (!oneSignalResponse.ok) {
      console.error("OneSignal error:", result);
      return new Response(
        JSON.stringify({ error: "Failed to send push", details: result }),
        { status: oneSignalResponse.status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`✅ Push sent to ${targetUserId}: ${title} (id: ${result.id})`);

    return new Response(
      JSON.stringify({ success: true, id: result.id, recipients: result.recipients }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Edge function error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
