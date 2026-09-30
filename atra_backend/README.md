# Atra Backend API (Firebase-Mediated)

This is the real Python Backend API for the **Atra** Project Handover System. 
It acts as a secure middleware layer between the **Flutter App** and **Firebase Firestore** using the **Firebase Admin SDK**.

---

## Target Architecture

```
                 Flutter App
                      │
                      │ HTTP / JSON (Port 8000)
                      ▼
               FastAPI REST API
                      │
                      │ Firebase Admin SDK
                      ▼
               Firebase Firestore
```

---

## Configuration & Credentials

The backend needs access to your Firebase project. To do this:

1. Go to the **Firebase Console** ➔ **Project Settings** ➔ **Service Accounts**.
2. Click **Generate New Private Key**, which downloads a `.json` file.
3. Save this file inside the `atra_backend/` folder and name it `firebase-credentials.json`.
4. (Optional) Customize the configuration in the `.env` file (copied from `.env.example`).

---

## How to Run Locally

1. Install Python dependencies:
   ```bash
   pip install fastapi uvicorn firebase-admin pydantic python-dotenv
   ```
2. Start the FastAPI server:
   ```bash
   python -m uvicorn app.main:app --port 8000 --reload
   ```

---

## How to Run with Docker

To build and run the backend inside a Docker container:

```bash
docker compose up --build -d
```
*Note: The `docker-compose.yml` mounts the `./firebase-credentials.json` file securely into the container at runtime. Ensure the file is present in the `atra_backend/` folder before launching.*

---

## API Documentation (Swagger UI)

When the server is running, access the interactive API docs at:
👉 **`http://localhost:8000/docs`**
