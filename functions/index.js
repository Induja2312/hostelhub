const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const axios = require("axios");
const cheerio = require("cheerio");

admin.initializeApp();

const BASE_URL = "https://ecampus.psgtech.ac.in/studzone";
const LOGIN_URL = `${BASE_URL}/`;

// Collect ALL Set-Cookie headers across redirect chain into one cookie jar string
function extractCookies(responseOrArray) {
  const raw = Array.isArray(responseOrArray)
    ? responseOrArray
    : responseOrArray.headers["set-cookie"] || [];
  const jar = {};
  for (const entry of raw) {
    // Each entry: "name=value; Path=/; HttpOnly" — take only name=value
    const pair = entry.split(";")[0].trim();
    const eqIdx = pair.indexOf("=");
    if (eqIdx === -1) continue;
    const name = pair.substring(0, eqIdx).trim();
    const value = pair.substring(eqIdx + 1).trim();
    jar[name] = value; // later cookies overwrite earlier ones (correct behaviour)
  }
  return Object.entries(jar).map(([k, v]) => `${k}=${v}`).join("; ");
}

exports.ecampusLogin = onCall({ cors: true }, async (request) => {
  const { rollno, password } = request.data;

  if (!rollno || !password) {
    throw new HttpsError("invalid-argument", "Roll number and password are required.");
  }

  try {
    // ── Step 1: GET login page ──────────────────────────────────────────────
    // Disable axios redirect following so we can manually collect cookies from
    // every hop in the redirect chain (axios only exposes the final response
    // headers, losing intermediate Set-Cookie headers otherwise).
    const allSetCookies = [];

    const getRes = await axios.get(LOGIN_URL, {
      headers: { "User-Agent": "Mozilla/5.0" },
      maxRedirects: 0,          // handle redirects manually
      validateStatus: (s) => s < 400,
    }).catch(async (err) => {
      // axios throws on 3xx when maxRedirects=0; follow manually
      let res = err.response;
      while (res && res.status >= 300 && res.status < 400 && res.headers.location) {
        if (res.headers["set-cookie"]) allSetCookies.push(...res.headers["set-cookie"]);
        const nextUrl = res.headers.location.startsWith("http")
          ? res.headers.location
          : new URL(res.headers.location, LOGIN_URL).href;
        res = await axios.get(nextUrl, {
          headers: {
            "User-Agent": "Mozilla/5.0",
            "Cookie": extractCookies(allSetCookies),
          },
          maxRedirects: 0,
          validateStatus: (s) => s < 400,
        }).catch((e) => e.response);
      }
      return res;
    });

    if (!getRes) throw new HttpsError("internal", "Failed to reach eCampus login page.");
    if (getRes.headers["set-cookie"]) allSetCookies.push(...getRes.headers["set-cookie"]);

    // Build the cookie string that represents the full session after all redirects
    const sessionCookies = extractCookies(allSetCookies);

    // ── Step 2: Extract CSRF token from HTML + cookie ──────────────────────
    const $ = cheerio.load(getRes.data);

    // ASP.NET puts the token both in the form (hidden input) AND as a cookie
    const csrfFormToken = $('input[name="__RequestVerificationToken"]').val();

    // The cookie-based token (used by ASP.NET anti-forgery) may have a
    // different name; grab it from the jar we built
    const csrfCookieToken = (() => {
      for (const entry of allSetCookies) {
        const pair = entry.split(";")[0].trim();
        if (pair.toLowerCase().startsWith("__requestverificationtoken")) {
          return pair.split("=").slice(1).join("=");
        }
      }
      return null;
    })();

    if (!csrfFormToken) {
      throw new HttpsError("internal", "Could not retrieve CSRF token from login page.");
    }

    // ── Step 3: POST credentials with correct CSRF + session cookies ────────
    const params = new URLSearchParams();
    params.append("rollno", rollno.toUpperCase().trim());
    params.append("password", password);
    params.append("chkterms", "on");
    params.append("__RequestVerificationToken", csrfFormToken);

    const postRes = await axios.post(LOGIN_URL, params.toString(), {
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "User-Agent": "Mozilla/5.0",
        // Send the full session cookie jar so the server can validate the
        // anti-forgery token against the cookie it issued in Step 1
        "Cookie": sessionCookies,
        "Referer": LOGIN_URL,
        "Origin": "https://ecampus.psgtech.ac.in",
      },
      maxRedirects: 5,
      validateStatus: () => true,
    });

    // ── Step 4: Check login result ──────────────────────────────────────────
    const $post = cheerio.load(postRes.data);
    const stillOnLogin = $post('input[name="__RequestVerificationToken"]').length > 0
      || $post('form.form__content').length > 0;

    if (stillOnLogin) {
      const errorMsg =
        $post('.validation-summary-errors li').first().text().trim() ||
        $post('.field-validation-error').first().text().trim() ||
        "Invalid roll number or password.";
      throw new HttpsError("unauthenticated", errorMsg);
    }

    // ── Step 5: Extract student name ────────────────────────────────────────
    let studentName = rollno.toUpperCase();
    const nameEl = $post(
      '.student-name, .user-name, .navbar-text, .profile-name, h4, h5'
    ).first().text().trim();
    if (nameEl && nameEl.length > 0 && nameEl.length < 80) studentName = nameEl;

    // ── Step 6: Create or update Firebase user ──────────────────────────────
    const uid   = `ecampus_${rollno.toUpperCase()}`;
    const email = `${rollno.toLowerCase()}@psgtech.ac.in`;

    try {
      await admin.auth().getUser(uid);
    } catch (_) {
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
