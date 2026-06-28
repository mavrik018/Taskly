import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Verify User Session from Authorization Header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Initialize client using internal auth token
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    // Get current authenticated user
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Invalid user token" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Parse Body & Route Action
    const { action, ...payload } = await req.json();

    let responseData;
    switch (action) {
      case "parse":
        responseData = await handleParse(payload.sentence, payload.currentDate);
        break;
      case "focus":
        responseData = await handleFocus(payload.tasks, payload.currentDate);
        break;
      case "breakdown":
        responseData = await handleBreakdown(payload.taskTitle);
        break;
      case "weekly":
        responseData = await handleWeekly(payload.completedTasks, payload.overdueTasks, payload.currentDate);
        break;
      case "reschedule":
        responseData = await handleReschedule(payload.overdueTasks, payload.currentDate);
        break;
      default:
        throw new Error(`Unknown action: ${action}`);
    }

    return new Response(JSON.stringify(responseData), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

// Helper functions for Groq API formatting

async function callGroq(prompt: string, maxTokens: number = 800) {
  if (!GROQ_API_KEY) {
    throw new Error("GROQ_API_KEY environment variable is not set");
  }

  const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${GROQ_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      // SWAP OUT THE DECOMMISSIONED LLAMA MODEL HERE:
      model: "llama-3.3-70b-versatile", 
      max_tokens: maxTokens,
      temperature: 0.1, 
      messages: [{ role: "user", content: prompt }],
    }),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Groq API request failed: ${errText}`);
  }

  const result = await response.json();
  return result.choices[0].message.content;
}

/**
 * Clean up text blocks from LLMs that might mistakenly return markdown formatting
 */
function safeJsonParse(text: string) {
  try {
    const cleaned = text.replace(/```json/g, "").replace(/```/g, "").trim();
    return JSON.parse(cleaned);
  } catch (e) {
    throw new Error(`Failed to parse AI response as JSON. Raw response: ${text}`);
  }
}

// ─── ACTION HANDLERS ────────────────────────────────────────────────────────

async function handleParse(sentence: string, currentDate: string) {
  const prompt = `Analyze the following natural sentence for a task and extract structured data.
Current date: ${currentDate}.
Sentence: "${sentence}"

Output only a valid JSON object matching this schema exactly without markdown wrapping:
{
  "title": "Cleaned task title (strip dates, times, and priority words like urgent/asap)",
  "dueDate": "ISO8601 string (e.g. YYYY-MM-DD) or null",
  "time": "Time string in HH:MM format or null",
  "priority": High=1, Medium=2, Low=3, None=4.
}`;
  const response = await callGroq(prompt);
  return safeJsonParse(response);
}

async function handleFocus(tasks: any[], currentDate: string) {
  const prompt = `Based on these pending tasks: ${JSON.stringify(tasks)}. Current Date/Time: ${currentDate}.
Select up to 3 tasks (or fewer if fewer than 3 tasks are pending in total, never return duplicate tasks) for the user to focus on today, and write one short, 
encouraging sentence (max 20 words) explaining why — without naming the tasks 
in the sentence, since they'll be shown separately as a list.
Respond ONLY in this JSON format, no other text:
{
  "message": "short encouraging sentence here",
  "task_ids": [id1, id2]
}`;
  const response = await callGroq(prompt);
  return safeJsonParse(response);
}

async function handleBreakdown(taskTitle: string) {
  const prompt = `Break down the vague task "${taskTitle}" into 5 to 8 concrete, actionable, sequential subtask titles.
Return ONLY a valid JSON array of strings without markdown wrapping: ["subtask 1", "subtask 2", ...]`;
  const response = await callGroq(prompt);
  return safeJsonParse(response);
}

async function handleWeekly(completedTasks: any[], overdueTasks: any[], currentDate: string) {
  const prompt = `Generate a weekly productivity review.
Completed tasks: ${JSON.stringify(completedTasks)}.
Overdue tasks: ${JSON.stringify(overdueTasks)}.
Current time: ${currentDate}.

Format the output as a friendly, analytical paragraph:
"Good week, [Name]. You completed [X] tasks — [comparison]. You consistently delay [Category] tasks on [Day]. Consider blocking [Day] mornings for focused work next week."
Keep it engaging and under 100 words.`;
  const response = await callGroq(prompt);
  return { summary: response.trim() };
}

async function handleReschedule(overdueTasks: any[], currentDate: string) {
  const prompt = `We have these overdue tasks: ${JSON.stringify(overdueTasks)}.
Please distribute their new due dates realistically across the next 3 days starting tomorrow (relative to current date: ${currentDate}).
Return ONLY a JSON array of objects matching this format without markdown wrapping:
[
  {"id": 123, "title": "Task Title", "newDueDate": "YYYY-MM-DDTHH:MM:SS"}
]`;
  const response = await callGroq(prompt);
  return safeJsonParse(response);
}