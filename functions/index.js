const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const axios = require("axios");
const cheerio = require("cheerio");

admin.initializeApp();

const BASE_URL = "https://ecampus.psgtech.ac.in/studzone";

exports.ecampusLogin = onCall({ cors: true }, async (request) => {
  const { rollno, password } = request.data;

  if (!rollno || !password) {
    throw new HttpsError("invalid-argument", "Roll number and password are required.");
  }

  try {
    // Step 1: GET login page for CSRF token + session cookie
    const getRes = await axios.get(`${BASE_URL}/`, {
      headers: { "User-Agent": "Mozilla/5.0" },
    });

    const cookies = getRes.headers["set-cookie"]
      ? getRes.headers["set-cookie"].map((c) => c.split(";")[0]).join("; ")
      : "";

    const $ = cheerio.load(getRes.data);
    const csrfToken = $('input[name="__RequestVerificationToken"]').val();

    if (!csrfToken) {
      throw new HttpsError("internal", "Could not retrieve CSRF token.");
    }

    // Step 2: POST credentials
    const params = new URLSearchParams();
    params.append("rollno", rollno.toUpperCase().trim());
    params.append("password", password);
    params.append("chkterms", "on");
    params.append("__RequestVerificationToken", csrfToken);

    const postRes = await axios.post(`${BASE_URL}`, params.toString(), {
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "User-Agent": "Mozilla/5.0",
        "Cookie": cookies,
        "Referer": `${BASE_URL}/`,
      },
      maxRedirects: 5,
      validateStatus: () => true,
    });

    // Step 3: Check if login succeeded
    const $post = cheerio.load(postRes.data);
    const stillOnLogin = $post('form.form__content').length > 0;

    if (stillOnLogin) {
      const errorMsg = $post('.validation-summary-errors li').first().text().trim();
      throw new HttpsError(
        "unauthenticated",
        errorMsg || "Invalid roll number or password."
      );
    }

    // Step 4: Extract student name
    let studentName = rollno.toUpperCase();
    const nameEl = $post('.student-name, .user-name, .navbar-text, h4').first().text().trim();
    if (nameEl && nameEl.length > 0 && nameEl.length < 60) studentName = nameEl;

    // Step 5: Create or get Firebase user
    const uid = `ecampus_${rollno.toUpperCase()}`;
    const email = `${rollno.toLowerCase()}@psgtech.ac.in`;

    try {
      await admin.auth().getUser(uid);
    } catch (e) {
      await admin.auth().createUser({ uid, email, displayName: studentName });
      await admin.firestore().collection("users").doc(uid).set({
        uid,
        name: studentName,
        email,
        role: "student",
        rollNumber: rollno.toUpperCase(),
        roomNumber: "",
        hostelBlock: "",
        phone: "",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    const customToken = await admin.auth().createCustomToken(uid);
    return { token: customToken, name: studentName };

  } catch (e) {
    if (e instanceof HttpsError) throw e;
    throw new HttpsError("internal", e.message);
  }
});
