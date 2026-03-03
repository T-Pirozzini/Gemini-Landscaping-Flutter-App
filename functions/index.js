const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

/**
 * Triggered when a new repair entry is created for any equipment.
 * Sends a push notification to all admin users if the priority is medium or high.
 */
exports.onEquipmentIssueCreated = onDocumentCreated(
  "equipment/{equipmentId}/repair_entries/{entryId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const entry = snapshot.data();
    const priority = entry.priority || "low";

    // Only notify for medium and high priority issues
    if (priority !== "medium" && priority !== "high") {
      return;
    }

    const db = getFirestore();
    const equipmentId = event.params.equipmentId;

    // Get equipment name for the notification
    const equipmentDoc = await db
      .collection("equipment")
      .doc(equipmentId)
      .get();
    const equipmentName = equipmentDoc.exists
      ? equipmentDoc.data().name
      : "Unknown Equipment";

    // Query all admin users who have an FCM token
    const adminsSnapshot = await db
      .collection("Users")
      .where("role", "==", "admin")
      .get();

    if (adminsSnapshot.empty) {
      console.log("No admin users found");
      return;
    }

    // Collect valid FCM tokens
    const tokens = [];
    adminsSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.fcmToken) {
        tokens.push(data.fcmToken);
      }
    });

    if (tokens.length === 0) {
      console.log("No admin FCM tokens found");
      return;
    }

    // Build notification
    const priorityLabel = priority.charAt(0).toUpperCase() + priority.slice(1);
    const description = entry.description || "No description provided";
    const reporter = entry.reportedBy || "Unknown";
    const siteName = entry.linkedSiteName;

    const title = `Equipment Alert: ${equipmentName}`;
    let body = `${priorityLabel} priority — ${description}`;
    if (siteName) {
      body += ` (at ${siteName})`;
    }
    body += ` — Reported by ${reporter.split("@")[0]}`;

    // Send to all admin tokens
    const message = {
      notification: { title, body },
      data: {
        equipmentId,
        priority,
        type: "equipment_issue",
      },
    };

    const results = await Promise.allSettled(
      tokens.map((token) =>
        getMessaging().send({ ...message, token })
      )
    );

    // Clean up invalid tokens
    for (let i = 0; i < results.length; i++) {
      if (results[i].status === "rejected") {
        const error = results[i].reason;
        if (
          error.code === "messaging/invalid-registration-token" ||
          error.code === "messaging/registration-token-not-registered"
        ) {
          // Find and remove the stale token
          const staleToken = tokens[i];
          const staleAdmins = await db
            .collection("Users")
            .where("fcmToken", "==", staleToken)
            .get();
          for (const doc of staleAdmins.docs) {
            await doc.ref.update({ fcmToken: null });
            console.log(`Removed stale FCM token for user ${doc.id}`);
          }
        } else {
          console.error(`Failed to send to token ${i}:`, error);
        }
      }
    }

    const successCount = results.filter(
      (r) => r.status === "fulfilled"
    ).length;
    console.log(
      `Sent ${successCount}/${tokens.length} notifications for ${equipmentName} (${priority})`
    );
  }
);
