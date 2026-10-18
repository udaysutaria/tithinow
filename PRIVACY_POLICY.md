# Privacy Policy for TithiNow

**Effective Date:** October 18, 2026  
**Last Updated:** October 18, 2026  

Welcome to **TithiNow** ("we", "our", or "us"). We are committed to protecting your privacy and ensuring you have a transparent, trustworthy experience. This Privacy Policy explains how our mobile and desktop application **TithiNow** handles information.

---

## 1. Summary: Privacy-First by Design

TithiNow is built as an **offline-first, privacy-focused Vedic Panchang application**. 

* **No Personal Data Collected:** We do not collect, store, sell, or share your personal information.
* **No Account Required:** You can use all features of TithiNow without creating an account or logging in.
* **No Tracking or Advertising:** Version 1.0 of TithiNow contains no third-party tracking SDKs, no behavioral profiling, and no advertisements.
* **Calculations on Device:** All astronomical and Panchang calculations (Tithi, Nakshatra, Choghadiya, Muhurta) are computed locally on your device.

---

## 2. Information We Do NOT Collect

We do not collect any of the following:
* Names, email addresses, phone numbers, or contact details.
* Precise GPS location or background location data.
* Device identifiers, Advertising IDs, or biometric data.
* Financial, banking, or payment information.
* Cookies, IP logs, or browsing history.

---

## 3. Data Stored Locally on Your Device

To provide accurate timings and remember your preferences, TithiNow stores small configuration data **locally on your device** using an internal SQLite database:

1. **Selected City:** When you select a city from our offline list of 7,100+ cities, your chosen city name and its geographic coordinates (latitude and longitude) are saved locally on your device to calculate sunrise, sunset, and Panchang timings.
2. **Language Preference:** Your selected interface language (English, Hindi, or Gujarati) is saved locally.
3. **Alarms & Reminders:** Alarms you configure for Tithis, Choghadiya, or Muhurats are stored locally and scheduled through your device's native alarm manager.

*This data never leaves your device and is never transmitted to any external server.*

---

## 4. Device Permissions Used

TithiNow requests only the minimal permissions necessary for core alarm and notification features:

* **Notifications (`POST_NOTIFICATIONS`):** Used strictly to alert you when a scheduled Muhurta, Choghadiya, or Tithi alarm rings.
* **Exact Alarms (`SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`):** Required on Android to trigger your devotional and timing alarms at the exact minute requested.
* **Foreground Service (`FOREGROUND_SERVICE`):** Used temporarily to play the alarm ringtone and display the full-screen alarm screen when an alarm fires.
* **Network Access:** Used solely to open external links that you explicitly tap (such as our official website or GitHub source code) in your device's default web browser.

---

## 5. Third-Party Services & Open Source Libraries

TithiNow is open-source software licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**. 

* The application uses the **Swiss Ephemeris** astronomical calculation engine (developed by Astrodienst AG) running as compiled native code directly on your device. It makes no network calls to Astrodienst.
* We do not integrate third-party analytics (such as Google Analytics or Facebook Pixel) or third-party advertising networks in this release.

---

## 6. Children's Privacy (COPPA Compliance)

TithiNow does not address anyone under the age of 13, nor does it knowingly collect personal information from children. Since the application does not collect any personal data whatsoever, it is safe for all audiences.

---

## 7. Data Retention & Deletion

Because all application data is stored locally on your device, you have complete control over it:
* You can reset your data at any time by clearing the app's cache and storage in your device settings.
* Uninstalling the application permanently deletes all locally stored preferences, alarms, and cached data.

---

## 8. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. Any changes will be posted on this page with an updated "Last Updated" date. If we introduce new features that require data collection (such as optional cloud backup), we will notify you and request your consent prior to implementation.

---

## 9. Contact Us

If you have any questions, feedback, or concerns regarding this Privacy Policy, please reach out to us:

* **Email:** [hello@tithinow.com](mailto:hello@tithinow.com) / [support@tithinow.com](mailto:support@tithinow.com)
* **Website:** [https://tithinow.com](https://tithinow.com)
* **Source Code & Issue Tracker:** [https://github.com/udaysutaria/tithinow](https://github.com/udaysutaria/tithinow)
* **Developer:** Uday Sutaria
