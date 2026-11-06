const {setGlobalOptions} = require("firebase-functions");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {
  getFirestore,
  Timestamp,
  FieldValue,
} = require("firebase-admin/firestore");
const crypto = require("crypto");

setGlobalOptions({maxInstances: 10});
initializeApp();

const db = getFirestore();

const CODE_COLLECTION = "staffJoinCodes";
const ATTEMPT_COLLECTION = "staffJoinAttempts";
const CODE_LIFETIME_MS = 24 * 60 * 60 * 1000;
const MAX_FAILED_ATTEMPTS = 5;
const ATTEMPT_WINDOW_MS = 15 * 60 * 1000;

/**
 * Requires an authenticated callable request.
 * @param {object} request The callable request.
 * @return {string} The authenticated user UID.
 */
function requireAuth(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Please sign in first.");
  }
  return request.auth.uid;
}

/**
 * Normalizes an email address.
 * @param {string} value The email address.
 * @return {string} The normalized email address.
 */
function normalizeEmail(value) {
  return typeof value === "string" ? value.trim().toLowerCase() : "";
}

/**
 * Hashes a joining code using SHA-256.
 * @param {string} code The joining code.
 * @return {string} The hexadecimal hash.
 */
function hashCode(code) {
  return crypto.createHash("sha256").update(code).digest("hex");
}

/**
 * Generates an eight-character joining code.
 * @return {string} The generated code.
 */
function generateCode() {
  // Avoid visually ambiguous characters.
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  const bytes = crypto.randomBytes(10);
  let result = "";
  for (let i = 0; i < 8; i++) {
    result += alphabet[bytes[i] % alphabet.length];
  }
  return result;
}

/**
 * Validates an owner and retrieves business details.
 * @param {string} uid The owner user ID.
 * @return {Promise<object>} The owner business details.
 */
async function getActiveOwner(uid) {
  const snapshot = await db.collection("users").doc(uid).get();
  if (!snapshot.exists) {
    throw new HttpsError("permission-denied", "Owner profile not found.");
  }

  const profile = snapshot.data();
  const businessId = profile.businessId;
  const status = profile.status;

  if (
    profile.role !== "owner" ||
    (status != null && status !== "active") ||
    typeof businessId !== "string" ||
    !businessId.trim()
  ) {
    throw new HttpsError(
        "permission-denied",
        "Only an active business owner can manage joining codes.",
    );
  }

  return {businessId, email: normalizeEmail(profile.email)};
}

exports.generateStaffJoinCode = onCall(async (request) => {
  const uid = requireAuth(request);
  const {businessId} = await getActiveOwner(uid);

  const code = generateCode();
  const codeHash = hashCode(code);
  const now = Date.now();
  const expiresAt = Timestamp.fromMillis(now + CODE_LIFETIME_MS);

  const codeRef = db.collection(CODE_COLLECTION).doc(businessId);

  await db.runTransaction(async (transaction) => {
    transaction.set(codeRef, {
      businessId,
      codeHash,
      createdBy: uid,
      createdAt: Timestamp.fromMillis(now),
      expiresAt,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  // Plaintext code is returned once and is never stored in Firestore.
  return {
    code,
    expiresAt: expiresAt.toDate().toISOString(),
  };
});

exports.submitStaffJoinCode = onCall(async (request) => {
  const uid = requireAuth(request);
  const authEmail = normalizeEmail(request.auth.token.email);

  if (!authEmail) {
    throw new HttpsError(
        "failed-precondition",
        "Your account must have a verified email address.",
    );
  }

  const inputCode = typeof request.data && request.data.code === "string" ?
    request.data.code.trim().toUpperCase() : "";

  if (!/^[A-HJ-NP-Z2-9]{8}$/.test(inputCode)) {
    throw new HttpsError("invalid-argument", "Enter a valid joining code.");
  }

  const profileRef = db.collection("users").doc(uid);
  const requestRef = db.collection("joinRequests").doc(uid);
  const attemptRef = db.collection(ATTEMPT_COLLECTION).doc(uid);
  const codeHash = hashCode(inputCode);

  const outcome = await db.runTransaction(async (transaction) => {
    const [profileSnap, requestSnap, attemptSnap] = await Promise.all([
      transaction.get(profileRef),
      transaction.get(requestRef),
      transaction.get(attemptRef),
    ]);

    if (profileSnap.exists) {
      throw new HttpsError(
          "already-exists",
          "Your account already has an assigned business profile.",
      );
    }

    if (requestSnap.exists) {
      throw new HttpsError(
          "already-exists",
          "You already have a join request. Please wait for the " +
            "owner to review it.",
      );
    }

    const now = Date.now();
    const attempts = attemptSnap.exists ? attemptSnap.data() : {};
    const windowStartedAt = attempts.windowStartedAt &&
      typeof attempts.windowStartedAt.toMillis === "function" ?
        attempts.windowStartedAt.toMillis() : 0;
    const windowExpired = now - windowStartedAt >= ATTEMPT_WINDOW_MS;
    const failedAttempts = windowExpired ? 0 : (attempts.failedAttempts || 0);

    if (failedAttempts >= MAX_FAILED_ATTEMPTS) {
      throw new HttpsError(
          "resource-exhausted",
          "Too many attempts. Please wait 15 minutes before trying again.",
      );
    }

    const candidateQuery = db.collection(CODE_COLLECTION)
        .where("codeHash", "==", codeHash)
        .limit(1);
    const candidateSnap = await transaction.get(candidateQuery);

    let validCodeDoc = null;
    if (!candidateSnap.empty) {
      const candidate = candidateSnap.docs[0];
      const data = candidate.data();
      if (data.expiresAt && data.expiresAt.toMillis() > now) {
        validCodeDoc = {ref: candidate.ref, data};
      }
    }

    if (!validCodeDoc) {
      const nextFailedAttempts = failedAttempts + 1;
      transaction.set(attemptRef, {
        failedAttempts: nextFailedAttempts,
        windowStartedAt: windowExpired ?
          Timestamp.fromMillis(now) : attempts.windowStartedAt,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});

      return {invalid: true};
    }

    const businessId = validCodeDoc.data.businessId;
    if (typeof businessId !== "string" || !businessId.trim()) {
      throw new HttpsError(
          "internal",
          "The joining code is not configured correctly.",
      );
    }

    transaction.create(requestRef, {
      businessId,
      email: authEmail,
      status: "pending",
      createdAt: Timestamp.fromMillis(now),
    });

    transaction.set(attemptRef, {
      failedAttempts: 0,
      windowStartedAt: Timestamp.fromMillis(now),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});

    return {invalid: false};
  });

  if (outcome.invalid) {
    throw new HttpsError(
        "permission-denied",
        "The joining code is invalid or expired.",
    );
  }

  return {
    success: true,
    message: "Your request has been sent to the business owner for approval.",
  };
});
