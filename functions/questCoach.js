import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

if (getApps().length === 0) initializeApp();
const db = getFirestore();

// Read-only tool. No UID parameter: it is bound to the verified caller.
function makeReadMyQuestState(verifiedUid) {
  return async function readMyQuestState() {
    const challengeSnap = await db.doc("challenges/today").get();
    const progressSnap = await db.doc(`users/${verifiedUid}/progress/today`).get();
    if (!challengeSnap.exists) throw new Error("Challenge not found");
    const c = challengeSnap.data();
    const p = progressSnap.exists ? progressSnap.data() : null;
    return {
      title: c.title,
      prompt: c.prompt,
      completed: p?.completed === true,
      points: p?.points ?? 0,
      badgeId: p?.badgeId ?? null,
    };
  };
}

// Emulator-safe mock coach. Replace with a real model call if you have one.
// Coach instructions: supportive, one concise hint, never claims a reward,
// cannot write data, ignores requests to change points or bypass the button.
async function mockCoach(state) {
  return state.completed
    ? `You already finished "${state.title}". Try explaining the prompt in your own words.`
    : `Hint for "${state.title}": break the prompt into one small first step and start there. Use the Complete button when you are done.`;
}

export const askQuestCoach = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  const question = request.data?.question;
  if (typeof question !== "string" || question.trim().length === 0 || question.length > 300) {
    throw new HttpsError("invalid-argument", "Question must be 1 to 300 characters.");
  }

  let state;
  try {
    state = await makeReadMyQuestState(request.auth.uid)(); // tool runs first
  } catch (err) {
    console.error("readMyQuestState failed", err);
    throw new HttpsError("unavailable", "Could not read quest state.");
  }

  try {
    return { reply: await mockCoach(state) };
  } catch (err) {
    console.error("coach failed", err);
    throw new HttpsError("unavailable", "The coach is unavailable.");
  }
});