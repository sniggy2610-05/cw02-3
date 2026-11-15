import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getApps, initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

if (getApps().length === 0) initializeApp();
const db = getFirestore();

export const completeToday = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  if (request.data?.challengeId !== "today") {
    throw new HttpsError("invalid-argument", "Unknown challenge.");
  }
  const uid = request.auth.uid;
  const progressRef = db.doc(`users/${uid}/progress/today`);

  return db.runTransaction(async (transaction) => {
    const progress = await transaction.get(progressRef);
    if (progress.exists) {
      return {
        completed: true,
        points: progress.data().points,
        badgeId: progress.data().badgeId,
        alreadyCompleted: true,
      };
    }
    const reward = {
      completed: true,
      points: 10,
      badgeId: "first-quest",
      completedAt: FieldValue.serverTimestamp(),
    };
    transaction.set(progressRef, reward);
    return {
      completed: true,
      points: reward.points,
      badgeId: reward.badgeId,
      alreadyCompleted: false,
    };
  });
});

export { askQuestCoach } from "./questCoach.js";