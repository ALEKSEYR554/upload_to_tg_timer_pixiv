automade with copilot bc im bored and it lgtm

# upload_to_tg_timer_pixiv

This repository automates uploading images from a local folder to a Telegram channel and its linked comments channel, with support for Pixiv metadata and scheduled posting. Below is a high-level description of how the main logic works, as implemented in [`upload.rb`](https://github.com/ALEKSEYR554/upload_to_tg_timer_pixiv/blob/23c4ce292a5202bbe4de693a7bbee39ff7c02f7a/upload.rb).

---

## Features

- **Automated Telegram Posting:** Uploads images to a Telegram channel and posts originals as documents in the linked comments channel.
- **Pixiv Metadata:** Extracts author information from Pixiv for images named in Pixiv's format and adds it to the caption.
- **Archive Backups:** Periodically compresses uploaded images (after `HOUR_SLEEP` is reached, i.e., after the posting hour ends) and sends the archive to a backup channel.
- **Scheduling:** Posts are spaced out by a configurable wait time and only happen during configurable hours.
- **Image Compression:** Large images are resized and compressed before posting.
- **Error Handling & Logging:** Robust error handling with retries and detailed logging.

---

## How It Works

### 1. Initialization

- Loads environment variables from `.env` (API keys, folder paths, channel IDs, etc.).
- Starts a local Telegram Bot API server in a separate thread.
- Creates necessary folders (`uploaded`, `compress`, `7z_archives`) if missing.

### 2. Telegram Client Setup

- Runs the Telegram bot using the provided token.
- Fetches the main channel and its linked comments channel.

### 3. File Grouping

- Scans the specified images folder for files (`jpg`, `png`, `jpeg`).
- Groups images by their Pixiv artwork ID (prefix before `_p`), shuffles the post order, and calculates the expected completion time.

### 4. Main Posting Loop

For each group of images:

- **Scheduling:** Waits until posting is allowed (awake hours), sleeping and archiving as needed.
- **Pixiv Metadata:** If file matches Pixiv format, fetches author name from Pixiv API for caption.
- **Image Compression:** Images exceeding size/dimension limits are resized and compressed.
- **Uploading:**
  - Posts compressed images as photos to the channel.
  - Posts original images as documents in the comments channel, replying to the photo post.
  - Handles both single and multi-image groups, batching uploads in groups of 10.
- **Error Handling:** On API errors (rate limits, timeouts, server errors), retries as needed.
- **Archiving:** When sleep hour (`HOUR_SLEEP`) is reached, compresses all uploaded images and sends archive to backup channel.
- **File Management:** Moves processed images to the `uploaded` folder.

### 5. Completion

- After all posts, sends a completion message to the admin user.
- Cleans up and stops the local Telegram Bot API server.

---

## Environment Variables

- `TELEGRAM_BOT_API_KEY` — Telegram bot token
- `TELEGRAM_APP_ID` / `TELEGRAM_APP_HASH` — For local Telegram API server
- `CHANNEL_ID` — Main Telegram channel ID
- `ADMIN_USER_ID` — Telegram user ID to send status messages
- `BACKUP_CHANNEL_ID` — Channel ID for backup archives
- `FOLDER_WITH_IMAGES` — Path to images folder
- `SLEEP_MINUTES` — Delay between posts (in minutes)
- `TIME_OFFSET` — Offset for server time
- `HOUR_AWAKE` / `HOUR_SLEEP` — Posting start/end hour

---

## Usage

1. **Install required gems:**
   ```sh
   gem install telegram-bot-ruby mini_magick fileutils json logger dotenv faraday
   ```
2. **Install [ImageMagick](https://imagemagick.org/script/download.php):**
   - On **Windows**: During installation, make sure to check "Install legacy utilities ( mogrify)".
   - On Linux/macOS: Usually, mogrify is included by default.
3. **Install [7-Zip](https://www.7-zip.org/download.html):**  
   Ensure the `7za` command-line tool is available in your system's PATH.
4. Set up your `.env` file with the required variables.
5. Put your images in the designated folder.
6. Run the script:
   ```sh
   ruby upload.rb
   ```

---

## Notes

- Only images following the Pixiv naming convention (`<id>_p<page>.<ext>`) will have author metadata and source links.
- Archives are created using `7za` and sent to the backup channel **after the posting hour ends (`HOUR_SLEEP`)**.
- Logging is written to `pixiv_logger.log`.

---

## License

MIT
